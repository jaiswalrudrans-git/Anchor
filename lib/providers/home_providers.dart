import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/date_utils.dart';
import '../models/idle_prompt.dart';
import '../models/todo.dart';

const List<String> defaultIdlePrompts = [
  'Solve 1 DSA problem right now',
  'Build or debug 1 feature on a side project',
  'Practice a core programming concept for 15 mins',
  'Revise 1 syllabus chapter from your vault',
];

/// Pure helper for sorting to-dos according to Stage 2 rules:
/// 1. Completed tasks sink to the bottom.
/// 2. Tasks with rollover_count > 0 first, ordered descending by rollover_count.
/// 3. Rest ordered by created_at ascending.
List<Todo> sortTodos(List<Todo> todos) {
  final list = List<Todo>.from(todos);
  list.sort((a, b) {
    // 1. Completed tasks sink to the bottom
    if (a.isCompleted != b.isCompleted) {
      return a.isCompleted ? 1 : -1;
    }

    // 2. Rollover count > 0 first (descending)
    final aHasRollover = a.rolloverCount > 0;
    final bHasRollover = b.rolloverCount > 0;
    if (aHasRollover && bHasRollover) {
      final comp = b.rolloverCount.compareTo(a.rolloverCount);
      if (comp != 0) return comp;
    } else if (aHasRollover != bHasRollover) {
      return aHasRollover ? -1 : 1;
    }

    // 3. Rest by created_at ascending
    return a.createdAt.compareTo(b.createdAt);
  });
  return list;
}

/// Pure helper determining if Kill Idle Time is unlocked:
/// Unlocked ONLY when at least one task has scheduled_date == today AND every one of them is completed.
bool isKillIdleUnlocked(List<Todo> todaysTodos) {
  if (todaysTodos.isEmpty) return false;
  return todaysTodos.every((t) => t.isCompleted);
}

/// Pure helper generating the locked status message for Kill Idle Time.
String getKillIdleStatusMessage(List<Todo> todaysTodos) {
  if (todaysTodos.isEmpty) {
    return "Plan today's tasks first.";
  }
  final remaining = todaysTodos.where((t) => !t.isCompleted).length;
  if (remaining == 0) {
    return 'All tasks done! Kill Idle Time unlocked.';
  }
  final word = remaining == 1 ? 'task' : 'tasks';
  return '$remaining $word left today. Finish them to unlock Kill Idle Time.';
}

// -----------------------------------------------------------------------------
// Todos AsyncNotifier
// -----------------------------------------------------------------------------

class TodosNotifier extends AsyncNotifier<List<Todo>> {
  final _uuid = const Uuid();

  SupabaseClient? get _supabase {
    try {
      if (Supabase.instance.isInitialized) {
        return Supabase.instance.client;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<Todo>> build() async {
    return _fetchTodos();
  }

  Future<List<Todo>> _fetchTodos() async {
    final client = _supabase;
    if (client == null) return [];

    final user = client.auth.currentUser;
    if (user == null) return [];

    final today = AppDateUtils.today();
    final todayStr = AppDateUtils.formatDbDate(today);
    final tomorrowStr = AppDateUtils.formatDbDate(AppDateUtils.tomorrow());

    try {
      final response = await client
          .from('todos')
          .select()
          .or('scheduled_date.eq.$todayStr,scheduled_date.eq.$tomorrowStr,and(is_completed.eq.false,scheduled_date.lt.$todayStr)')
          .order('created_at', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => Todo.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('TodosNotifier._fetchTodos error: $e');
      return [];
    }
  }

  /// Refreshes to-dos from Supabase.
  Future<void> refreshTodos() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchTodos());
  }

  /// Adds a new to-do with optimistic UI update.
  Future<Todo?> addTodo(String title, DateTime date) async {
    final client = _supabase;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw StateError('User not authenticated');
    }

    final trimmed = title.trim();
    if (trimmed.isEmpty) return null;

    final sanitizedDate = AppDateUtils.dateOnly(date);
    final newTodo = Todo(
      id: _uuid.v4(),
      userId: user.id,
      title: trimmed,
      scheduledDate: sanitizedDate,
      isCompleted: false,
      rolloverCount: 0,
      createdAt: DateTime.now(),
    );

    final previous = state.value ?? [];
    // Optimistic update
    state = AsyncData([...previous, newTodo]);

    try {
      await client.from('todos').insert(newTodo.toJson());
      return newTodo;
    } catch (e) {
      // Rollback on failure
      state = AsyncData(previous);
      debugPrint('addTodo failed: $e');
      rethrow;
    }
  }

  /// Toggles task completion with optimistic UI update.
  Future<void> toggleComplete(String id) async {
    final client = _supabase;
    if (client == null) throw StateError('Supabase uninitialized');

    final previous = state.value ?? [];
    final index = previous.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final target = previous[index];
    final updated = target.copyWith(isCompleted: !target.isCompleted);

    final updatedList = List<Todo>.from(previous);
    updatedList[index] = updated;

    // Optimistic update
    state = AsyncData(updatedList);

    try {
      await client.from('todos').update({
        'is_completed': updated.isCompleted,
      }).eq('id', id);
    } catch (e) {
      // Rollback on failure
      state = AsyncData(previous);
      debugPrint('toggleComplete failed: $e');
      rethrow;
    }
  }

  /// Reschedules a to-do to a new date without touching rollover_count.
  Future<void> reschedule(String id, DateTime newDate) async {
    final client = _supabase;
    if (client == null) throw StateError('Supabase uninitialized');

    final previous = state.value ?? [];
    final index = previous.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final sanitizedDate = AppDateUtils.dateOnly(newDate);
    final target = previous[index];
    final updated = target.copyWith(scheduledDate: sanitizedDate);

    final updatedList = List<Todo>.from(previous);
    updatedList[index] = updated;

    // Optimistic update
    state = AsyncData(updatedList);

    try {
      await client.from('todos').update({
        'scheduled_date': AppDateUtils.formatDbDate(sanitizedDate),
      }).eq('id', id);
    } catch (e) {
      // Rollback on failure
      state = AsyncData(previous);
      debugPrint('reschedule failed: $e');
      rethrow;
    }
  }

  /// Deletes a to-do with optimistic UI update.
  Future<void> delete(String id) async {
    final client = _supabase;
    if (client == null) throw StateError('Supabase uninitialized');

    final previous = state.value ?? [];
    final updatedList = previous.where((t) => t.id != id).toList();

    // Optimistic update
    state = AsyncData(updatedList);

    try {
      await client.from('todos').delete().eq('id', id);
    } catch (e) {
      // Rollback on failure
      state = AsyncData(previous);
      debugPrint('delete failed: $e');
      rethrow;
    }
  }

  /// Restores a deleted to-do item (for Undo snackbar action).
  Future<void> restoreTodo(Todo todo) async {
    final client = _supabase;
    final previous = state.value ?? [];
    final updatedList = sortTodos([...previous, todo]);
    state = AsyncData(updatedList);

    if (client != null) {
      try {
        await client.from('todos').insert(todo.toJson());
      } catch (e) {
        state = AsyncData(previous);
        debugPrint('restoreTodo failed: $e');
        rethrow;
      }
    }
  }
}

/// Main to-dos provider.
final todosProvider = AsyncNotifierProvider<TodosNotifier, List<Todo>>(() {
  return TodosNotifier();
});

/// Derived provider returning sorted to-dos for today.
final todaysTodosProvider = Provider<List<Todo>>((ref) {
  final todosAsync = ref.watch(todosProvider);
  final todos = todosAsync.value ?? [];
  final today = AppDateUtils.today();

  final todays = todos.where((t) {
    return AppDateUtils.dateOnly(t.scheduledDate) == today;
  }).toList();

  return sortTodos(todays);
});

/// Derived provider returning pre-scheduled to-dos for tomorrow.
final tomorrowsTodosProvider = Provider<List<Todo>>((ref) {
  final todosAsync = ref.watch(todosProvider);
  final todos = todosAsync.value ?? [];
  final tomorrow = AppDateUtils.tomorrow();

  final tomorrows = todos.where((t) {
    return AppDateUtils.dateOnly(t.scheduledDate) == tomorrow;
  }).toList();

  return sortTodos(tomorrows);
});

/// Derived provider returning whether Kill Idle Time is unlocked.
final killIdleUnlockedProvider = Provider<bool>((ref) {
  final todays = ref.watch(todaysTodosProvider);
  return isKillIdleUnlocked(todays);
});

// -----------------------------------------------------------------------------
// Idle Prompts AsyncNotifier
// -----------------------------------------------------------------------------

class IdlePromptsNotifier extends AsyncNotifier<List<IdlePrompt>> {
  final _uuid = const Uuid();
  Future<void>? _seedingFuture;

  SupabaseClient? get _supabase {
    try {
      if (Supabase.instance.isInitialized) {
        return Supabase.instance.client;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<IdlePrompt>> build() async {
    final list = await _fetchPrompts();
    if (list.isEmpty) {
      // Auto-seed default prompts reliably on first load
      await seedIfEmpty();
      return _fetchPrompts();
    }
    return list;
  }

  Future<List<IdlePrompt>> _fetchPrompts() async {
    final client = _supabase;
    if (client == null) return [];

    final user = client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await client
          .from('idle_prompts')
          .select()
          .order('created_at', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => IdlePrompt.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('IdlePromptsNotifier._fetchPrompts error: $e');
      return [];
    }
  }

  /// Seeds the 4 default prompts if the pool is empty.
  /// Guarded against concurrent runs via a single in-flight future.
  Future<void> seedIfEmpty() async {
    if (_seedingFuture != null) {
      await _seedingFuture;
      return;
    }
    _seedingFuture = _performSeed();
    try {
      await _seedingFuture;
    } finally {
      _seedingFuture = null;
    }
  }

  Future<void> _performSeed() async {
    final client = _supabase;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;

    try {
      final existing = await client.from('idle_prompts').select('id');
      if ((existing as List<dynamic>).isNotEmpty) {
        return;
      }

      final now = DateTime.now();
      final inserts = defaultIdlePrompts.map((text) {
        return {
          'id': _uuid.v4(),
          'user_id': user.id,
          'prompt_text': text,
          'created_at': now.toIso8601String(),
        };
      }).toList();

      await client.from('idle_prompts').upsert(
        inserts,
        onConflict: 'user_id,prompt_text',
        ignoreDuplicates: true,
      );
      state = AsyncData(await _fetchPrompts());
    } catch (e) {
      debugPrint('seedIfEmpty error: $e');
      rethrow;
    }
  }

  /// Adds a custom prompt to the pool.
  Future<void> addPrompt(String promptText) async {
    final client = _supabase;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;

    final trimmed = promptText.trim();
    if (trimmed.isEmpty) return;

    final newPrompt = IdlePrompt(
      id: _uuid.v4(),
      userId: user.id,
      promptText: trimmed,
      createdAt: DateTime.now(),
    );

    final previous = state.value ?? [];
    state = AsyncData([...previous, newPrompt]);

    try {
      await client.from('idle_prompts').insert(newPrompt.toJson());
    } catch (e) {
      state = AsyncData(previous);
      debugPrint('addPrompt error: $e');
      rethrow;
    }
  }

  /// Deletes a prompt from the pool.
  Future<void> deletePrompt(String id) async {
    final client = _supabase;
    if (client == null) return;

    final previous = state.value ?? [];
    final updated = previous.where((p) => p.id != id).toList();
    state = AsyncData(updated);

    try {
      await client.from('idle_prompts').delete().eq('id', id);
    } catch (e) {
      state = AsyncData(previous);
      debugPrint('deletePrompt error: $e');
      rethrow;
    }
  }

  /// Restores a deleted prompt to the pool (for undo).
  Future<void> restorePrompt(IdlePrompt prompt) async {
    final client = _supabase;
    final previous = state.value ?? [];
    state = AsyncData([...previous, prompt]);

    if (client != null) {
      try {
        await client.from('idle_prompts').insert(prompt.toJson());
      } catch (e) {
        state = AsyncData(previous);
        debugPrint('restorePrompt error: $e');
        rethrow;
      }
    }
  }
}

/// Provider for idle prompts pool.
final idlePromptsProvider = AsyncNotifierProvider<IdlePromptsNotifier, List<IdlePrompt>>(() {
  return IdlePromptsNotifier();
});
