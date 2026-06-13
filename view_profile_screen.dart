import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/nearby_user.dart';
import '../../../data/services/user_service.dart';
import '../../widgets/naaro_avatar.dart';
import '../chat/chat_screen.dart';

class ViewProfileScreen extends StatelessWidget {
  final NearbyUser nearbyUser;
  const ViewProfileScreen({super.key, required this.nearbyUser});

  void _showBlockReport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _BlockReportSheet(nearbyUser: nearbyUser),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = nearbyUser.hasPhoto;

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: hasPhoto,
      appBar: AppBar(
        backgroundColor: hasPhoto ? Colors.transparent : AppTheme.surface,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.black38, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => _showBlockReport(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.black38, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.more_horiz_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Hero photo area
          SizedBox(
            height: 300,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasPhoto)
                  Image.memory(
                    base64Decode(nearbyUser.photoBase64!),
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    color: AppTheme.surfaceElevated,
                    child: Center(
                      child: NaaroAvatar(
                          photoBase64: nearbyUser.photoBase64, radius: 60),
                    ),
                  ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, AppTheme.background],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20, left: 24,
                  child: _ProximityBadge(label: nearbyUser.proximityText),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nearbyUser.nickname ?? 'Unknown',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(letterSpacing: -0.5))
                      .animate().fadeIn(),
                  if (nearbyUser.bio != null && nearbyUser.bio!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(nearbyUser.bio!,
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(color: AppTheme.onSurfaceMuted, height: 1.6))
                        .animate().fadeIn(delay: 100.ms),
                  ],
                  const Spacer(),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ElevatedButton.icon(
                        onPressed: nearbyUser.uid == null ? null : () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              otherUid: nearbyUser.uid!,
                              otherNickname: nearbyUser.nickname ?? 'Nearby',
                              otherPhotoBase64: nearbyUser.photoBase64,
                            ),
                          ));
                        },
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text('Say Hello'),
                      ).animate().fadeIn(delay: 200.ms),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProximityBadge extends StatelessWidget {
  final String label;
  const _ProximityBadge({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accent.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7,
              decoration: const BoxDecoration(
                  color: AppTheme.online, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(
              color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _BlockReportSheet extends StatelessWidget {
  final NearbyUser nearbyUser;
  const _BlockReportSheet({required this.nearbyUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.divider, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Text(nearbyUser.nickname ?? 'This user',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          _SheetTile(icon: Icons.block_rounded, label: 'Block user',
              color: AppTheme.error, onTap: () async {
                Navigator.pop(context);
                await context.read<UserService>().blockUser(nearbyUser.uid!);
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('User blocked.')));
              }),
          const SizedBox(height: 8),
          _SheetTile(icon: Icons.flag_outlined, label: 'Report user',
              color: AppTheme.onSurfaceMuted, onTap: () {
                Navigator.pop(context);
                _showReportDialog(context);
              }),
          const SizedBox(height: 8),
          _SheetTile(icon: Icons.close_rounded, label: 'Cancel',
              color: AppTheme.onSurfaceMuted, onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final reasons = ['Spam', 'Fake profile', 'Harassment', 'Inappropriate behavior'];
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppTheme.surface,
      title: const Text('Report user'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: reasons.map((r) => ListTile(
          title: Text(r),
          onTap: () async {
            Navigator.pop(context);
            await context.read<UserService>().reportUser(
                targetUid: nearbyUser.uid!, reason: r);
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report submitted. Thank you.')));
          },
        )).toList(),
      ),
    ));
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SheetTile({required this.icon, required this.label,
      required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Text(label, style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: color)),
          ]),
        ),
      ),
    );
  }
}
