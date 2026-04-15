# FIXES_APPLIED.md — Security Fix Report
**Date:** 2026-04-10  
**Status:** ✅ All fixes applied. AAB rebuild succeeded.

---

## C1 — Remove .env from APK Assets ✅

**Problem:** `.env` file was listed in `pubspec.yaml` assets, causing secrets to be bundled inside the APK/AAB and extractable by anyone.

**Fixes applied:**
1. Removed `.env` from `pubspec.yaml` assets list
2. Removed `flutter_dotenv: ^5.2.1` from `pubspec.yaml` dependencies
3. Updated `lib/main.dart` — removed `flutter_dotenv` import, replaced `dotenv.env[...]` with `const String.fromEnvironment(...)` 
4. Updated `lib/screens/labs_screen.dart` — removed `flutter_dotenv` import, replaced dotenv calls with `String.fromEnvironment`
5. Updated `lib/services/bloodwork_service.dart` — same treatment
6. Confirmed `.env` is already in `.gitignore` (no change needed)

**All three files (main.dart, labs_screen.dart, bloodwork_service.dart) now use `String.fromEnvironment()` exclusively.**

---

## C2 — Remove Hardcoded Postgres Password ✅

**Problem:** `run_migration.sh` contained hardcoded DB password in a psql connection string.

**Fixes applied:**
- Sanitized `run_migration.sh` — removed hardcoded Supabase URL, anon key, and postgres password
- Replaced psql command with `$DB_PASSWORD` env var reference
- `update_peptide_studies.sh` — no secrets found, no changes needed

---

## C3 — Wrap print() calls in kDebugMode ✅

**Problem:** 338 raw `print()` calls would log sensitive data in production builds.

**Fix applied via Claude Code:**
- 36 files modified across `lib/`
- All `print()` calls wrapped with `if (kDebugMode) { print(...); }`
- `import 'package:flutter/foundation.dart'` added where missing
- Pre-existing guarded prints left untouched (no double-wrapping)
- **0 unguarded print() calls remain**

---

## C5 Prep — SHA-1 Fingerprints ✅

### Release Keystore (`biohacker-release.jks`)
- **Alias:** biohacker
- **SHA-1:**   `0B:7A:D9:6E:E9:65:B5:29:89:7E:4B:35:E1:32:AC:7B:89:C4:B1:A9`
- **SHA-256:** `B6:AD:02:69:0F:05:47:EC:FE:FF:E7:E6:0C:27:C5:9C:DD:81:8C:8C:09:56:19:D6:4D:DA:3B:D0:2A:E1:53:0E`

### Debug Keystore (`biohacker-app/android/app/debug.keystore`)
- **Alias:** androiddebugkey
- **SHA-1:**   `5E:8F:16:06:2E:A3:CD:2C:4A:0D:54:78:76:BA:A6:F3:8C:AB:F6:25`
- **SHA-256:** `FA:C6:17:45:DC:09:03:78:6F:B9:ED:E6:2A:96:2B:39:9F:73:48:F0:BB:6F:89:9B:83:32:66:75:91:03:3B:9C`

> **Note:** Standard `~/.android/debug.keystore` was not found on this machine. The debug keystore above is from the biohacker-app (React Native project) directory. If you need a fresh Flutter debug keystore, run: `flutter run` once and it will be created at `~/.android/debug.keystore`.

---

## Google Auth Fix (C5) — What to Register

To fix Google Sign-In, register **both** SHA-1 fingerprints in your Firebase/Google Cloud project:

### Firebase Console
1. Go to: https://console.firebase.google.com/project/YOUR_PROJECT/settings/general/android:com.dayhoff.biohacker
2. Under **Your apps → Android app**, click **Add fingerprint**
3. Add the **Release SHA-1:** `0B:7A:D9:6E:E9:65:B5:29:89:7E:4B:35:E1:32:AC:7B:89:C4:B1:A9`
4. Add the **Debug SHA-1:** `5E:8F:16:06:2E:A3:CD:2C:4A:0D:54:78:76:BA:A6:F3:8C:AB:F6:25`
5. Download the updated `google-services.json` and place it in `android/app/`

### Google Cloud Console (OAuth)
1. Go to: https://console.cloud.google.com/apis/credentials
2. Find your Android OAuth 2.0 Client ID
3. Ensure both SHA-1 fingerprints are registered
4. Package name: `com.dayhoff.biohacker` (verify in `android/app/build.gradle`)

---

## Correct Flutter Build Command (Going Forward)

```bash
cd /path/to/biohacker-flutter

# Source credentials from local .env (never commit .env)
SUPABASE_URL=$(grep SUPABASE_URL .env | cut -d'=' -f2)
SUPABASE_ANON_KEY=$(grep SUPABASE_ANON_KEY .env | cut -d'=' -f2)
LAB_PDF_ENDPOINT=$(grep LAB_PDF_ENDPOINT .env | cut -d'=' -f2)
LAB_PDF_API_KEY=$(grep LAB_PDF_API_KEY .env | cut -d'=' -f2)

flutter build appbundle --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=LAB_PDF_ENDPOINT="$LAB_PDF_ENDPOINT" \
  --dart-define=LAB_PDF_API_KEY="$LAB_PDF_API_KEY"
```

For CI/CD (GitHub Actions, etc.), set these as repository secrets and pass via `--dart-define`.

**Optional extra defines (if used):**
```
--dart-define=BLOODWORK_AI_API_KEY="$BLOODWORK_AI_API_KEY"
```

---

## AAB Rebuild ✅

```
✓ Built build/app/outputs/bundle/release/app-release.aab (54.2MB)
```

Build completed successfully with all security fixes in place. The `.env` file is no longer bundled — credentials are compile-time constants injected via `--dart-define`.
