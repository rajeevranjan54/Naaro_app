# Naaro — Setup & Build Guide

## Prerequisites
- Flutter SDK 3.x installed → https://docs.flutter.dev/get-started/install
- Android Studio + Android SDK
- Firebase project already created (naaro-cc497) ✅
- Java 17+

---

## 1 — Project Structure

```
naaro/
├── android/
│   ├── app/
│   │   ├── src/main/AndroidManifest.xml
│   │   └── build.gradle
│   └── build.gradle
├── lib/
│   ├── core/
│   │   ├── constants/app_constants.dart
│   │   └── theme/app_theme.dart
│   ├── data/
│   │   ├── models/
│   │   │   ├── user_model.dart
│   │   │   ├── message_model.dart
│   │   │   ├── conversation_model.dart
│   │   │   └── nearby_user.dart
│   │   └── services/
│   │       ├── user_service.dart
│   │       ├── chat_service.dart
│   │       └── ble_service.dart
│   ├── presentation/
│   │   ├── screens/
│   │   │   ├── auth/
│   │   │   │   ├── splash_gate.dart
│   │   │   │   └── onboarding_screen.dart
│   │   │   ├── home/
│   │   │   │   ├── main_shell.dart
│   │   │   │   └── home_screen.dart
│   │   │   ├── chat/
│   │   │   │   ├── chat_screen.dart
│   │   │   │   └── conversations_screen.dart
│   │   │   └── profile/
│   │   │       ├── view_profile_screen.dart
│   │   │       └── my_profile_screen.dart
│   │   └── widgets/
│   │       └── nearby_user_card.dart
│   ├── firebase_options.dart
│   └── main.dart
├── pubspec.yaml
├── firestore.rules
└── storage.rules
```

---

## 2 — Place google-services.json

Copy your `google-services.json` into:
```
naaro/android/app/google-services.json
```
(Already configured for package `com.rajeev.naaro`)

---

## 3 — Create assets folder

```bash
mkdir -p naaro/assets/images
```
Add a placeholder image `assets/images/placeholder.png` if desired.

---

## 4 — Install dependencies

```bash
cd naaro
flutter pub get
```

---

## 5 — Firebase Console Setup

### A. Authentication
1. Go to Firebase Console → Authentication → Sign-in method
2. Enable **Anonymous** sign-in

### B. Firestore Database
1. Go to Firestore Database → Create database
2. Start in **production mode**
3. Go to Rules tab → paste contents of `firestore.rules` → Publish

### C. Storage
1. Go to Storage → Get started
2. Go to Rules tab → paste contents of `storage.rules` → Publish

### D. Firestore Indexes
Create these composite indexes in Firestore Console → Indexes:

| Collection | Fields | Order |
|---|---|---|
| conversations | participantIds (Array), lastMessageAt (Desc) | — |
| users | bleToken (Asc), isActive (Asc) | — |

---

## 6 — Run the App

```bash
# Connect Android device (enable Developer Options + USB Debugging)
flutter devices

# Run in debug mode
flutter run

# Build release APK
flutter build apk --release
# APK will be at: build/app/outputs/flutter-apk/app-release.apk
```

---

## 7 — BLE Testing

To test nearby detection you need **two physical Android devices** — BLE doesn't work on emulators.

1. Install the app on both devices
2. Open the app on both
3. Stand within 2–5 meters of each other
4. Both should appear in each other's Nearby screen within ~8 seconds

### BLE Tuning (in `app_constants.dart`)
```dart
rssiVeryClose  = -60   // Very Close label (≈2m)
rssiNearby     = -75   // Nearby label (≈5m)
rssiCutoff     = -85   // Ignore beyond this
disappearDelayMs = 8000  // Delay before removing disappeared user
rssiHistorySize  = 6     // Samples for weighted average
```
Adjust these based on your real-world testing environment.

---

## 8 — Key Features Summary

| Feature | Implementation |
|---|---|
| Nearby detection | BLE scan with RSSI smoothing + debounce + delayed removal |
| Distance filter | RSSI cutoff at -85 dBm (~8–10m) |
| Proximity labels | "Very Close" < -60 dBm, "Nearby" -60 to -75 dBm |
| Privacy | Temporary BLE tokens, no GPS, anonymous auth |
| Message lock | 2 messages max before reply, 120 char limit |
| Chat unlock | Auto-unlocks when receiver replies |
| Block/Report | Full implementation with Firestore |
| Battery | Cyclic scanning: 4s scan / 3s pause |

---

## 9 — Common Issues

**BLE not scanning:**
- Ensure Location permission is granted (required on Android <12)
- Check Bluetooth is ON
- Test on physical device only

**Users not appearing:**
- Both devices must have app open and Bluetooth ON
- Check Firestore has the `bleToken` index created
- RSSI cutoff may need adjustment for your environment

**Firebase errors:**
- Confirm `google-services.json` is in `android/app/`
- Confirm Anonymous Auth is enabled in Firebase Console
- Confirm Firestore rules are published

---

## 10 — Next Steps (Post-MVP)

- Push notifications (Firebase Messaging) for new messages
- BLE advertising implementation (requires platform channel for full control)
- Conversation expiry job (Cloud Functions)
- Spam detection (Cloud Functions)
- iOS support (same Flutter codebase, different BLE entitlements)
