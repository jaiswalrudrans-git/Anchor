import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Platform-safe haptic feedback helper.
/// Performs haptic feedback exclusively on Android; safe no-op on Windows/web.
class Haptics {
  Haptics._();

  static bool get _isAndroid {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  static Future<void> light() async {
    if (_isAndroid) {
      await HapticFeedback.lightImpact();
    }
  }

  static Future<void> success() async {
    if (_isAndroid) {
      await HapticFeedback.mediumImpact();
    }
  }
}
