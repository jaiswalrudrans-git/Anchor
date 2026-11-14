import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/services/file_vault_service.dart';
import '../core/services/notification_service.dart';
import '../core/utils/date_utils.dart';
import '../models/academic_item.dart';
import '../models/chapter.dart';
import '../models/chapter_file.dart';
import '../models/module.dart';
import '../models/subject.dart';

const _uuid = Uuid();

enum AcademicsSegment { syllabus, assignments, exams }

class AcademicsActiveSegmentNotifier extends Notifier<AcademicsSegment> {
  @override
  AcademicsSegment build() => AcademicsSegment.syllabus;

  void setSegment(AcademicsSegment segment) {
    state = segment;
  }
}

final academicsActiveSegmentProvider =
    NotifierProvider<AcademicsActiveSegmentNotifier, AcademicsSegment>(() {
  return AcademicsActiveSegmentNotifier();
});

// ==========================================
// PURE FILTERING AND SORTING FUNCTIONS
// ==========================================

/// Sorts subjects by sort_order ascending, then by name ascending.
List<Subject> sortSubjects(List<Subject> subjects) {
  final list = List<Subject>.from(subjects);
  list.sort((a, b) {
    final orderCmp = a.sortOrder.compareTo(b.sortOrder);
    if (orderCmp != 0) return orderCmp;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return list;
}

/// Sorts modules by sort_order ascending, then by title ascending.
List<AcademicModule> sortModules(List<AcademicModule> modules) {
  final list = List<AcademicModule>.from(modules);
  list.sort((a, b) {
    final orderCmp = a.sortOrder.compareTo(b.sortOrder);
    if (orderCmp != 0) return orderCmp;
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  });
  return list;
}

/// Sorts chapters by sort_order ascending, then by title ascending.
List<Chapter> sortChapters(List<Chapter> chapters) {
  final list = List<Chapter>.from(chapters);
  list.sort((a, b) {
    final orderCmp = a.sortOrder.compareTo(b.sortOrder);
    if (orderCmp != 0) return orderCmp;
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  });
  return list;
}

/// Sorts assignments: incomplete first by due_date ASC then created_at ASC;
/// completed sink to the bottom.
List<AcademicItem> sortAssignments(List<AcademicItem> items) {
  final assignments = items.where((i) => i.itemType == 'assignment').toList();
  final incomplete = assignments.where((i) => !i.isCompleted).toList();
  final completed = assignments.where((i) => i.isCompleted).toList();

  incomplete.sort((a, b) {
    final dateCmp = a.dueDate.compareTo(b.dueDate);
    if (dateCmp != 0) return dateCmp;
    return a.createdAt.compareTo(b.createdAt);
  });

  completed.sort((a, b) {
    final dateCmp = a.dueDate.compareTo(b.dueDate);
    if (dateCmp != 0) return dateCmp;
    return a.createdAt.compareTo(b.createdAt);
  });

  return [...incomplete, ...completed];
}

/// Strictly sorts incomplete exams by due_date ASC, then created_at ASC.
List<AcademicItem> sortExams(List<AcademicItem> items) {
  final exams = items.where((i) => i.itemType == 'exam' && !i.isCompleted).toList();
  exams.sort((a, b) {
    final dateCmp = a.dueDate.compareTo(b.dueDate);
    if (dateCmp != 0) return dateCmp;
    return a.createdAt.compareTo(b.createdAt);
  });
  return exams;
}

/// Filters urgent assignments for Home Radar (next 7 days window: today <= due_date <= today+7).
/// Incomplete only, sorted due_date ASC. Overdue assignments (< today) are excluded.
List<AcademicItem> filterUrgentAssignments(List<AcademicItem> items, DateTime today) {
  final cleanToday = AppDateUtils.dateOnly(today);
  final endWindow = cleanToday.add(const Duration(days: 7));

  final filtered = items.where((i) {
    if (i.itemType != 'assignment' || i.isCompleted) return false;
    final due = AppDateUtils.dateOnly(i.dueDate);
    return !due.isBefore(cleanToday) && !due.isAfter(endWindow);
  }).toList();

  filtered.sort((a, b) {
    final dateCmp = a.dueDate.compareTo(b.dueDate);
    if (dateCmp != 0) return dateCmp;
    return a.createdAt.compareTo(b.createdAt);
  });

  return filtered;
}

/// Filters urgent exams for Home Radar (next 14 days window: today <= due_date <= today+14).
/// Sorted strictly due_date ASC. Incomplete exams only.
List<AcademicItem> filterUrgentExams(List<AcademicItem> items, DateTime today) {
  final cleanToday = AppDateUtils.dateOnly(today);
  final endWindow = cleanToday.add(const Duration(days: 14));

  final filtered = items.where((i) {
    if (i.itemType != 'exam' || i.isCompleted) return false;
    final due = AppDateUtils.dateOnly(i.dueDate);
    return !due.isBefore(cleanToday) && !due.isAfter(endWindow);
  }).toList();

  filtered.sort((a, b) {
    final dateCmp = a.dueDate.compareTo(b.dueDate);
    if (dateCmp != 0) return dateCmp;
    return a.createdAt.compareTo(b.createdAt);
  });

  return filtered;
}

/// Logical grouping for assignments.
enum AssignmentGroup {
  overdue,
  today,
  thisWeek,
  later,
  completed;

  String get label => switch (this) {
        AssignmentGroup.overdue => 'Overdue',
        AssignmentGroup.today => 'Due today',
        AssignmentGroup.thisWeek => 'This week',
        AssignmentGroup.later => 'Later',
        AssignmentGroup.completed => 'Completed',
      };
}

/// Groups assignments into Overdue, Due today, This week, Later, and Completed.
/// Within each group, sorts incomplete by due_date ASC and completed by due_date DESC.
Map<AssignmentGroup, List<AcademicItem>> groupAssignments(
  List<AcademicItem> items,
  DateTime today,
) {
  final cleanToday = AppDateUtils.dateOnly(today);
  final weekEnd = cleanToday.add(const Duration(days: 7));

  final groups = <AssignmentGroup, List<AcademicItem>>{
    AssignmentGroup.overdue: [],
    AssignmentGroup.today: [],
    AssignmentGroup.thisWeek: [],
    AssignmentGroup.later: [],
    AssignmentGroup.completed: [],
  };

  for (final item in items) {
    if (item.itemType != 'assignment') continue;
    if (item.isCompleted) {
      groups[AssignmentGroup.completed]!.add(item);
    } else {
      final due = AppDateUtils.dateOnly(item.dueDate);
      if (due.isBefore(cleanToday)) {
        groups[AssignmentGroup.overdue]!.add(item);
      } else if (due.isAtSameMomentAs(cleanToday)) {
        groups[AssignmentGroup.today]!.add(item);
      } else if (!due.isAfter(weekEnd)) {
        groups[AssignmentGroup.thisWeek]!.add(item);
      } else {
        groups[AssignmentGroup.later]!.add(item);
      }
    }
  }

  for (final entry in groups.entries) {
    if (entry.key == AssignmentGroup.completed) {
      entry.value.sort((a, b) {
        final dateCmp = b.dueDate.compareTo(a.dueDate);
        if (dateCmp != 0) return dateCmp;
        return b.createdAt.compareTo(a.createdAt);
      });
    } else {
      entry.value.sort((a, b) {
        final dateCmp = a.dueDate.compareTo(b.dueDate);
        if (dateCmp != 0) return dateCmp;
        return a.createdAt.compareTo(b.createdAt);
      });
    }
  }

  return groups;
}

class SubjectSyllabusStats {
  final int totalModules;
  final int totalChapters;
  final int studiedChapters;
  final double progress; // 0.0 to 1.0

  const SubjectSyllabusStats({
    required this.totalModules,
    required this.totalChapters,
    required this.studiedChapters,
    required this.progress,
  });
}

class ModuleSyllabusStats {
  final int totalChapters;
  final int studiedChapters;
  final double progress; // 0.0 to 1.0

  const ModuleSyllabusStats({
    required this.totalChapters,
    required this.studiedChapters,
    required this.progress,
  });
}

// ==========================================
// 1. SUBJECTS NOTIFIER & PROVIDER
// ==========================================

class SubjectsNotifier extends AsyncNotifier<List<Subject>> {
  SupabaseClient? get _supabase {
    try {
      if (Supabase.instance.isInitialized) {
        return Supabase.instance.client;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<Subject>> build() async {
    return _fetchSubjects();
  }

  Future<List<Subject>> _fetchSubjects() async {
    final client = _supabase;
    if (client == null) return [];

    try {
      final response = await client
          .from('subjects')
          .select()
          .order('sort_order', ascending: true)
          .order('name', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return sortSubjects(
        data.map((j) => Subject.fromJson(j as Map<String, dynamic>)).toList(),
      );
    } catch (e) {
      debugPrint('SubjectsNotifier._fetchSubjects error: $e');
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchSubjects());
  }

  Future<Subject?> addSubject(String name) async {
    final client = _supabase;
    final user = client?.auth.currentUser;
    if (client == null || user == null) throw StateError('User not authenticated');

    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final current = state.value ?? [];
    final nextOrder = current.isEmpty
        ? 1
        : (current.map((s) => s.sortOrder).reduce((a, b) => a > b ? a : b) + 1);

    final newSubject = Subject(
      id: _uuid.v4(),
      userId: user.id,
      name: trimmed,
      sortOrder: nextOrder,
    );

    state = AsyncData(sortSubjects([...current, newSubject]));

    try {
      await client.from('subjects').insert(newSubject.toJson());
      return newSubject;
    } catch (e) {
      state = AsyncData(current);
      debugPrint('addSubject failed: $e');
      rethrow;
    }
  }

  Future<void> renameSubject(String id, String newName) async {
    final client = _supabase;
    if (client == null) throw StateError('Supabase uninitialized');

    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final current = state.value ?? [];
    final index = current.indexWhere((s) => s.id == id);
    if (index == -1) return;

    final updated = current[index].copyWith(name: trimmed);
    final updatedList = List<Subject>.from(current);
    updatedList[index] = updated;

    state = AsyncData(sortSubjects(updatedList));

    try {
      await client.from('subjects').update({'name': trimmed}).eq('id', id);
    } catch (e) {
      state = AsyncData(current);
      debugPrint('renameSubject failed: $e');
      rethrow;
    }
  }

  Future<void> deleteSubject(String id) async {
    final client = _supabase;
    if (client == null) throw StateError('Supabase uninitialized');

    final current = state.value ?? [];
    final updatedList = current.where((s) => s.id != id).toList();

    state = AsyncData(updatedList);

    try {
      await ref.read(fileVaultServiceProvider).onSubjectRemoved(id);
      await client.from('subjects').delete().eq('id', id);
    } catch (e) {
      state = AsyncData(current);
      debugPrint('deleteSubject failed: $e');
      rethrow;
    }
  }
}

final subjectsProvider = AsyncNotifierProvider<SubjectsNotifier, List<Subject>>(() {
  return SubjectsNotifier();
});

/// Currently selected subject ID in the Academics tab.
class SelectedSubjectNotifier extends Notifier<String?> {
  @override
  String? build() {
    final subjects = ref.watch(subjectsProvider).value ?? [];
    return subjects.isNotEmpty ? subjects.first.id : null;
  }

  void select(String? id) => state = id;
}

final selectedSubjectIdProvider =
    NotifierProvider<SelectedSubjectNotifier, String?>(() {
  return SelectedSubjectNotifier();
});

// ==========================================
// 2. MODULES NOTIFIER & PROVIDER
// ==========================================

class ModulesNotifier extends AsyncNotifier<List<AcademicModule>> {
  SupabaseClient? get _supabase {
    try {
      if (Supabase.instance.isInitialized) {
        return Supabase.instance.client;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<AcademicModule>> build() async {
    return _fetchModules();
  }

  Future<List<AcademicModule>> _fetchModules() async {
    final client = _supabase;
    if (client == null) return [];

    try {
      final response = await client
          .from('modules')
          .select()
          .order('sort_order', ascending: true)
          .order('title', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return sortModules(
        data.map((j) => AcademicModule.fromJson(j as Map<String, dynamic>)).toList(),
      );
    } catch (e) {
      debugPrint('ModulesNotifier._fetchModules error: $e');
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchModules());
  }

  Future<AcademicModule?> addModule(String subjectId, String title) async {
    final client = _supabase;
    final user = client?.auth.currentUser;
    if (client == null || user == null) throw StateError('User not authenticated');

    final trimmed = title.trim();
    if (trimmed.isEmpty) return null;

    final current = state.value ?? [];
    final subjectModules = current.where((m) => m.subjectId == subjectId).toList();
    final nextOrder = subjectModules.isEmpty
        ? 1
        : (subjectModules.map((m) => m.sortOrder).reduce((a, b) => a > b ? a : b) + 1);

    final newModule = AcademicModule(
      id: _uuid.v4(),
      subjectId: subjectId,
      userId: user.id,
      title: trimmed,
      sortOrder: nextOrder,
    );

    state = AsyncData(sortModules([...current, newModule]));

    try {
      await client.from('modules').insert(newModule.toJson());
      return newModule;
    } catch (e) {
      state = AsyncData(current);
      debugPrint('addModule failed: $e');
      rethrow;
    }
  }

  Future<void> renameModule(String id, String newTitle) async {
    final client = _supabase;
    if (client == null) throw StateError('Supabase uninitialized');

    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return;

    final current = state.value ?? [];
    final index = current.indexWhere((m) => m.id == id);
    if (index == -1) return;

    final updated = current[index].copyWith(title: trimmed);
    final updatedList = List<AcademicModule>.from(current);
    updatedList[index] = updated;

    state = AsyncData(sortModules(updatedList));

    try {
      await client.from('modules').update({'title': trimmed}).eq('id', id);
    } catch (e) {
      state = AsyncData(current);
      debugPrint('renameModule failed: $e');
      rethrow;
    }
  }

  Future<void> deleteModule(String id) async {
    final client = _supabase;
    if (client == null) throw StateError('Supabase uninitialized');

    final current = state.value ?? [];
    final updatedList = current.where((m) => m.id != id).toList();

    state = AsyncData(updatedList);

    try {
      await ref.read(fileVaultServiceProvider).onModuleRemoved(id);
      await client.from('modules').delete().eq('id', id);
    } catch (e) {
      state = AsyncData(current);
      debugPrint('deleteModule failed: $e');
      rethrow;
    }
  }
}

final modulesProvider = AsyncNotifierProvider<ModulesNotifier, List<AcademicModule>>(() {
  return ModulesNotifier();
});

/// Returns modules filtered for the selected subject.
final modulesForSelectedSubjectProvider = Provider<List<AcademicModule>>((ref) {
  final selectedSubjectId = ref.watch(selectedSubjectIdProvider);
  if (selectedSubjectId == null) return [];

  final modulesAsync = ref.watch(modulesProvider);
  final allModules = modulesAsync.value ?? [];

  final subjectModules = allModules.where((m) => m.subjectId == selectedSubjectId).toList();
  return sortModules(subjectModules);
});

// ==========================================
// 3. CHAPTERS NOTIFIER & PROVIDER
// ==========================================

class ChaptersNotifier extends AsyncNotifier<List<Chapter>> {
  SupabaseClient? get _supabase {
    try {
      if (Supabase.instance.isInitialized) {
        return Supabase.instance.client;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<Chapter>> build() async {
    return _fetchChapters();
  }

  Future<List<Chapter>> _fetchChapters() async {
    final client = _supabase;
    if (client == null) return [];

    try {
      final response = await client
          .from('chapters')
          .select()
          .order('sort_order', ascending: true)
          .order('title', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return sortChapters(
        data.map((j) => Chapter.fromJson(j as Map<String, dynamic>)).toList(),
      );
    } catch (e) {
      debugPrint('ChaptersNotifier._fetchChapters error: $e');
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchChapters());
  }

  Future<Chapter?> addChapter(String moduleId, String title) async {
    final client = _supabase;
    final user = client?.auth.currentUser;
    if (client == null || user == null) throw StateError('User not authenticated');

    final trimmed = title.trim();
    if (trimmed.isEmpty) return null;

    final current = state.value ?? [];
    final moduleChapters = current.where((c) => c.moduleId == moduleId).toList();
    final nextOrder = moduleChapters.isEmpty
        ? 1
        : (moduleChapters.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) + 1);

    final newChapter = Chapter(
      id: _uuid.v4(),
      moduleId: moduleId,
      userId: user.id,
      title: trimmed,
      sortOrder: nextOrder,
    );

    state = AsyncData(sortChapters([...current, newChapter]));

    try {
      await client.from('chapters').insert(newChapter.toJson());
      return newChapter;
    } catch (e) {
      state = AsyncData(current);
      debugPrint('addChapter failed: $e');
      rethrow;
    }
  }

  Future<void> renameChapter(String id, String newTitle) async {
    final client = _supabase;
    if (client == null) throw StateError('Supabase uninitialized');

    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return;

    final current = state.value ?? [];
    final index = current.indexWhere((c) => c.id == id);
    if (index == -1) return;

    final updated = current[index].copyWith(title: trimmed);
    final updatedList = List<Chapter>.from(current);
    updatedList[index] = updated;

    state = AsyncData(sortChapters(updatedList));

    try {
      await client.from('chapters').update({'title': trimmed}).eq('id', id);
    } catch (e) {
      state = AsyncData(current);
      debugPrint('renameChapter failed: $e');
      rethrow;
    }
  }

  Future<void> toggleStudied(String id) async {
    final client = _supabase;
    if (client == null) throw StateError('Supabase uninitialized');

    final current = state.value ?? [];
    final index = current.indexWhere((c) => c.id == id);
    if (index == -1) return;

    final target = current[index];
    final updated = target.copyWith(isStudied: !target.isStudied);
    final updatedList = List<Chapter>.from(current);
    updatedList[index] = updated;

    state = AsyncData(sortChapters(updatedList));

    try {
      await client.from('chapters').update({'is_studied': updated.isStudied}).eq('id', id);
    } catch (e) {
      state = AsyncData(current);
      debugPrint('toggleStudied failed: $e');
      rethrow;
    }
  }

  /// Hook for cleanup when a chapter is removed: deletes storage objects and local cached files.
  Future<void> onChapterRemoved(String chapterId) async {
    await ref.read(fileVaultServiceProvider).onChapterRemoved(chapterId);
  }

  Future<void> deleteChapter(String id) async {
    final client = _supabase;
    if (client == null) throw StateError('Supabase uninitialized');

    final current = state.value ?? [];
    final updatedList = current.where((c) => c.id != id).toList();

    state = AsyncData(updatedList);

    try {
      await onChapterRemoved(id);
      await client.from('chapters').delete().eq('id', id);
    } catch (e) {
      state = AsyncData(current);
      debugPrint('deleteChapter failed: $e');
      rethrow;
    }
  }
}

final chaptersProvider = AsyncNotifierProvider<ChaptersNotifier, List<Chapter>>(() {
  return ChaptersNotifier();
});

// ==========================================
// 4. ACADEMIC ITEMS NOTIFIER & PROVIDER
// ==========================================

class AcademicItemsNotifier extends AsyncNotifier<List<AcademicItem>> {
  SupabaseClient? get _supabase {
    try {
      if (Supabase.instance.isInitialized) {
        return Supabase.instance.client;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<AcademicItem>> build() async {
    return _fetchItems();
  }

  Future<List<AcademicItem>> _fetchItems() async {
    final client = _supabase;
    if (client == null) return [];

    try {
      final response = await client
          .from('academic_items')
          .select()
          .order('due_date', ascending: true)
          .order('created_at', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      final items = data
          .map((j) => AcademicItem.fromJson(j as Map<String, dynamic>))
          .toList();

      // Trigger notification resync on Android
      ref.read(notificationServiceProvider).resyncAll(items);

      return items;
    } catch (e) {
      debugPrint('AcademicItemsNotifier._fetchItems error: $e');
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchItems());
  }

  Future<AcademicItem?> addItem({
    required String title,
    required String itemType, // 'assignment' | 'exam'
    required DateTime dueDate,
    String? subjectId,
  }) async {
    final client = _supabase;
    final user = client?.auth.currentUser;
    if (client == null || user == null) throw StateError('User not authenticated');

    final trimmed = title.trim();
    if (trimmed.isEmpty) return null;

    final sanitizedDate = AppDateUtils.dateOnly(dueDate);
    final newItem = AcademicItem(
      id: _uuid.v4(),
      userId: user.id,
      subjectId: subjectId?.isEmpty == true ? null : subjectId,
      title: trimmed,
      itemType: itemType,
      dueDate: sanitizedDate,
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    final current = state.value ?? [];
    state = AsyncData([...current, newItem]);

    try {
      await client.from('academic_items').insert(newItem.toJson());

      // Schedule notification
      final notificationService = ref.read(notificationServiceProvider);
      if (itemType == 'assignment') {
        await notificationService.scheduleAssignment(newItem);
      } else if (itemType == 'exam') {
        await notificationService.scheduleExam(newItem);
      }

      return newItem;
    } catch (e) {
      state = AsyncData(current);
      debugPrint('addItem failed: $e');
      rethrow;
    }
  }

  Future<void> toggleAssignmentComplete(String id) async {
    final client = _supabase;
    if (client == null) throw StateError('Supabase uninitialized');

    final current = state.value ?? [];
    final index = current.indexWhere((i) => i.id == id);
    if (index == -1) return;

    final target = current[index];
    final updated = target.copyWith(isCompleted: !target.isCompleted);

    final updatedList = List<AcademicItem>.from(current);
    updatedList[index] = updated;

    state = AsyncData(updatedList);

    try {
      await client.from('academic_items').update({
        'is_completed': updated.isCompleted,
      }).eq('id', id);

      final notificationService = ref.read(notificationServiceProvider);
      if (updated.isCompleted) {
        await notificationService.cancelReminder(id);
      } else {
        await notificationService.scheduleAssignment(updated);
      }
    } catch (e) {
      state = AsyncData(current);
      debugPrint('toggleAssignmentComplete failed: $e');
      rethrow;
    }
  }

  Future<void> markExamCompleted(String id) async {
    final client = _supabase;
    if (client == null) throw StateError('Supabase uninitialized');

    final current = state.value ?? [];
    final index = current.indexWhere((i) => i.id == id);
    if (index == -1) return;

    final target = current[index];
    final updated = target.copyWith(isCompleted: true);

    final updatedList = List<AcademicItem>.from(current);
    updatedList[index] = updated;

    state = AsyncData(updatedList);

    try {
      await client.from('academic_items').update({
        'is_completed': true,
      }).eq('id', id);

      await ref.read(notificationServiceProvider).cancelReminder(id);
    } catch (e) {
      state = AsyncData(current);
      debugPrint('markExamCompleted failed: $e');
      rethrow;
    }
  }

  Future<void> editItem({
    required String id,
    required String title,
    required DateTime dueDate,
    String? subjectId,
  }) async {
    final client = _supabase;
    if (client == null) throw StateError('Supabase uninitialized');

    final current = state.value ?? [];
    final index = current.indexWhere((i) => i.id == id);
    if (index == -1) return;

    final target = current[index];
    final sanitizedDate = AppDateUtils.dateOnly(dueDate);
    final updated = target.copyWith(
      title: title.trim(),
      dueDate: sanitizedDate,
      subjectId: subjectId?.isEmpty == true ? null : subjectId,
    );

    final updatedList = List<AcademicItem>.from(current);
    updatedList[index] = updated;

    state = AsyncData(updatedList);

    try {
      await client.from('academic_items').update({
        'title': updated.title,
        'due_date': AppDateUtils.formatDbDate(updated.dueDate),
        'subject_id': updated.subjectId,
      }).eq('id', id);

      if (!updated.isCompleted) {
        final notificationService = ref.read(notificationServiceProvider);
        await notificationService.cancelReminder(id);
        if (updated.itemType == 'assignment') {
          await notificationService.scheduleAssignment(updated);
        } else if (updated.itemType == 'exam') {
          await notificationService.scheduleExam(updated);
        }
      }
    } catch (e) {
      state = AsyncData(current);
      debugPrint('editItem failed: $e');
      rethrow;
    }
  }

  Future<void> restoreItem(AcademicItem item) async {
    final client = _supabase;
    if (client == null) throw StateError('Supabase uninitialized');

    final current = state.value ?? [];
    if (current.any((i) => i.id == item.id)) return;

    state = AsyncData([...current, item]);

    try {
      await client.from('academic_items').upsert(item.toJson());
      if (!item.isCompleted) {
        final notificationService = ref.read(notificationServiceProvider);
        if (item.itemType == 'assignment') {
          await notificationService.scheduleAssignment(item);
        } else if (item.itemType == 'exam') {
          await notificationService.scheduleExam(item);
        }
      }
    } catch (e) {
      state = AsyncData(current);
      debugPrint('restoreItem failed: $e');
      rethrow;
    }
  }

  Future<void> deleteItem(String id) async {
    final client = _supabase;
    if (client == null) throw StateError('Supabase uninitialized');

    final current = state.value ?? [];
    final updatedList = current.where((i) => i.id != id).toList();

    state = AsyncData(updatedList);

    try {
      await ref.read(notificationServiceProvider).cancelReminder(id);
      await client.from('academic_items').delete().eq('id', id);
    } catch (e) {
      state = AsyncData(current);
      debugPrint('deleteItem failed: $e');
      rethrow;
    }
  }
}

final academicItemsProvider =
    AsyncNotifierProvider<AcademicItemsNotifier, List<AcademicItem>>(() {
  return AcademicItemsNotifier();
});

// ==========================================
// 5. DERIVED PROVIDERS FOR UI & HOME RADAR
// ==========================================

/// Active (incomplete) assignments sorted by due_date ASC.
final activeAssignmentsProvider = Provider<List<AcademicItem>>((ref) {
  final itemsAsync = ref.watch(academicItemsProvider);
  final allItems = itemsAsync.value ?? [];
  final active = allItems.where((i) => i.itemType == 'assignment' && !i.isCompleted).toList();
  active.sort((a, b) {
    final dateCmp = a.dueDate.compareTo(b.dueDate);
    if (dateCmp != 0) return dateCmp;
    return a.createdAt.compareTo(b.createdAt);
  });
  return active;
});

/// Completed assignments sorted by due_date DESC.
final completedAssignmentsProvider = Provider<List<AcademicItem>>((ref) {
  final itemsAsync = ref.watch(academicItemsProvider);
  final allItems = itemsAsync.value ?? [];
  final completed = allItems.where((i) => i.itemType == 'assignment' && i.isCompleted).toList();
  completed.sort((a, b) {
    final dateCmp = b.dueDate.compareTo(a.dueDate);
    if (dateCmp != 0) return dateCmp;
    return b.createdAt.compareTo(a.createdAt);
  });
  return completed;
});

/// Exams strictly sorted by due_date ASC (no "Past" section).
final examsListProvider = Provider<List<AcademicItem>>((ref) {
  final itemsAsync = ref.watch(academicItemsProvider);
  final allItems = itemsAsync.value ?? [];
  return sortExams(allItems);
});

/// Home Radar: Upcoming assignments (next 7 days, incomplete, due_date ASC).
final urgentAssignmentsRadarProvider = Provider<List<AcademicItem>>((ref) {
  final itemsAsync = ref.watch(academicItemsProvider);
  final allItems = itemsAsync.value ?? [];
  return filterUrgentAssignments(allItems, AppDateUtils.today());
});

/// Home Radar: Upcoming exams (next 14 days, due_date ASC).
final urgentExamsRadarProvider = Provider<List<AcademicItem>>((ref) {
  final itemsAsync = ref.watch(academicItemsProvider);
  final allItems = itemsAsync.value ?? [];
  return filterUrgentExams(allItems, AppDateUtils.today());
});

/// Overall studied stats and progress for a subject.
final subjectSyllabusStatsProvider =
    Provider.family<SubjectSyllabusStats, String>((ref, subjectId) {
  final allModules = ref.watch(modulesProvider).value ?? [];
  final subjectModules = allModules.where((m) => m.subjectId == subjectId).toList();
  final moduleIds = subjectModules.map((m) => m.id).toSet();

  final allChapters = ref.watch(chaptersProvider).value ?? [];
  final subjectChapters = allChapters.where((c) => moduleIds.contains(c.moduleId)).toList();

  final totalModules = subjectModules.length;
  final totalChapters = subjectChapters.length;
  final studiedChapters = subjectChapters.where((c) => c.isStudied).length;
  final progress = totalChapters == 0 ? 0.0 : (studiedChapters / totalChapters);

  return SubjectSyllabusStats(
    totalModules: totalModules,
    totalChapters: totalChapters,
    studiedChapters: studiedChapters,
    progress: progress,
  );
});

/// Studied stats and progress for a single module.
final moduleSyllabusStatsProvider =
    Provider.family<ModuleSyllabusStats, String>((ref, moduleId) {
  final allChapters = ref.watch(chaptersProvider).value ?? [];
  final moduleChapters = allChapters.where((c) => c.moduleId == moduleId).toList();

  final totalChapters = moduleChapters.length;
  final studiedChapters = moduleChapters.where((c) => c.isStudied).length;
  final progress = totalChapters == 0 ? 0.0 : (studiedChapters / totalChapters);

  return ModuleSyllabusStats(
    totalChapters: totalChapters,
    studiedChapters: studiedChapters,
    progress: progress,
  );
});

/// Count of active (incomplete) assignments for a subject.
final subjectPendingAssignmentsCountProvider =
    Provider.family<int, String>((ref, subjectId) {
  final assignments = ref.watch(activeAssignmentsProvider);
  return assignments.where((a) => a.subjectId == subjectId).length;
});

/// Fast lookup for file count of a chapter.
final chapterFileCountProvider =
    Provider.family<int, String>((ref, chapterId) {
  final files = ref.watch(chapterFilesForChapterProvider(chapterId));
  return files.length;
});

// ==========================================
// 6. CHAPTER FILES NOTIFIER & PROVIDERS
// ==========================================

class ChapterFilesNotifier extends AsyncNotifier<List<ChapterFile>> {
  SupabaseClient? get _supabase {
    try {
      if (Supabase.instance.isInitialized) {
        return Supabase.instance.client;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<ChapterFile>> build() async {
    return _fetchFiles();
  }

  Future<List<ChapterFile>> _fetchFiles() async {
    final client = _supabase;
    if (client == null) return [];
    try {
      final response = await client
          .from('chapter_files')
          .select()
          .order('created_at', ascending: false);
      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => ChapterFile.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ChapterFilesNotifier._fetchFiles failed: $e');
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchFiles());
  }

  Future<List<ChapterFile>> pickAndUpload({
    required String chapterId,
    void Function(String fileName, double progress)? onProgress,
  }) async {
    final service = ref.read(fileVaultServiceProvider);
    final current = state.value ?? [];
    final existingNames = current
        .where((f) => f.chapterId == chapterId)
        .map((f) => f.fileName)
        .toList();

    final uploaded = await service.pickAndUploadFiles(
      chapterId: chapterId,
      existingFileNames: existingNames,
      onProgress: onProgress,
    );

    if (uploaded.isNotEmpty) {
      state = AsyncData([...uploaded, ...current]);
    }
    return uploaded;
  }

  Future<void> deleteFile(ChapterFile file) async {
    final service = ref.read(fileVaultServiceProvider);
    final current = state.value ?? [];
    final updated = current.where((f) => f.id != file.id).toList();

    // Optimistic update
    state = AsyncData(updated);

    try {
      await service.deleteFile(file);
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

final chapterFilesProvider =
    AsyncNotifierProvider<ChapterFilesNotifier, List<ChapterFile>>(() {
  return ChapterFilesNotifier();
});

final chapterFilesForChapterProvider =
    Provider.family<List<ChapterFile>, String>((ref, chapterId) {
  final filesAsync = ref.watch(chapterFilesProvider);
  final allFiles = filesAsync.value ?? [];
  return allFiles.where((f) => f.chapterId == chapterId).toList();
});

/// Computes the offline/cloud-only status for a chapter file.
final fileCacheStatusProvider =
    FutureProvider.family<VaultFileStatus, ChapterFile>((ref, file) async {
  final service = ref.watch(fileVaultServiceProvider);
  return service.getFileStatus(file);
});

