import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/supabase_config.dart';
import 'core/constants/theme.dart';
import 'core/services/auth_service.dart';
import 'screens/auth_screen.dart';
import 'screens/main_shell.dart';
import 'widgets/error_state.dart';
import 'widgets/loading_state.dart';
import 'widgets/responsive_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register Windows custom URL scheme if running on Windows desktop
  if (!kIsWeb && Platform.isWindows) {
    await SupabaseConfig.registerWindowsProtocolIfNeeded();
  }

  // Guard against missing --dart-define parameters
  if (!SupabaseConfig.isConfigured) {
    runApp(const MissingConfigApp());
    return;
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey, // ignore: deprecated_member_use
  );

  runApp(
    const ProviderScope(
      child: AnchorApp(),
    ),
  );
}

/// Fallback app displayed when build-time configuration is missing.
class MissingConfigApp extends StatelessWidget {
  const MissingConfigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anchor - Configuration Required',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ResponsiveContainer(
            maxWidth: 600,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.vpn_key_off_outlined,
                  size: 56,
                  color: AppColors.primaryText,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Missing Supabase Configuration',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Anchor requires Supabase credentials to connect to the backend. Please launch the app with the required --dart-define flags:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppTheme.borderRadius8,
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: const SelectableText(
                    'flutter run \\\n'
                    '  --dart-define=SUPABASE_URL=https://<your-project-id>.supabase.co \\\n'
                    '  --dart-define=SUPABASE_ANON_KEY=<your-anon-key>',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: AppColors.primaryText,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Consult SETUP.md for complete instructions on creating the Supabase project and configuring Google OAuth.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Root application widget.
class AnchorApp extends StatelessWidget {
  const AnchorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anchor',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

/// AuthGate routes to [MainShell] when authenticated or [AuthScreen] when unauthenticated.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authStateProvider);

    return authStateAsync.when(
      data: (authState) {
        final session = authState.session;
        if (session != null) {
          return const MainShell();
        }
        return const AuthScreen();
      },
      loading: () {
        // Check if there is already a cached session before showing a loader
        final currentSession = ref.read(authServiceProvider).currentSession;
        if (currentSession != null) {
          return const MainShell();
        }
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: LoadingState(message: 'Checking session...'),
        );
      },
      error: (error, stack) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: ErrorState(
            title: 'Authentication Error',
            message: error.toString(),
            onRetry: () => ref.invalidate(authStateProvider),
          ),
        );
      },
    );
  }
}
