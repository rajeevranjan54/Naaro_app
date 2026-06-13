import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../widgets/naaro_avatar.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/user_service.dart';
import '../auth/splash_gate.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _nicknameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  File? _newPhoto;
  bool _editing = false;
  bool _saving = false;

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _startEditing(UserModel user) {
    _nicknameCtrl.text = user.nickname;
    _bioCtrl.text = user.bio ?? '';
    setState(() => _editing = true);
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 512, imageQuality: 85);
    if (picked != null) setState(() => _newPhoto = File(picked.path));
  }

  Future<void> _save(UserModel current) async {
    if (_nicknameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);

    try {
      final userService = context.read<UserService>();
      final uid = userService.currentUid!;

      String? photoBase64 = current.photoBase64;
      if (_newPhoto != null) {
        photoBase64 = await userService.encodePhotoToBase64(_newPhoto!);
      }

      await userService.createOrUpdateProfile(
        nickname: _nicknameCtrl.text.trim(),
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        photoBase64: photoBase64,
        bleToken: current.bleToken,
      );

      setState(() {
        _editing = false;
        _saving = false;
        _newPhoto = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!')),
      );
    } catch (_) {
      setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign out',
                  style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );
    if (confirm != true) return;
    await context.read<UserService>().signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashGate()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: StreamBuilder<UserModel?>(
          stream: context.read<UserService>().watchCurrentUser(),
          builder: (context, snap) {
            final user = snap.data;
            if (user == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Profile',
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(letterSpacing: -0.5),
                      ),
                      const Spacer(),
                      if (!_editing)
                        IconButton(
                          onPressed: () => _startEditing(user),
                          icon: const Icon(Icons.edit_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.surfaceElevated,
                            foregroundColor: AppTheme.onSurface,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Avatar
                  Center(
                    child: GestureDetector(
                      onTap: _editing ? _pickPhoto : null,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 56,
                            backgroundColor: AppTheme.surfaceElevated,
                            backgroundImage: _newPhoto != null
                                ? FileImage(_newPhoto!)
                                : user.photoUrl != null
                                    ? CachedNetworkImageProvider(user.photoUrl!)
                                    : null,
                            child: (user.photoUrl == null && _newPhoto == null)
                                ? const Icon(Icons.person_rounded,
                                    size: 56,
                                    color: AppTheme.onSurfaceMuted)
                                : null,
                          ),
                          if (_editing)
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppTheme.background, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_rounded,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(),

                  const SizedBox(height: 32),

                  if (_editing) ...[
                    // Edit form
                    Text('Nickname',
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nicknameCtrl,
                      maxLength: 24,
                      style: const TextStyle(color: AppTheme.onSurface),
                      decoration: const InputDecoration(counterText: ''),
                    ),
                    const SizedBox(height: 20),
                    Text('Bio',
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _bioCtrl,
                      maxLength: 80,
                      maxLines: 3,
                      style: const TextStyle(color: AppTheme.onSurface),
                      decoration:
                          const InputDecoration(hintText: 'Optional bio…'),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                setState(() => _editing = false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.onSurfaceMuted,
                              side: const BorderSide(
                                  color: AppTheme.divider),
                              minimumSize: const Size(0, 50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving ? null : () => _save(user),
                            child: _saving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5))
                                : const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // View mode
                    _InfoCard(
                      label: 'Nickname',
                      value: user.nickname,
                      icon: Icons.badge_outlined,
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 12),
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      _InfoCard(
                        label: 'Bio',
                        value: user.bio!,
                        icon: Icons.info_outline_rounded,
                      ).animate().fadeIn(delay: 150.ms),
                      const SizedBox(height: 12),
                    ],
                    _InfoCard(
                      label: 'Privacy',
                      value:
                          'Your phone number, email, and location are never shared.',
                      icon: Icons.shield_outlined,
                      valueColor: AppTheme.accent,
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 32),
                    OutlinedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sign out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ).animate().fadeIn(delay: 250.ms),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  const _InfoCard(
      {required this.label,
      required this.value,
      required this.icon,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.onSurfaceMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.onSurfaceMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        color: valueColor ?? AppTheme.onSurface,
                        fontSize: 14,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
