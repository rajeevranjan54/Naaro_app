import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/services/ble_service.dart';
import '../../../data/services/user_service.dart';
import 'home_screen.dart';
import '../chat/conversations_screen.dart';
import '../profile/my_profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _index = 0;
  late final BleService _bleService;
  bool _bleInitialized = false;

  final _screens = const [
    HomeScreen(),
    ConversationsScreen(),
    MyProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initBle();
  }

  Future<void> _initBle() async {
    final userService = context.read<UserService>();
    final uid = userService.currentUid;
    if (uid == null) return;

    _bleService = context.read<BleService>();
    await _bleService.initToken(uid);
    await _bleService.startScanning();
    setState(() => _bleInitialized = true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_bleInitialized) return;
    if (state == AppLifecycleState.resumed) {
      _bleService.startScanning();
    } else if (state == AppLifecycleState.paused) {
      _bleService.stopScanning();
      context.read<UserService>().setInactive();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_bleInitialized) _bleService.stopScanning();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.divider, width: 0.5)),
        ),
        child: NavigationBar(
          backgroundColor: AppTheme.surface,
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          indicatorColor: AppTheme.primary.withOpacity(0.15),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.radar_rounded),
              selectedIcon: Icon(Icons.radar_rounded, color: AppTheme.primary),
              label: 'Nearby',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: Icon(Icons.chat_bubble_rounded,
                  color: AppTheme.primary),
              label: 'Messages',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon:
                  Icon(Icons.person_rounded, color: AppTheme.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
