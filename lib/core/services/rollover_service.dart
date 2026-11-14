import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/date_utils.dart';
import '../../models/todo.dart';

/// Automatic Rollover Engine for overdue to-dos.
///
/// Runs on app launch (after auth), login, and AppLifecycleState.resumed.
/// Queries todos where `is_completed = false AND scheduled_date < today`.
/// Updates `scheduled_date = today` and `rollover_count = rollover_count + daysMissed`.
/// Idempotent and concurrency-guarded.
class RolloverService {
  final SupabaseClient? _client;
  bool _isRunning = false;

  RolloverService({SupabaseClient? supabase}) : _client = supabase;

  SupabaseClient? get _supabase {
    if (_client != null) return _client;
    try {
      if (Supabase.instance.isInitialized) {
        return Supabase.instance.client;
      }
    } catch (_) {}
    return null;
  }

  /// Pure helper computing the number of missed days between [scheduledDate] and [today].
  /// Returns 0 if [scheduledDate] is today or in the future.
  /// Returns `max(1, daysBetween(scheduledDate, today))` if [scheduledDate] is before today.
  static int computeRollover(DateTime scheduledDate, DateTime today) {
    final s = AppDateUtils.dateOnly(scheduledDate);
    final t = AppDateUtils.dateOnly(today);
    if (!s.isBefore(t)) {
      return 0;
    }
    final diff = AppDateUtils.daysBetween(s, t);
    return max(1, diff);
  }

  /// Runs the rollover engine.
  /// Returns the number of todos rolled over to today.
  /// Idempotent: running multiple times on the same date will find 0 overdue todos.
  Future<int> runRollover({DateTime? targetToday}) async {
    if (_isRunning) {
      debugPrint('RolloverService: rollover already in progress, skipping concurrent run');
      return 0;
    }
    _isRunning = true;

    try {
      final client = _supabase;
      if (client == null) return 0;

      final user = client.auth.currentUser;
      if (user == null) {
        return 0;
      }

      final today = targetToday != null
          ? AppDateUtils.dateOnly(targetToday)
          : AppDateUtils.today();
      final todayStr = AppDateUtils.formatDbDate(today);

      // Query incomplete todos scheduled before today
      final response = await client
          .from('todos')
          .select()
          .eq('is_completed', false)
          .lt('scheduled_date', todayStr);

      final List<dynamic> data = response as List<dynamic>;
      if (data.isEmpty) {
        return 0;
      }

      final todos = data.map((json) => Todo.fromJson(json as Map<String, dynamic>)).toList();

      // Concurrently update each overdue todo
      final updates = todos.map((todo) async {
        final daysMissed = computeRollover(todo.scheduledDate, today);
        if (daysMissed <= 0) return;

        final newRolloverCount = todo.rolloverCount + daysMissed;
        await client.from('todos').update({
          'scheduled_date': todayStr,
          'rollover_count': newRolloverCount,
        }).eq('id', todo.id);
      });

      await Future.wait(updates);
      debugPrint('RolloverService: Successfully rolled over ${todos.length} todo(s) to $todayStr');
      return todos.length;
    } catch (e) {
      debugPrint('RolloverService error: $e');
      return 0;
    } finally {
      _isRunning = false;
    }
  }
}

/// Provider for [RolloverService].
final rolloverServiceProvider = Provider<RolloverService>((ref) {
  return RolloverService();
});
