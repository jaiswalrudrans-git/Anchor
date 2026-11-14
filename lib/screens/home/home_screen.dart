import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/theme.dart';
import '../../core/services/auth_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/responsive_container.dart';

/// Home tab placeholder screen.
/// Includes an overflow menu with Sign Out.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            shape: RoundedRectangleBorder(
              side: AppTheme.borderSide1,
              borderRadius: AppTheme.borderRadius8,
            ),
            onSelected: (value) async {
              if (value == 'sign_out') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref.read(authServiceProvider).signOut();
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'sign_out',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: AppColors.primaryText),
                    SizedBox(width: 12),
                    Text('Sign out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: const SafeArea(
        child: ResponsiveContainer(
          child: EmptyState(
            icon: Icons.checklist_outlined,
            title: 'No tasks scheduled',
            message: 'Your daily tasks and anti-procrastination queue will appear here in Stage 2.',
          ),
        ),
      ),
    );
  }
}
