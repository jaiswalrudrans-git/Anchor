import 'package:flutter/foundation.dart';

/// Centralized logging utility for Anchor.
/// Deliberately no-ops in release mode (`kReleaseMode`).
class AppLog {
  AppLog._();

  /// Logs a debug message in debug/profile mode only.
  static void d(String message) {
    if (!kReleaseMode) {
      debugPrint('[Anchor] $message');
    }
  }

  /// Logs an error message and optional stack trace in debug/profile mode only.
  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    if (!kReleaseMode) {
      debugPrint('[Anchor ERROR] $message');
      if (error != null) {
        debugPrint('  Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('  StackTrace: $stackTrace');
      }
    }
  }

  /// Named argument variant for convenience: `AppLog.error('msg', error: e)`.
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    e(message, error, stackTrace);
  }
}
