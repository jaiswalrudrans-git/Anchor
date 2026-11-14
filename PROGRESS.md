# Execute App - Project Progress Log

## Current Status: Stage 1 Complete (Foundation, Backend & Auth)

### 1. What Exists Now
- **Flutter Multi-platform Project Skeleton**: Configured for Android (`io.execute.app`, singleTask launchMode, deep link intent filters) and Windows Desktop ("Execute" window and binary name, `io.execute.app` custom protocol handler, single-instance forwarding).
- **Strict Monochrome Wireframe System**: Complete theme tokens and `ThemeData` adhering to `#FFFFFF` background, `#F4F4F5` surface, `#E4E4E7` 1px border, `#111111` primary text/action fill, `#71717A` secondary text, `#A1A1AA` disabled, elevation 0, and max 8px border radius.
- **Supabase Backend Schema**: Full migration script (`supabase/migrations/001_init.sql`) defining all 14 tables, UUID PKs, RLS policies, cascading foreign keys, performance indexes, and the private `academic_vault` storage bucket with folder security policies.
- **Data Models**: All 14 typed immutable Dart data models with `fromJson`, `toJson`, `copyWith`, date-only parsing, and robust num handling (`int` and `double`).
- **Date Utilities**: Date-only sanitization (`dateOnly`, `today`), ISO parsing and formatting (`formatDbDate`, `parseDbDate`), month keys (`monthKey`), week start calculation (`startOfWeek`), and DST-immune day difference (`daysBetween`).
- **OAuth Authentication Service**: `AuthService` using Supabase OAuth with Google (`OAuthProvider.google`), deep-link callback integration (`app_links`), session state stream (`authStateProvider`), and current user provider (`currentUserProvider`).
- **Adaptive Main Shell**: Responsive root navigation switching between bottom `NavigationBar` (< 700px) and left `NavigationRail` (>= 700px) with 5 tabs in exact order: **Home | Academics | Expenses | Habits | Workout**. State preserved via `IndexedStack`. Zero global FAB in shell.
- **Missing Configuration Fallback**: Informative, non-crashing diagnostic screen when `--dart-define` keys are missing.
- **Test Suite**: 26 unit and widget tests covering date utilities, all 14 models round-trip JSON serialization, shell layout responsiveness, and auth/missing config screens.

---

### 2. Files Added & Changed

#### Root & Platform Config
- `pubspec.yaml` - Added `supabase_flutter`, `flutter_riverpod`, `app_links`, `url_launcher`, `intl`, `path`.
- `android/app/build.gradle.kts` - Updated namespace and applicationId to `io.execute.app`.
- `android/app/src/main/AndroidManifest.xml` - Added INTERNET permission, singleTask launchMode, display name "Execute", and `io.execute.app://login-callback` intent filter.
- `android/app/src/main/kotlin/io/execute/app/MainActivity.kt` - Kotlin package aligned with `io.execute.app`.
- `windows/runner/main.cpp` - Integrated `app_links` C API (`SendAppLinkToInstance`), set window title to "Execute".
- `windows/runner/Runner.rc` - Set ProductName and FileDescription to "Execute".

#### Database & Documentation
- `supabase/migrations/001_init.sql` - Complete idempotent database schema, RLS, indexes, and storage policies.
- `SETUP.md` - Complete setup guide for Supabase, GCP OAuth, redirect whitelists, Windows protocol, and CLI run commands.
- `PROGRESS.md` - Stage progress documentation.

#### Core
- `lib/core/constants/supabase_config.dart` - Supabase URL, anon key, redirect URL, and Windows protocol registration.
- `lib/core/constants/theme.dart` - Monochrome tokens and complete Material 3 `ThemeData`.
- `lib/core/constants/categories.dart` - Standard expense categories.
- `lib/core/utils/date_utils.dart` - Date-only handling, formatting, parsing, differences.
- `lib/core/utils/streak_utils.dart` - Placeholder for Stage 4.
- `lib/core/services/auth_service.dart` - OAuth Google auth service, session stream, and Riverpod providers.
- `lib/core/services/file_vault_service.dart` - Placeholder for Stage 3.
- `lib/core/services/notification_service.dart` - Placeholder for Stage 2.
- `lib/core/services/rollover_service.dart` - Placeholder for Stage 2.
- `lib/core/services/exam_cleanup_service.dart` - Placeholder for Stage 3.
- `lib/core/services/expense_reset_service.dart` - Placeholder for Stage 5.

#### Models
- `lib/models/model_helpers.dart` - Num parsing helpers.
- `lib/models/todo.dart` - Todo model.
- `lib/models/idle_prompt.dart` - Idle prompt model.
- `lib/models/subject.dart` - Academic subject model.
- `lib/models/module.dart` - Academic module model.
- `lib/models/chapter.dart` - Academic chapter model.
- `lib/models/chapter_file.dart` - Chapter file attachment model.
- `lib/models/academic_item.dart` - Assignment / exam item model.
- `lib/models/expense_settings.dart` - Expense settings model.
- `lib/models/expense_transaction.dart` - Expense transaction model.
- `lib/models/habit.dart` - Habit model.
- `lib/models/habit_log.dart` - Habit completion log model.
- `lib/models/workout_day.dart` - Workout day model.
- `lib/models/workout_exercise.dart` - Workout exercise model.
- `lib/models/expense_month_summary.dart` - Monthly expense summary model.

#### Providers
- `lib/providers/home_providers.dart` - Placeholder for Stage 2.
- `lib/providers/academics_providers.dart` - Placeholder for Stage 3.
- `lib/providers/expenses_providers.dart` - Placeholder for Stage 5.
- `lib/providers/habits_providers.dart` - Placeholder for Stage 4.
- `lib/providers/workout_providers.dart` - Placeholder for Stage 6.

#### UI & Screens
- `lib/main.dart` - Application entrypoint, auth gate, missing config fallback screen.
- `lib/screens/auth_screen.dart` - Unauthenticated Google sign-in screen.
- `lib/screens/main_shell.dart` - Adaptive 5-destination navigation shell.
- `lib/screens/home/home_screen.dart` - Home tab placeholder with Sign Out menu.
- `lib/screens/academics/academics_screen.dart` - Academics tab placeholder.
- `lib/screens/expenses/expenses_screen.dart` - Expenses tab placeholder.
- `lib/screens/habits/habits_screen.dart` - Habits tab placeholder.
- `lib/screens/workout/workout_screen.dart` - Workout tab placeholder.
- `lib/widgets/empty_state.dart` - Reusable monochrome empty state.
- `lib/widgets/loading_state.dart` - Reusable monochrome loading state.
- `lib/widgets/error_state.dart` - Reusable monochrome error state.
- `lib/widgets/responsive_container.dart` - Desktop max 900px centering container.

#### Tests
- `test/date_utils_test.dart` - 7 tests for `AppDateUtils`.
- `test/models_test.dart` - 14 tests for all models round-trip serialization and copyWith.
- `test/navigation_shell_test.dart` - 5 widget tests for adaptive shell, tabs, auth, and config fallback.

---

### 3. Public Service & Provider Names
- `authServiceProvider`: Provider of `AuthService`.
- `authStateProvider`: StreamProvider of `AuthState` from Supabase.
- `currentUserProvider`: Provider of current Supabase `User?`.
- `AppDateUtils`: Static utility class for dates (`dateOnly`, `today`, `formatDbDate`, `parseDbDate`, `monthKey`, `startOfWeek`, `daysBetween`).
- `SupabaseConfig`: Configuration helper reading `--dart-define` parameters.
- `AppColors`, `AppTheme`: Global styling tokens and light ThemeData.

---

### 4. Known Limitations
- Native compilation on Windows requires developer machines to have the "Desktop development with C++" workload installed via Visual Studio Installer.
- Scheduled local notifications are Android-only and will be wired in Stage 2 with platform guards.

---

### 5. What Stage 2 Must Know
- **Home Tab Integration**: Replace placeholder `HomeScreen` contents with the anti-procrastination task list, idle prompts, rollover service, and notification scheduling.
- **Add Todo Sheet**: Must be defined directly inside `screens/home/` (e.g. `add_todo_sheet.dart`) and invoked via a screen-specific FloatingActionButton or button with a unique `heroTag`. Never place an FAB in `MainShell`.
- **Date Handling**: Scheduled dates must use `AppDateUtils.dateOnly(...)` and `AppDateUtils.formatDbDate(...)` to avoid timezone offset bugs.
- **User Scoping**: All Supabase queries must rely on authenticated user context or pass `user_id: user.id` matching RLS policies.
