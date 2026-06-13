import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String nickname;
  final String? bio;
  final String? photoBase64;   // Base64-encoded JPEG — no Storage needed
  final String bleToken;
  final DateTime createdAt;
  final DateTime lastSeen;
  final bool isActive;
  final List<String> blockedUids;

  const UserModel({
    required this.uid,
    required this.nickname,
    this.bio,
    this.photoBase64,
    required this.bleToken,
    required this.createdAt,
    required this.lastSeen,
    this.isActive = true,
    this.blockedUids = const [],
  });

  bool get hasPhoto => photoBase64 != null && photoBase64!.isNotEmpty;

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      nickname: d['nickname'] ?? '',
      bio: d['bio'],
      photoBase64: d['photoBase64'],
      bleToken: d['bleToken'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeen: (d['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: d['isActive'] ?? true,
      blockedUids: List<String>.from(d['blockedUids'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'nickname': nickname,
    'bio': bio,
    'photoBase64': photoBase64,
    'bleToken': bleToken,
    'createdAt': Timestamp.fromDate(createdAt),
    'lastSeen': Timestamp.fromDate(lastSeen),
    'isActive': isActive,
    'blockedUids': blockedUids,
  };

  UserModel copyWith({
    String? nickname,
    String? bio,
    String? photoBase64,
    String? bleToken,
    DateTime? lastSeen,
    bool? isActive,
    List<String>? blockedUids,
  }) {
    return UserModel(
      uid: uid,
      nickname: nickname ?? this.nickname,
      bio: bio ?? this.bio,
      photoBase64: photoBase64 ?? this.photoBase64,
      bleToken: bleToken ?? this.bleToken,
      createdAt: createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isActive: isActive ?? this.isActive,
      blockedUids: blockedUids ?? this.blockedUids,
    );
  }
}
