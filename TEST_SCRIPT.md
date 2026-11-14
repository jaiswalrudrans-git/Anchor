# Anchor - End-to-End Manual Test Script

This document provides a numbered, end-to-end verification checklist to test Anchor on both Android and Windows Desktop.

---

## 1. Authentication & OAuth Sign-In

- [ ] **1.1 Missing Config Diagnostic Screen**
  - Run `flutter run` without `--dart-define` flags.
  - Verify that the app renders a clean monochrome diagnostic screen listing missing environment variables without crashing.
- [ ] **1.2 Google OAuth Login (Android)**
  - Launch app with `--dart-define` flags.
  - Tap "Continue with Google".
  - Chrome opens for Google login. Select account.
  - App resumes via deep link (`io.anchor.app://login-callback`) directly into the Main Shell (`Home` tab).
- [ ] **1.3 Google OAuth Login (Windows Desktop)**
  - Launch app with `--dart-define` flags.
  - Tap "Continue with Google".
  - Browser opens. Select Google account.
  - Custom protocol callback activates running Windows instance (single-instance forwarding) without opening duplicate windows.
- [ ] **1.4 Sign Out**
  - Tap the three-dot overflow menu in AppBar -> "Sign out".
  - Confirmation dialog appears. Tap "Sign out".
  - Returns to AuthScreen.

---

## 2. Main Shell & Navigation

- [ ] **2.1 Mobile Floating Dock Navigation (< 600 dp)**
  - On a mobile viewport, verify the floating pill-shaped dock pinned at the bottom (`12 dp + safe-area bottom offset`) with 4 destinations in exact order: **Home | Academics | Expenses | Habits**.
  - Verify the **selected destination** pops out into a 56 dp bubble centered 14 dp above the dock's top edge, sitting in a smooth concave notch with Bezier shoulders, displaying an accent ring, soft accent fill, and filled icon.
  - Verify a 4 dp gap of the scaffold background between the bubble and notch edge.
  - Tap another destination: verify the bubble and notch **glide smoothly across** (320 ms) with midpoint icon cross-fade and an arrival pop (tiny lift & settle).
  - Verify the **Quick Add "+" button** is a separate 60 dp circular button floating beside the dock (`12 dp gap`), with key `quick_add_button`. It never moves when tabs change, and its icon rotates 45° while the Quick Add sheet is open.
  - Verify zero `BottomAppBar` and zero `FloatingActionButton` exist in the shell.
  - Focus an input (open on-screen keyboard): verify the dock and plus button slide down out of view (200 ms) and return when closed.
  - On short screens / landscape phones (height < 480 dp): verify dock shrinks to 56 dp, bubble to 48 dp, and inactive labels are hidden.
- [ ] **2.2 Desktop & Tablet Floating Navigation Rail (>= 600 dp)**
  - On medium (600–899 dp) and expanded (>= 900 dp) viewports, verify left floating rail panel (radius 28, card raised surface, 1 px border, inset 12 dp from window edge, vertically centered).
  - Verify 4 destinations stacked vertically with a vertically sliding round bubble.
  - Leading item holds the Quick Add button (key `quick_add_button`): 60 dp circle on medium, extended 'Add' pill on expanded.
  - Verify Windows keyboard navigation: Up/Down arrows move focus, Enter/Space activates destination, visible focus ring.
  - Verify `Ctrl+N` opens the Quick Add modal; `Esc` dismisses it.
  - Verify state preservation across tab switching (`IndexedStack`).

---

## 3. Home Screen: To-Dos, Rollover & Kill Idle Time

- [ ] **3.1 Inline Quick-Add Task**
  - In the quick-add input at the top of Home, type "Read Chapter 3" and press Enter or the arrow icon.
  - Verify task appears immediately in today's task list.
- [ ] **3.2 Modal Add Task (`+ Add Task`)**
  - Tap `+ Add Task` header button.
  - `AddTodoSheet` opens containing **only** title and date selector (Today / Tomorrow / Pick Date).
  - Add a task for Tomorrow: "Physics Homework". Verify it appears in the collapsible Tomorrow section.
- [ ] **3.3 Task Completion & Sorting**
  - Tap the checkbox of a task.
  - Verify strikethrough styling and that completed tasks sink to the bottom.
- [ ] **3.4 Reschedule Task**
  - Tap the calendar icon on an uncompleted task. Pick tomorrow.
  - Verify task moves to the Tomorrow section.
- [ ] **3.5 Rollover Engine Simulation**
  - In Supabase Table Editor (`todos`), find an uncompleted task and change its `scheduled_date` to yesterday's date (`YYYY-MM-DD`).
  - In Anchor, tap the Refresh button (or restart app / minimize and resume).
  - Verify task's `scheduled_date` automatically rolls over to today, and the badge `Rolled over 1x` appears.
- [ ] **3.6 Kill Idle Time Focus Challenge**
  - With pending tasks in today's list: banner displays "Plan today's tasks first" or "X tasks remaining". Kill Idle button is locked.
  - Complete all tasks scheduled for today.
  - Banner unlocks with active "Kill Idle Time" button.
  - Tap "Kill Idle Time": challenge dialog displays a random prompt from the pool.
  - Focus countdown timer begins (15:00). Tap "Shuffle Another" to switch challenge.
  - Manage pool: add a custom challenge prompt and delete one.

---

## 4. Academics: Syllabus Tree & Chapter File Vault

- [ ] **4.1 Subject Management**
  - Switch to Academics tab -> Syllabus segment.
  - Tap `+ Subject` chip. Enter "Data Structures". Tap Save.
  - Verify new subject chip is selected.
  - Long press subject chip: rename or delete dialogs work with cascading confirmation.
- [ ] **4.2 Modules & Chapters**
  - Tap `+ Add Module`. Enter "Binary Trees". Save.
  - Expand module, tap `+ Add Chapter`. Enter "AVL Trees & Rotations". Save.
- [ ] **4.3 Chapter File Vault (Multi-Platform Storage)**
  - Tap on chapter "AVL Trees & Rotations".
  - `ChapterVaultSheet` opens showing "No files attached yet".
  - Tap `+ Upload File`: file picker opens. Select a PDF or image (`.pdf` or `.png`).
  - File uploads to Supabase private storage `academic_vault/{user_id}/{chapter_id}/...`.
  - Badge shows `Cached Offline`.
  - Tap the file: opens in OS default viewer via `open_filex`.
  - Delete file: confirmation dialog removes it from Supabase storage and local cache.
- [ ] **4.4 Cross-Device Vault Sync**
  - Upload a file on Device A (e.g. Windows).
  - Open chapter on Device B (e.g. Android). File appears with `Cloud Only` badge.
  - Tap file: downloads atomically to local vault cache, status changes to `Cached Offline`, and opens in viewer.

---

## 5. Academics: Assignments, Exams & Notifications

- [ ] **5.1 Assignments Tab**
  - Switch to Assignments tab.
  - Notice subject chips bar is hidden (scoped strictly to Syllabus).
  - Tap `+ Add Assignment`. Form opens with title, subject dropdown, due date.
  - Enter "DSA Assignment 1", due tomorrow. Save.
  - Verify assignment appears in list sorted by `due_date ASC`.
  - Check checkbox: completes assignment, moves to collapsible Completed section.
- [ ] **5.2 Exams Tab**
  - Switch to Exams tab. Tap `+ Add Exam`.
  - Enter "Midterm Exam", due in 5 days. Save.
  - Verify sorted strictly by date (no priority tags, no past section).
- [ ] **5.3 Academic Radar Slot (Home)**
  - Switch to Home tab.
  - Verify `AcademicRadarSlot` displays urgent assignments (next 7 days) and upcoming exams (next 14 days).
  - Checking off an assignment in Radar completes it immediately and removes it from the radar.
- [ ] **5.4 Past Exam Auto-Cleanup Simulation**
  - In Supabase Table Editor (`academic_items`), locate an exam and change its `due_date` to yesterday.
  - In Anchor, tap Refresh or resume app.
  - Verify past exam is automatically and silently deleted from the database.
- [ ] **5.5 Android Scheduled Notifications**
  - Add an assignment due tomorrow. On Android, verify notification is scheduled for 21:00 today.
  - On Windows Desktop, verify operation completes cleanly as a safe no-op without errors.

---

## 6. Expenses: Allowance Ledger, Rollover & History

- [ ] **6.1 Monthly Allowance Setup**
  - Switch to Expenses tab.
  - Tap the edit pencil on "Monthly Allowance". Enter `15000`. Save.
  - Verify 4-metric header updates: Allowance ₹15,000.00, Remaining Balance ₹15,000.00.
- [ ] **6.2 Log Transactions**
  - Tap `+ Log Transaction`.
  - Test 3 transaction types:
    - **Spent**: Title "Groceries", Amount `1200`, Category "Food". Tap Save.
    - **Received**: Title "Tutoring", Amount `2000`, Category "Income". Tap Save.
    - **Saved**: Title "Emergency Fund", Amount `1000`, Category "Savings". Tap Save.
  - Verify:
    - Spent metric increases by ₹1,200.
    - Remaining balance reflects `(Allowance + Received) - (Spent + Saved)`.
    - Savings Locker reflects ₹1,000.
- [ ] **6.3 Monthly Rollover Gap Simulation**
  - In Supabase Table Editor (`expense_settings`), change `last_reset_month` to previous month (e.g. `2026-10` when current month is `2026-11`).
  - In Anchor, open Expenses tab or trigger refresh.
  - Verify:
    - Rollover engine runs multi-month gap traversal.
    - Previous month closes with snapshot in `expense_month_summaries`.
    - Positive remainder carries into `total_savings` (Savings Locker).
    - Current month resets to fresh allowance.
- [ ] **6.4 Expenses History Tab**
  - Tap "History" segment.
  - Verify list of closed months with allowance, spent, saved, and carried to savings.
  - Tap a past month: navigates to that month's read-only ledger. Notice `+ Log Transaction` and delete icons are hidden.

---

## 7. Habits: Daily Matrix, Streaks & Weekly Report

- [ ] **7.1 Add Habit**
  - Switch to Habits tab.
  - Tap `+ New Habit`. Sheet opens containing **only** habit title field.
  - Enter "Drink 3L Water". Tap Create.
- [ ] **7.2 Today Checkbox Toggle & Immediate Streak Update**
  - Tap the circular checkbox on "Drink 3L Water".
  - Box fills solid black with checkmark, streak increases immediately (e.g. `1d streak`).
  - Tap again: unchecks and streak updates.
- [ ] **7.3 Monthly Consistency Matrix Grid**
  - Scroll down to the Monthly Consistency Matrix.
  - Columns represent days 1..daysInMonth.
  - Tap a past day cell: toggles completion to fix forgotten logs.
  - Future day cells are inert.
  - Aggregate row at bottom fills solid when all active habits are done on that day.
- [ ] **7.4 Monthly Reality Report Card**
  - Verify honest metrics: Completions (total logs this month), Streak Breaks (missed days through yesterday), Rebounds (days completed after a miss).
- [ ] **7.5 Weekly Report Tab**
  - Tap "Weekly Report" segment.
  - Week navigator displays `< Week of ... >`.
  - Next button `>` is disabled at current week (cannot navigate into future).
  - Tap `<` to view previous week.
  - Per-habit cards show completions `X / N days`, 7-cell Mon–Sun strip, rebounds, and comparison (`+X vs last week`).
  - Overall weekly summary card shows total completions, best habit, weakest habit.

---

## 8. Global Quick Add & Fast Actions

- [ ] **8.1 Quick Add Sheet & Type Selector**
  - Tap the global Quick Add FAB (or press `Ctrl+N` on desktop).
  - Verify FAB plus icon rotates 90° smoothly (150 ms) while sheet opens.
  - Verify adaptive presentation: bottom sheet on compact (< 600 dp), centered dialog (max width 480 dp) on medium/expanded (>= 600 dp).
  - Header displays "Quick add" and close icon button.
  - Verify 5 type chips: `To-do`, `Assignment`, `Exam`, `Expense`, `Habit`.
- [ ] **8.2 Smart Default Type**
  - Verify default selected chip reflects active context:
    - On Home tab: defaults to `To-do`.
    - On Academics tab (Syllabus or Assignments segment): defaults to `Assignment`.
    - On Academics tab (Exams segment): defaults to `Exam`.
    - On Expenses tab: defaults to `Expense`.
    - On Habits tab: defaults to `Habit`.
- [ ] **8.3 Title Preservation Across Types**
  - Select `To-do` chip, type "Physics Lab Report".
  - Switch chip to `Assignment`: title remains "Physics Lab Report".
  - Switch chip to `Exam`: title remains "Physics Lab Report".
  - Switch chip to `Expense`: title clears appropriately.
- [ ] **8.4 Add Entry, Tab Preservation & Undo**
  - From Quick Add, enter a task "Buy Notebooks" and tap `Done`.
  - Sheet closes; current tab does NOT navigate away.
  - Bottom 4-second Undo SnackBar appears: `Added to to-do` with `Undo` button.
  - Tapping `Undo` immediately deletes the created task and refreshes state.
  - Test similarly for Assignment, Exam, and Expense.
- [ ] **8.5 Habit Checkoff in Quick Add**
  - Select `Habit` type chip.
  - Verify today's active habits list with circular checkboxes and streak count.
  - Verify NO text input field and NO habit creation button exists in Quick Add.
  - Toggle a habit checkbox: checkmark toggles and streak increments live.
  - If no habits exist: empty state displays "No habits yet" with an "Open Habits" button that closes the sheet and switches to the Habits tab.
- [ ] **8.6 Dirty Discard Confirmation Dialog**
  - Type some text into the title field without submitting.
  - Tap the close button (or press `Esc` / Android back button).
  - Confirmation dialog appears: "Discard this entry?".
  - Tap "Keep editing": stays in sheet with input preserved.
  - Tap "Discard": sheet closes and input is discarded.
- [ ] **8.7 Desktop Keyboard Shortcuts**
  - On desktop (Windows), press `Ctrl+N`: Quick Add modal opens immediately.
  - Press `Esc`: Quick Add modal closes (or triggers discard confirmation if dirty).

---

## 9. Final Isolation & Add-Button Audit

- [ ] **9.1 Shell & Page Add Controls Verification**
  - Shell: Exactly ONE global FloatingActionButton (`heroTag: 'quick_add'`) docked at `endDocked` on compact, or as leading item on `NavigationRail`.
  - Home: Inline quick-add bar + header button `+ Add Task` (`AddTodoSheet`). Zero FABs.
  - Academics: Only `AddSubjectDialog`, `AddModuleDialog`, `AddChapterDialog`, `AddAssignmentSheet`, `AddExamSheet`. Zero FABs.
  - Expenses: Metric card setup + itemized ledger button `+ Log Transaction` (`AddTransactionSheet`). Zero FABs.
  - Habits: Header button `+ New Habit` (`AddHabitSheet`). Zero FABs.
  - Workout: Feature completely removed; zero workout routes or controls exist.
