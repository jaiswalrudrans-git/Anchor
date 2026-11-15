import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/dimens.dart';
import '../../core/constants/theme.dart';
import '../motion/pressable_scale.dart';

/// User profile avatar component with image network caching and initials fallback.
class ProfileAvatar extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;
  final String? tooltip;

  const ProfileAvatar({super.key, this.size = 36.0, this.onTap, this.tooltip});

  static String getInitials(User? user) {
    if (user == null) return 'U';
    final metadata = user.userMetadata ?? {};
    final fullName =
        (metadata['full_name'] ?? metadata['name'] ?? '') as String;
    if (fullName.trim().isNotEmpty) {
      final parts = fullName.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }
    final email = user.email ?? '';
    if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return 'U';
  }

  static String? getAvatarUrl(User? user) {
    if (user == null) return null;
    final metadata = user.userMetadata ?? {};
    final url = metadata['avatar_url'] ?? metadata['picture'];
    if (url is String && url.trim().isNotEmpty) {
      return url.trim();
    }
    return null;
  }

  static String getDisplayName(User? user) {
    if (user == null) return 'User';
    final metadata = user.userMetadata ?? {};
    final fullName =
        (metadata['full_name'] ?? metadata['name'] ?? '') as String;
    if (fullName.trim().isNotEmpty) return fullName.trim();
    final email = user.email ?? '';
    if (email.isNotEmpty) return email.split('@').first;
    return 'User';
  }

  static User? getCurrentUser() {
    try {
      return Supabase.instance.client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final user = getCurrentUser();
    final avatarUrl = getAvatarUrl(user);
    final initials = getInitials(user);

    final Widget fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.accentSoft,
        shape: BoxShape.circle,
        border: Border.all(color: palette.border, width: AppDimens.hairline),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
            color: palette.accent,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );

    Widget avatar = avatarUrl == null
        ? fallback
        : Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: palette.border,
                width: AppDimens.hairline,
              ),
            ),
            child: ClipOval(
              child: Image.network(
                avatarUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                cacheWidth: (size * 2).toInt(),
                cacheHeight: (size * 2).toInt(),
                errorBuilder: (context, error, stackTrace) => fallback,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return fallback;
                },
              ),
            ),
          );

    if (onTap != null) {
      avatar = PressableScale(onTap: onTap, child: avatar);
    }

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: avatar);
    }

    return avatar;
  }
}
