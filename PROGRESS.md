# Anchor App - Project Progress Log

## Current Status: Stage 4 Complete (Chapter File Vault - Offline First)

### 1. What Exists Now
- **Flutter Multi-platform Project Skeleton**: Configured for Android (`io.anchor.app`, singleTask launchMode, deep link intent filters, exact alarms & boot receiver, open_filex FileProvider), Windows Desktop ("Anchor" window and binary name, `io.anchor.app` custom protocol handler, single-instance forwarding), and Web preview.
- **Strict Monochrome Wireframe System**: Complete theme tokens and `ThemeData` adhering to `#FFFFFF` background, `#F4F4F5` surface, `#E4E4E7` 1px border, `#111111` primary text/action fill, `#71717A` secondary text, `#A1A1AA` disabled, elevation 0, and max 8px border radius.
- **Supabase Backend Schema**: Full migration script (`supabase/migrations/001_init.sql`) defining all 14 tables, UUID PKs, RLS policies, cascading foreign keys, performance indexes, and the private `academic_vault` storage bucket with folder security policies.
- **Data Models**: All 14 typed immutable Dart data models with `fromJson`, `toJson`, `copyWith`, date-only parsing, and robust num handling (`int` and `double`).
- **Date Utilities**: Date-only sanitization (`dateOnly`, `today`, `tomorrow`), ISO parsing and formatting (`formatDbDate`, `parseDbDate`), month keys (`monthKey`), week start calculation (`startOfWeek`), and DST-immune day difference (`daysBetween`).
- **OAuth Authentication Service**: `AuthService` using Supabase OAuth with Google (`OAuthProvider.google`), deep-link callback integration (`app_links`), session state stream (`authStateProvider`), and current user provider (`currentUserProvider`).
- **Adaptive Main Shell**: Responsive root navigation switching between bottom `NavigationBar` (< 700px) and left `NavigationRail` (>= 700px) with 5 tabs in exact order: **Home | Academics | Expenses | Habits | Workout**. State preserved via `IndexedStack`. Zero global FAB in shell. Lifecycle observer running rollover checks and past exam cleanup on launch and `resumed`.
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
  - `AcademicRadarSlot`: Filled with live urgent assignments (next 7 days) and upcoming exams (next 14 days). Checkbox completes assignment immediately, removing it from radar.
  - `WorkoutStripSlot`: Placeholder widget for Stage 7.
- **Academics Data Layer & Providers (`lib/providers/academics_providers.dart`)**:
  - `subjectsProvider`: `AsyncNotifier` managing subjects with CRUD (`addSubject`, `renameSubject`, `deleteSubject`) and cascade handling.
  - `selectedSubjectIdProvider`: Notifier for the currently selected subject chip (scoped to Syllabus tab only).
  - `modulesProvider`: `AsyncNotifier` managing syllabus modules (`addModule`, `renameModule`, `deleteModule`).
  - `chaptersProvider`: `AsyncNotifier` managing chapters (`addChapter`, `renameChapter`, `deleteChapter`), with hook `onChapterRemoved(chapterId)`.
  - `academicItemsProvider`: `AsyncNotifier` managing assignments and exams with CRUD, optimistic updates, and notifications sync.
  - Derived providers: `activeAssignmentsProvider`, `completedAssignmentsProvider`, `examsListProvider`, `urgentAssignmentsRadarProvider`, `urgentExamsRadarProvider`.
- **Notification Engine (`lib/core/services/notification_service.dart`)**:
  - Deterministic 31-bit notification IDs (`uuid.hashCode & 0x7fffffff`).
  - Assignment reminder rule: 21:00 on `due_date - 1 day` (returns `null` if in the past).
  - Exam reminder rule: 08:00 on `due_date - 3 days` (returns `null` if in the past).
  - Platform guard: Android only (`AndroidScheduleMode.exactAllowWhileIdle` with inexact fallback). Safe no-op on Windows/web.
  - `resyncAll()` on app launch.
- **Past Exam Auto-Cleanup (`lib/core/services/exam_cleanup_service.dart`)**:
  - Pure date check: `shouldDeleteExam(examDate, today)`.
  - Automatically queries and deletes exams with `due_date < today` on app launch and resume, canceling their notifications. Silent and idempotent.
- **Academics Screen UI (`lib/screens/academics/`)**:
  - Horizontal scrollable subject chips bar with `+ Subject` action chip and long-press edit/delete actions, shown exclusively when on the Syllabus tab.
  - Segmented toggle: **Syllabus | Assignments | Exams**.
  - Context-aware add buttons (switching segments dynamically switches between `+ Add Module`, `+ Add Assignment`, and `+ Add Exam`).
  - `SyllabusTab`: Modules as `ExpansionTile`s, chapters nested with chapter vault opening, rename/delete dialogs.
  - `AssignmentsTab`: Sorted by `due_date ASC`, checkbox completes and cancels notification, collapsible completed section.
  - `ExamsTab`: Sorted strictly by `due_date ASC` (no priority tags, no "Past" section).
  - `AddAssignmentSheet` & `AddExamSheet`: Strict modal sheets with title/name, optional subject dropdown, and date pickers.
- **Chapter File Vault Engine (`lib/core/services/file_vault_service.dart`)**:
  - Local caching at `{getApplicationDocumentsDirectory()}/vault/{chapter_id}/{file_name}`.
  - Multi-platform file picker (`file_picker` 13.3.3) for `pdf, ppt, pptx, doc, docx, txt, xls, xlsx, png, jpg, jpeg`.
  - Pure utilities: `sanitizeFileName` (strips traversal & illegal characters), `resolveDuplicateName` (appends ` (1)`, ` (2)`... without collisions), `formatFileSize` (`B`, `KB`, `MB`), and `isFileCachedOnDisk` (validates existence and expected size).
  - Upload flow: reads bytes, uploads to Supabase Storage at `academic_vault/{user_id}/{chapter_id}/{file_name}`, inserts record in `chapter_files`, and caches locally on the uploading device immediately (`Cached Offline`). If DB insert fails, rolls back and removes the uploaded storage object (no orphans).
  - Cache status: `Cached Offline` (local file exists and size matches) vs `Cloud Only`.
  - Open flow: if cached, opens via `OpenFilex.open(localPath)`. If cloud only, downloads via Dio to a `.tmp` file, verifies size, moves to cache path (atomic - no partial files in cache path), flips status, then opens in the OS default viewer. Handles missing applications and offline errors cleanly.
  - Delete flow: removes from Supabase Storage first, then removes local cached file and DB row. Storage failures preserve the DB row (no half-deleted states).
  - Cleanup hooks: `onChapterRemoved(chapterId)`, `onModuleRemoved(moduleId)`, and `onSubjectRemoved(subjectId)` collect affected `chapter_files` before deletion, delete storage objects in bulk, and delete local `{vault}/{chapter_id}` directories.
- **Chapter Vault UI (`lib/screens/academics/widgets/chapter_vault_sheet.dart`)**:
  - Responsive modal: bottom sheet on phone, dialog on desktop.
  - Displays chapter title, list of files with extension badge, file name, formatted size, cache status badge (`Cached Offline` / `Cloud Only`), and delete action with confirmation dialog.
  - `+ Upload Material (PPT / PDF)` is the ONLY add control inside the vault.
  - Pull-to-refresh / refresh button to synchronize cloud files across devices.
  - Empty state: "No materials yet."
- **Test Suite**: 80 unit and widget tests covering date utils, all 14 models, rollover engine, idle unlock, navigation shell, notification reminder pure functions, past exam cleanup boundaries, radar filters, context-aware academics UI, file vault sanitizer/naming/sizes/caching logic, and vault sheet interactions. Clean `flutter analyze` (0 issues).

---

### 2. Files Added & Changed

#### Stage 4 Files Added
- `lib/core/services/file_vault_service.dart` - Offline-first file vault operations, local cache management, upload/download/delete flows, and cascading cleanup hooks.
- `android/app/src/main/res/xml/filepaths.xml` - Android FileProvider paths for `open_filex`.
- `test/vault_unit_test.dart` - Unit tests for file name sanitization, duplicate name resolution, file size formatting, and local disk cache verification.
- `test/vault_widget_test.dart` - Widget tests for ChapterVaultSheet (empty state, file list, upload button restriction, and delete confirmation).

#### Stage 4 Files Modified
- `pubspec.yaml` & `pubspec.lock` - Added `file_picker`, `open_filex`, `path_provider`, and `dio`.
- `android/app/src/main/AndroidManifest.xml` - Registered `androidx.core.content.FileProvider` for `open_filex`.
- `lib/providers/academics_providers.dart` - Added `ChapterFilesNotifier`, `chapterFilesProvider`, `chapterFilesForChapterProvider`, `fileCacheStatusProvider`, and wired vault cleanup hooks into `deleteSubject`, `deleteModule`, and `deleteChapter`.
- `lib/screens/academics/widgets/chapter_vault_sheet.dart` - Replaced placeholder with complete offline-first vault sheet with upload, download-on-tap, and delete flows.
- `test/academics_widget_test.dart` - Updated chapter tap test assertion to verify `ChapterVaultSheet` and upload button.

---

### 3. Public Service & Provider Names
- `fileVaultServiceProvider`: Provider of `FileVaultService`.
- `chapterFilesProvider`: `AsyncNotifierProvider` for `List<ChapterFile>`.
- `chapterFilesForChapterProvider(chapterId)`: Provider filtering files for a specific chapter.
- `fileCacheStatusProvider(file)`: `FutureProvider.family` computing `VaultFileStatus` (`cachedOffline` / `cloudOnly`).
- `notificationServiceProvider`: Provider of `NotificationService`.
- `examCleanupServiceProvider`: Provider of `ExamCleanupService`.
- `subjectsProvider`: `AsyncNotifierProvider` for subjects list.
- `selectedSubjectIdProvider`: `NotifierProvider` for currently selected subject.
- `modulesProvider`: `AsyncNotifierProvider` for syllabus modules list.
- `modulesForSelectedSubjectProvider`: Provider for modules of the selected subject.
- `chaptersProvider`: `AsyncNotifierProvider` for chapters list (includes `onChapterRemoved(chapterId)` hook).
- `academicItemsProvider`: `AsyncNotifierProvider` for assignments and exams.
- `activeAssignmentsProvider`: Provider for incomplete assignments sorted `due_date ASC`.
- `completedAssignmentsProvider`: Provider for completed assignments sorted `due_date DESC`.
- `examsListProvider`: Provider for exams sorted `due_date ASC`.
- `urgentAssignmentsRadarProvider`: Provider for urgent assignments (next 7 days, incomplete).
- `urgentExamsRadarProvider`: Provider for upcoming exams (next 14 days).

---

### 4. What Stage 5 (Expenses & Budget) Needs to Know
- **Expenses Tab**: Position 2 in `MainShell` navigation (index 2: Home = 0, Academics = 1, Expenses = 2, Habits = 3, Workout = 4).
- **Data Models**: `Expense`, `ExpenseCategory`, and `MonthlyBudget` are already generated in `lib/models/`.
- **Date Handling**: Monthly budgets use `AppDateUtils.monthKey(DateTime)` (`YYYY-MM`). Expenses use `AppDateUtils.dateOnly(DateTime)` and `AppDateUtils.formatDbDate(DateTime)`.
- **Database Tables**: Tables `expenses`, `expense_categories`, and `monthly_budgets` are already created with RLS in `supabase/migrations/001_init.sql`.
- **UI Constraints**: Strict monochrome wireframe (`#FFFFFF`, `#F4F4F5`, `#E4E4E7`, `#111111`, `#71717A`), elevation 0, max 8px border radius. No global FAB in `MainShell`.

