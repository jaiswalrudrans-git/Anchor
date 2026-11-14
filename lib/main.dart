import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'core/constants/motion.dart';
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

  // Desktop window constraints: minimum size 360 x 600
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    try {
      await windowManager.ensureInitialized();
      const windowOptions = WindowOptions(
        minimumSize: Size(360, 600),
      );
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.setMinimumSize(const Size(360, 600));
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (e) {
      debugPrint('WindowManager initialization error: $e');
    }
  }

  // Register Windows custom URL scheme if running on Windows desktop
  if (!kIsWeb && Platform.isWindows) {
    await SupabaseConfig.registerWindowsProtocolIfNeeded();
  }

  // Pre-load theme settings before first frame
  try {
    final prefs = await SharedPreferences.getInstance();
    ThemeController.setInitialTheme(prefs);
  } catch (e) {
    debugPrint('SharedPreferences theme preload error: $e');
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
      theme: buildTheme(Brightness.light, AppAccent.iris),
      darkTheme: buildTheme(Brightness.dark, AppAccent.iris),
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (ctx) {
          final palette = ctx.palette;
          return Scaffold(
            body: SafeArea(
              child: ResponsiveContainer(
                maxWidth: 600,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.vpn_key_off_outlined,
                      size: 56,
                      color: palette.textPrimary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Missing Supabase Configuration',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Anchor requires Supabase credentials to connect to the backend. Please launch the app with the required --dart-define flags:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: palette.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: palette.card,
                        borderRadius: AppTheme.borderRadius8,
                        border: Border.all(color: palette.border, width: 1),
                      ),
                      child: SelectableText(
                        'flutter run \\\n'
                        '  --dart-define=SUPABASE_URL=https://<your-project-id>.supabase.co \\\n'
                        '  --dart-define=SUPABASE_ANON_KEY=<your-anon-key>',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: palette.textPrimary,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Consult SETUP.md for complete instructions on creating the Supabase project and configuring Google OAuth.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Root application widget wired to dynamic ThemeController.
class AnchorApp extends ConsumerWidget {
  const AnchorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeControllerProvider);
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    ThemeController.updateCurrentPalette(themeState, platformBrightness);
    ThemeController.updateDesktopWindow(themeState.mode, platformBrightness);

    return MaterialApp(
      title: 'Anchor',
      themeMode: themeState.mode,
      theme: buildTheme(Brightness.light, themeState.accent),
      darkTheme: buildTheme(Brightness.dark, themeState.accent),
      themeAnimationDuration: Motion.base,
      themeAnimationCurve: Motion.standard,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
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
    final palette = context.palette;

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
        return Scaffold(
          backgroundColor: palette.background,
          body: const LoadingState(message: 'Checking session...'),
        );
      },
      error: (error, stack) {
        return Scaffold(
          backgroundColor: palette.background,
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
