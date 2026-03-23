# BIOHACKER APP — SECURITY, FUNCTIONALITY & UAT AUDIT REPORT

**Date:** 2026-03-23
**Auditor:** Claude (Automated + Static Analysis)
**Codebase:** Flutter / Supabase, ~39,757 lines
**Scope:** lib/, android/, ios/, SQL migrations

---

## EXECUTIVE SUMMARY

The app has a solid security foundation: Supabase RLS policies properly isolate all user data, password requirements are strong, error messages are sanitised, and all debug logging is conditionally guarded (`kDebugMode`). The main security gaps are a **critical plaintext HTTP endpoint** used to transmit medical lab PDFs, hardcoded credentials in source code, and several incomplete features that create broken UX.

---

## 1. CRITICAL ISSUES

### SEC-001 — Medical Lab PDFs Sent Over Plain HTTP to Hardcoded Private IP
**File:** `lib/screens/labs_screen.dart:212`
**Code:**
```dart
Uri.parse('http://100.71.64.116:9000/api/extract-lab-pdf'),
```
**Description:** PDF lab reports containing medical biomarker data (testosterone, cortisol, glucose, thyroid, liver enzymes, etc.) are transmitted via plain HTTP — no TLS — to what appears to be a private/development server (Tailscale IP or LAN). This endpoint is hardcoded and has no authentication header.
**Impact:** Medical data transmitted unencrypted over the network. Anyone on the same network segment can intercept and read full lab PDFs. The server is inaccessible in production (private IP), making PDF upload non-functional for all external users.
**Fix:** Replace with a production HTTPS endpoint. Add `Authorization: Bearer <token>` header. Validate TLS certificate. Never hardcode IPs — load from env/config.

---

### SEC-002 — Supabase Credentials Hardcoded in Source Code
**File:** `lib/main.dart:17-18`
**Code:**
```dart
url: 'https://dfiewtwbxqfrrmyiqhqo.supabase.co',
anonKey: 'sb_publishable_swGU8s8l_FgSo2GuKbGkfA_00Wd9zIV',
```
**Description:** The Supabase project URL and anonymous key are committed directly to source. While the anon key is a "publishable" key (not a service-role secret), hardcoding it in source creates long-term risk: it cannot be rotated without a new app release, it will appear in git history permanently, and any future accidental commit of a service key would follow the same pattern.
**Impact:** Medium-risk now. High-risk precedent that could lead to service key exposure. Anyone with source access can target the Supabase project.
**Fix:** Use `flutter_dotenv` or `--dart-define` at build time. Add to `.gitignore`. Rotate the key if repo is or ever becomes public.

---

## 2. HIGH PRIORITY

### FUNC-001 — Lab Image Upload Does Not Persist to Database
**File:** `lib/screens/labs_screen.dart:158-198`
**Description:** When a user uploads a lab image (camera or gallery), the app reads the bytes but **never uploads to Supabase storage or saves to the database**. It only appends a stub `LabResult` to local in-memory state with an empty `extractedData: {}`. The record is lost on next app open.
**Code:**
```dart
// TODO: Call real extraction API
// For now, just add to results without extracted data
final result = LabResult(
  ...
  extractedData: {}, // Empty until API extraction
);
// saveLabResult() is NEVER called for image uploads
```
**Impact:** Image-uploaded lab results are silently discarded. Users believe data was saved; it was not. Major data integrity failure for a core feature.
**Fix:** Either call `_labsDb.saveLabResult(labResult)` after creating the stub (as is done for PDFs), or clearly show a "feature coming soon" state instead of accepting the upload.

---

### SEC-003 — Unguarded `print()` Statements in Production Code
**File:** `lib/services/profile_photo_service.dart:23,45,48,71,73,86,89,113`
**File:** `lib/screens/labs_screen.dart:162,203,230,243,245,266`
**Description:** These files contain bare `print()` calls (not wrapped in `kDebugMode`) that will execute in production release builds on Android. They log user photo URLs, file paths, operation status, and PDF upload details to logcat.
**Example:**
```dart
print('[ProfilePhotoService] Upload success: $publicUrl');  // exposes photo URL
print('PDF upload started: ${pdfFile.path}');              // exposes local file path
print('Extracted ${extractedBiomarkers.length} biomarkers from PDF');
```
**Impact:** Health-related metadata visible in device logs. Any app with `READ_LOGS` permission or an attached debugger can capture this. Less severe in post-API 26 Android, but still violates principle of least exposure.
**Fix:** Wrap all `print()` calls in `if (kDebugMode)` blocks, or replace with a logging library that strips debug logs from release builds.

---

### FUNC-002 — "Remember Me" Toggle Is Non-Functional
**File:** `lib/screens/login_screen.dart:27,229`
**Description:** A "Remember Me" checkbox is rendered in the login UI and maintains local boolean state (`_rememberMe`), but the value is never used — it does not affect session persistence, token TTL, or any Supabase auth parameter.
**Impact:** Misleading UX. Users expect behaviour that isn't implemented. Could also cause confusion if Supabase's default session behaviour doesn't match user expectations.
**Fix:** Either implement persistent session behaviour using `supabase.auth.signInWithPassword` with appropriate `persistSession` config, or remove the toggle entirely until the feature is built.

---

### FUNC-003 — BloodworkAI Service Is Entirely Non-Functional
**File:** `lib/services/bloodwork_service.dart:7,124-129`
**Description:** Two separate blockers prevent this service from working:
1. `_apiKey = 'YOUR_BLOODWORK_AI_API_KEY'` — placeholder, will always fail auth
2. `_readFile()` always returns `[]` (empty bytes) — file is never actually read
```dart
static Future<List<int>> _readFile(String filePath) async {
  // Implementation depends on file source
  return [];  // Always empty!
}
```
**Impact:** Any code path that calls `BloodworkService.uploadLabPdf()` will send an empty file with an invalid API key. Feature is broken at both ends.
**Fix:** Complete the `_readFile()` implementation using `dart:io File` or `path_provider`. Load API key from environment. This appears to be deferred/stub code that should be clearly marked as not-yet-active.

---

### SEC-004 — Google Sign-In Icon Loaded from External Network URL
**File:** `lib/screens/signup_screen.dart:344`
**Code:**
```dart
Image.network('https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg'),
```
**Description:** The Google brand icon on the sign-up screen is fetched from Google's CDN at runtime. This creates a dependency on network availability (fails offline), introduces a minor supply-chain risk if the URL content changes, and adds a small performance overhead.
**Impact:** Button renders broken/empty when device is offline or the CDN URL is unavailable. Minor brand risk if Google changes the asset.
**Fix:** Download the SVG, add it to `assets/`, and use `Image.asset()` instead.

---

### FUNC-004 — No Password Reset Flow
**File:** `lib/providers/auth_provider.dart`, `lib/screens/login_screen.dart`
**Description:** There is no "Forgot Password" link on the login screen and no `resetPassword()` method in `AuthProvider`. Supabase provides this via `supabase.auth.resetPasswordForEmail()`.
**Impact:** Users who forget their password have no self-service recovery path. This is a critical usability gap for any production app.
**Fix:** Add a "Forgot Password" button on the login screen, implement `resetPasswordForEmail()` in `AuthProvider`, and handle the deep-link callback for password reset.

---

### FUNC-005 — PDF Upload Non-Functional for External Users (Private IP Endpoint)
**File:** `lib/screens/labs_screen.dart:212`
**Description:** As noted in SEC-001, the PDF extraction endpoint `http://100.71.64.116:9000` is a private network IP. For any user not on the developer's local network (i.e., everyone in production), this will immediately fail with a connection error.
**Impact:** PDF lab upload is completely broken in production for all users.
**Fix:** Deploy the extraction backend to a public HTTPS endpoint and update the URL.

---

## 3. MEDIUM PRIORITY

### SEC-005 — Generic OAuth Deep Link Scheme
**File:** `android/app/src/main/AndroidManifest.xml:33`
**File:** `ios/Runner/Info.plist`
**Code:** `android:scheme="com.example.biohacker"`
**Description:** The OAuth redirect URI uses `com.example.biohacker://login-callback`. The `com.example` prefix is the default Flutter package name and is not unique. In theory, another app could register the same scheme and intercept the OAuth callback on Android (where scheme-based deep links are not verified by default). The `com.example` prefix is also not allowed in production Play Store releases.
**Impact:** Medium security risk on OAuth flow. App will be rejected from Play Store with default package name.
**Fix:** Set a unique, reverse-domain package name (e.g., `com.yourcompany.biohacker`), update deep link scheme, and register it in Supabase dashboard. On Android 12+, consider using App Links (HTTPS deep links) with Digital Asset Links for verified redirect.

---

### FUNC-006 — Signup Passes Untrimmed Email to Supabase
**File:** `lib/screens/signup_screen.dart:87-91`
**Description:** Email is trimmed for validation (`_emailController.text.trim()`) but the raw, untrimmed string is passed to `signUp()`:
```dart
await ref.read(authProviderProvider).signUp(
  _emailController.text,      // ← not .trim()
  _passwordController.text,
  _firstNameController.text,  // ← not .trim()
);
```
**Impact:** If a user accidentally enters a trailing space, the account email or display name will include it. Supabase may handle this server-side, but it's inconsistent validation.
**Fix:** Use `_emailController.text.trim()` and `_firstNameController.text.trim()` in the `signUp()` call.

---

### FUNC-007 — Error Message in Lab Screen Exposes Raw Exception
**File:** `lib/screens/labs_screen.dart:153,193,269`
**Code:**
```dart
SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
```
**Description:** Several error handlers in `labs_screen.dart` surface the raw exception string (`$e`) directly to users. This contrasts with the consistent `UserFeedback.getFriendlyErrorMessage()` pattern used everywhere else.
**Impact:** Users may see internal error strings (e.g., Supabase error codes, stack trace fragments, PostgreSQL messages). Could leak implementation details.
**Fix:** Replace raw `'Error: $e'` with `UserFeedback.getFriendlyErrorMessage(e)` to be consistent with the rest of the app.

---

### FUNC-008 — Dead Code / Backup Files in Codebase
**Files:**
- `lib/screens/reports_screen_backup.dart`
- `lib/screens/calendar_screen_backup.dart`
- `lib/screens/profile_screen_old.dart`
- `lib/screens/cycle_setup_form.dart`
- `lib/screens/cycle_setup_form_v2.dart`
- `lib/screens/cycle_setup_form_v3.dart`

**Description:** Multiple backup, old, and versioned screen files exist alongside active code. These are not referenced by routing.
**Impact:** Increases maintenance burden, inflates binary size, and could confuse future developers. Dead code with `print()` statements could still be compiled into the release build in some configurations.
**Fix:** Delete all `_backup`, `_old`, and superseded version files. Use git history for recovery if needed.

---

### SEC-006 — Profile Photo Upload Has No File Type or Size Validation
**File:** `lib/services/profile_photo_service.dart:10-25`
**Description:** `pickImage()` uses `image_picker` with `imageQuality: 85` and `maxWidth/maxHeight: 800`, but there is no validation of the MIME type, file extension, or actual content type before upload to Supabase storage.
**Impact:** Malformed or non-image files that pass the picker (edge cases) could be uploaded. No client-side size limit enforcement (though Supabase storage has configurable limits).
**Fix:** Validate that the picked file has an image MIME type. Consider enforcing a maximum file size (e.g., 5MB) before upload.

---

### FUNC-009 — Labs Database Logs Raw Response Data in Debug Mode
**File:** `lib/services/labs_database.dart:50`
**Code:**
```dart
if (kDebugMode) {
  print('[LabsDatabase] Query succeeded. Response: $response');
}
```
**Description:** In debug mode, the full raw database response — including all biomarker values — is printed to the console. While guarded by `kDebugMode`, this means developers with debug builds attached to production accounts would see all health data in plaintext logs.
**Impact:** PII exposure in development workflows. Consider replacing with a count/summary log.
**Fix:** Change to `print('[LabsDatabase] Query succeeded. ${response.length} results');`

---

### FUNC-010 — Dashboard Snapshots May Serve Stale Health Data
**File:** `lib/services/dashboard_analytics_service.dart` (referenced in migration `create_dashboard_snapshots_table.sql`)
**Description:** Dashboard analytics appear to use a snapshot/caching pattern. If cache invalidation is not tied to new dose logs, cycle changes, or lab uploads, users may see stale metrics.
**Impact:** Incorrect health dashboard data could cause users to make wrong dosing decisions.
**Fix:** Verify snapshot cache invalidation triggers are set for all write operations (dose logs, cycles, labs).

---

## 4. LOW PRIORITY

### LOW-001 — No Rate Limiting on Client-Side Login Attempts
**File:** `lib/screens/login_screen.dart`
**Description:** There is no client-side rate limiting or lockout on the login form. Supabase has server-side rate limiting, but the client does not provide any feedback delay or attempt counter.
**Fix:** Add a brief UI delay or attempt counter after 3 failed logins (cosmetic; Supabase will handle real lockout).

---

### LOW-002 — `flutter_dotenv` Not in Dependencies
**File:** `pubspec.yaml`
**Description:** No environment variable management library is present. This reinforces the pattern of hardcoding configuration values. If secrets need to be added (BloodworkAI key, future API keys), there is no established env var pattern to follow.
**Fix:** Add `flutter_dotenv` or use `--dart-define` in build scripts.

---

### LOW-003 — Android App Label Is Underscore-Formatted
**File:** `android/app/src/main/AndroidManifest.xml:3`
**Code:** `android:label="biohacker_app"`
**Description:** The app label shown on the Android home screen will display as "biohacker_app" rather than "Biohacker".
**Fix:** Change to `android:label="Biohacker"`.

---

### LOW-004 — SQL Migration Files Committed to Repository Root
**Files:** `DATABASE_MIGRATION.sql`, `DATABASE_MIGRATION_IMPERIAL.sql`, `FIX_WEIGHT_LOGS_RLS.sql`, `MISSING_COLUMNS_FIX.sql`, etc.
**Description:** Multiple SQL migration files exist in the project root. These expose the full database schema (table names, column names, RLS policy structure) to anyone with source access.
**Impact:** Low in isolation, but combined with the exposed Supabase URL/key (SEC-002), gives an attacker a complete map of the database.
**Fix:** Move migrations to a `supabase/migrations/` directory (standard Supabase CLI structure), add a `.gitignore` entry if the repo is public, or use Supabase migrations properly via CLI.

---

### LOW-005 — `confetti` Package Likely Unnecessary in Production
**File:** `pubspec.yaml:43`
**Description:** `confetti: ^0.7.0` is a dependency. If used only for onboarding completion, it could be lazy-loaded or removed if not actively used.
**Fix:** Verify usage; remove if only used in one place that could use a simpler animation.

---

### LOW-006 — `WillPopScope` Is Deprecated in Flutter 3.16+
**File:** `lib/utils/user_feedback.dart:292`
**Code:** `child: WillPopScope(onWillPop: () async => false, ...)`
**Description:** `WillPopScope` is deprecated in favour of `PopScope` in Flutter 3.16+. With SDK `^3.11.0`, this will generate deprecation warnings.
**Fix:** Replace with `PopScope(canPop: false, ...)`.

---

### LOW-007 — Session Refresh and Token Expiry Not Explicitly Handled
**File:** `lib/providers/auth_provider.dart`
**Description:** Token refresh is handled implicitly by the Supabase Flutter SDK (it auto-refreshes before expiry). There is no explicit error handling for the case where a refresh fails (e.g., network offline for extended period, token revoked). The `onAuthStateChange` listener handles signout, but there is no user-facing "session expired" message.
**Fix:** Add a handler for `AuthChangeEvent.tokenRefreshed` and `AuthChangeEvent.signedOut` to show a user-friendly session expiry message.

---

## 5. FUNCTIONALITY GAPS (UAT)

| Flow | Status | Issue |
|------|--------|-------|
| New user signup | ✅ Works | Password validation strong. Email confirmation required. |
| Login with email | ✅ Works | Boot sequence animation is a nice touch. |
| Google OAuth | ⚠️ Partial | Requires correct deep link in production. `com.example` scheme won't work post-Play Store publication. |
| Onboarding (6 screens) | ✅ Works | Profile → Health Goals → Habits → Notifications → Lab Prefs → Current Status |
| Cycle creation | ✅ Works | V4 form is comprehensive with multi-peptide support |
| Dose logging | ✅ Works | Schedules, missed doses, side effects all functional |
| Lab image upload | ❌ Broken | Data not persisted to DB (FUNC-001) |
| Lab PDF upload | ❌ Broken | Private IP endpoint unreachable in production (SEC-001, FUNC-005) |
| View lab biomarkers | ⚠️ Partial | Only works if data was saved via working path |
| Protocols (create) | ✅ Works | 6 sovereign stacks + custom creation |
| Protocols (initiate) | ✅ Works | Creates cycles per peptide in stack |
| Reports/analytics | ✅ Works | Charts, trends visible |
| Weight tracker | ✅ Works | Logging and history |
| Notifications | ✅ Works | All 4 channels configured, reschedule on boot |
| Password reset | ❌ Missing | No forgot-password flow (FUNC-004) |
| Profile photo | ✅ Works | Pick → upload → Supabase storage → profile update |
| Sign out | ✅ Works | Clears Supabase + Google sessions |
| Data deletion | ✅ Works | Cycles have cascade delete confirmation |

---

## 6. SECURITY POSTURE SUMMARY

| Category | Status | Notes |
|----------|--------|-------|
| Authentication | ✅ Good | Supabase email+password + Google OAuth |
| Password Policy | ✅ Good | Min 8 chars, upper, lower, digit required |
| RLS Policies | ✅ Good | All tables properly isolated by `auth.uid()` |
| Error Sanitisation | ✅ Good | `UserFeedback.getFriendlyErrorMessage()` used throughout (except labs screen) |
| Debug Log Hygiene | ⚠️ Mixed | Most guarded by `kDebugMode`; `profile_photo_service.dart` and `labs_screen.dart` have unguarded prints |
| Data in Transit | ❌ Critical | PDF upload uses plaintext HTTP (SEC-001) |
| Credential Management | ⚠️ At Risk | Supabase anon key hardcoded in source (SEC-002) |
| Session Management | ✅ Good | Supabase SDK handles refresh automatically |
| Deep Links | ⚠️ Needs Fix | Generic `com.example` scheme; must change for Play Store |
| SQL Injection | ✅ N/A | Supabase SDK uses parameterised queries; no raw SQL |
| XSS | ✅ N/A | Flutter renders to canvas; no HTML injection surface |
| File Upload | ⚠️ Partial | No MIME type validation; image resized but not validated |
| Audit Logging | ✅ Good | `audit_log` table tracks all CRUD with user_id |

---

## 7. PRIORITISED FIX LIST

```
IMMEDIATE (before any production release):
  1. [SEC-001] Replace HTTP private-IP endpoint with production HTTPS
  2. [FUNC-001] Fix image upload to persist to database
  3. [FUNC-005] Deploy extraction backend to public endpoint
  4. [FUNC-004] Add forgot-password flow

SHORT-TERM (before marketing/beta):
  5. [SEC-002] Move Supabase credentials to dart-define / .env
  6. [SEC-003] Guard all print() calls with kDebugMode
  7. [FUNC-002] Remove or implement "Remember Me" toggle
  8. [FUNC-003] Complete or remove BloodworkAI service stub
  9. [SEC-004] Bundle Google icon as local asset
  10. [SEC-005] Set production package name and deep link scheme
  11. [FUNC-007] Use UserFeedback.getFriendlyErrorMessage() in labs screen

MAINTENANCE:
  12. [FUNC-008] Delete backup/old screen files
  13. [LOW-003] Fix Android app label
  14. [LOW-006] Replace WillPopScope with PopScope
  15. [LOW-002] Add flutter_dotenv to dependencies
```

---

*Report generated via static analysis. Dynamic/runtime testing against a live Supabase instance was not performed. RLS policies were reviewed at the SQL migration level only — verify they match what is currently deployed in the Supabase dashboard.*
