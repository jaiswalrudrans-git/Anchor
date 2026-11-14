import 'dart:io';
import 'package:flutter/foundation.dart';

/// Configuration for Supabase backend.
/// Injected via `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// OAuth redirect URI used on both Android and Windows.
  static const String redirectUrl = 'io.anchor.app://login-callback';

  /// Returns true if both URL and Anon Key were supplied at build/run time.
  static bool get isConfigured => url.trim().isNotEmpty && anonKey.trim().isNotEmpty;

  /// Registers the custom URL protocol on Windows (HKCU\Software\Classes\io.anchor.app).
  /// Safe no-op on non-Windows platforms.
  static Future<void> registerWindowsProtocolIfNeeded() async {
    if (kIsWeb || !Platform.isWindows) return;

    try {
      final exePath = Platform.resolvedExecutable;
      for (final scheme in ['io.anchor.app', 'io.execute.app']) {
        await Process.run('reg', [
          'add',
          'HKCU\\Software\\Classes\\$scheme',
          '/ve',
          '/t',
          'REG_SZ',
          '/d',
          'URL:Anchor Protocol',
          '/f',
        ]);
        await Process.run('reg', [
          'add',
          'HKCU\\Software\\Classes\\$scheme',
          '/v',
          'URL Protocol',
          '/t',
          'REG_SZ',
          '/d',
          '',
          '/f',
        ]);
        await Process.run('reg', [
          'add',
          'HKCU\\Software\\Classes\\$scheme\\shell\\open\\command',
          '/ve',
          '/t',
          'REG_SZ',
          '/d',
          '"$exePath" "%1"',
          '/f',
        ]);
      }
    } catch (_) {
      // Ignored if permissions or process call fails
    }
  }
}
