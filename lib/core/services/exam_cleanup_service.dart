import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/academic_item.dart';
import '../utils/app_log.dart';
import '../utils/date_utils.dart';
import 'notification_service.dart';

/// Service responsible for automatically deleting past exams from the backend.
/// Runs idempotently on launch, login, and when the app resumes.
class ExamCleanupService {
  final SupabaseClient? client;
  final NotificationService _notificationService;
  bool _isRunning = false;

  ExamCleanupService({this.client, NotificationService? notificationService})
    : _notificationService = notificationService ?? NotificationService();

  SupabaseClient? get _supabase {
    if (client != null) return client;
    try {
      if (Supabase.instance.isInitialized) {
        return Supabase.instance.client;
      }
    } catch (_) {}
    return null;
  }

  /// Pure helper: returns true if the exam should be deleted based on today's date.
  /// An exam is kept for its entire scheduled day and deleted from the next day onward.
  static bool shouldDeleteExam(DateTime examDate, DateTime today) {
    final cleanExam = AppDateUtils.dateOnly(examDate);
    final cleanToday = AppDateUtils.dateOnly(today);
    return cleanExam.isBefore(cleanToday);
  }

  /// Pure helper: filters all exams from a list that are strictly before today.
  static List<AcademicItem> filterOverdueExams(
    List<AcademicItem> items,
    DateTime today,
  ) {
    return items.where((item) {
      return item.itemType == 'exam' && shouldDeleteExam(item.dueDate, today);
    }).toList();
  }

  /// Runs the cleanup query against Supabase.
  /// Concurrency-guarded to prevent duplicate concurrent runs.
  Future<int> runCleanup({DateTime? now}) async {
    if (_isRunning) return 0;
    _isRunning = true;

    try {
      final client = _supabase;
      final user = client?.auth.currentUser;
      if (client == null || user == null) return 0;

      final today = now != null
          ? AppDateUtils.dateOnly(now)
          : AppDateUtils.today();
      final todayStr = AppDateUtils.formatDbDate(today);

      // 1. Fetch overdue exams to cancel their notifications
      final response = await client
          .from('academic_items')
          .select()
          .eq('item_type', 'exam')
          .lt('due_date', todayStr);

      final List<dynamic> rawList = response as List<dynamic>;
      final overdueExams = rawList
          .map((json) => AcademicItem.fromJson(json as Map<String, dynamic>))
          .toList();

      if (overdueExams.isEmpty) return 0;

      // 2. Cancel notifications for each past exam
      for (final exam in overdueExams) {
        await _notificationService.cancelReminder(exam.id);
      }

      // 3. Delete past exams from database
      await client
          .from('academic_items')
          .delete()
          .eq('item_type', 'exam')
          .lt('due_date', todayStr);

      AppLog.d(
        'ExamCleanupService: deleted ${overdueExams.length} past exam(s).',
      );
      return overdueExams.length;
    } catch (e) {
      AppLog.e('ExamCleanupService.runCleanup failed', e);
      return 0;
    } finally {
      _isRunning = false;
    }
  }
}

/// Provider for the singleton [ExamCleanupService].
final examCleanupServiceProvider = Provider<ExamCleanupService>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return ExamCleanupService(notificationService: notificationService);
});
