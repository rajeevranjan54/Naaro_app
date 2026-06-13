import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/services/user_service.dart';
import '../home/main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nicknameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? _photo;
  bool _loading = false;
  int _step = 0;

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final userService = context.read<UserService>();
      if (userService.currentUid == null) await userService.signInAnonymously();

      String? photoBase64;
      if (_photo != null) {
        photoBase64 = await userService.encodePhotoToBase64(_photo!);
      }

      await userService.createOrUpdateProfile(
        nickname: _nicknameCtrl.text.trim(),
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        photoBase64: photoBase64,
        bleToken: '',
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ));
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Something went wrong. Please try again.'),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(child: _step == 0 ? _buildWelcome() : _buildForm()),
    );
  }

  Widget _buildWelcome() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accent],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.wifi_tethering_rounded,
                color: Colors.white, size: 36),
          ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 32),
          Text('Meet people\nnearby.',
              style: Theme.of(context).textTheme.displayLarge
                  ?.copyWith(height: 1.15, letterSpacing: -0.5))
              .animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          const SizedBox(height: 16),
          Text(
            'Naaro silently detects people physically close to you — on the train, in a café, at the airport.',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppTheme.onSurfaceMuted, height: 1.6),
          ).animate().fadeIn(delay: 350.ms),
          const SizedBox(height: 40),
          _FeatureRow(icon: Icons.bluetooth_rounded,
              text: 'Uses Bluetooth — not GPS. Works indoors.'),
          const SizedBox(height: 12),
          _FeatureRow(icon: Icons.lock_outline_rounded,
              text: 'No phone number, email, or real name needed.'),
          const SizedBox(height: 12),
          _FeatureRow(icon: Icons.chat_bubble_outline_rounded,
              text: 'Send 2 intro messages. Full chat unlocks on reply.'),
          const Spacer(),
          ElevatedButton(
            onPressed: () => setState(() => _step = 1),
            child: const Text('Get Started'),
          ).animate().fadeIn(delay: 600.ms),
          const SizedBox(height: 12),
          Center(child: Text('No account. Just a nickname.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.onSurfaceMuted)))
              .animate().fadeIn(delay: 700.ms),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text('Create your\nprofile',
                style: Theme.of(context).textTheme.displayMedium
                    ?.copyWith(height: 1.2, letterSpacing: -0.5))
                .animate().fadeIn(),
            const SizedBox(height: 8),
            Text('This is what nearby people will see.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppTheme.onSurfaceMuted))
                .animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 36),

            // Photo picker
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: AppTheme.surfaceElevated,
                      backgroundImage: _photo != null ? FileImage(_photo!) : null,
                      child: _photo == null
                          ? const Icon(Icons.person_rounded,
                              size: 44, color: AppTheme.onSurfaceMuted)
                          : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.primary, shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.background, width: 2),
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 8),
            Center(child: Text('Optional photo',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppTheme.onSurfaceMuted))),
            const SizedBox(height: 32),

            Text('Nickname *', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nicknameCtrl,
              maxLength: 24,
              textInputAction: TextInputAction.next,
              style: const TextStyle(color: AppTheme.onSurface),
              decoration: const InputDecoration(
                  hintText: 'e.g. Alex, BlueCap, Wanderer…', counterText: ''),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Nickname is required';
                if (v.trim().length < 2) return 'At least 2 characters';
                return null;
              },
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 20),

            Text('Short bio', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bioCtrl,
              maxLength: 80,
              maxLines: 2,
              style: const TextStyle(color: AppTheme.onSurface),
              decoration: const InputDecoration(
                  hintText: 'Optional — e.g. "Reading a sci-fi novel 📖"'),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 36),

            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 22, width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Text('Enter Naaro'),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.accent, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppTheme.onSurface, height: 1.5))),
      ],
    );
  }
}
