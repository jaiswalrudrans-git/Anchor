<div align="center">
  <img src="assets/branding/glyph_black.png" alt="Anchor Logo" width="96" height="96" />
  <h1>Anchor</h1>
  <p><strong>Plan it. Do it. Anchor it.</strong></p>
  <p>Personal anti-procrastination, academics, expenses, habits, and workouts tracking built with Flutter & Supabase.</p>
</div>

---

## Tech Stack

- **Framework**: Flutter (Dart null-safe)
- **State Management**: `flutter_riverpod`
- **Backend**: Supabase (Postgres 15+, RLS, GoTrue Auth, Storage)
- **Visual Design**: Strict monochrome wireframe with dynamic accents and dark mode
- **Platforms**: Android, Windows Desktop, Web Preview

---

## Branding

The Anchor brand mark is a solid black anchor glyph whose ring head contains a check mark.

- **Asset Directory**: `assets/branding/`
  - Masters: `assets/branding/source/`
  - Core app assets: `glyph_black.png`, `glyph_white.png`, `tile_light_1024.png`, `tile_dark_1024.png`
  - Platform assets: `assets/branding/android/`, `assets/branding/windows/`, `assets/branding/web/`
  - In-app splash: `assets/branding/inapp/`
  - Static landing site: `site/`
  - Visual verification contact sheet: `assets/branding/_preview.png`
- **Regenerate Assets**:
  ```bash
  python tool/generate_brand_assets.py
  ```
- **Brand Rules**:
  1. The glyph is strictly monochrome: black (`#111111`) on light surfaces, white (`#FFFFFF`) on dark surfaces. Never apply accent colors to the brand mark.
  2. The glyph is never stretched, rotated, outlined, or given drop shadows or decorative effects.
  3. Minimum clear space around the glyph: 25% of its width.
  4. Launcher / brand tile backgrounds: `#FFFFFF` for light mode, `#0E0E10` for dark mode.

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
