class AppConstants {
  // BLE
  static const String bleServiceUuid = 'F0001110-0451-4000-B000-000000000000';
  static const String bleCharUuid    = 'F0001111-0451-4000-B000-000000000000';
  static const String bleManufacturerId = 'NAARO';

  // RSSI thresholds (dBm)
  static const int rssiVeryClose  = -60;  // ≤2 m  → "Very Close"
  static const int rssiNearby     = -75;  // ≤5 m  → "Nearby"
  static const int rssiCutoff     = -85;  // ignore beyond this

  // BLE timing
  static const int scanWindowMs        = 4000;   // scan window
  static const int scanPauseMs         = 3000;   // pause between cycles
  static const int disappearDelayMs    = 8000;   // delay before removing user
  static const int rssiHistorySize     = 6;      // samples for smoothing
  static const int debounceMs          = 1500;   // debounce new detections

  // Messages
  static const int maxPreReplyMessages = 2;
  static const int maxMessageCharacters = 120;
  static const int requestExpiryHours  = 24;

  // Spam / cooldown
  static const int interactionCooldownHours = 2;
  static const int maxDailyNewInteractions  = 20;

  // Firestore collections
  static const String colUsers         = 'users';
  static const String colConversations = 'conversations';
  static const String colMessages      = 'messages';
  static const String colReports       = 'reports';
  static const String colBlocks        = 'blocks';
}
