# Anchor App - Project Progress Log

## Current Status: Stage 7 Complete (Workout, Home Workout Strip & Final Hardening) — ALL 7 STAGES COMPLETE

### 1. Complete Application Feature Map

- **Flutter Multi-platform Architecture**:
  - Configured for Android (`io.anchor.app`, singleTask launchMode, deep link intent filters, exact alarms & boot receiver, open_filex FileProvider), Windows Desktop ("Anchor" window and binary name, `io.anchor.app` custom protocol handler, single-instance forwarding via Win32 messages), and Web preview.
  - Strict monochrome wireframe visual system: `#FFFFFF` background, `#F4F4F5` surface, `#E4E4E7` 1px border, `#111111` primary text/actions, `#71717A` secondary text, `#A1A1AA` disabled, elevation 0, max 8px border radius.
  - Adaptive root navigation switching between bottom `NavigationBar` (< 700px) and left `NavigationRail` (>= 700px) with 5 tabs in exact order: **Home | Academics | Expenses | Habits | Workout**. State preserved via `IndexedStack`. Zero global FAB in shell.
  - Centralized lifecycle observer in `MainShell`: runs rollover engine, past exam cleanup, monthly expense reset, and data refreshes on launch and resume without racing.

- **Stage 1: Foundation, DB Schema & Google OAuth**:
  - Full Supabase migration script (`supabase/migrations/001_init.sql`) defining all 14 tables, UUID PKs, cascading foreign keys, performance indexes, and the private `academic_vault` storage bucket with path-scoped RLS policies.
  - Google OAuth sign-in flow with custom URL scheme callback handling on Android and Windows Desktop. Missing configuration diagnostic screen.

- **Stage 2: Home Screen, Carry-Over To-Dos & Kill Idle Time**:
  - `todosProvider`: to-do CRUD with optimistic updates.
  - Idempotent `RolloverService`: rolls overdue uncompleted tasks to today with `rollover_count += daysMissed` on app launch and resume.
  - Kill Idle Time: Top banner locked until all today's tasks are completed. Unlocks 15:00 focus challenge timer with custom challenge pool management.
  - Quick-add inline input and `AddTodoSheet` containing only to-do fields.

- **Stage 3: Academics & Notifications**:
  - 3-level syllabus tree: Subjects -> Modules -> Chapters.
  - Scoped horizontal subject chips bar (exclusively on Syllabus tab).
  - Segmented toggle: **Syllabus | Assignments | Exams**.
  - `AcademicRadarSlot` on Home displaying urgent assignments (next 7 days) and upcoming exams (next 14 days).
  - Notification reminders (Android-only, safe no-op on Windows/web): 21:00 on `due_date - 1` for assignments; 08:00 on `due_date - 3` for exams.
  - `ExamCleanupService`: automatically deletes past exams with `due_date < today`.

- **Stage 4: Chapter File Vault**:
  - Multi-platform file picker (`pdf, ppt, pptx, doc, docx, txt, xls, xlsx, png, jpg, jpeg`).
  - Storage bucket `academic_vault` at `{user_id}/{chapter_id}/{file_name}`.
  - Local caching with offline status badge (`Cached Offline` vs `Cloud Only`).
  - Tap-to-open delegates directly to native OS viewer via `open_filex`.

- **Stage 5: Expenses (Allowance Ledger, Rollover & History)**:
  - 4-metric header: Monthly Allowance, Spent This Month, Remaining Balance, Savings Locker.
  - Segmented toggle: **Monthly Ledger | History**.
  - `ExpenseResetService`: multi-month gap traversal, pure `computeMonthClose`, positive remainder transferred to `total_savings` (Savings Locker).
  - Itemized transactions (Spent, Received, Saved). Read-only past months ledger and permanent history list.

- **Stage 6: Habits (Daily Matrix, Streaks & Weekly Report)**:
  - Pure calculation engine (`StreakUtils`): `currentStreak`, `missedDays`, `rebounds`, `weekStats`, `monthStats`, `dayStatus`.
  - Segmented toggle: **Overview | Weekly Report**.
  - Daily habit rows with one-tap today toggle and immediate streak update. Idempotent upsert/delete against `UNIQUE(habit_id, log_date)`.
  - Monthly consistency matrix (1..daysInMonth) with fixed habit column, scrollable day cells, tappable past cells to fix forgotten logs, inert future cells, and aggregate row.
  - Monthly Reality Report Card: Completions, Streak Breaks, Rebounds.
  - Weekly Report tab: Mon–Sun week navigator (future bounded), per-habit cards with 7-cell strip, and overall weekly summary.

- **Stage 7: Workout, Home Workout Strip & Final Hardening**:
  - 7 weekday tabs (Mon..Sun, 1=Mon..7=Sun), defaulting to today's weekday.
  - Editable split header per weekday (`EditSplitDialog`), creating `workout_days` lazily.
  - Exercise checklist: exercise name + sets/reps string, checkbox, delete icon.
  - **Today-only toggling rule**: checkbox is toggleable ONLY when viewing today's weekday tab; on other days it is display-only (disabled), preventing accidental logs on the wrong day.
  - Natural daily reset: checked state is derived from `last_completed_date == today`. Resets naturally each morning without background jobs. Templates are never deleted automatically.
  - `AddExerciseSheet`: strict page-specific add control containing ONLY exercise name and sets/reps.
  - `WorkoutStripSlot` (Home screen): displays `Today: {splitTitle}` and today's exercise checklist, synchronizing in real time with the Workout tab via shared Riverpod providers.
  - Add-button audit: verified that each page's add control opens only its own form and that zero FAB exists in `MainShell`.
  - Test suite: **157 unit and widget tests** passing across all modules.

---

### 2. Files Added & Changed in Stage 7

#### Files Added
- `lib/screens/workout/widgets/add_exercise_sheet.dart` - Modal sheet with strictly exercise name and sets/reps fields.
- `lib/screens/workout/widgets/edit_split_dialog.dart` - Dialog for setting or editing split title per weekday.
- `test/workout_unit_test.dart` - Unit tests for serialization, natural daily reset, and date derivation.
- `test/workout_widget_test.dart` - Widget tests for 7 weekday tabs, split header editing, today-only toggling rule, delete confirmation, and Home strip real-time sync.
- `test/add_buttons_audit_test.dart` - Full add-button audit asserting page-specific isolation across all 7 pages and zero FAB in `MainShell`.
- `TEST_SCRIPT.md` - Complete numbered end-to-end manual test script covering all 7 stages.

#### Files Modified
- `lib/providers/workout_providers.dart` - Full implementation of `workoutDaysProvider`, `workoutExercisesProvider`, `selectedWeekdayProvider`, and derived providers.
- `lib/screens/workout/workout_screen.dart` - Full 7-day tabbed Workout screen with editable split header and today-only interactive checklist.
- `lib/screens/home/widgets/workout_strip_slot.dart` - Replaced placeholder with live, synchronized today's workout card.
- `lib/screens/main_shell.dart` - Wired workout providers refresh into background sync.
- `test/navigation_shell_test.dart` - Updated tab switching assertion to match live Workout screen.
- `SETUP.md` - Enhanced with release build commands, platform caveats, and known v1 limitations.

---

### 3. Public Service & Provider Names
- `workoutDaysProvider`: `AsyncNotifierProvider` for `List<WorkoutDay>`.
- `workoutExercisesProvider`: `AsyncNotifierProvider` for `List<WorkoutExercise>` (`addExercise`, `deleteExercise`, `toggleExerciseToday`).
- `selectedWeekdayProvider`: `NotifierProvider` for active weekday tab (1..7).
- `workoutDayForWeekdayProvider`: Family provider returning `WorkoutDay?` for a weekday.
- `exercisesForWeekdayProvider`: Family provider returning `List<WorkoutExercise>` for a weekday.
- `todaysWeekdayProvider`: Provider returning today's weekday integer (1..7).
- `todaysWorkoutDayProvider`: Provider returning today's `WorkoutDay?`.
- `todaysExercisesProvider`: Provider returning today's `List<WorkoutExercise>`.

---

### 4. Verification Summary
- `flutter analyze`: **0 issues found** (clean).
- `flutter test`: **All 157 tests passed** across the entire test suite.
- Security: All 14 tables protected by Postgres RLS, Storage path-scoped, `--dart-define` key injection.
- Zero Git Push: No changes pushed to git (per explicit user instruction).
