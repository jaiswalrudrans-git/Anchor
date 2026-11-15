# Anchor: Production Release Checklist & Build Guide

## 1. Release Binaries

All binaries compiled in `--release` mode with production `--dart-define` parameters:
- `SUPABASE_URL=https://nnwrgwhqbysbgqpeyozz.supabase.co`
- `SUPABASE_ANON_KEY=sb_publishable_CIuH5EgroUFub8PLYvyWZw_RSONwTKP`

### Windows (Desktop)
- **Executable**: `build\windows\x64\runner\Release\anchor.exe`
- **Bundle Directory**: `build\windows\x64\runner\Release\`
- **Packaging Note**: To distribute, zip the entire `Release/` directory (includes `anchor.exe`, `data/`, and required Flutter/plugin runtime DLLs).

### Android (Mobile)
- **Arm64-v8a APK (Standard 64-bit phones)**: `build\app\outputs\flutter-apk\app-arm64-v8a-release.apk` (21.7 MB)
- **Armeabi-v7a APK (Legacy 32-bit phones)**: `build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk` (19.4 MB)
- **x86_64 APK (Chromebooks / Emulators)**: `build\app\outputs\flutter-apk\app-x86_64-release.apk` (23.1 MB)
- **Universal Release APK (All architectures)**: `build\app\outputs\flutter-apk\app-release.apk` (59.5 MB)
- **Google Play App Bundle (AAB)**: `build\app\outputs\bundle\release\app-release.aab` (57.1 MB)

---

## 2. Production Signing Setup (Android)

For official Google Play publishing, sign with a custom keystore:
1. Generate keystore:
   ```bash
   keytool -genkey -v -keystore android/anchor-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias anchor
   ```
2. Create `android/key.properties` from `android/key.properties.example`:
   ```properties
   storePassword=YOUR_KEYSTORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=anchor
   storeFile=anchor-release.jks
   ```
3. Rebuild with `flutter build appbundle --release --dart-define=...`

---

## 3. Backend & Security Verification

1. **Row-Level Security (RLS)**:
   - Run `supabase/checks/rls_check.sql` in the Supabase SQL editor.
   - Verify 0 tables missing RLS or policies.
2. **Network Security**:
   - `android:usesCleartextTraffic="false"` is active in `AndroidManifest.xml`.
   - Client embeds only the public Anon key.
3. **Deep Linking / OAuth**:
   - Android scheme: `io.anchor.app://login-callback`
   - Windows protocol: `io.anchor.app://login-callback` (registered in HKCU registry).

---

## 4. Performance & High Refresh Rate Verification

1. **120 Hz / 90 Hz Display Rate**:
   - Enabled via `flutter_displaymode 0.7.0` on Android startup.
2. **Driver Benchmark Script**:
   - Connect device via USB debugging and run:
     ```bash
     flutter drive --profile -t test_driver/perf_test_e2e.dart --driver test_driver/perf_test.dart
     ```
   - Summaries and traces are output to `perf/`.
