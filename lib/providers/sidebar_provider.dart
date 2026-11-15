import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the collapsed state of the desktop sidebar at viewports >= 900 dp.
/// Backed by SharedPreferences key `sidebar_collapsed`.
class SidebarCollapsedNotifier extends Notifier<bool> {
  static const prefKey = 'sidebar_collapsed';

  @override
  bool build() {
    return false;
  }

  /// Initializes the state from persistent preferences.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(prefKey) ?? false;
    } catch (_) {
      // Safe fallback if SharedPreferences isn't ready
    }
  }

  /// Toggles the collapsed state and saves to persistent storage.
  Future<void> toggle() async {
    state = !state;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKey, state);
    } catch (_) {}
  }

  /// Explicitly sets the collapsed state and saves to persistent storage.
  Future<void> setCollapsed(bool value) async {
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKey, value);
    } catch (_) {}
  }
}

/// Provider for sidebar collapsed state (only honored at >= 900 dp).
final sidebarCollapsedProvider =
    NotifierProvider<SidebarCollapsedNotifier, bool>(() {
      return SidebarCollapsedNotifier();
    });
