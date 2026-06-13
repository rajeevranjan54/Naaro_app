import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/services/ble_service.dart';
import 'data/services/chat_service.dart';
import 'data/services/user_service.dart';
import 'firebase_options.dart';
import 'presentation/screens/auth/splash_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const NaaroApp());
}

class NaaroApp extends StatelessWidget {
  const NaaroApp({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();

    return MultiProvider(
      providers: [
        Provider<UserService>(create: (_) => userService),
        Provider<ChatService>(create: (_) => ChatService()),
        Provider<BleService>(
          create: (_) => BleService(userService: userService),
          dispose: (_, s) => s.dispose(),
        ),
      ],
      child: MaterialApp(
        title: 'Naaro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashGate(),
      ),
    );
  }
}
