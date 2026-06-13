import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../models/nearby_user.dart';
import 'user_service.dart';

class BleService {
  final UserService _userService;

  // Raw nearby map: bleToken -> NearbyUser
  final Map<String, NearbyUser> _nearbyMap = {};
  final Map<String, DateTime> _debounceMap = {};

  StreamSubscription? _scanSub;
  Timer? _scanCycleTimer;
  Timer? _staleCleanupTimer;

  // Public stream of resolved nearby users
  final _nearbyController = StreamController<List<NearbyUser>>.broadcast();
  Stream<List<NearbyUser>> get nearbyStream => _nearbyController.stream;

  String? _myBleToken;

  BleService({required UserService userService}) : _userService = userService;

  String get myBleToken => _myBleToken ?? '';

  /// Generate a short random BLE token (no real device ID exposed)
  String _generateBleToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(8, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  Future<String> initToken(String uid) async {
    _myBleToken = _generateBleToken();
    await _userService.updateBleToken(uid, _myBleToken!);
    return _myBleToken!;
  }

  Future<void> startScanning() async {
    if (_myBleToken == null) return;

    _scanCycleTimer?.cancel();
    _staleCleanupTimer?.cancel();

    await _runScanCycle();
    _scanCycleTimer = Timer.periodic(
      Duration(milliseconds: AppConstants.scanWindowMs + AppConstants.scanPauseMs),
      (_) => _runScanCycle(),
    );

    // Stale user cleanup every 2 seconds
    _staleCleanupTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _removeStaleUsers();
    });
  }

  Future<void> _runScanCycle() async {
    try {
      final state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) return;

      await FlutterBluePlus.startScan(
        timeout: Duration(milliseconds: AppConstants.scanWindowMs),
        androidUsesFineLocation: false,
      );

      _scanSub?.cancel();
      _scanSub = FlutterBluePlus.scanResults.listen(_onScanResults);

      await Future.delayed(Duration(milliseconds: AppConstants.scanWindowMs));
      await FlutterBluePlus.stopScan();
      _scanSub?.cancel();
    } catch (_) {
      // BLE unavailable — silently skip
    }
  }

  void _onScanResults(List<ScanResult> results) {
    for (final result in results) {
      _processScanResult(result);
    }
  }

  void _processScanResult(ScanResult result) {
    // Try to extract our BLE token from manufacturer data or local name
    final token = _extractToken(result);
    if (token == null) return;
    if (token == _myBleToken) return;  // ignore self

    final rssi = result.rssi;

    // Apply distance cutoff filter
    if (rssi < AppConstants.rssiCutoff) return;

    // Debounce: don't spam-process same token rapidly
    final now = DateTime.now();
    final lastDebounce = _debounceMap[token];
    if (lastDebounce != null &&
        now.difference(lastDebounce).inMilliseconds < AppConstants.debounceMs) {
      // Just update RSSI without full processing
      if (_nearbyMap.containsKey(token)) {
        _nearbyMap[token] = _nearbyMap[token]!.withNewRssi(rssi);
      }
      return;
    }
    _debounceMap[token] = now;

    if (_nearbyMap.containsKey(token)) {
      // Update existing
      _nearbyMap[token] = _nearbyMap[token]!.withNewRssi(rssi);
    } else {
      // New detection
      _nearbyMap[token] = NearbyUser(
        bleToken: token,
        rssiHistory: [rssi],
        lastSeenAt: now,
        firstSeenAt: now,
      );
      // Resolve to real user profile asynchronously
      _resolveToken(token);
    }

    _emitNearby();
  }

  String? _extractToken(ScanResult result) {
    // Check local name first (we'll encode token there during advertising)
    final localName = result.advertisementData.localName;
    if (localName.startsWith('NR:')) {
      return localName.substring(3);
    }
    // Check manufacturer data
    final mfData = result.advertisementData.manufacturerData;
    if (mfData.isNotEmpty) {
      final bytes = mfData.values.first;
      if (bytes.length >= 3) {
        try {
          final raw = String.fromCharCodes(bytes);
          if (raw.startsWith('NR:')) return raw.substring(3);
        } catch (_) {}
      }
    }
    return null;
  }

  Future<void> _resolveToken(String token) async {
    try {
      final user = await _userService.getUserByBleToken(token);
      if (user != null && _nearbyMap.containsKey(token)) {
        _nearbyMap[token] = _nearbyMap[token]!.copyWith(
          uid: user.uid,
          nickname: user.nickname,
          bio: user.bio,
          photoUrl: user.photoUrl,
        );
        _emitNearby();
      }
    } catch (_) {}
  }

  void _removeStaleUsers() {
    final staleKeys = _nearbyMap.entries
        .where((e) => e.value.isStale)
        .map((e) => e.key)
        .toList();

    if (staleKeys.isNotEmpty) {
      for (final key in staleKeys) {
        _nearbyMap.remove(key);
        _debounceMap.remove(key);
      }
      _emitNearby();
    }
  }

  void _emitNearby() {
    // Filter to only resolved users, sort by signal strength
    final resolved = _nearbyMap.values
        .where((u) => u.isResolved)
        .toList()
      ..sort((a, b) => b.smoothedRssi.compareTo(a.smoothedRssi));

    _nearbyController.add(resolved);
  }

  Future<void> stopScanning() async {
    _scanCycleTimer?.cancel();
    _staleCleanupTimer?.cancel();
    _scanSub?.cancel();
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
  }

  void dispose() {
    stopScanning();
    _nearbyController.close();
  }
}
