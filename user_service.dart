import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image/image.dart' as img;

import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';

class UserService {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<UserCredential> signInAnonymously() =>
      _auth.signInAnonymously();

  Future<void> signOut() => _auth.signOut();

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection(AppConstants.colUsers).doc(uid).get();
    return doc.exists ? UserModel.fromDoc(doc) : null;
  }

  Future<UserModel?> getCurrentUser() async {
    final uid = currentUid;
    if (uid == null) return null;
    return getUser(uid);
  }

  Stream<UserModel?> watchCurrentUser() {
    final uid = currentUid;
    if (uid == null) return Stream.value(null);
    return _db
        .collection(AppConstants.colUsers)
        .doc(uid)
        .snapshots()
        .map((s) => s.exists ? UserModel.fromDoc(s) : null);
  }

  Future<void> createOrUpdateProfile({
    required String nickname,
    String? bio,
    String? photoBase64,
    required String bleToken,
  }) async {
    final uid = currentUid!;
    final existing = await getUser(uid);
    final now = DateTime.now();

    final user = UserModel(
      uid: uid,
      nickname: nickname,
      bio: bio,
      photoBase64: photoBase64 ?? existing?.photoBase64,
      bleToken: bleToken,
      createdAt: existing?.createdAt ?? now,
      lastSeen: now,
    );

    await _db.collection(AppConstants.colUsers).doc(uid).set(user.toMap());
  }

  Future<void> updateBleToken(String uid, String token) async {
    await _db.collection(AppConstants.colUsers).doc(uid).update({
      'bleToken': token,
      'lastSeen': FieldValue.serverTimestamp(),
      'isActive': true,
    });
  }

  Future<void> setInactive() async {
    final uid = currentUid;
    if (uid == null) return;
    await _db.collection(AppConstants.colUsers).doc(uid).update({
      'isActive': false,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<UserModel?> getUserByBleToken(String token) async {
    final query = await _db
        .collection(AppConstants.colUsers)
        .where('bleToken', isEqualTo: token)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return UserModel.fromDoc(query.docs.first);
  }

  /// Compress image → resize to 200×200 → Base64 string (~20–40 KB)
  /// Stored directly in Firestore — no Storage bucket needed.
  Future<String?> encodePhotoToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      // Resize to 200×200 to keep Firestore document small
      final resized = img.copyResize(decoded, width: 200, height: 200);
      final jpegBytes = img.encodeJpg(resized, quality: 75);
      return base64Encode(jpegBytes);
    } catch (_) {
      return null;
    }
  }

  // ── Block / Report ────────────────────────────────────────────────────────

  Future<void> blockUser(String targetUid) async {
    final uid = currentUid!;
    await _db.collection(AppConstants.colUsers).doc(uid).update({
      'blockedUids': FieldValue.arrayUnion([targetUid]),
    });
  }

  Future<void> reportUser({
    required String targetUid,
    required String reason,
    String? details,
  }) async {
    final uid = currentUid!;
    await _db.collection(AppConstants.colReports).add({
      'reporterId': uid,
      'targetId': targetUid,
      'reason': reason,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> isBlocked(String targetUid) async {
    final user = await getCurrentUser();
    return user?.blockedUids.contains(targetUid) ?? false;
  }
}
