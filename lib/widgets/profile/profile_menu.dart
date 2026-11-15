import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/dimens.dart';
import '../../core/constants/theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/responsive.dart';
import '../brand/anchor_logo.dart';
import '../motion/animated_progress_bar.dart';
import '../motion/pressable_scale.dart';
import '../stat_chip.dart';
import 'profile_avatar.dart';

/// Modal bottom sheet (on compact) or anchored popover (on medium/expanded)
/// displaying Appearance mode, 7-accent color picker, preview strip, and Sign out.
class ProfileMenu extends ConsumerStatefulWidget {
  const ProfileMenu({super.key});

  /// Opens the ProfileMenu adaptively:
  /// - Compact (< 600 dp): Bottom sheet
  /// - Medium / Expanded (>= 600 dp): Anchored popover dialog (width 340)
  static Future<void> show(BuildContext context) {
    final isCompact = Breakpoints.isCompact(context);

    if (isCompact) {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.palette.cardRaised,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimens.radiusXl),
          ),
        ),
        builder: (ctx) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) =>
              ProfileMenuContent(scrollController: scrollController),
        ),
      );
    }

    return showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => Stack(
        children: [
          // Dismiss barrier
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ),
          Positioned(
            top: 56,
            right: 24,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 340,
                constraints: const BoxConstraints(maxHeight: 640),
                decoration: BoxDecoration(
                  color: ctx.palette.cardRaised,
                  borderRadius: AppDimens.borderRadiusLg,
                  border: Border.all(
                    color: ctx.palette.border,
                    width: AppDimens.hairline,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ctx.palette.scrim.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: const ProfileMenuContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  ConsumerState<ProfileMenu> createState() => _ProfileMenuState();
}

class _ProfileMenuState extends ConsumerState<ProfileMenu> {
  @override
  Widget build(BuildContext context) {
    return const ProfileMenuContent();
  }
}

class ProfileMenuContent extends ConsumerStatefulWidget {
  final ScrollController? scrollController;

  const ProfileMenuContent({super.key, this.scrollController});

  @override
  ConsumerState<ProfileMenuContent> createState() => _ProfileMenuContentState();
}

class _ProfileMenuContentState extends ConsumerState<ProfileMenuContent> {
  String _version = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = '${info.version}+${info.buildNumber}';
        });
      }
    } catch (_) {
      // Fallback
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final nav = Navigator.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.palette.cardRaised,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimens.borderRadiusMd,
          side: BorderSide(
            color: ctx.palette.border,
            width: AppDimens.hairline,
          ),
        ),
        title: Text(
          'Sign out of Anchor?',
          style: TextStyle(
            color: ctx.palette.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'You can sign back in at any time with your Google account.',
          style: TextStyle(color: ctx.palette.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: ctx.palette.textSecondary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ctx.palette.danger,
              foregroundColor: ctx.palette.onDanger,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      nav.pop(); // Close menu
      await ref.read(authServiceProvider).signOut();
    }
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
    final themeState = ref.watch(themeControllerProvider);
    final user = getCurrentUser();

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle for bottom sheet
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16.0),
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 1. User Header
          Row(
            children: [
              const ProfileAvatar(size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ProfileAvatar.getDisplayName(user),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? 'Signed In',
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: 16),

          // 2. Appearance Section (Light | Dark | System)
          Text(
            'APPEARANCE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: palette.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_outlined, size: 16),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_outlined, size: 16),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.brightness_auto_outlined, size: 16),
              ),
            ],
            selected: {themeState.mode},
            onSelectionChanged: (newSelection) {
              ref
                  .read(themeControllerProvider.notifier)
                  .setThemeMode(newSelection.first);
            },
          ),
          if (themeState.mode == ThemeMode.system) ...[
            const SizedBox(height: 6),
            Text(
              'Follows your device',
              style: TextStyle(fontSize: 11, color: palette.textMuted),
            ),
          ],

          const SizedBox(height: 20),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: 16),

          // 3. Accent Color Section
          Text(
            'ACCENT COLOR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: palette.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.start,
            children: AppAccent.values.map((accent) {
              final isSelected = accent == themeState.accent;
              final swatchColor = accent.colorFor(Theme.of(context).brightness);
              final onColor = ContrastHelper.onAccent(swatchColor);

              return Semantics(
                label:
                    'Accent color ${accent.displayName}${isSelected ? ", selected" : ""}',
                button: true,
                selected: isSelected,
                child: PressableScale(
                  key: Key('accent_swatch_${accent.id}'),
                  onTap: () {
                    ref
                        .read(themeControllerProvider.notifier)
                        .setAccent(accent);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: swatchColor,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: palette.textPrimary.withValues(
                                    alpha: 0.9,
                                  ),
                                  width: 2.5,
                                )
                              : Border.all(
                                  color: palette.border,
                                  width: AppDimens.hairline,
                                ),
                        ),
                        child: isSelected
                            ? Icon(Icons.check, size: 20, color: onColor)
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        accent.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? palette.textPrimary
                              : palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),
          Text(
            'Switch the accent whenever you want a fresh look.',
            style: TextStyle(fontSize: 11, color: palette.textSecondary),
          ),

          const SizedBox(height: 20),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: 16),

          // 4. Live Preview Strip
          Text(
            'PREVIEW',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: palette.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: AppDimens.borderRadiusMd,
              border: Border.all(
                color: palette.border,
                width: AppDimens.hairline,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daily Goals',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      '70%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: palette.accent,
                        fontFeatures: AppTypography.tabularFigures,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const AnimatedProgressBar(value: 0.7, height: 6),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: palette.accent,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Icon(
                        Icons.check,
                        size: 12,
                        color: palette.onAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Review discrete mathematics',
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.textPrimary,
                          decoration: TextDecoration.lineThrough,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    StatChip(
                      icon: Icons.local_fire_department,
                      value: '7',
                      label: 'Day streak',
                      iconColor: palette.accent,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: 10),

          // 5. Account Section: Sign Out
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout, size: 20, color: palette.danger),
            title: Text(
              'Sign out',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: palette.danger,
              ),
            ),
            onTap: () => _handleSignOut(context),
          ),

          const SizedBox(height: 12),
          // 6. Version Footer
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnchorMark(size: 16.0, color: palette.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Anchor v$_version',
                  style: TextStyle(fontSize: 11, color: palette.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
