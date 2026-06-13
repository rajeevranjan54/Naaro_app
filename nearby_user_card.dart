import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/nearby_user.dart';
import 'naaro_avatar.dart';

class NearbyUserCard extends StatelessWidget {
  final NearbyUser user;
  final VoidCallback onTap;

  const NearbyUserCard({super.key, required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isVeryClose = user.proximityLabel == ProximityLabel.veryClose;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isVeryClose
                ? AppTheme.accent.withOpacity(0.3)
                : AppTheme.divider,
            width: isVeryClose ? 1.5 : 1,
          ),
          boxShadow: isVeryClose
              ? [BoxShadow(
                  color: AppTheme.accent.withOpacity(0.08),
                  blurRadius: 16, spreadRadius: 2)]
              : null,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                NaaroAvatar(photoBase64: user.photoBase64, radius: 28),
                Positioned(
                  bottom: 1, right: 1,
                  child: Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.online,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.surface, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.nickname ?? '…',
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis),
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(user.bio!,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppTheme.onSurfaceMuted),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 6),
                  _ProximityChip(label: user.proximityText, isClose: isVeryClose),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.onSurfaceMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ProximityChip extends StatelessWidget {
  final String label;
  final bool isClose;
  const _ProximityChip({required this.label, required this.isClose});

  @override
  Widget build(BuildContext context) {
    final color = isClose ? AppTheme.accent : AppTheme.primaryLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 5, height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 11,
              fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
