# BIOHACKER Flutter App — Security & Quality Audit Report

**Date:** 2026-04-10  
**Scope:** 109 Dart files in `lib/`, Android configs, Supabase migrations, CI/CD  
**Auditor:** Wintermute (automated + manual analysis)

---

## Executive Summary

The app has a solid architectural foundation — Supabase RLS on all 19 tables, FlutterSecureStorage for tokens, biometric auth, HIPAA consent screen, session timeouts. However, **two P0 issues need immediate attention before any production deployment**: credentials are being bundled into the APK via `.env`, and there are 338+ unguarded `print()` calls leaking PHI (medication doses, lab results, user IDs, weight data) to logcat in production builds.

---

## CRITICAL Issues

### C1 — `.env` File Bundled in APK (Credentials Exposed)
**File:** `pubspec.yaml` (assets section) + `.env`  
**Risk:** Anyone who downloads and extracts the APK can read the Supabase URL and anon key.

The `.env` file containing live production Supabase credentials is listed as a Flutter asset:
```yaml
assets:
  - .env   # ← This ships INSIDE the APK
```
`main.dart` loads it at runtime: `await dotenv.load(fileName: '.env')`.

**Fix:**
1. Remove `.env` from `pubspec.yaml` assets immediately
2. Add `.env` to `.gitignore`
3. Use `--dart-define` for release builds (CI already does this correctly in `.github/workflows/build.yml` — just remove the `.env` fallback path)
4. Rotate the Supabase anon key in Supabase Dashboard → Settings → API

---

### C2 — Hardcoded Postgres Password in `run_migration.sh`
**File:** `run_migration.sh`  
**Risk:** Full database access credential in plaintext in the repo.

```bash
postgresql://postgres.dfiewtwbxqfrrmyiqhqo:DKhjd89&D&67#@aws-0-us-east-1.pooler.supabase.com:6543/postgres
```
This also appears in `TOOLS.md` (workspace config file).

**Fix:**
1. Rotate the Supabase database password immediately (Supabase Dashboard → Settings → Database → Reset password)
2. Delete `run_migration.sh` or replace with `$DATABASE_URL` env var reference
3. Scrub git history: `git filter-branch` or BFG Repo-Cleaner

---

### C3 — PHI Leaked to Logcat via `print()` (338 occurrences)
**Files:** Widespread — `weight_logs_database.dart`, `cycles_screen.dart`, `reports_service.dart`, `calendar_screen.dart`, `dashboard_screen.dart`, `user_profile_service.dart`, and many more  
**Risk:** Direct HIPAA §164.312(a) violation. On Android, `print()` writes to logcat which is readable by any app with `READ_LOGS` permission. On production devices, this data may be captured by crash reporters, MDM tools, or USB debugging sessions.

**Specific PHI being logged:**
- `weight_logs_database.dart:51` — `User: ${user.id}, Weight: $weightLbs`
- `weight_logs_database.dart:61` — `Data being inserted: $data` (full weight record)
- `reports_service.dart:677-770` — Lab results count, biomarker processing, cycle context
- `cycles_screen.dart:971-1032` — Peptide name, dose, weeks for each cycle creation
- `calendar_screen.dart:754-763, 937-945` — Individual dose details (peptide, amount, status, cycleId, date)
- `dashboard_screen.dart:117-122` — Dose log ID, cycle ID, peptide name, date, amount, status
- `user_profile_service.dart:354-395` — Full profile updates including medical data

**Fix:** Replace all bare `print()` with `kDebugMode`-gated `debugPrint()`:
```dart
// Before:
print('DEBUG: Saving weight log - User: ${user.id}, Weight: $weightLbs');

// After:
if (kDebugMode) debugPrint('Saving weight log');  // No PHI in message
```
For production, strip ALL PHI from log messages entirely. Consider a logging utility that strips sensitive fields automatically.

---

### C4 — No HIPAA Business Associate Agreement (BAA) on Supabase
**Risk:** Storing actual PHI (lab results, medications, biomarkers, side effects) on Supabase without a signed BAA is a HIPAA violation regardless of technical controls.

Supabase does **not** offer a BAA on Free or Pro plans. BAA requires Supabase Enterprise.

**Options:**
1. **Supabase Enterprise** — Contact Supabase sales for BAA + HIPAA compliance tier
2. **Self-hosted Supabase** — Full control, no BAA needed; requires DevOps overhead
3. **Alternative:** AWS (HIPAA-eligible services) + Postgres; or Neon/PlanetScale with BAA

---

### C5 — Google Sign-In Completely Broken (3 Root Causes)
See dedicated section below.

---

## HIGH Issues

### H1 — No Rate Limiting on Authentication
**Files:** `login_screen.dart`, `signup_screen.dart`  
**Risk:** Brute-force attacks on user accounts; credential stuffing.

No attempt counter, no exponential backoff, no CAPTCHA, no account lockout after N failed attempts.

**Fix:** Implement client-side backoff + Supabase Auth rate limiting (Dashboard → Auth → Rate Limits). Consider adding reCAPTCHA via `flutter_recaptcha_v2` for production.

---

### H2 — Session Tokens Never Expire Client-Side
**File:** `providers/auth_provider.dart:28-31`  
**Risk:** Stolen tokens remain valid indefinitely; no forced re-auth after inactivity.

Supabase JWT access tokens expire (default 1 hour), but the app doesn't check expiration on restore or handle `AuthException` from expired tokens gracefully in all code paths.

**Fix:** On app foreground, call `supabase.auth.refreshSession()` and handle `AuthException` by redirecting to login.

---

### H3 — No User Data Deletion Workflow (HIPAA Right to Erasure)
**Risk:** HIPAA §164.526 and GDPR Article 17 — users must be able to request complete data deletion.

No "Delete My Account" feature found in the codebase. The profile screen has data export but no deletion path.

**Fix:** Implement a delete account flow that:
1. Calls a Supabase Edge Function or RPC with `CASCADE` deletes across all PHI tables
2. Deletes the storage bucket files (lab PDFs, profile photos)
3. Calls `supabase.auth.admin.deleteUser(userId)` to remove the auth record
4. Clears local FlutterSecureStorage

---

### H4 — OAuth Deep Link Not Verified (Token Interception Risk)
**File:** `providers/auth_provider.dart:92-120`  
**Risk:** The `com.biohacker.app://login-callback` scheme could be registered by a malicious app.

**Fix:** Verify the scheme is registered in `AndroidManifest.xml` (it is) and consider using HTTPS App Links (`https://biohacker.app/auth/callback`) with Digital Asset Links verification for stronger protection.

---

## MEDIUM Issues

### M1 — Session Timeout Silently Fails When App Is Backgrounded
**File:** `services/session_manager.dart:59-99`  
**Risk:** 30-minute timeout doesn't trigger if `_context == null` (app was backgrounded during the countdown).

**Fix:** Use `AppLifecycleObserver` to track when the app moves to background; store the timestamp; on foreground resume, check if timeout has elapsed and force logout.

---

### M2 — Biometric Auth Allows Weak PIN Fallback
**File:** `services/biometric_auth_service.dart:64`  
```dart
biometricOnly: false,  // Allows PIN/password fallback
```
**Risk:** Attacker with device knowledge can bypass biometric using the device PIN.

**Fix:** Set `biometricOnly: true` for sensitive operations (viewing lab results, dosing records), and require re-authentication with Supabase password instead of device PIN for full access.

---

### M3 — Profile Photo Path Traversal Risk
**File:** `services/profile_photo_service.dart:56-66`  
**Risk:** File path is constructed from URL segments without sanitization. Malformed URLs could cause unexpected deletions.

**Fix:** Validate that the extracted path starts with `profile-photos/{userId}/` before deletion.

---

### M4 — Error Messages Leak Internal Schema Details
**Files:** `auth_provider.dart`, `dose_schedule_service.dart`  
**Risk:** Raw Supabase exceptions (table names, column names, RLS policy errors) returned to UI.

`UserFeedback.getFriendlyErrorMessage()` exists but is underused. Apply it everywhere errors surface to users.

---

### M5 — Bloodwork Service Has Mock Data in Production Build
**File:** `services/bloodwork_service.dart:7-10, 146-171`  
Feature disabled but mock data generation code ships in the build. Confusing and potentially misleading.

---

### M6 — Notification Tap Routing Unimplemented
**File:** `services/notification_service.dart:121`  
```dart
// TODO: push to relevant screen via global navigator key
```
Notifications are scheduled but tapping them does nothing. Major UX issue for dose reminders.

---

### M7 — Reconstitution Data Hardcoded in Screens
**Files:** `calendar_screen.dart:33`, `dashboard_screen.dart:49`  
```dart
// Reconstitution data (TODO: move to database)
```
Peptide reconstitution ratios are hardcoded Maps in two separate screens instead of a shared data source. This will cause inconsistencies.

---

## LOW Issues

### L1 — 8 AnimationControllers Without Confirmed `dispose()`
**Files:** `widgets/dystopian_trend_chart.dart`, `widgets/cyberpunk_rain.dart`, `widgets/cyberpunk_animations.dart`, `widgets/city_background.dart`, `widgets/cyberpunk_frame.dart`, `widgets/expandable_cycle_card.dart`, `screens/login_screen.dart`, `screens/onboarding/welcome_screen.dart`

Verify each has `@override void dispose() { _controller.dispose(); super.dispose(); }`.

---

### L2 — Time Parsing Crash on Malformed Input
**File:** `dose_logs_service.dart:100`  
`TimeOfDay.fromDateTime(DateTime.parse(scheduledTime))` — if `scheduledTime` is null or malformed, this throws uncaught exception.

---

### L3 — Notification ID Collisions via `hashCode`
**File:** `notification_service.dart:134`  
`hashCode` is not guaranteed unique. Use a counter or UUID-derived integer for notification IDs.

---

### L4 — No Certificate Pinning
Supabase connections use HTTPS but no certificate pinning. Mitigated by the anon key being the only sensitive credential in transit (RLS handles server-side auth).

---

### L5 — ~25 ListViews Missing Empty State Checks
`ListView.builder` calls without `isEmpty` guards result in blank screens rather than "no data" messages. Identified in reports, calendar, and cycle screens.

---

### L6 — `profile_screen_old.dart` Ships in Build
Dead code with its own `print()` PHI logging. Should be deleted.

---

### L7 — 232 Uses of `!` Null Force-Unwrap
High density of `!` operators indicates potential NPEs under edge cases (e.g., first launch, partial onboarding). Audit the most critical paths (auth, dose logging).

---

### L8 — Email Not Lowercased on Signup
**File:** `signup_screen.dart:88`  
`.trim()` but no `.toLowerCase()`. `User@Example.com` and `user@example.com` create separate accounts.

---

## Google Auth — Root Cause Analysis & Fix Steps

### Root Causes (All Three Must Be Fixed)

**Root Cause 1: Empty `oauth_client` in `google-services.json`**  
`android/app/google-services.json` has `"oauth_client": []` — no SHA-1 fingerprint was ever registered in Firebase Console. Without a registered fingerprint, Firebase doesn't generate OAuth client credentials, so Google Sign-In has no client ID to use.

**Root Cause 2: Package Name Mismatch**  
- `google-services.json` registered package: `com.example.biohacker`  
- `build.gradle.kts` actual package: `com.biohacker.biohacker_app`  
These must match exactly for the Firebase SDK to initialize correctly.

**Root Cause 3: Supabase Google Provider Likely Not Configured**  
The app uses Supabase's browser-based OAuth flow (`supabase.auth.signInWithOAuth(OAuthProvider.google)`), not the native `google_sign_in` package for actual sign-in. For this to work, the Supabase Google provider must be configured with the correct Web Client ID and Secret.

### Fix Steps (Execute In Order)

**Step 1: Get your SHA-1 fingerprints**
```bash
# Debug keystore (for testing)
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android 2>/dev/null | grep SHA1

# Release keystore
keytool -list -v \
  -keystore android/keystore/biohacker-release.jks \
  -alias biohacker \
  -storepass 'biohacker2026!' 2>/dev/null | grep SHA1
```

**Step 2: Fix Firebase App Registration**
1. Go to [Firebase Console](https://console.firebase.google.com) → Project `biohacker-9a929` → Project Settings → Your Apps
2. Find the Android app — it's registered as `com.example.biohacker`
3. **Option A (Recommended):** Delete the old app entry, add a new Android app with package name `com.biohacker.biohacker_app`, add both SHA-1 fingerprints
4. **Option B:** Edit the existing app to update the package name AND add SHA-1 fingerprints
5. Download the new `google-services.json` and replace `android/app/google-services.json`
6. Verify the new file has `"oauth_client"` entries with a `client_id`

**Step 3: Get the Web Client ID from Google Cloud Console**
1. Go to [Google Cloud Console](https://console.cloud.google.com) → APIs & Services → Credentials
2. After adding SHA-1 to Firebase, a "Web client (auto created by Google Service)" entry will appear
3. Copy the **Web client ID** and **client secret** (format: `xxxxx.apps.googleusercontent.com`)

**Step 4: Configure Supabase Google Provider**
1. Go to Supabase Dashboard → Authentication → Providers → Google
2. Enable Google provider
3. Enter the **Web Client ID** and **Client Secret** from Step 3
4. Set Callback URL (shown in Supabase) — add this to the OAuth client's authorized redirect URIs in Google Cloud Console

**Step 5: Verify Deep Link Configuration**
1. Supabase Dashboard → Authentication → URL Configuration → Redirect URLs
2. Add `com.biohacker.app://login-callback`
3. Verify `AndroidManifest.xml` has the intent filter for this scheme (it does)

**Step 6: Clean the unused `google_sign_in` code**  
The `GoogleSignIn()` instance in `auth_provider.dart:9` is only called for `signOut()`. This is unnecessary since Supabase handles the full OAuth flow. Either keep it for Google-specific signout (fine) or remove it and just call `supabase.auth.signOut()`.

---

## Supabase Assessment

### RLS Coverage: ✅ All 19 Tables Protected
Every table uses `auth.uid() = user_id` row-level isolation. Full CRUD policies on all PHI tables. This is the strongest part of the security posture.

| Table | RLS | PHI? |
|-------|-----|------|
| `cycles` | ✅ | Yes — peptide protocols |
| `dose_logs` | ✅ | Yes — medication doses |
| `dose_schedules` | ✅ | Yes — treatment schedules |
| `side_effects_log` | ✅ | Yes — symptoms |
| `weight_logs` | ✅ | Yes — body weight/fat |
| `labs_results` | ✅ | Yes — lab PDFs + biomarkers |
| `user_profiles` | ✅ | Yes — age, gender, conditions |
| `health_goals` | ✅ | Yes |
| `cycle_reviews` | ✅ | Yes |
| `cycle_expenses` | ✅ | Indirect PHI |
| `peptide_inventory` | ✅ | Indirect PHI |
| `protocol_templates` | ✅ | Public read for `is_public=true` |
| `dashboard_snapshots` | ✅ | Aggregate cache |
| `notification_preferences` | ✅ | Settings only |
| `audit_log` | ✅ | INSERT only (correct) |
| `subscription_purchases` | ✅ | Financial |
| `storage.objects` | ✅ | User-scoped write, public read |

**Minor gap:** `side_effects_log` is missing UPDATE policy — users can't edit existing entries. Add if needed.

### Credential Handling
- **Runtime loading:** `dotenv` → `--dart-define` fallback (good pattern)
- **CRITICAL:** `.env` bundled as asset (see C1 above — APK exposure)
- **CRITICAL:** Postgres password in `run_migration.sh` (see C2 above)
- **CI/CD:** GitHub Actions uses `--dart-define` with secrets (correct)

### Free Tier Limitations for Production

| Resource | Free Limit | Risk |
|----------|-----------|------|
| Database storage | 500MB | Medium — lab PDFs accumulate |
| Storage (files) | 1GB | **High** — PDF uploads will hit this |
| Auth MAU | 50,000 | Low initially |
| No automated backups | — | **High** — health data loss risk |
| No HIPAA BAA | Enterprise only | **Critical** — legal compliance |
| No point-in-time recovery | Pro+ | High for health data |

### Upgrade Recommendation

**Minimum for production:** Supabase Pro ($25/month)
- 8GB database, 100GB storage
- Daily backups + PITR (7 days)
- Better rate limits

**Required for HIPAA compliance:** Supabase Enterprise
- Signed BAA
- Dedicated resources
- HIPAA audit logs
- Alternatively: self-host Supabase on HIPAA-compliant infrastructure (AWS with Business Associate Agreement)

---

## Action Plan (Prioritized)

### Do Before ANY Production Release
1. **Remove `.env` from `pubspec.yaml` assets** and rotate Supabase anon key (30 min)
2. **Rotate Supabase database password** and delete/sanitize `run_migration.sh` (15 min)
3. **Fix Google Auth** — Register SHA-1, fix package name, configure Supabase Google provider (2-3 hours)
4. **Wrap all `print()` calls in `kDebugMode`** — especially in `weight_logs_database.dart`, `reports_service.dart`, `cycles_screen.dart`, `calendar_screen.dart` (2-4 hours with find/replace + review)

### Before Launch
5. Implement rate limiting on auth (1-2 hours)
6. Add session token expiration check on app foreground (1 hour)
7. Implement "Delete My Account" data erasure flow (4-8 hours)
8. Fix notification tap routing (2-3 hours)
9. Upgrade Supabase to Pro minimum; evaluate Enterprise for HIPAA BAA

### Soon After Launch
10. Sanitize error messages (apply `UserFeedback.getFriendlyErrorMessage()` everywhere)
11. Centralize reconstitution data from hardcoded Maps to database
12. Verify `AnimationController.dispose()` in all 8 flagged widget files
13. Add empty state UI to all 25 ListViews
14. Delete `profile_screen_old.dart` dead code
15. Email normalization: add `.toLowerCase()` alongside `.trim()` on signup

---

*Report generated by automated analysis of 109 Dart files + Android configs + Supabase migration files.*
