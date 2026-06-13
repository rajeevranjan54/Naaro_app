import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageStatus { sent, delivered, read }

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final MessageStatus status;
  final bool isSystemMessage;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.isSystemMessage = false,
  });

  factory MessageModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      conversationId: d['conversationId'] ?? '',
      senderId: d['senderId'] ?? '',
      text: d['text'] ?? '',
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == (d['status'] ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
      isSystemMessage: d['isSystemMessage'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'conversationId': conversationId,
    'senderId': senderId,
    'text': text,
    'timestamp': Timestamp.fromDate(timestamp),
    'status': status.name,
    'isSystemMessage': isSystemMessage,
  };
}
