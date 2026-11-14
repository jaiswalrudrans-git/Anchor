# Anchor App - Project Progress Log

## Current Status: Stage 2 Complete (Home, Rollover Engine & Kill Idle Time)

### 1. What Exists Now
- **Flutter Multi-platform Project Skeleton**: Configured for Android (`io.anchor.app`, singleTask launchMode, deep link intent filters), Windows Desktop ("Anchor" window and binary name, `io.anchor.app` custom protocol handler, single-instance forwarding), and Web preview.
- **Strict Monochrome Wireframe System**: Complete theme tokens and `ThemeData` adhering to `#FFFFFF` background, `#F4F4F5` surface, `#E4E4E7` 1px border, `#111111` primary text/action fill, `#71717A` secondary text, `#A1A1AA` disabled, elevation 0, and max 8px border radius.
- **Supabase Backend Schema**: Full migration script (`supabase/migrations/001_init.sql`) defining all 14 tables, UUID PKs, RLS policies, cascading foreign keys, performance indexes, and the private `academic_vault` storage bucket with folder security policies.
- **Data Models**: All 14 typed immutable Dart data models with `fromJson`, `toJson`, `copyWith`, date-only parsing, and robust num handling (`int` and `double`).
- **Date Utilities**: Date-only sanitization (`dateOnly`, `today`, `tomorrow`), ISO parsing and formatting (`formatDbDate`, `parseDbDate`), month keys (`monthKey`), week start calculation (`startOfWeek`), and DST-immune day difference (`daysBetween`).
- **OAuth Authentication Service**: `AuthService` using Supabase OAuth with Google (`OAuthProvider.google`), deep-link callback integration (`app_links`), session state stream (`authStateProvider`), and current user provider (`currentUserProvider`).
- **Adaptive Main Shell**: Responsive root navigation switching between bottom `NavigationBar` (< 700px) and left `NavigationRail` (>= 700px) with 5 tabs in exact order: **Home | Academics | Expenses | Habits | Workout**. State preserved via `IndexedStack`. Zero global FAB in shell. Lifecycle observer running rollover checks on `resumed`.
- **Rollover Engine (`lib/core/services/rollover_service.dart`)**:
  - Pure helper `computeRollover(scheduledDate, today) -> int` returning exact days missed for overdue incomplete tasks and 0 for same-day or future tasks.
  - Idempotent `runRollover()` guarded against concurrent execution (`_isRunning`). Queries `is_completed = false AND scheduled_date < today`, updates `scheduled_date = today` and `rollover_count += daysMissed`. Runs on app launch, auth login, and app resume.
- **Home To-Do Data Layer & Providers (`lib/providers/home_providers.dart`)**:
  - `todosProvider`: `AsyncNotifier` supporting `addTodo`, `toggleComplete`, `reschedule`, `delete`, and `refreshTodos` with optimistic UI updates and error rollback.
  - `todaysTodosProvider`: Derived provider for today's tasks sorted by: rollover > 0 descending, then created_at ascending, completed tasks sink to bottom.
  - `tomorrowsTodosProvider`: Derived provider for pre-scheduled tasks for tomorrow.
  - `idlePromptsProvider`: `AsyncNotifier` managing idle challenge pool, auto-seeding 4 defaults once, supporting custom additions and deletions.
  - `killIdleUnlockedProvider`: Returns `true` ONLY if today has tasks and all are completed (`is_completed = true`).
- **Home UI (`lib/screens/home/`)**:
  - `KillIdleWidget`: Top status banner. Renders muted status line when locked ("Plan today's tasks first" or "N task(s) left today. Finish them to unlock Kill Idle Time.") and prominent button when unlocked.
  - `KillIdleDialog`: Challenge modal with random prompt display, "Shuffle Another", 15:00 countdown focus timer (properly cancelled in `dispose`), and "Manage Pool" bottom sheet.
  - Quick-add inline input (`home_quick_add_input`) and local header actions (no FAB in shell).
  - `AddTodoSheet`: Modal bottom sheet containing ONLY to-do fields (title, Today / Tomorrow / Pick date selector) without foreign inputs.
  - `TodoItemRow`: Monochrome task row with checkbox, strikethrough, `Rolled over Nx` badge, reschedule calendar button (preserving rollover count), and delete button with confirmation dialog.
  - Collapsible "Tomorrow" section for pre-scheduled tasks.
  - Placeholder slot widgets: `AcademicRadarSlot` (Stage 3) and `WorkoutStripSlot` (Stage 7).
- **Test Suite**: 41 unit and widget tests covering date utils, all 14 models, rollover engine logic, sorting rules, unlock conditions, to-do sheet assertions, shell adaptability, and auth states. Clean `flutter analyze` (0 issues).

---

### 2. Files Added & Changed

#### Stage 2 Files Added
- `lib/core/services/rollover_service.dart` - Rollover calculation and idempotent background database sync.
- `lib/screens/home/widgets/academic_radar_slot.dart` - Slot widget for Stage 3.
- `lib/screens/home/widgets/workout_strip_slot.dart` - Slot widget for Stage 7.
- `lib/screens/home/widgets/add_todo_sheet.dart` - Modal sheet with strict to-do fields.
- `lib/screens/home/widgets/todo_item_row.dart` - Row widget with checkbox, badges, reschedule picker, delete dialog.
- `lib/screens/home/widgets/kill_idle_widget.dart` - Top status / unlocked action banner.
- `lib/screens/home/widgets/kill_idle_dialog.dart` - 15:00 timer, shuffle, pool management.
- `test/home_unit_test.dart` - 12 unit tests for rollover calculation, sorting, and unlock logic.
- `test/home_widget_test.dart` - 3 widget tests for to-do sheet field validation and unlock UI behavior.

#### Stage 2 Files Modified
- `lib/core/utils/date_utils.dart` - Added `tomorrow()`.
- `lib/providers/home_providers.dart` - Complete implementation of `todosProvider`, `idlePromptsProvider`, derived providers, and pure sorting functions.
- `lib/screens/home/home_screen.dart` - Integrated Kill Idle Time, to-do list, tomorrow collapsible section, and slots.
- `lib/screens/main_shell.dart` - Integrated `WidgetsBindingObserver` to run rollover checks on `resumed`.
- `test/navigation_shell_test.dart` - Updated to ensure zero FAB in shell and async list settling.

---

### 3. Public Service & Provider Names
- `rolloverServiceProvider`: Provider of `RolloverService`.
- `todosProvider`: `AsyncNotifierProvider` for to-dos.
- `todaysTodosProvider`: Derived provider for today's sorted to-dos.
- `tomorrowsTodosProvider`: Derived provider for tomorrow's pre-scheduled to-dos.
- `idlePromptsProvider`: `AsyncNotifierProvider` for idle challenge prompts.
- `killIdleUnlockedProvider`: Derived provider returning `bool` unlock status.
- `AcademicRadarSlot`: Placeholder slot widget for Stage 3 (`lib/screens/home/widgets/academic_radar_slot.dart`).
- `WorkoutStripSlot`: Placeholder slot widget for Stage 7 (`lib/screens/home/widgets/workout_strip_slot.dart`).
- `authServiceProvider`: Provider of `AuthService`.
- `authStateProvider`: StreamProvider of `AuthState` from Supabase.
- `currentUserProvider`: Provider of current Supabase `User?`.
- `AppDateUtils`: Static utility class for dates (`dateOnly`, `today`, `tomorrow`, `formatDbDate`, `parseDbDate`, `monthKey`, `startOfWeek`, `daysBetween`).
- `SupabaseConfig`: Configuration helper reading `--dart-define` parameters.
- `AppColors`, `AppTheme`: Global styling tokens and light ThemeData.

---

### 4. What Stage 3 Needs to Know
- Slot widget `AcademicRadarSlot` is already located at `lib/screens/home/widgets/academic_radar_slot.dart` and mounted in `HomeScreen` directly below the collapsible "Tomorrow" section and above `WorkoutStripSlot`.
- In Stage 3, replace the internal contents of `AcademicRadarSlot` with the actual Academic Radar widget (showing urgent assignments, exam countdowns, and quick access to subjects/vault).
- Date utilities in `AppDateUtils` should be used for all exam/assignment due dates.
- All 14 data models are in `lib/models/`, including `Subject`, `Module`, `Chapter`, `ChapterFile`, and `AcademicItem`.
- `academic_vault` storage bucket is already defined in migration `001_init.sql`.

### 4. Known Limitations
- Native compilation on Windows requires developer machines to have the "Desktop development with C++" workload installed via Visual Studio Installer.
- Scheduled local notifications are Android-only and will be wired in Stage 2 with platform guards.

---

### 5. What Stage 2 Must Know
- **Home Tab Integration**: Replace placeholder `HomeScreen` contents with the anti-procrastination task list, idle prompts, rollover service, and notification scheduling.
- **Add Todo Sheet**: Must be defined directly inside `screens/home/` (e.g. `add_todo_sheet.dart`) and invoked via a screen-specific FloatingActionButton or button with a unique `heroTag`. Never place an FAB in `MainShell`.
- **Date Handling**: Scheduled dates must use `AppDateUtils.dateOnly(...)` and `AppDateUtils.formatDbDate(...)` to avoid timezone offset bugs.
- **User Scoping**: All Supabase queries must rely on authenticated user context or pass `user_id: user.id` matching RLS policies.
