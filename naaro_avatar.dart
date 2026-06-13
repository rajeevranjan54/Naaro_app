import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Displays a profile photo from a Base64 string.
/// Falls back to a person icon when no photo is available.
class NaaroAvatar extends StatelessWidget {
  final String? photoBase64;
  final double radius;

  const NaaroAvatar({super.key, this.photoBase64, this.radius = 28});

  @override
  Widget build(BuildContext context) {
    if (photoBase64 != null && photoBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(photoBase64!);
        return CircleAvatar(
          radius: radius,
          backgroundColor: AppTheme.surfaceElevated,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (_) {}
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.surfaceElevated,
      child: Icon(Icons.person_rounded,
          size: radius * 0.9, color: AppTheme.onSurfaceMuted),
    );
  }
}
