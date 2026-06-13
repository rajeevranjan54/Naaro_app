import 'package:cloud_firestore/cloud_firestore.dart';

enum ConversationStatus { pending, active, expired, blocked }

class ConversationModel {
  final String id;
  final List<String> participantIds;
  final String initiatorId;
  final String receiverId;
  final ConversationStatus status;
  final int initiatorMessageCount;  // messages sent before reply
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final String? lastMessageText;
  final Map<String, int> unreadCounts;

  const ConversationModel({
    required this.id,
    required this.participantIds,
    required this.initiatorId,
    required this.receiverId,
    this.status = ConversationStatus.pending,
    this.initiatorMessageCount = 0,
    required this.createdAt,
    this.lastMessageAt,
    this.lastMessageText,
    this.unreadCounts = const {},
  });

  bool get isUnlocked => status == ConversationStatus.active;
  bool get isPending   => status == ConversationStatus.pending;

  factory ConversationModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ConversationModel(
      id: doc.id,
      participantIds: List<String>.from(d['participantIds'] ?? []),
      initiatorId: d['initiatorId'] ?? '',
      receiverId: d['receiverId'] ?? '',
      status: ConversationStatus.values.firstWhere(
        (e) => e.name == (d['status'] ?? 'pending'),
        orElse: () => ConversationStatus.pending,
      ),
      initiatorMessageCount: d['initiatorMessageCount'] ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageAt: (d['lastMessageAt'] as Timestamp?)?.toDate(),
      lastMessageText: d['lastMessageText'],
      unreadCounts: Map<String, int>.from(d['unreadCounts'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
    'participantIds': participantIds,
    'initiatorId': initiatorId,
    'receiverId': receiverId,
    'status': status.name,
    'initiatorMessageCount': initiatorMessageCount,
    'createdAt': Timestamp.fromDate(createdAt),
    'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
    'lastMessageText': lastMessageText,
    'unreadCounts': unreadCounts,
  };

  ConversationModel copyWith({
    ConversationStatus? status,
    int? initiatorMessageCount,
    DateTime? lastMessageAt,
    String? lastMessageText,
    Map<String, int>? unreadCounts,
  }) {
    return ConversationModel(
      id: id,
      participantIds: participantIds,
      initiatorId: initiatorId,
      receiverId: receiverId,
      status: status ?? this.status,
      initiatorMessageCount: initiatorMessageCount ?? this.initiatorMessageCount,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      unreadCounts: unreadCounts ?? this.unreadCounts,
    );
  }
}
