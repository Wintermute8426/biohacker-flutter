# HIPAA Security Testing Guide

## Quick Test (2-minute session timeout)

### Setup for Testing
1. Edit `lib/config/hipaa_config.dart`:
   ```dart
   static const Duration sessionTimeout = Duration(minutes: 2);
   static const Duration warningThreshold = Duration(minutes: 1, seconds: 30);
   ```

2. Run the app:
   ```bash
   flutter run
   ```

### Test Scenarios

#### 1. HIPAA Notice (First Launch)
- [ ] Fresh install or clear app data
- [ ] Launch app
- [ ] HIPAA notice screen appears
- [ ] Try to continue without checking box → button disabled
- [ ] Check "I acknowledge" → button enabled
- [ ] Click "Continue" → proceeds to login

#### 2. Session Timeout
- [ ] Login to app
- [ ] Navigate to home screen
- [ ] Wait 1.5 minutes without interaction
- [ ] Warning dialog appears: "Session expiring in 2 minutes"
- [ ] Click "Continue Session" → dialog closes, session extended
- [ ] Wait 1.5 minutes again → warning dialog appears
- [ ] Click "Logout" OR wait 30 seconds → auto-logout
- [ ] Verify redirected to login screen

#### 3. Biometric Authentication
**Prerequisites:** Device with fingerprint or Face ID

- [ ] Login and navigate to Profile screen
- [ ] Scroll to "Security" section
- [ ] Toggle "Biometric Authentication" ON
- [ ] Biometric prompt appears immediately
- [ ] Authenticate successfully → toggle stays ON, success message
- [ ] Close app completely
- [ ] Reopen app → biometric prompt appears before home screen
- [ ] Authenticate successfully → proceeds to home
- [ ] Go to Profile → Toggle biometric OFF
- [ ] Close and reopen app → no biometric prompt

**Failure Test:**
- [ ] Enable biometric
- [ ] Close app
- [ ] Reopen app → biometric prompt appears
- [ ] Cancel or fail authentication 3 times
- [ ] App logs out and returns to login screen

#### 4. Secure Storage Verification

**Android (ADB):**
```bash
adb shell
run-as com.biohacker.app
cd shared_prefs
cat FlutterSharedPreferences.xml
```
- [ ] Verify NO session tokens visible in plain text
- [ ] Verify NO biometric preference visible

**iOS (Xcode):**
- Open Xcode → Devices and Simulators
- Select device → Download Container
- Browse app data
- [ ] Verify secure storage in Keychain (encrypted)

#### 5. Activity Tracking
- [ ] Login and go to home screen
- [ ] Wait 1 minute
- [ ] Tap anywhere or scroll → session timer resets
- [ ] Wait 1.5 minutes → warning should appear (not 30s from now)
- [ ] Navigate between tabs → session timer resets

## Automated Tests (Future)

Create widget tests for:
- HIPAA notice checkbox validation
- Session timeout warning dialog
- Biometric prompt flow
- Secure storage encryption

## Performance Test

- [ ] Session tracking doesn't impact app performance
- [ ] Activity recording is non-blocking (<1ms overhead)
- [ ] No memory leaks from timer cleanup

## Reset for Production

After testing, restore production values:

```dart
// lib/config/hipaa_config.dart
static const Duration sessionTimeout = Duration(minutes: 30);
static const Duration warningThreshold = Duration(minutes: 28);
```

## Known Issues / Future Enhancements

- [ ] Re-show HIPAA notice when version changes (not implemented yet)
- [ ] Audit log for security events (login, logout, biometric changes)
- [ ] Admin dashboard for monitoring session timeouts
- [ ] Data breach notification system
- [ ] Two-factor authentication (TOTP)
