import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/theme.dart';
import '../core/services/auth_service.dart';
import '../widgets/brand/anchor_logo.dart';
import '../widgets/responsive_container.dart';

/// Screen displayed when user is unauthenticated.
/// Provides a single "Continue with Google" button using Supabase OAuth.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
      // On success, redirect callback triggers auth state update.
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initiate sign in: $e';
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_errorMessage!)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 440,
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Anchor Brand Tile
              const Center(child: AnchorTile(size: 72.0)),
              const SizedBox(height: 24),

              // Title
              Text(
                'Anchor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Personal anti-procrastination, academics, expenses, and habits.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: palette.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 40),

              // Error display if present
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.dangerSoft,
                    borderRadius: AppTheme.borderRadius8,
                    border: Border.all(color: palette.danger, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: palette.danger),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(fontSize: 13, color: palette.danger),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Continue with Google Button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              palette.onAccent,
                            ),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.login, size: 18),
                            SizedBox(width: 10),
                            Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
