import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

  // ── Conversations ─────────────────────────────────────────────────────────

  String _conversationId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<ConversationModel?> getConversation(String uid1, String uid2) async {
    final id = _conversationId(uid1, uid2);
    final doc = await _db.collection(AppConstants.colConversations).doc(id).get();
    return doc.exists ? ConversationModel.fromDoc(doc) : null;
  }

  Stream<ConversationModel?> watchConversation(String uid1, String uid2) {
    final id = _conversationId(uid1, uid2);
    return _db
        .collection(AppConstants.colConversations)
        .doc(id)
        .snapshots()
        .map((s) => s.exists ? ConversationModel.fromDoc(s) : null);
  }

  Stream<List<ConversationModel>> watchMyConversations(String uid) {
    return _db
        .collection(AppConstants.colConversations)
        .where('participantIds', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map(ConversationModel.fromDoc)
            .where((c) => c.status != ConversationStatus.blocked)
            .toList());
  }

  Future<ConversationModel> getOrCreateConversation(
      String myUid, String otherUid) async {
    final existing = await getConversation(myUid, otherUid);
    if (existing != null) return existing;

    final id = _conversationId(myUid, otherUid);
    final conv = ConversationModel(
      id: id,
      participantIds: [myUid, otherUid],
      initiatorId: myUid,
      receiverId: otherUid,
      status: ConversationStatus.pending,
      initiatorMessageCount: 0,
      createdAt: DateTime.now(),
      unreadCounts: {myUid: 0, otherUid: 0},
    );

    await _db
        .collection(AppConstants.colConversations)
        .doc(id)
        .set(conv.toMap());
    return conv;
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  Stream<List<MessageModel>> watchMessages(String conversationId) {
    return _db
        .collection(AppConstants.colConversations)
        .doc(conversationId)
        .collection(AppConstants.colMessages)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(MessageModel.fromDoc).toList());
  }

  /// Sends a message. Returns error string if blocked, otherwise null.
  Future<String?> sendMessage({
    required String myUid,
    required String otherUid,
    required String text,
  }) async {
    final conv = await getOrCreateConversation(myUid, otherUid);

    // Enforce pre-reply message limit for initiator
    if (conv.isPending && conv.initiatorId == myUid) {
      if (conv.initiatorMessageCount >= AppConstants.maxPreReplyMessages) {
        return 'waiting_for_reply';
      }
    }

    // Check conversation isn't blocked/expired
    if (conv.status == ConversationStatus.blocked ||
        conv.status == ConversationStatus.expired) {
      return 'conversation_unavailable';
    }

    final msgRef = _db
        .collection(AppConstants.colConversations)
        .doc(conv.id)
        .collection(AppConstants.colMessages)
        .doc();

    final message = MessageModel(
      id: msgRef.id,
      conversationId: conv.id,
      senderId: myUid,
      text: text,
      timestamp: DateTime.now(),
    );

    // Batch write: message + conversation update
    final batch = _db.batch();

    batch.set(msgRef, message.toMap());

    final Map<String, dynamic> convUpdate = {
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageText': text,
      'unreadCounts.$otherUid': FieldValue.increment(1),
    };

    // If initiator is sending before reply
    if (conv.isPending && conv.initiatorId == myUid) {
      convUpdate['initiatorMessageCount'] = FieldValue.increment(1);
    }

    // If receiver replies for first time → unlock conversation
    if (conv.isPending && conv.receiverId == myUid) {
      convUpdate['status'] = ConversationStatus.active.name;
    }

    batch.update(
      _db.collection(AppConstants.colConversations).doc(conv.id),
      convUpdate,
    );

    await batch.commit();
    return null;
  }

  Future<void> markAsRead(String conversationId, String uid) async {
    await _db
        .collection(AppConstants.colConversations)
        .doc(conversationId)
        .update({'unreadCounts.$uid': 0});
  }

  Future<void> blockConversation(String conversationId) async {
    await _db
        .collection(AppConstants.colConversations)
        .doc(conversationId)
        .update({'status': ConversationStatus.blocked.name});
  }
}
