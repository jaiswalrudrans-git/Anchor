# Anchor App - Project Progress Log

## Current Status: Final Stage Complete (Smooth 120 Hz, Clean-Up, Release Builds for Windows & Android) — SHIP READY

### Final Stage Summary: Release Optimization, Performance & Production Packaging

- **Phase 1: Code Clean-Up & Dead Code Elimination**:
  - **Strict Static Analysis**: Enforced analyzer error severity and linter rules in `analysis_options.yaml` (`avoid_print`, `unused_element`, `unused_field`, `unused_import`, `unused_local_variable`, `unused_catch_clause`, `unnecessary_null_checks`, `prefer_const_constructors`, `prefer_const_declarations`, `prefer_final_fields`, `prefer_final_locals`, `use_build_context_synchronously`, `cancel_subscriptions`, `close_sinks`).
  - **Zero Debug Residue**: Replaced every ad-hoc `debugPrint` and `print` across `lib/` with centralized `AppLog` (`lib/core/utils/app_log.dart`), which cleanly no-ops in release builds (`kReleaseMode`).
  - **Dead Code & Leftovers**: Eliminated unused dependencies (`cupertino_icons`, `dio`). Cleared commented-out Flutter boilerplate in `pubspec.yaml` and `res/drawable*/launch_background.xml`.
  - **Automated Fix & Format**: Applied 47 automatic code fixes via `dart fix --apply` and formatted entire codebase using `dart format .`.
  - **Zero Hardcoded Colors Guard**: Replaced fallback error widget text color with `palette?.textMuted`; verified 100% pass on `test/guards/no_hardcoded_colors_test.dart` and `test/guards/dark_surfaces_test.dart`.

- **Phase 2: Performance (Smooth 120 Hz Target & Frame Budget)**:
  - **Display Rate Negotiation**: Integrated `flutter_displaymode 0.7.0` on Android startup (`main()`) to request maximum device refresh rate (90 Hz / 120 Hz) with fallback safety.
  - **Ticker & Animation Throttling**: Wrapped hidden `IndexedStack` pages in `TickerMode(enabled: currentIndex == i, child: ...)` so inactive screens halt animation tickers and do not consume frame budget.
  - **Layer Isolation**: Applied `RepaintBoundary` around the floating dock and navigation actions to decouple dock animations from screen rebuilds. `CardProgressStroke` animated painter is isolated with its own boundary.
  - **Automated Performance Driver**: Implemented `test_driver/perf_test.dart` and `test_driver/perf_test_e2e.dart` measuring frame build and raster times across dock glide, Quick Add transitions, and Home scroll.

- **Phase 3: Responsive & System Insets Audit**:
  - **10-Viewport Responsive Matrix**: Validated all screen sizes from 320x568 up to 1920x1080 across text scale 1.0 and 1.3 with 0 layout overflows (`test/quality_audit_test.dart`: 24/24 passed).
  - **Android 13+ Predictive Back**: Enabled `android:enableOnBackInvokedCallback="true"` in `AndroidManifest.xml` to support modern predictive back navigation gestures without breaking modal sheets.

- **Phase 4: Functional Regression Sweep**:
  - Full automated suite: **333/333 passed** across all 16 test files.
  - Zero functional regressions in To-dos, Academics, Expenses, Habits, Quick Add, and Profile.

- **Phase 5: Security & Backend Hygiene**:
  - **Git Secrets Protection**: Updated `.gitignore` to strictly exclude `.env`, `*.env`, `android/key.properties`, `key.properties`, `*.jks`, `*.keystore`, and performance trace files.
  - **RLS Verification Query**: Created `supabase/checks/rls_check.sql` covering all public tables and the `academic_vault` storage bucket.
  - **Cleartext Traffic Disabled**: Configured `android:usesCleartextTraffic="false"` in `AndroidManifest.xml`.
  - **Deep Link Callback**: Verified OAuth callback schemes (`io.anchor.app://login-callback`).

- **Phase 6: Release Build & Packaging Delivery**:
  - **Release Signing**: Added `android/key.properties.example` template and wired release signing config in `android/app/build.gradle.kts`.
  - **R8 & Resource Shrinking**: Enabled `isMinifyEnabled = true` and `isShrinkResources = true` with comprehensive `android/app/proguard-rules.pro`.
  - **Android Release Binaries**:
    - `build\app\outputs\flutter-apk\app-arm64-v8a-release.apk` (21.7 MB - down from 58.7 MB, 63% reduction)
    - `build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk` (19.4 MB)
    - `build\app\outputs\flutter-apk\app-x86_64-release.apk` (23.1 MB)
    - `build\app\outputs\flutter-apk\app-release.apk` (59.5 MB universal)
    - `build\app\outputs\bundle\release\app-release.aab` (57.1 MB Play Store bundle)
  - **Windows Release Executable**:
    - `build\windows\x64\runner\Release\anchor.exe` (Standalone 98.8 KB executable with complete runtime bundle in `Release/`)
  - **Documentation**: Generated `RELEASE_CHECKLIST.md` at repo root.

---

## Previous Milestones:

### 0. Branding Stage Summary: Complete Brand Identity & Icon Integration

- **Brand Asset Architecture & Generation Pipeline (`tool/generate_brand_assets.py`)**:
  - Deterministic, Pillow-only script that creates all brand assets from source masters without external graphic editors.
  - **Masters (`assets/branding/source/`)**:
    - `anchor_symbol_transparent_1024.png`: transparent glyph master.
    - `anchor_selected_black_on_white_1024.png`: legacy black on white master.
    - `anchor_android_monochrome_1024.png`: Android 13 themed icon layer.
  - **Programmatic Quality & Self-Check Assertions**:
    - Adaptive icon foreground glyph fits strictly inside the 66% circle safe zone (maximum radius 130.10 px $\le 142.56$ px limit).
    - Status bar notification icons (`ic_stat_anchor_*.png`) have pure white RGB `(255, 255, 255)` with variable alpha to prevent Android OS tinting artifacts.
    - Windows ICO (`app_icon.ico`) contains all 9 required resolutions: `[16, 20, 24, 32, 40, 48, 64, 128, 256]`.
    - Idempotent generation: running the script repeatedly yields 100% byte-for-byte identical assets.
  - **Visual Verification Contact Sheet**:
    - Generated `assets/branding/_preview.png` displaying adaptive masks (circle, squircle, rounded square), Android 13 themed preview, notification icon on dark bar, ICO resolutions, light/dark splash, and light/dark tab favicons.

- **Platform-Level Branding Configurations**:
  - **Android**:
    - `android/app/src/main/AndroidManifest.xml`: Set `android:label="Anchor"` and `android:roundIcon="@mipmap/ic_launcher_round"`.
    - Adaptive launcher icon: `res/mipmap-anydpi-v26/ic_launcher.xml` and `ic_launcher_round.xml` referencing `@drawable/ic_launcher_foreground` and `@color/ic_launcher_background` (`#FFFFFF`).
    - Android 13 themed icons: `<monochrome android:drawable="@drawable/ic_launcher_monochrome"/>`.
    - Notification icons: `res/drawable-*/ic_stat_anchor.png` (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi) and configured in `NotificationService` as `@drawable/ic_stat_anchor`.
    - Splash background colors: `#FFFFFF` (light) and `#0E0E10` (dark) matching Flutter canvas first-frame scaffolds.
  - **Windows Desktop**:
    - `windows/CMakeLists.txt`: Set `set(BINARY_NAME "anchor")` to generate `anchor.exe`.
    - `windows/runner/Runner.rc`: Set `CompanyName` ("io.anchor"), `FileDescription` ("Anchor"), `InternalName` ("anchor"), `OriginalFilename` ("anchor.exe"), `ProductName` ("Anchor"), `LegalCopyright` ("Copyright (C) 2026 io.anchor. All rights reserved.").
    - Window Title: `main.cpp` sets window title to `Anchor`.
    - Application Icon: `windows/runner/resources/app_icon.ico` replaced with multi-resolution Anchor icon.
    - Setup Installer: Created `windows/installer/anchor_setup.iss` and PowerShell automated build script `tool/build_windows_installer.ps1`.
  - **Web & Static Landing Presence**:
    - `web/index.html`: Set `<title>Anchor</title>`, `<meta name="theme-color">` for light (`#FFFFFF`) and dark (`#0E0E10`), Open Graph tags, apple-touch-icon, and favicons.
    - `web/manifest.json`: Set name, short_name, theme colors, and icons (any & maskable).
    - `site/`: Self-contained static landing website with responsive layout, light/dark mode support, download buttons, and complete PWA metadata.

- **In-App Branding Widgets (`lib/widgets/brand/anchor_logo.dart`)**:
  - `AnchorMark`: High-performance vector asset rendering `glyph_black.png` tinted via `ColorFilter.mode(palette.textPrimary, BlendMode.srcIn)` with semantic label `Anchor`.
  - `AnchorTile`: Rounded square (radius $0.22 \times \text{size}$) in `cardRaised` with 1 px `border`, containing `AnchorMark` at 56% size.
  - `AnchorWordmark`: Lockup containing `AnchorMark` and lowercase `anchor` in Inter SemiBold with $-0.5$ letter-spacing.
  - `BootScreen` (`lib/screens/boot_screen.dart`): Splash continuation screen with 88 dp centered `AnchorMark`, 400 ms entry motion (`Motion.moment`), 600 ms delayed progress line, and 200 ms cross-fade handoff to auth/home. Respects reduced motion.
  - `AuthScreen`: Replaced legacy "A" monogram with `AnchorTile(size: 72.0)`.
  - `ProfileMenu`: Added `AnchorMark(size: 16.0, color: palette.textSecondary)` to version footer.
  - `FloatingRail`: Displays `AnchorWordmark` on expanded desktop viewports ($\ge 900$ dp) and `AnchorMark(size: 28.0)` on medium viewports.

- **Automated Verification**:
  - `flutter analyze`: **0 issues found** (100% clean).
  - `flutter test test/brand_widget_test.dart`: **16/16 PASSED** (AnchorMark light/dark tinting, AnchorTile 7 accents, BootScreen motion & reduced motion, AuthScreen tile audit, FloatingRail wordmark).
  - `flutter test`: **333/333 PASSED** across all 16 test files.

- **Manual Steps Checklist**:
  1. Google Cloud Console: Set app name to "Anchor" and upload `assets/branding/android/playstore_512.png` on the OAuth consent screen.
  2. Supabase Dashboard: In Auth > URL/branding and email templates, set display name to "Anchor" and configure brand logo URL.
  3. Play Console: Upload `playstore_512.png` and `feature_graphic_1024x500.png` for store listing.
  4. GitHub Repository: Set repository social preview / avatar to `assets/branding/web/og-image.png`.
  5. Windows Installer: Install Inno Setup 6 on a Windows machine and execute `tool/build_windows_installer.ps1`.

---

### 1. Polish Stage 7 Summary: Responsive Matrix, Universal Alignment & Quality Audit

- **Universal Responsive Dock Alignment (`lib/widgets/navigation/floating_dock.dart`)**:
  - **Exact Closed Geometry & Math Formula**: Removed all arbitrary edge clamping (`[84, width - 84]`) which previously caused 52 dp decoupling on Home (slot 0) and Habits (slot 3).
  - Slot Center Formula: `centerX = (position + 0.5) * (totalWidth / 4.0)` ensures identical mathematical alignment for destination slots, pop-out bubble, and the concave notch across every device width.
  - Path Subtraction: `Path.combine(PathOperation.difference, pill, cutout)` naturally blends the notch into the dock's rounded end caps, guaranteeing a continuous closed path with zero edge collisions.
  - Verified across 10 distinct viewport configurations (`360x640`, `390x844`, `412x915`, `600x960`, `768x1024`, `1024x768`, `1280x800`, `1920x1080`, `844x390` landscape, and `717x800` foldable) at both 1.0 and 1.3 text scales with **zero layout overflow**.

- **Programmatic Theme & WCAG Contrast Audit (`test/quality_audit_test.dart`)**:
  - All 7 accent colors (`Iris`, `Jade`, `Ember`, `Saffron`, `Rose`, `Lagoon`, `Plum`) audited across light and dark modes:
    - Graphical elements / badges meet $\ge 3:1$ contrast against background and card surfaces.
    - `ContrastHelper.onAccent` dynamically selects `#FFFFFF` or `#111111` for high-luminance accents (such as Saffron), guaranteeing $\ge 4.5:1$ text contrast.
    - Dark mode surfaces use near-black `#0E0E10` and `#17171A` with higher-luminance dark accent variants.
  - Zero hardcoded colors outside `theme.dart`.

- **Motion Tier & Consistency Audit**:
  | Interaction / Component | Motion Tier | Duration | Curve | Purpose |
  |---|---|---|---|---|
  | Dock Slot Glide | Functional / Subtle | 320 ms | `Curves.easeInOutCubic` | Seamless lateral glide of notch + bubble |
  | Bubble Arrival Pop | Micro-interaction | 180 ms | `Curves.easeOutBack` | 4 dp lift + 6% scale overshoot on arrival |
  | Quick Add Plus Rotation | Functional | 200 ms | `Curves.easeInOut` | 45° rotation into 'X' when modal sheet opens |
  | Pressable Scale | Tap Feedback | 100 ms | `Curves.fastOutSlowIn` | Subtle button compression (scale 0.94) |
  | Keyboard Slide | Adaptive | 200 ms | `Curves.easeInOut` | Dock & Plus slide offscreen on keyboard entry |
  | Habit Completion Flash | Playful Moment | 300 ms | `Curves.easeOut` | Habit cell glow & celebration on check |
  | Milestone Celebrations | Achievement | 500 ms | `Curves.easeOutBack` | Triggered only on: all tasks done, focus session complete, exam marked done |
  - **Reduced Motion**: Respects `MediaQuery.disableAnimations` across all navigation and interactive components, instantly jumping to destination with zero overshoot or delays.

- **Accessibility & Copy Audit**:
  - All interactive controls provide `Semantics` tags (`button: true`, `selected: bool`, `label: String`).
  - Added keyboard activation (`Enter` / `Space`) via `FocusableActionDetector` to `PressableScale` and `ProfileMenu` accent swatches.
  - Desktop keyboard shortcuts: `Ctrl+N` opens Quick Add; `Esc` dismisses modals; Arrow keys navigate the floating rail.
  - Minimum tap targets $\ge 44$ dp everywhere.
  - Prohibited copy words (`successfully`, `please`, `Click here`) removed; sentence case with clean terminal punctuation applied.

- **Automated Verification & Test Suite**:
  - `test/quality_audit_test.dart`: **24/24 PASSED** (Multi-device matrix, theme contrast, reduced motion).
  - `test/floating_dock_polish_test.dart`: **35/35 PASSED**.
  - `test/dock_shape_test.dart`: **18/18 PASSED**.
  - **Total Test Suite (`flutter test`)**: **317 unit, widget, and layout tests** passing across all 15 test files (100% green).
  - `flutter analyze`: **0 issues found** (completely clean).

---

### 2. Polish Stage 2C Summary: Floating Dock Footer (Pop-Out Tabs + Separate Round Plus)

- **Floating Dock Navigation Architecture (`lib/widgets/navigation/`)**:
  - Replaced the Stage 2B notched `BottomAppBar` with a **floating pill-shaped dock** holding the 4 destinations (Home, Academics, Expenses, Habits) and a **separate floating round plus button** to the right.
  - **Zero FABs & Zero BottomAppBar**: Completely removed `FloatingActionButton`, `BottomAppBar`, and `FloatingActionButtonLocation.endDocked` across the entire codebase. Shell navigation add button is a custom `QuickAddButton` with key `quick_add_button`.
  - **Exact Geometry (Compact < 600 dp)**:
    - Anatomy: `[ 16 dp margin ][ DOCK (flex) ][ 12 dp gap ][ PLUS 60 dp ][ 16 dp margin ]` pinned at `12 dp + safe-area bottom offset`.
    - Dock: height 68 dp, corner radius 34 dp, 4 equal slots.
    - Dock surface: `cardRaised` fill, 1 px `border` stroke following the full outline (including the notch), subtle soft shadow in light mode. Opaque surface with `extendBody: true` for underlying scroll content.
    - Quick Add button (`lib/widgets/navigation/quick_add_button.dart`): 60 dp circle, vertically centered on dock, accent fill, `onAccent` 28 dp plus icon, key `quick_add_button`, tooltip and semantics label "Quick add", `PressableScale` (targetScale 0.94). Icon rotates 45° (200 ms) while the Quick Add sheet is open.
    - Inactive destination: 24 dp outlined icon (`textSecondary`), 11 sp label (`textSecondary`, `maxLines: 1`, `FittedBox(scaleDown)`). Entire slot is tap target (>= 48 dp tall).
    - Selected destination: pops out into a **bubble** (diameter 56 dp, center 14 dp above dock top edge, `accentSoft` fill, 2 px `accent` ring, 26 dp filled `accent` icon). Label sits below the bubble in `textPrimary` (medium weight). Thin 4 dp scaffold background gap between bubble and notch edge.
  - **Gliding Concave Notch Geometry (`DockShape` & `DockClipper`)**:
    - Notch circle radius $r = 34$ dp, center at bubble center (14 dp above dock top), cutting ~20 dp deep into the dock.
    - Smooth cubic Bezier S-curve shoulders (~16 dp horizontal span) blending into the dock outline.
    - **Device-Universal Notch Formula**: Exact 1:1 mathematical alignment across every screen width: $centerX = (position + 0.5) \times (width / 4.0)$, with zero arbitrary clamping. The notch is carved directly out of the dock pill via `Path.combine(PathOperation.difference, pill, cutout)` so that `notchApex == bubbleCenter == labelCenter` at all times on every device.
    - Continuous closed path used simultaneously for clipping, 1 px border painting, and shadow.
  - **Motion & Micro-interactions**:
    - **Glide**: Notch and bubble glide sideways together to newly tapped slot in 320 ms (`Curves.easeInOutCubic`).
    - **Icon Cross-Fade**: Bubble icon smoothly cross-fades at midpoint (150 ms). Inactive destination icons fade out on bubble arrival and fade back in on departure.
    - **Arrival Pop**: Bubble lifts 4 dp and settles back with tiny overshoot (180 ms `Curves.easeOutBack`, scale 0.94 to 1.0).
    - **Haptics**: `Haptics.light()` triggered on tab selection.
    - **Reduced Motion**: Respects `MediaQuery.disableAnimations` (instant jump, no pop, instant icon swap).
  - **Responsive & Keyboard Adaptation**:
    - **Content Clearance (`ShellMetrics`)**: `ShellMetrics.contentBottomPadding(context)` dynamically computes total clearance (`dockHeight + dockBottomOffset + safe-area bottom + 16 dp`), consumed by `PageContainer` and scroll views so content is never obscured.
    - **Keyboard Dismiss**: `resizeToAvoidBottomInset: false` on compact shell; dock and plus button slide down smoothly (200 ms) via `AnimatedSlide` when `viewInsets.bottom > 0`.
    - **Short Screens (< 480 dp)**: Dock scales to 56 dp, bubble to 48 dp (12 dp above dock top edge), inactive labels hidden (icons only, labels retained in semantics).
    - **Text Scale Clamping**: Dock text scale clamped to 1.0–1.15 so labels never wrap or clip.
  - **Restyled Floating Navigation Rail (Tablets & Desktop >= 600 dp)**:
    - Floating rounded panel (`lib/widgets/navigation/floating_rail.dart`): radius 28, `cardRaised` fill, 1 px `border`, inset 12 dp from window edge, vertically centered.
    - 4 destinations stacked vertically with vertically sliding bubble (same 320 ms glide and pop, no notch).
    - Leading Quick Add button: 60 dp circle on medium, extended pill with "Add" label on expanded (>= 900 dp). Key `quick_add_button`.
    - Full keyboard navigation on Windows: Up/Down arrow keys move focus, Enter/Space activates destination, visible focus ring. `Ctrl+N` opens Quick Add; `Esc` dismisses it.
- **Tokens & Theming**:
  - 100% token-based styling via `context.palette` (`cardRaised`, `border`, `accent`, `accentSoft`, `onAccent`, `textPrimary`, `textSecondary`, `background`).
  - Added `bool get isDark => ContrastHelper.relativeLuminance(background) < 0.2;` to `AppPalette`.
- **Files Created**:
  - `lib/widgets/navigation/floating_dock.dart`
  - `lib/widgets/navigation/quick_add_button.dart`
  - `lib/widgets/navigation/floating_rail.dart`
  - `test/dock_shape_test.dart`
  - `test/floating_dock_polish_test.dart`
- **Files Modified**:
  - `lib/core/constants/dimens.dart`
  - `lib/core/constants/theme.dart`
  - `lib/core/utils/responsive.dart`
  - `lib/widgets/responsive/page_container.dart`
  - `lib/screens/main_shell.dart`
  - `lib/screens/home/widgets/tomorrow_section.dart`
  - `lib/screens/home/widgets/academic_radar_slot.dart`
  - `lib/screens/academics/widgets/add_assignment_sheet.dart`
  - `lib/screens/academics/widgets/add_exam_sheet.dart`
  - `lib/screens/expenses/widgets/add_transaction_sheet.dart`
  - `test/add_buttons_audit_test.dart`
  - `test/navigation_shell_test.dart`
  - `test/expenses_widget_test.dart`
  - `test/expenses_polish_test.dart`
  - `TEST_SCRIPT.md`
  - `PROGRESS.md`
- **Automated Verification & Test Metrics**:
  - `test/dock_shape_test.dart`: **18/18 PASSED**.
  - `test/floating_dock_polish_test.dart`: **35/35 PASSED**.
  - `test/add_buttons_audit_test.dart`: **8/8 PASSED**.
  - `test/navigation_shell_test.dart`: **6/6 PASSED**.
  - `test/guards/no_hardcoded_colors_test.dart`: **PASSED** (0 hardcoded colors).
  - `test/guards/dark_surfaces_test.dart`: **PASSED** (all dark surfaces and WCAG contrast verified).
  - **Total Test Suite (`flutter test`)**: **287 unit, widget, and layout tests** passing across all files (100% green).
  - `flutter analyze`: **0 issues found** (completely clean).

---

### 2. Polish Stage 2B Summary: Remove Workout + Global Quick Add Button

- **Supabase Database Migration (`supabase/migrations/005_drop_workout.sql`)**:
  - Drops `workout_exercises` and `workout_days` tables with `cascade`.
  - Removes associated indexes, triggers, and RLS policies cleanly and permanently.
  - Active schema now consists of exactly 12 core tables (Auth, Profiles, Todos, Idle Prompts, Subjects, Modules, Chapters, Academic Items, File Vault, Expense Settings, Expense Transactions, Expense Month Summaries, Habits, Habit Logs).

- **Complete Workout Module Removal**:
  - Completely removed `lib/screens/workout/` (screen, `AddExerciseSheet`, `EditSplitDialog`).
  - Completely removed models `lib/models/workout_day.dart` and `lib/models/workout_exercise.dart`.
  - Completely removed providers `lib/providers/workout_providers.dart`.
  - Completely removed `WorkoutStripSlot` from `lib/screens/home/widgets/workout_strip_slot.dart`.
  - Deleted obsolete test files `test/workout_widget_test.dart` and `test/workout_unit_test.dart`.
  - Removed workout references from `lib/main.dart` and all remaining providers/widgets.

- **Main Navigation Shell & Global Quick Add Button (`lib/screens/main_shell.dart`)**:
  - The application now has exactly 4 tabs: `Home` (0), `Academics` (1), `Expenses` (2), `Habits` (3).
  - **Reversed FAB Rule**: The shell now owns **exactly ONE FloatingActionButton** (`heroTag: 'quick_add'`) in the entire app. Individual pages own zero FABs.
  - **Compact (< 600 dp)**: Notched `BottomAppBar` with `CircularNotchedRectangle()` and `notchMargin: 6.0`. 4 destinations share the left portion evenly (flex 1, min 64 dp); right ~88 dp is reserved for the docked FAB at `FloatingActionButtonLocation.endDocked`. Selected state styled with `accentSoft` pill and accent icon/label.
  - **Medium & Expanded (>= 600 dp)**: Left `NavigationRail` with 4 destinations. The Quick Add button sits as the `leading` item: 48–56 dp round circle on medium; extended pill with plus icon and "Add" label on expanded (>= 900 dp).
  - **FAB Animation & Feedback**: 56 dp circle, accent fill, `onAccent` plus icon, 1px background ring border, `PressableScale` tap bounce, and plus icon rotates 90° smoothly (150 ms) while the Quick Add sheet is open.
  - **Global Desktop Shortcuts**: `Ctrl+N` opens the Quick Add modal from anywhere; `Esc` closes it (or triggers the dirty discard confirmation dialog).
  - **Bottom Clearance**: `PageContainer` default bottom clearance ensures content is never obscured by the notched bar on compact mobile, and `MonthlyLedgerTab` includes explicit bottom scroll padding.

- **Shared Form Bodies & Quick Add System (`lib/widgets/quick_add/`)**:
  - `lib/widgets/quick_add/widgets/date_picker_chips.dart`: Segmented chip control (`Today | Tomorrow | Pick date`) for clean, quick date selection.
  - Shared forms extracted for reuse across full sheets and Quick Add:
    - `lib/widgets/quick_add/forms/todo_form_body.dart`: Title field and date picker chips.
    - `lib/widgets/quick_add/forms/assignment_form_body.dart`: Title field, subject dropdown, and date picker chips. Preserves test keys.
    - `lib/widgets/quick_add/forms/exam_form_body.dart`: Title field, subject dropdown, and date picker chips. Preserves test keys.
    - `lib/widgets/quick_add/forms/transaction_form_body.dart`: Centered amount field, 3-way toggle (Spent / Received / Savings), category chip wrap, and notes field.
    - `lib/widgets/quick_add/forms/habit_today_checklist.dart`: Quick checkoff list of today's active habits with icons, streaks, and checkboxes. Contains **zero text inputs and zero creation controls**; empty state displays an "Open Habits" button that closes the sheet and switches to the Habits tab.
  - Thin wrappers maintained for page-specific sheets: `AddTodoSheet`, `AddAssignmentSheet`, `AddExamSheet`, and `AddTransactionSheet`.

- **Adaptive Quick Add Sheet (`lib/widgets/quick_add/quick_add_sheet.dart`)**:
  - Opens via `showAdaptiveSheet`: bottom sheet on compact (< 600 dp, max height 90%, draggable, keyboard-aware), centered dialog (max width 480 dp) on medium/expanded (>= 600 dp).
  - **Smart Default (`quickAddContextProvider`)**: Auto-selects the initial type chip matching the active context:
    - Home tab -> `To-do`
    - Academics tab (Syllabus or Assignments segment) -> `Assignment`
    - Academics tab (Exams segment) -> `Exam`
    - Expenses tab -> `Expense`
    - Habits tab -> `Habit`
  - **Title Preservation**: Preserves title when switching between To-do, Assignment, and Exam chips.
  - **4-Second Undo SnackBar**: Submitting stays on the current tab and displays an Undo SnackBar (`Added to to-do`, `Assignment added`, `Exam added`, `Expense logged`). Notifiers are safely captured prior to popping the modal to prevent unmounted `ref` errors.
  - **Dirty Discard Confirmation**: If dismissed via close icon, tap outside, or `Esc` while text has been typed, prompts "Discard this entry?" with Keep Editing / Discard options.

- **Files Created**:
  - `supabase/migrations/005_drop_workout.sql`
  - `lib/core/utils/expense_utils.dart`
  - `lib/widgets/quick_add/quick_add_sheet.dart`
  - `lib/widgets/quick_add/widgets/date_picker_chips.dart`
  - `lib/widgets/quick_add/forms/todo_form_body.dart`
  - `lib/widgets/quick_add/forms/assignment_form_body.dart`
  - `lib/widgets/quick_add/forms/exam_form_body.dart`
  - `lib/widgets/quick_add/forms/transaction_form_body.dart`
  - `lib/widgets/quick_add/forms/habit_today_checklist.dart`
  - `test/quick_add_test.dart`
  - `test/expenses_polish_test.dart`

- **Files Deleted**:
  - `lib/screens/workout/workout_screen.dart`
  - `lib/screens/workout/widgets/add_exercise_sheet.dart`
  - `lib/screens/workout/widgets/edit_split_dialog.dart`
  - `lib/models/workout_day.dart`
  - `lib/models/workout_exercise.dart`
  - `lib/providers/workout_providers.dart`
  - `lib/screens/home/widgets/workout_strip_slot.dart`
  - `test/workout_widget_test.dart`
  - `test/workout_unit_test.dart`

- **Automated Guard & Test Metrics**:
  - `test/guards/no_hardcoded_colors_test.dart`: **PASSED** (0 hardcoded colors).
  - `test/guards/dark_surfaces_test.dart`: **PASSED** (all dark surfaces and WCAG contrast verified).
  - `test/quick_add_test.dart`: **16/16 PASSED**.
  - `test/navigation_shell_test.dart`: **6/6 PASSED**.
  - `test/add_buttons_audit_test.dart`: **8/8 PASSED**.
  - `test/home_widget_test.dart`: **3/3 PASSED**.
  - `test/academics_widget_test.dart`: **4/4 PASSED**.
  - `test/expenses_widget_test.dart`: **7/7 PASSED**.
  - `test/expenses_polish_test.dart`: **11/11 PASSED**.
  - `test/habits_widget_test.dart`: **5/5 PASSED**.
  - `test/habits_polish_test.dart`: **11/11 PASSED**.
  - **Total Test Suite (`flutter test`)**: **234 unit, widget, and guard tests** passing with 0 failures.
  - `flutter analyze`: **0 issues found** (clean).

---

### 2. Polish Stage 6 Summary: Expenses & Workout (+ Home Workout Strip)

- **Pure Helpers & Utilities (`lib/core/utils/expense_workout_utils.dart`)**:
  - `SpendingTone getSpendingTone(double spent, double allowance)`: Budget tone thresholds (<75% accent, 75-100% warning, >100% danger). Zero/unset allowance returns accent tone.
  - `String getSpendingCaption(double spent, double allowance)`: Formats budget state, e.g. "₹1,200.00 of ₹5,000.00 spent" or "Over budget by ₹500.00".
  - `IconData getExpenseCategoryIcon(String category, [String? txType])`: Deterministic Material icon per category (`restaurant_outlined`, `directions_bus_outlined`, `school_outlined`, `fitness_center_outlined`, `person_outline`, `category_outlined`, and `savings_outlined` for savings transfers).
  - `String formatDayHeader(DateTime txDate, [DateTime? relativeTo])`: Sticky-style day header labels (`Today`, `Yesterday`, `EEE, d MMM`) calculated safely across midnight boundaries.
  - `double calculateDayNetSpend(List<ExpenseTransaction> txs)`: Net cash outflow/inflow computation per calendar day.
  - `String formatDayNetSpend(double net, {bool includePrefix = true})`: Formatted net spend with signed currency (`Net: -₹X` or `Net: +₹X`).
  - `List<DayTransactionGroup> groupTransactionsByDay(List<ExpenseTransaction> txs, [DateTime? relativeTo])`: Groups transactions by calendar day descending with precalculated net spend.
  - `int getWorkoutCompletedCount(List<WorkoutExercise> exercises, int todayWeekday)` and `double getWorkoutProgress(...)`: Math helpers for workout checklists.
  - `bool shouldTriggerWorkoutAchievement(...)`: Pure transition detector firing strictly once when the last exercise of today is completed.

- **Expenses 4-Metric Header & Spending Bar (`lib/screens/expenses/widgets/expense_metrics_header.dart`)**:
  - 4 metrics formatted with `AppCard`, tabular figures, and `CountUpText` (300 ms): Monthly Allowance (editable via `EditAllowanceDialog`), Spent This Month, Remaining Balance (prominent card with `accentSoft` when positive, `dangerSoft` when negative), and Savings Locker (accumulated total savings).
  - Layout adapts smoothly: 1 row of 4 on medium/expanded (>= 600 dp), 2x2 grid on compact (< 600 dp).
  - Spending progress bar directly underneath with `AnimatedProgressBar` using budget tones (accent < 75%, warning 75-100%, danger > 100% with `Over budget by ₹X` caption).
  - Zero/unset allowance presents responsive inline nudge banner with "Set allowance" button (`set_allowance_nudge_button`) that stacks adaptively on narrow mobile widths (< 450 dp) to prevent text wrapping explosions.
  - Active in current month only; past closed months display read-only snapshot.

- **Month Navigation & Tabs (`lib/screens/expenses/expenses_screen.dart`)**:
  - Segmented toggle between `Monthly ledger` and `History` with 200 ms cross-fade (`AnimatedSwitcher`).
  - Compact month selector pill with prev/next arrows and `CURRENT` badge.

- **Itemized Ledger (`lib/screens/expenses/widgets/monthly_ledger_tab.dart`)**:
  - Transactions grouped by calendar day descending with sticky header displaying day label and net spend.
  - Transaction row: category icon in `accentSoft` rounded square, 1-line ellipsis title, category `Tag`, signed amount (`-₹250` textPrimary, `+₹500` success, `₹300` savings with piggy bank icon), and formatted time of day.
  - Swipe-to-delete (`Dismissible`) with danger background, 4-second Undo SnackBar (`restoreTransaction`), and hover/desktop delete button.
  - Deleting a `saved` transaction decrements `total_savings` via `adjustSavings(-amount)`; undo restores both transaction and savings.
  - Read-only for past closed months with snapshot summary card (`closed_month_snapshot_card`).
  - Empty state with clear messaging (`No transactions this month` / `Log your first one to start tracking.`).

- **Log Transaction Sheet (`lib/screens/expenses/widgets/add_transaction_sheet.dart`)**:
  - Shortened transaction type toggle labels (`Spent`, `Received`, `Savings`; caption/tooltip "Move to savings" when selected) to eliminate wrapping on 360 dp mobile devices.
  - Centered 28sp amount field with rupee prefix `₹` and numeric keyboard.
  - Category chips with icons in wrapping layout.
  - Submit button disabled until valid amount entered.
  - Strict form isolation (only transaction fields).

- **Expenses History Tab (`lib/screens/expenses/widgets/expenses_history_tab.dart`)**:
  - Closed month `AppCard` items displaying spent, received, saved, and remainder as tabular stat rows.
  - Mini progress bar of spent vs allowance with percentage badge.
  - Tapping opens the read-only ledger for that month.
  - Empty state: "History appears after your first month closes."

- **Workout Screen (`lib/screens/workout/workout_screen.dart`)**:
  - Day selector: 7 weekday pills `Mon … Sun`, today dot, exercise tick-dot, and rest-day moon icon (`Icons.bedtime_outlined`).
  - Split header card with inline edit dialog (`EditSplitDialog`), `3 / 5 done` progress bar on today, and exercise count on other days.
  - Checkable exercise cards with 22dp `AnimatedCheckbox`, sets/reps as `accentSoft` chip, and quiet delete.
  - Off-today checkboxes are visibly disabled with tooltip ("You can only check off today's exercises").
  - Completed rows dim and animate to bottom (250 ms).
  - Achievement moment: pulse ring + `Haptics.success()` triggers strictly once when the last exercise of today is checked.
  - Strict form isolation: `+ Add Exercise` opens `AddExerciseSheet` with name and sets/reps fields only.
  - Responsive 2-column layout on expanded screens (>= 900 dp): vertical day list on left, details on right.

- **Home Workout Strip (`lib/screens/home/widgets/workout_strip_slot.dart`)**:
  - Restyled as `AppCard` with `Today: {splitTitle}`, `3 / 5` chip, slim progress bar, and compact checkable rows synchronized via shared `workoutExercisesProvider`.
  - Empty state with text button that navigates directly to the Workout tab via `mainNavIndexProvider`.
  - Rest days display split title and rest message cleanly.

- **Main Navigation Shell (`lib/screens/main_shell.dart`)**:
  - Added `MainNavIndexNotifier` and `mainNavIndexProvider` allowing cross-tab programmatic navigation from Home cards to destination tabs.

- **Automated Guard & Test Metrics**:
  - `test/guards/no_hardcoded_colors_test.dart`: **PASSED** (0 hardcoded colors).
  - `test/guards/dark_surfaces_test.dart`: **PASSED** (all dark surfaces and WCAG contrast verified).
  - `test/expenses_workout_polish_test.dart`: **16/16 PASSED** (tone thresholds, caption formatting, day grouping, swipe delete & savings undo, workout progress & single achievement trigger, 360 dp form isolation, and responsive layouts at 360x640, 800x1000, 1280x800 with text scale 1.3).
  - `test/expenses_widget_test.dart`: **7/7 PASSED**.
  - `test/workout_widget_test.dart`: **8/8 PASSED**.
  - `test/navigation_shell_test.dart`: **6/6 PASSED**.
  - Total test suite: **241 unit, widget, and guard tests** passing across the codebase with 0 failures.
  - `flutter analyze`: **0 issues found** (clean).

---

### 2. Polish Stage 5 Summary: Habits (Playful Redesign)

- **Database Migration (`supabase/migrations/004_habit_icon.sql`)**:
  - Idempotent migration: `alter table public.habits add column if not exists icon text not null default 'check_circle';`.
  - Runs multiple times safely without errors.

- **Habit Icons Catalog (`lib/core/constants/habit_icons.dart`)**:
  - 24 curated Material icon keys: `check_circle`, `fitness_center`, `menu_book`, `water_drop`, `self_improvement`, `code`, `bedtime`, `directions_run`, `restaurant`, `school`, `edit_note`, `savings`, `music_note`, `brush`, `language`, `spa`, `directions_bike`, `wb_sunny`, `no_food`, `phone_disabled`, `timer`, `favorite`, `psychology`, `cleaning_services`.
  - Automatic fallback to `check_circle` for any unknown key.
  - Exposes `allKeys` for consistent UI enumeration.

- **Add & Edit Habit Sheet (`lib/screens/habits/widgets/add_habit_sheet.dart`)**:
  - Contextual sheet for creating a new habit or editing an existing habit.
  - Strict field isolation: contains ONLY the title field and the 24-icon picker grid.
  - Icon picker items feature tap bounce animation (`PressableScale`), `palette.accentSoft` background, and `palette.accent` border when selected.
  - Form preserves keys `add_habit_title_field` and `create_habit_button`.

- **Habit Cards (`lib/screens/habits/widgets/habit_card.dart`)**:
  - Built with `AppCard` (radius 16, border).
  - 44dp leading icon in `palette.accentSoft` rounded square with bounce (6dp up and back) and tilt (0.08 rad) animation on today tick.
  - Title (max 2 lines) with mini 7-day strip ending today (12dp boxes, pre-creation days subtle, done in accent, missed outlined, today accented).
  - Streak chip with flame icon, tabular figures, and roll-up transition.
  - **Milestone Detection (7, 30, 100 days)**: Fires strictly on user-initiated tick transition; flame chip scales up playfully (`_pulseScale`), and an inline `X-day streak!` badge appears for 4s and fades out. Never replays on rebuild or relaunch.
  - Trailing 32dp playful `AnimatedCheckbox` with radiating dots painter (6-8 accent dots fading over 450ms).
  - Quiet snappy reversal on un-ticking (no dots).
  - Long-press and desktop options menu for edit and delete (`delete_habit_${habit.id}`).

- **Monthly Heatmap (`lib/screens/habits/widgets/monthly_heatmap.dart`)**:
  - Replaces the old horizontal-scrolling matrix completely with a calendar-style Mon–Sun grid (zero horizontal scroll).
  - Month navigation with limits: bounded between the earliest habit creation month and the current month.
  - Filter chips `All Habits | <habit items>` with smooth crossfade of cell colors.
  - 5 intensity tiers: none (outline), 1–33% (25% accent), 34–66% (50% accent), 67–99% (75% accent), 100% (solid accent with `onAccent` text).
  - Today cell highlighted with accent ring; future cells dim and inert.
  - Tapping past or today cells opens `DayLogSheet` to correct forgotten logs with instant state update.
  - Cell entrance staggered via `FadeSlideIn`.
  - Legend row below grid (`Less ▢▢▢▢▢ More`).

- **Monthly Reality Report Card (`lib/screens/habits/widgets/monthly_reality_report_card.dart`)**:
  - 3 `StatChip` cards: Completions (check), Missed days (calendar-x), Rebounds (trending-up).
  - Tabular figure count-up animations via `CountUpText` (400ms duration).
  - Rule-based neutral summary text below (e.g. `You bounced back 3 times this month.`).

- **Weekly Report Tab (`lib/screens/habits/widgets/weekly_report_tab.dart`)**:
  - Mon–Sun week navigator bounded against the future.
  - **Summary Hero Card**: 120dp completion ring custom painter, count-up percentage, `X of Y check-ins`, `Perfect days: N`, and week-over-week comparison chip.
  - **Daily Bars**: 7 vertical bars Mon–Sun with weekday letters, today highlighted, future days as faint empty slots, and best day accent dot.
  - **Insight Chips**: `Best day: Tue`, `Weakest day: Fri` (hidden if < 3 eligible days), `Longest streak: <Habit> Zd`.
  - **Per-Habit Cards**: Icon, name, completion ring, 7-cell Mon–Sun strip, stats row (`Missed`, `Rebounds`, `Streak`), and 6-week trend sparkline custom painter.

- **Responsive Layout**:
  - Compact (< 600 dp): single column, zero overflow at text scale 1.3.
  - Medium (600–899 dp): single column with wider margins, heatmap cells cap at 44dp.
  - Expanded (>= 900 dp): 2 columns (Overview: cards left, heatmap + reality right; Weekly report: hero + bars + insights left, per-habit cards right).

- **Testing & Verification**:
  - `flutter analyze`: **0 issues found**.
  - Full test suite: **225 tests passing across 22 test files** (including 11 new tests in `test/habits_polish_test.dart` and all existing unit/widget/guard tests).
  - Guard tests verified: zero hardcoded colors, dark surfaces verified, WCAG contrast compliant.

---

- **Flutter Multi-platform Architecture**:
  - Configured for Android (`io.anchor.app`, singleTask launchMode, deep link intent filters, exact alarms & boot receiver, open_filex FileProvider), Windows Desktop ("Anchor" window and binary name, `io.anchor.app` custom protocol handler, single-instance forwarding via Win32 messages), and Web preview.
  - Complete, end-to-end dark theme foundation in `lib/core/constants/theme.dart`: `AppPalette` (`ThemeExtension<AppPalette>`) with 22 tokens (`background`, `card`, `cardRaised`, `border`, `textPrimary`, `textSecondary`, `textMuted`, `accent`, `accentSoft`, `onAccent`, `selectedFill`, `onSelected`, `disabledForeground`, `disabledFill`, `scrim`, `success`, `successSoft`, `warning`, `warningSoft`, `danger`, `dangerSoft`, `onDanger`).
  - Strict mathematical WCAG AA contrast ratio compliance ($\ge 4.5:1$ for body text and `onAccent` against all 7 accents in both brightness modes; $\ge 7:1$ for primary text on backgrounds and cards).
  - 7 user-selectable accents: `iris`, `jade`, `ember`, `saffron`, `rose`, `lagoon`, `plum`.
  - Android splash and launch backgrounds (`launch_background.xml`, `values/colors.xml`, `values-night/colors.xml`) eliminating white launch flash in dark mode.
  - Windows Desktop titlebar and background sync via `window_manager` in `ThemeController.updateDesktopWindow`.
  - Offline bundled font: official Inter font family (`Inter-Regular`, `Inter-Medium`, `Inter-SemiBold`) under `assets/fonts/` with tabular figures support for all numeric data displays.
  - Responsive layout framework: `Breakpoints` and `SizeClass` (compact < 600 dp, medium 600–899 dp, expanded >= 900 dp). Centered `PageContainer` (max width 1100 dp, horizontal padding 16 / 24 / 32 dp).
  - Adaptive root navigation in `MainShell`: compact (< 600 dp) uses bottom `NavigationBar`; medium (600–899 dp) uses compact `NavigationRail`; expanded (>= 900 dp) uses extended `NavigationRail` with "Anchor" header.
  - Desktop window constraints: minimum window size 360 x 600 via `window_manager`, text scale clamped to 0.85–1.3.
  - Motion kit: `Motion` tokens (`snap`, `base`, `moment`, `playful`), reduced-motion guard, and Android-guarded haptics.
  - Centralized lifecycle observer in `MainShell`: runs rollover engine, past exam cleanup, monthly expense reset, and data refreshes on launch and resume without racing.

- **One-Shot End-to-End Dark Mode Sweep**:
  - **Zero Hardcoded Colors**: Verified by automated test guard `test/guards/no_hardcoded_colors_test.dart` that 100% of `.dart` files outside `theme.dart` have zero hardcoded colors (`Color(0x...)`, `Color.fromARGB`, `Color.fromRGBO`, `Colors.<except transparent>`, legacy `AppColors`, or `ThemeData.light/dark`).
  - **Zero Ad-hoc Brightness Checks**: No `if (isDark)` branches outside `theme.dart`. All styling flows strictly from `context.palette` and Material 3 component themes.
  - **Scaffold Leaks Sealed**: All screens (Auth, Home, Academics, Expenses, Habits, Workout) omit `backgroundColor` or use theme inheritance, eliminating pure white page backgrounds in dark mode.
  - **Card & Surface Hierarchy**: All cards render `palette.card` (`#17171A`), raised surfaces/sheets render `palette.cardRaised` (`#1E1E22`), and background renders `#0E0E10`.
  - **Segmented Controls & Chips**: Unified across Academics, Expenses, Habits, and Workout. Track is `palette.card`, border `palette.border`. Selected segment is `palette.selectedFill` (`palette.accent` in dark mode, `#111111` in light mode) with legible `palette.onSelected` text.
  - **Dialogs & Bottom Sheets**: All modal sheets and alert dialogs inherit dark surface background, hairline borders, and correct primary/secondary text hierarchy.
  - **Loading Spinners**: All `CircularProgressIndicator` instances use `palette.accent` or `palette.onAccent`, completely eliminating dark/black dots on dark backgrounds.
  - **Double Plus Sign Regression Fixed**: Cleaned button text and action chips across the entire app so `Icon(Icons.add)` is paired only with text (e.g. `Subject`, `Log Transaction`, `New Habit`, `Add Exercise`), never with redundant `+` in both icon and label.
  - **100% Light Mode Fidelity**: All light mode values and appearances remain completely untouched. Light mode golden visual output is 100% identical.

- **Automated Guard Tests**:
  - `test/guards/no_hardcoded_colors_test.dart`: Scans entire `lib/` directory recursively and asserts zero color violations.
  - `test/guards/dark_surfaces_test.dart`: Pumps Home, Academics (3 segments), Expenses (2 tabs + sheet), Habits (2 tabs + sheet), Workout (+ sheet), ProfileMenu in dark mode, asserting surface luminance $< 0.1$, contrast $\ge 4.5:1$, and smooth live theme switching between light, dark, and custom accents.
  - Test suite: **196 unit, widget, and guard tests** passing cleanly with 0 failures and 0 analyzer warnings.

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

### 3. Polish Stage 1 Deliverables (Theme Engine, Motion Kit, Responsive Foundation)

#### Files Added & Created
- `lib/core/constants/dimens.dart`: 4-point spacing scale (`space4`..`space48`), radii (`radiusSm` 8, `radiusMd` 12, `radiusLg` 16, `radiusXl` 20), hairlines, touch targets (44 dp).
- `lib/core/constants/motion.dart`: Motion tokens (`snap` 150ms, `base` 250ms, `moment` 400ms, `playful` 450ms; `standard`, `emphasized` curves; `Motion.duration` respecting reduced motion).
- `lib/core/utils/haptics.dart`: Safe Android-only haptic feedback (`light()`, `success()`).
- `lib/core/utils/responsive.dart`: Material 3 `SizeClass` (compact < 600 dp, medium 600-899 dp, expanded >= 900 dp), `Breakpoints` helpers.
- `lib/widgets/motion/pressable_scale.dart`: Micro-interaction scaling tap feedback (0.97 in 100ms).
- `lib/widgets/motion/animated_checkbox.dart`: Custom animated checkbox with fill expansion and check stroke draw-in.
- `lib/widgets/motion/animated_progress_bar.dart`: Slim progress bar with animated value transitions in `Motion.base`.
- `lib/widgets/motion/count_up_text.dart`: Number animation with tabular figures support.
- `lib/widgets/motion/fade_slide_in.dart`: Fade + 8 dp slide up entrance animation for cards and staggered list items.
- `lib/widgets/motion/pulse_ring.dart`: One-shot soft accent ring pulse for achievement moments.
- `lib/widgets/motion/collapse_on_remove.dart`: Smooth size + fade collapsing on list item removal.
- `lib/widgets/responsive/page_container.dart`: Centers page content with max width (1100 dp) and size-class responsive padding.
- `lib/widgets/responsive/responsive_builder.dart`: Builder providing current `SizeClass`.
- `lib/widgets/responsive/adaptive_columns.dart`: 1-column layout on compact/medium and multi-column on expanded.
- `lib/widgets/responsive/adaptive_grid.dart`: Adaptive grid using `SliverGridDelegateWithMaxCrossAxisExtent`.
- `lib/widgets/responsive/adaptive_sheet.dart`: `showAdaptiveSheet()` (bottom sheet on compact, centered modal dialog on desktop/tablet).
- `lib/widgets/app_card.dart`: Polished card container (`palette.card`, hairline `palette.border`, radius 12).
- `lib/widgets/section_header.dart`: Section header with title, optional count badge, and optional trailing action.
- `lib/widgets/tag.dart`: Small pill badge for categories, subjects, or status chips.
- `lib/widgets/stat_chip.dart`: Compact metric card displaying icon, prominent tabular value, and label.
- `lib/widgets/skeleton_box.dart`: Subtle pulsing shimmer placeholder for loading states.
- `assets/fonts/Inter-Regular.ttf`, `Inter-Medium.ttf`, `Inter-SemiBold.ttf`: Offline bundled font assets.
- `test/theme_unit_test.dart`: Contrast engine tests, lerp interpolation test, theme persistence test, responsive breakpoint classification tests.
- `test/motion_widgets_test.dart`: Widget tests for all motion kit components and shared polished widgets.

#### Files Modified
- `pubspec.yaml`: Added `shared_preferences: ^2.5.6`, `window_manager: ^0.4.3`, and bundled `Inter` fonts.
- `lib/core/constants/theme.dart`: Full token theme engine (`AppPalette`, `AppAccent` with 7 accents, `ContrastHelper`, `buildTheme`, `ThemeController`).
- `lib/widgets/empty_state.dart`: Restyled with `accentSoft` circle, `palette.accent` icon, sentence-case copy.
- `lib/widgets/error_state.dart`: Restyled with `palette.dangerSoft` circle and tokens.
- `lib/widgets/loading_state.dart`: Restyled with `palette.accent` indicator and tokens.
- `lib/screens/main_shell.dart`: Responsive navigation across compact, medium, and expanded size classes.
- `lib/main.dart`: Desktop minimum window size (360 x 600), theme preloading, dynamic `ThemeController` binding, text scale clamp (0.85–1.3).
- `test/navigation_shell_test.dart`: Updated to assert compact (`NavigationBar`), medium (`NavigationRail`), and expanded (`NavigationRail` extended with 'Anchor' title).

---

### 4. Polish Stage 2 Deliverables (Profile Menu & Theme Picker)

#### Files Added & Created
- `lib/widgets/profile/profile_avatar.dart`: 36 dp / 48 dp circular profile avatar with network image caching, loading and error fallbacks, and uppercase initials badge on `palette.accentSoft` background.
- `lib/widgets/profile/profile_menu.dart`: Adaptive profile sheet (bottom sheet on compact < 600 dp; anchored popover width 340 on medium/expanded >= 600 dp). Includes:
  - Header: 48 dp avatar, display name, email.
  - Appearance section: 3-way SegmentedButton (`Light | Dark | System`) with icons, live crossfade lerp, and "Follows your device" caption.
  - Accent color section: 7-accent swatch circles (Iris, Jade, Ember, Saffron, Rose, Lagoon, Plum) with 2.5px ring and contrast-checked checkmark.
  - Live preview strip: 70% progress bar, completed task item, and streak chip.
  - Sign out row with confirmation dialog ("Sign out of Anchor?" with Cancel and Sign out).
  - Version footer: package version via `package_info_plus`.
- `test/profile_menu_test.dart`: 9 tests covering avatar initial fallback, display name extraction, appearance mode toggling, accent swatch selection, sign out confirmation, and 360x640 + 1280x800 responsive overflow checks.

#### Files Modified
- `lib/core/constants/theme.dart`: Default mode set to `ThemeMode.light` (clean, calm wireframe appearance by default; no unintended dark mode switch). Added `_syncToCloud` and `syncFromCloudOnSignIn` for best-effort Supabase user metadata synchronization (`theme_mode`, `theme_accent`).
- `lib/screens/home/home_screen.dart`: Removed "+" button and 3-dot kebab menu from AppBar actions. Added `ProfileAvatar(size: 36, onTap: () => ProfileMenu.show(context))` next to refresh button. Refactored all container and text colors to use `context.palette` tokens.
- `lib/screens/home/widgets/todo_item_row.dart`: Refactored all colors to `palette.card`, `palette.border`, `palette.textPrimary`, `palette.textSecondary`.
- `lib/screens/home/widgets/kill_idle_widget.dart`: Themed unlocked button with `palette.accent` and `palette.onAccent`; themed locked card with `palette.card` and `palette.textSecondary`.
- `lib/screens/home/widgets/kill_idle_dialog.dart`: Refactored background, timer, challenge card, and manage prompt pool sheet to `context.palette`.
- `lib/screens/home/widgets/add_todo_sheet.dart`: Refactored background to `palette.cardRaised`, target date chips to `palette.accent`/`palette.border`, and submit indicator to `palette.onAccent`.
- `lib/screens/home/widgets/academic_radar_slot.dart`: Refactored radar container to `palette.card`, rows to `palette.background`, chips to `palette.cardRaised`, texts to `palette.textPrimary`/`textSecondary`.
- `lib/screens/home/widgets/workout_strip_slot.dart`: Refactored container to `palette.card`, checkboxes to `palette.accent` and `palette.onAccent`, and strike-through text to `palette.textSecondary`.
- `pubspec.yaml`: Added `package_info_plus: ^10.2.2`.

---

### 5. Verification Summary
- `flutter analyze`: **0 issues found** (clean).
- `flutter test`: **All 186 tests passed** across the entire test suite (158 existing + 19 Stage 1 + 9 Stage 2).
- Security: All tables protected by Postgres RLS, Storage path-scoped, `--dart-define` key injection.
- Zero Git Push: No changes pushed to git (per explicit user instruction).

---

### 6. Polish Stage 3: Complete Dark Mode One-Shot Fix

#### Step A: Systematic Root Cause Diagnosis Matrix

| Screen / Component | File & Line | Symptom in Dark Mode | Root Cause | Systemic Fix |
|---|---|---|---|---|
| **Expenses Screen** | `lib/screens/expenses/expenses_screen.dart:51` | Body is stark white | Hardcoded `backgroundColor: AppColors.background` (`#FFFFFF`) on `Scaffold` | Remove explicit `backgroundColor` so it inherits themed `ThemeData.scaffoldBackgroundColor` (`#0E0E10`) |
| **Habits Screen** | `lib/screens/habits/habits_screen.dart:29` | Body is stark white | Hardcoded `backgroundColor: AppColors.background` on `Scaffold` | Remove explicit `backgroundColor` so it inherits themed `scaffoldBackgroundColor` |
| **Workout Screen** | `lib/screens/workout/workout_screen.dart:50` | Body is stark white | Hardcoded `backgroundColor: AppColors.background` on `Scaffold` | Remove explicit `backgroundColor` so it inherits themed `scaffoldBackgroundColor` |
| **Academics Screen** | `lib/screens/academics/academics_screen.dart:89` | Body / sheets white | Hardcoded `backgroundColor: AppColors.background` on `Scaffold` | Remove explicit `backgroundColor` so it inherits themed `scaffoldBackgroundColor` |
| **Academics Chips** | `lib/screens/academics/academics_screen.dart:225` | Unselected subject chips invisible; add subject chip text faint | ActionChip / ChoiceChip styles using `AppColors.primaryText` (`#111111`) and missing dark `ChipThemeData` | Map `ChipThemeData` in `buildTheme` for dark mode with `palette.card` surface, `palette.border`, and `palette.textPrimary`/`textSecondary` labels |
| **Academics Module Cards** | `lib/screens/academics/widgets/syllabus_tab.dart:180` | Module cards remain white with dark text; 3-dot menu faint | Cards use default container or `AppColors.surface` (`#F4F4F5`); `CardThemeData` not fully mapped for dark | Replace with `palette.card`, `palette.border`, and ensure `CardThemeData` maps `surfaceContainer` |
| **Expenses Metric Cards** | `lib/screens/expenses/widgets/expense_metrics_header.dart` | 4 metric cards remain light with low contrast | Hardcoded `AppColors.surface` / `AppColors.background` containers | Use `palette.card`, `palette.border`, `palette.textPrimary`, `palette.textSecondary` |
| **Segmented Controls** | Academics, Expenses, Habits, Workout | Segmented controls have light gray tracks, black selected pills, faint unselected text | Custom button styles or default `SegmentedButtonThemeData` using M3 seed colors | Unify in `buildTheme`: in dark mode, selected = `palette.accent` fill with `palette.onAccent` text; unselected track = `palette.card` with `palette.border` hairline; unselected text = `palette.textSecondary` |
| **Month / Day Selectors** | Expenses & Workout | Light gray track with black selected pill, faint arrows | Explicit `AppColors.surface` containers and hardcoded text/icon colors | Refactor to use `palette.card`, `palette.border`, `palette.textPrimary`, `palette.textSecondary`, with selected day = `palette.accent` / `palette.onAccent` |
| **Habits App Bar Action** | `lib/screens/habits/habits_screen.dart:40` | `+ New Habit` outlined button invisible (dark-on-dark) | `OutlinedButton.styleFrom(foregroundColor: AppColors.primaryText)` | In `OutlinedButtonThemeData`, set dark border to `palette.border` (or `palette.accent`) and foreground to `palette.textPrimary` |
| **Habits Loading Spinner** | `lib/screens/habits/widgets/habits_overview_tab.dart` | Loading indicator is a tiny black dot on white | `CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryText))` | Map `ProgressIndicatorThemeData(color: palette.accent, linearTrackColor: palette.border, circularTrackColor: palette.border)` |
| **Workout Split Card** | `lib/screens/workout/workout_screen.dart` | Split card is light gray | Container color set to `AppColors.surface` | Change to `palette.card` and `palette.border` |
| **Workout Empty State & Outlined Button** | `lib/screens/workout/workout_screen.dart:421` | Empty-state title near-white on white; `Add Exercise` button faint | `EmptyState` and `OutlinedButton` inheriting incomplete M3 dark surface roles | Complete M3 `ColorScheme` in `buildTheme` + `palette` tokens |
| **Bottom Sheets & Dialogs** | All modal sheets & dialogs | Surfaces white in dark mode | Hardcoded `backgroundColor: AppColors.background` | Use `palette.cardRaised` (`#1E1E22`), `BottomSheetThemeData`, and `DialogThemeData` |
| **Double Plus Sign Regression** | `add_transaction_sheet.dart:273` | Button text contains redundant `+` (`+ Move to Savings` / `+ Log Transaction`) | Inconsistent button label format | Change label to clean `'Move to Savings'` and `'Log Transaction'` without leading `+` |

---

### 7. Polish Stage 3: Home Complete

#### Implementation Details
- **Layout & Responsiveness**:
  - Compact / Medium (< 900 dp): Single column inside centered `PageContainer` (Header, Kill Idle Time area, Today's Tasks card, Tomorrow section, Academic Radar, Workout strip).
  - Expanded (>= 900 dp): Responsive two-column layout with left column flex 3 (Header, Kill Idle, Today's Tasks, Tomorrow) and right column flex 2 (Academic Radar, Workout strip).
  - Header block: Local time greeting ("Good morning / afternoon / evening") with localized date in secondary text ("Saturday, 14 Nov").
- **Duplicate Add Controls Removed**:
  - Removed top "+" AppBar action button and "Add Task" link button.
  - Home features strictly a single inline input (`home_quick_add_input`) with accent submit button and date chip selector (Today / Tomorrow / Pick date), plus the small `+` in the Tomorrow section (`tomorrow_add_button`).
- **Today's Tasks Card with Clockwise Progress Stroke**:
  - Custom `CardProgressStrokePainter` tracing rounded rectangle clockwise from top-left, animated with `TweenAnimationBuilder` (`Motion.moment`, `Curves.easeOutCubic`) in both directions.
  - Count chip morphs dynamically from `3/5` to `All done` with check icon at 100% via `AnimatedSwitcher`.
  - Achievement moment: Soft `PulseRing` accent pulse and `Haptics.success()` trigger strictly on transition into "all done" (guarded against re-firing on subsequent rebuilds or initial launch).
- **Task Rows**:
  - Custom `AnimatedCheckbox` paired with accessible standard Semantics.
  - Animated strike-through text (200 ms).
  - Rollover count displayed as warning-soft `Tag` with repeat icon.
  - Desktop hover visibility for trailing delete action (`MouseRegion`), persistent on touch devices.
  - Delete with `CollapseOnRemove` animation and 4-second Undo snackbar (`restoreTodo`).
- **Tomorrow Section**:
  - Collapsible `AppCard`-styled section with count chip and expansion chevron.
  - Small `+` button revealing inline input for tomorrow (`tomorrow_quick_add_input`).
- **Kill Idle Time Area & Focus Challenge Dialog**:
  - Locked state renders clean muted status row with lock icon and `AnimatedProgressBar`.
  - Unlocked state renders active accent button with `PulseRing`.
  - Transitions cleanly via `AnimatedSwitcher` without retaining inactive widgets in the tree.
  - Prompt seeding race guard: Single in-flight future lock in `IdlePromptsNotifier` with `002_idle_prompts_unique.sql` unique constraint on `(user_id, prompt_text)`.
  - Redesigned focus dialog/sheet with circular 15:00 countdown timer ring (`_TimerRingPainter`), tabular figures, Start/Pause/Reset controls, completion celebration, shuffle cross-fade, and pool manager with undo.
- **Automated Guard & Test Metrics**:
  - `test/guards/no_hardcoded_colors_test.dart`: **PASSED** (0 hardcoded colors).
  - `test/guards/dark_surfaces_test.dart`: **PASSED** (all surfaces and sheets dark-mode compliant).
  - `test/home_polish_test.dart`: **7/7 PASSED** (stroke math, prompt seeding guard, count chip morphing, achievement moment, responsive layouts).
  - Total test suite: **203 unit, widget, and guard tests** passing across 20 test files.
  - `flutter analyze`: **0 issues found** (clean).

---

### 8. Polish Stage 4: Academics (+ Home Radar) Complete

#### Implementation Details
- **Database Migration & Models**:
  - `supabase/migrations/003_chapter_studied.sql`: Added `is_studied boolean not null default false` with idempotent `if not exists` check.
  - `lib/models/chapter.dart`: Updated `Chapter` model with `isStudied` field, JSON serialization, `copyWith`, and value equality.
- **Provider Infrastructure (`lib/providers/academics_providers.dart`)**:
  - Added `ChaptersNotifier.toggleStudied(chapterId)`: Optimistic toggle of chapter studied status with rollback on failure.
  - Added `AcademicItemsNotifier.markExamCompleted(id)`: Sets `is_completed = true` in Supabase and cancels active notification reminders.
  - Added `AcademicItemsNotifier.editItem(...)` and `AcademicItemsNotifier.restoreItem(...)`: Handles assignment editing and undo restores with automated notification cancellation/rescheduling.
  - Updated `sortExams` and `filterUrgentExams`: Completed exams are strictly excluded (`!i.isCompleted`) while remaining in the database until automated daily cleanup.
  - Added `chapterFileCountProvider(chapterId)`: Reactive lookup of file attachments per chapter.
  - Added `SubjectSyllabusStats` & `subjectSyllabusStatsProvider(subjectId)`: Computes overall studied percentage and module/chapter counts (safe against division by zero).
  - Added `ModuleSyllabusStats` & `moduleSyllabusStatsProvider(moduleId)`: Computes per-module progress and studied counts.
  - Added `subjectPendingAssignmentsCountProvider(subjectId)`: Reactive count of incomplete assignments for subject chip badges.
  - Added `AssignmentGroup` and `groupAssignments(items, today)`: Partitions coursework into Overdue, Due today, This week, Later, and Completed groups.
- **New Shared Widgets (`lib/widgets/academics/`)**:
  - `urgency_tone.dart`: `UrgencyTone` enum (overdue: danger, soon: warning, normal: accent) with soft background, border, and foreground tokens.
  - `countdown_pill.dart`: `CountdownPill` rendering `Today`, `1d`, `2d`, or `Overdue Xd` with tabular figures and urgency coloring.
  - `deadline_bar.dart`: `DeadlineBar` 4dp thin proximity bar animated with `TweenAnimationBuilder` (1.0 at 0 or overdue, 0.5 at 7 days, 0.0 at 14+ days).
  - `assignment_tile.dart`: `AssignmentTile` featuring `AnimatedCheckbox`, strikethrough text, subject `Tag`, `CountdownPill`, `DeadlineBar`, `EditAssignmentSheet`, desktop hover, and undoable delete (`CollapseOnRemove` + 4-second Undo snackbar).
  - `exam_countdown_tile.dart`: `ExamCountdownTile` with large tabular days remaining counter, exam-day accent border, and "Mark as done" achievement flow (checkmark draw-in, `PulseRing`, `Haptics.success()`, 300ms slide/collapse dismissal).
  - `chapter_row.dart`: `ChapterRow` featuring `AnimatedCheckbox` studied toggle, file count badge (`paperclip` + count), title dimming without strikethrough when studied, and vault sheet opener.
  - `edit_assignment_sheet.dart`: Adaptive bottom sheet for editing assignment title, subject, and due date with notification rescheduling.
- **Academics Screen & Tabs**:
  - `AcademicsScreen`: Centered `PageContainer`, 200ms segment fade-through, horizontal subject chips with pending assignment count badges, and restyled accent text-button add controls.
  - `AssignmentsTab`: Grouped into collapsible sections (**Overdue**, **Due today**, **This week**, **Later**, and collapsed **Completed**), count chips, and 2-column wide layout on expanded (>= 900 dp).
  - `ExamsTab`: Strict `due_date ASC` countdown list, exam-day completion, and 2-column wide layout on expanded (>= 900 dp).
  - `SyllabusTab`: Subject header card with overall studied % progress bar, module `AppCard` expansion sections with progress bars and session expansion memory, module completion bar pulse, two-pane layout on expanded (>= 900 dp).
- **Home Radar Restyle**:
  - Restyled `AcademicRadarSlot` using compact `AssignmentTile` (incomplete, next 7 days) and compact `ExamCountdownTile` (incomplete, next 14 days with exam-day "Mark as done" flow).
  - "Academic Radar" header with count chip and "All clear." empty state.
- **Automated Guard & Test Metrics**:
  - `test/guards/no_hardcoded_colors_test.dart`: **PASSED** (0 hardcoded colors).
  - `test/guards/dark_surfaces_test.dart`: **PASSED** (all dark surfaces and WCAG contrast verified).
  - `test/academics_polish_test.dart`: **11/11 PASSED** (urgency thresholds, pill labels, deadline fill fractions, assignment grouping, exam completion & filtering, studied math & rollback, responsive layouts at 360x640, 800x1000, 1280x800 with text scale 1.3).
  - Total test suite: **214 unit, widget, and guard tests** passing across 21 test files with 0 failures.
  - `flutter analyze`: **0 issues found** (clean).



