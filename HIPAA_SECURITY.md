# HIPAA Security Implementation

This document describes the HIPAA-compliant security features implemented in the Biohacker Flutter app.

## Features Implemented

### 1. Session Timeout (30 minutes)

**Location:** `lib/services/session_manager.dart`

- Tracks user activity (taps, scrolls, navigation)
- Auto-logout after 30 minutes of inactivity
- Shows warning dialog at 28 minutes ("Session expiring in 2 minutes")
- Stores last activity timestamp in secure storage
- Clears all local data on timeout

**Integration:**
- `AuthProvider` initializes session manager after login
- `HomeScreen` wraps UI in `GestureDetector` to track activity
- Activity tracked on all user interactions

**Testing:**
- Adjust `HipaaConfig.sessionTimeout` to `Duration(minutes: 2)` for faster testing
- Adjust `HipaaConfig.warningThreshold` to `Duration(minutes: 1, seconds: 30)` for 30s warning

### 2. Biometric Authentication

**Location:** `lib/services/biometric_auth_service.dart`

- Supports fingerprint, Face ID, and device credentials
- Optional feature (user can enable/disable in Profile settings)
- Prompts for biometric on app launch if enabled
- Automatic fallback to PIN/password if biometric unavailable
- Preference stored in secure storage

**Integration:**
- `OnboardingCheck` in `main.dart` checks biometric setting on app launch
- `ProfileScreen` has toggle to enable/disable biometric authentication
- User must verify biometric before enabling the feature

**Platform Permissions:**
- **Android:** `USE_BIOMETRIC`, `USE_FINGERPRINT` in AndroidManifest.xml
- **iOS:** `NSFaceIDUsageDescription` in Info.plist

### 3. Data Encryption

**Location:** `lib/services/secure_storage_service.dart`

**Secure Storage (flutter_secure_storage):**
- Session tokens
- Biometric preference
- HIPAA acknowledgment
- Last activity timestamp

**Platform-specific encryption:**
- **iOS:** Keychain with `first_unlock` accessibility
- **Android:** KeyStore with encrypted shared preferences

**Supabase Encryption:**
- Data encrypted at rest (AES-256)
- Data encrypted in transit (TLS 1.3)
- Verify in Supabase dashboard: Settings → Database → Encryption

**What's encrypted:**
- All user profile data (age, weight, health metrics)
- Peptide dosing logs
- Lab results and PDF uploads
- Cycle tracking data
- Session authentication tokens

**Migration from SharedPreferences:**
- Session tokens moved to secure storage
- Biometric preference in secure storage
- Other preferences remain in SharedPreferences (non-sensitive data)

### 4. HIPAA Notice Screen

**Location:** `lib/screens/hipaa_notice_screen.dart`

- Shown on first app launch (before login)
- Legal disclaimer covering:
  - Data collection practices
  - Security measures (encryption, timeout, biometric)
  - User rights (access, modify, delete, export)
  - Security best practices
  - Data retention policy
  - Contact information
- "I acknowledge" checkbox required to continue
- Acknowledgment timestamp stored in secure storage
- Re-show on major privacy policy updates (update `HipaaConfig.hipaaNoticeVersion`)

## Configuration

**File:** `lib/config/hipaa_config.dart`

```dart
class HipaaConfig {
  // Production: 30 minutes
  // Testing: 2 minutes
  static const Duration sessionTimeout = Duration(minutes: 30);
  
  // Production: 28 minutes (2 min warning)
  // Testing: 1.5 minutes (30s warning)
  static const Duration warningThreshold = Duration(minutes: 28);
  
  // HIPAA notice version (increment on privacy policy updates)
  static const String hipaaNoticeVersion = '1.0';
  static const String hipaaNoticeLastUpdated = '2026-03-26';
}
```

## Testing Checklist

### Session Timeout
- [ ] Set `HipaaConfig.sessionTimeout` to `Duration(minutes: 2)`
- [ ] Login and wait 1.5 minutes without interaction
- [ ] Warning dialog appears at 1.5 minutes
- [ ] "Continue Session" button extends session
- [ ] Wait another 30 seconds → auto-logout
- [ ] Verify all secure storage cleared on logout

### Biometric Authentication
- [ ] Enable biometric in Profile → Security
- [ ] Verify biometric prompt appears on app launch
- [ ] Test successful authentication (proceed to home)
- [ ] Test failed authentication (logout user)
- [ ] Disable biometric → verify no prompt on next launch
- [ ] Test on device without biometric hardware → toggle hidden

### HIPAA Notice
- [ ] Fresh install → HIPAA notice appears before login
- [ ] Cannot proceed without checking "I acknowledge"
- [ ] After acknowledgment → login screen appears
- [ ] Subsequent logins → HIPAA notice does not appear
- [ ] Update `HipaaConfig.hipaaNoticeVersion` → notice re-appears (future feature)

### Data Encryption
- [ ] Login and create test data (dosing log, lab result)
- [ ] Use `adb shell` or device file explorer
- [ ] Verify session token NOT in SharedPreferences XML
- [ ] Verify secure storage encrypted (iOS Keychain, Android KeyStore)
- [ ] Check Supabase dashboard → Database encryption enabled

## Production Deployment

Before launching to production:

1. **Reset session timeout to production values:**
   ```dart
   static const Duration sessionTimeout = Duration(minutes: 30);
   static const Duration warningThreshold = Duration(minutes: 28);
   ```

2. **Update HIPAA notice contact emails:**
   - Replace `privacy@biohacker.app` with real email
   - Replace `security@biohacker.app` with real email

3. **Verify Supabase encryption:**
   - Dashboard → Settings → Database
   - Confirm "Encryption at Rest" enabled
   - Confirm SSL/TLS enabled for connections

4. **Add data breach notification system:**
   - Implement breach detection
   - User notification via email
   - Compliance reporting (required by HIPAA)

5. **Business Associate Agreement (BAA):**
   - Sign BAA with Supabase (if handling PHI)
   - Sign BAA with any third-party services

6. **Security audit:**
   - Penetration testing
   - Code review
   - Compliance review by legal team

## HIPAA Compliance Notes

**Covered entities:**
- This app is intended for individual use (not a covered entity)
- If used by healthcare providers → requires BAA

**Technical safeguards implemented:**
- Access control (biometric, password)
- Audit controls (session tracking, activity logs)
- Integrity controls (encryption at rest and in transit)
- Transmission security (TLS 1.3)

**Administrative safeguards needed:**
- Security training for development team
- Incident response plan
- Risk assessment documentation

**Physical safeguards:**
- Device-level security (biometric, PIN)
- User responsibility (keep device secure)

## Support

For security questions: security@biohacker.app  
For privacy questions: privacy@biohacker.app

---

**Last updated:** 2026-03-26  
**Version:** 1.0
