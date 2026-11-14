# Anchor

**Anchor** is a personal anti-procrastination, academics, expenses, and habits tracking application built with **Flutter** (targeting Android and Windows Desktop, with Web preview) and backed by **Supabase** (Postgres, Row Level Security, Storage, and Google OAuth).

---

## Tech Stack

- **Framework**: Flutter (Dart null-safe)
- **State Management**: `flutter_riverpod`
- **Backend**: Supabase (Postgres 15+, RLS, GoTrue Auth, Storage)
- **Visual Design**: Strict monochrome wireframe with dynamic accents and dark mode
- **Platforms**: Android, Windows Desktop, Web Preview

---

## 4 Core Modules & Global Quick Add

1. **Home**: Daily anti-procrastination tasks, idle prompts, and rollover tracking.
2. **Academics**: Academic vault, subjects, modules, chapters, files, and exam schedules.
3. **Expenses**: Monthly allowance, category budgets, transaction logs, and savings overflow.
4. **Habits**: Consistency tracking, daily completions, and streak grids.
- **Global Quick Add**: Adaptive quick-add sheet/dialog for to-dos, assignments, exams, expenses, and today's habits checkoff accessible from any tab (or `Ctrl+N` on desktop).

---

## Getting Started

### 1. Database & Supabase Setup
Follow the step-by-step setup in [SETUP.md](SETUP.md) to:
- Run the idempotent database migration script in [`supabase/migrations/001_init.sql`](supabase/migrations/001_init.sql).
- Configure Google OAuth and callback URLs.

### 2. Run the App

Pass your Supabase project configuration via `--dart-define`:

```bash
# Android
flutter run -d android \
  --dart-define=SUPABASE_URL=https://<your-project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<your-anon-key>

# Windows Desktop
flutter run -d windows \
  --dart-define=SUPABASE_URL=https://<your-project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<your-anon-key>

# Web (Edge)
flutter run -d edge \
  --dart-define=SUPABASE_URL=https://<your-project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
```

---

## Development

```bash
# Analyze code
flutter analyze

# Run test suite
flutter test
```
