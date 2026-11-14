# Anchor - Setup & Configuration Guide

This guide documents the complete setup instructions for the **Anchor** application backend (Supabase Postgres, Storage, and Auth) and platform targets (Android & Windows Desktop).

---

## 1. Supabase Project Setup

1. Log in to [Supabase](https://supabase.com) and create a new project.
2. Note your **Project URL** and **Anon / Public Key** from **Project Settings -> API**:
   - `SUPABASE_URL`: `https://<project-ref>.supabase.co`
   - `SUPABASE_ANON_KEY`: `eyJhbGciOi...`

---

## 2. Run Database Migration

1. In your Supabase dashboard, navigate to **SQL Editor**.
2. Click **New query** and paste the entire contents of [`supabase/migrations/001_init.sql`](supabase/migrations/001_init.sql).
3. Click **Run**.
4. Run [`supabase/migrations/005_drop_workout.sql`](supabase/migrations/005_drop_workout.sql):
   - **Fresh project:** Run `001_init.sql` followed by `005_drop_workout.sql` (both idempotent).
   - **Existing project:** Run `005_drop_workout.sql` once in the Supabase SQL editor.
   - ⚠️ **WARNING:** `005_drop_workout.sql` drops `workout_exercises` and `workout_days` tables and **permanently deletes all workout data**.
5. The remaining 12 tables and RLS policies are fully configured.

### Verification & RLS Security Check Script
Run the following SQL snippet in the Supabase SQL editor to verify that all 12 tables, RLS policies, and the storage bucket are properly configured:

```sql
-- 1. Verify all 12 tables exist (Workout tables dropped)
select table_name 
from information_schema.tables 
where table_schema = 'public' 
order by table_name;

-- 2. Verify Row Level Security (RLS) is enabled on all tables
select tablename, rowsecurity 
from pg_tables 
where schemaname = 'public' 
order by tablename;

-- 3. Verify private storage bucket exists
select id, name, public 
from storage.buckets 
where id = 'academic_vault';

-- 4. Test RLS Isolation (as simulated user)
-- Setting auth context to user '00000000-0000-0000-0000-000000000001'
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';

-- Attempt insert as User 1
insert into public.todos (id, user_id, title, scheduled_date)
values ('11111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-000000000001', 'Test User 1 Todo', current_date);

-- Switch to User 2
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000002';

-- User 2 should NOT see User 1's todo (returns 0 rows)
select count(*) as cross_user_leak_count 
from public.todos 
where id = '11111111-1111-1111-1111-111111111111';

-- Clean up test row
reset role;
delete from public.todos where id = '11111111-1111-1111-1111-111111111111';
```

---

## 3. Google OAuth & GCP Credentials

1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
2. Create or select a project, then navigate to **APIs & Services -> Credentials**.
3. Configure the **OAuth Consent Screen** (User type: External, add your email and app name "Anchor").
4. Click **Create Credentials -> OAuth client ID**:
   - Application type: **Web application**
   - Name: `Anchor Auth`
   - **Authorized JavaScript origins**:
     - `https://<project-ref>.supabase.co`
   - **Authorized redirect URIs**:
     - `https://<project-ref>.supabase.co/auth/v1/callback`
5. Save the **Client ID** and **Client Secret**.
6. Return to your Supabase Dashboard:
   - Navigate to **Authentication -> Providers -> Google**.
   - Toggle **Enable Google provider** to ON.
   - Paste the **Client ID** and **Client Secret**.
   - Click **Save**.

---

## 4. Supabase Redirect URL Configuration

Supabase must be instructed to permit redirects back to our application custom scheme.

1. In Supabase Dashboard, navigate to **Authentication -> URL Configuration**.
2. Set **Site URL** to:
   ```
   io.anchor.app://login-callback
   ```
3. Under **Redirect URLs**, add:
   ```
   io.anchor.app://login-callback
   io.anchor.app://*
   io.execute.app://login-callback
   io.execute.app://*
   http://localhost:*
   ```
4. Click **Save**.

---

## 5. Platform Deep Linking & URL Protocol Setup

### Android
- **Manifest scheme**: Configured in `android/app/src/main/AndroidManifest.xml` with intent filter:
  - Scheme: `io.anchor.app` (and `io.execute.app` supported)
  - Host: `login-callback`
  - Activity `launchMode="singleTask"` ensures callback focuses the running activity instead of creating duplicates.
- **Test deep link with ADB**:
  ```bash
  adb shell am start -a android.intent.action.VIEW -d "io.anchor.app://login-callback" io.anchor.app
  ```

### Windows Desktop
- **Scheme**: `io.anchor.app`
- **Automatic Registration**: On startup, `main.dart` invokes `SupabaseConfig.registerWindowsProtocolIfNeeded()` which writes the protocol to `HKCU\Software\Classes\io.anchor.app` pointing to `Platform.resolvedExecutable`.
- **Single-Instance Forwarding**: `windows/runner/main.cpp` calls `SendAppLinkToInstance()` from the `app_links` C++ API. When Windows invokes a second instance to deliver the OAuth callback URL, it forwards the URL to the running instance via Win32 messages and terminates immediately without creating a second window.
- **Manual Registry Verification (PowerShell)**:
  ```powershell
  # Check if scheme is registered:
  Get-ItemProperty "HKCU:\Software\Classes\io.anchor.app\shell\open\command"

  # Test trigger:
  Start-Process "io.anchor.app://login-callback"
  ```

---

## 6. Running & Building the Application

Never hardcode Supabase keys into source code. Always pass them via `--dart-define`:

### Running in Debug / Development

#### Android
```bash
flutter run -d android \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
```

#### Windows Desktop
```powershell
flutter run -d windows `
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
```

#### Missing Config Graceful Fallback
If you run without flags (`flutter run`), the app displays a clear monochrome diagnostic screen with copyable command line flags rather than crashing.

---

### Building for Release

#### Android APK
```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

#### Windows Desktop Release Binary
```powershell
flutter build windows --release `
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
```
Output: `build/windows/x64/runner/Release/`

---

## 7. Known v1 Limitations & Platform Notes

1. **Scheduled Notifications**: Scheduled reminders for assignments (21:00 on `due_date - 1`) and exams (08:00 on `due_date - 3`) use `flutter_local_notifications` and exact alarm APIs which are **Android-only** in v1. On Windows and Web, notification scheduling calls are safe no-ops and will never throw errors or crash.
2. **File Vault In-App Viewer**: Anchor intentionally avoids bloated custom PDF/Office rendering libraries. Tap-to-open delegates directly to the native operating system's default viewer via `open_filex` for maximum fidelity and zero memory overhead.
3. **Workout Module Deprecation**: Per Polish Stage 6, workout tracking was deprecated and removed in favor of habits and academic focus. Tables `workout_exercises` and `workout_days` are dropped via migration `005_drop_workout.sql`.
4. **Single Currency**: Expense tracking is configured for Indian Rupee (`₹`) formatting in v1. Multi-currency conversion or receipt scanning is outside v1 scope.
5. **Windows Visual Studio Build Requirement**: Building native Windows C++ binaries requires Visual Studio 2022 with the "Desktop development with C++" workload installed (`flutter doctor`).
