import '../../core/constants/app_constants.dart';

enum ProximityLabel { veryClose, nearby }

class NearbyUser {
  final String bleToken;
  final List<int> rssiHistory;
  final DateTime lastSeenAt;
  final DateTime firstSeenAt;

  final String? uid;
  final String? nickname;
  final String? bio;
  final String? photoBase64;   // Base64 image — no URL needed

  const NearbyUser({
    required this.bleToken,
    required this.rssiHistory,
    required this.lastSeenAt,
    required this.firstSeenAt,
    this.uid,
    this.nickname,
    this.bio,
    this.photoBase64,
  });

  int get smoothedRssi {
    if (rssiHistory.isEmpty) return -100;
    double total = 0;
    double weight = 0;
    for (int i = 0; i < rssiHistory.length; i++) {
      double w = (i + 1).toDouble();
      total += rssiHistory[i] * w;
      weight += w;
    }
    return (total / weight).round();
  }

  ProximityLabel get proximityLabel {
    if (smoothedRssi >= AppConstants.rssiVeryClose) return ProximityLabel.veryClose;
    return ProximityLabel.nearby;
  }

  String get proximityText =>
      proximityLabel == ProximityLabel.veryClose ? 'Very Close' : 'Nearby';

  bool get isResolved => uid != null && nickname != null;
  bool get hasPhoto => photoBase64 != null && photoBase64!.isNotEmpty;

  bool get isStale =>
      DateTime.now().difference(lastSeenAt).inMilliseconds >
      AppConstants.disappearDelayMs;

  NearbyUser copyWith({
    List<int>? rssiHistory,
    DateTime? lastSeenAt,
    String? uid,
    String? nickname,
    String? bio,
    String? photoBase64,
  }) {
    return NearbyUser(
      bleToken: bleToken,
      rssiHistory: rssiHistory ?? this.rssiHistory,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      firstSeenAt: firstSeenAt,
      uid: uid ?? this.uid,
      nickname: nickname ?? this.nickname,
      bio: bio ?? this.bio,
      photoBase64: photoBase64 ?? this.photoBase64,
    );
  }

  NearbyUser withNewRssi(int rssi) {
    final history = [...rssiHistory, rssi];
    if (history.length > AppConstants.rssiHistorySize) history.removeAt(0);
    return copyWith(rssiHistory: history, lastSeenAt: DateTime.now());
  }
}
