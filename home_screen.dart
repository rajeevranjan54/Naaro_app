import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/nearby_user.dart';
import '../../../data/services/ble_service.dart';
import '../../widgets/nearby_user_card.dart';
import '../profile/view_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _permissionsGranted = false;
  bool _checkingPermissions = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final granted = statuses.values.every(
      (s) => s == PermissionStatus.granted,
    );
    setState(() {
      _permissionsGranted = granted;
      _checkingPermissions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: _checkingPermissions
                  ? const Center(child: CircularProgressIndicator())
                  : !_permissionsGranted
                      ? _buildPermissionDenied()
                      : _buildNearbyList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nearby',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      letterSpacing: -0.5,
                    ),
              ),
              Text(
                'People physically close to you',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.onSurfaceMuted),
              ),
            ],
          ),
          const Spacer(),
          _ScanningPulse(),
        ],
      ),
    );
  }

  Widget _buildNearbyList() {
    final bleService = context.read<BleService>();

    return StreamBuilder<List<NearbyUser>>(
      stream: bleService.nearbyStream,
      builder: (context, snap) {
        final users = snap.data ?? [];

        if (users.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: users.length,
          itemBuilder: (context, i) {
            return NearbyUserCard(
              user: users[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ViewProfileScreen(nearbyUser: users[i]),
                ),
              ),
            ).animate().fadeIn(delay: (i * 60).ms).slideY(begin: 0.15);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.radar_rounded,
                  size: 40, color: AppTheme.onSurfaceMuted),
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 2000.ms, color: AppTheme.primary.withOpacity(0.3)),
            const SizedBox(height: 24),
            Text(
              'Scanning…',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'No one detected nearby yet.\nMake sure others have Naaro open.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.onSurfaceMuted, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bluetooth_disabled_rounded,
                size: 56, color: AppTheme.onSurfaceMuted),
            const SizedBox(height: 20),
            Text(
              'Bluetooth access needed',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Naaro uses Bluetooth to detect nearby users. Please grant the required permissions.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.onSurfaceMuted, height: 1.6),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => openAppSettings(),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanningPulse extends StatefulWidget {
  @override
  State<_ScanningPulse> createState() => _ScanningPulseState();
}

class _ScanningPulseState extends State<_ScanningPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surfaceElevated,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary
                    .withOpacity(0.4 * (1 - _ctrl.value)),
                blurRadius: 20 * _ctrl.value,
                spreadRadius: 8 * _ctrl.value,
              ),
            ],
          ),
          child: const Icon(Icons.wifi_tethering_rounded,
              color: AppTheme.primary, size: 22),
        );
      },
    );
  }
}
