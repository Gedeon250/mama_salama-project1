import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared avatar used everywhere a user's picture appears — falls back to
/// a role icon when `photoUrl` is null/empty, and can show a small camera
/// badge when [onTap] is provided (used on the editable profile screen).
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final double radius;
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.photoUrl,
    this.radius = 20,
    this.icon = Icons.person,
    this.backgroundColor,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppColors.secondaryContainer,
      backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
      child: hasPhoto ? null : Icon(icon, size: radius, color: iconColor ?? AppColors.primary),
    );

    if (onTap == null) return avatar;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
