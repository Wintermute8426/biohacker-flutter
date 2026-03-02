# Biohacker Flutter — CI/CD Pipeline Guide

## Overview

This document describes the complete process for building, testing, and distributing the Biohacker Flutter app.

**Workflow:**
1. Push code to GitHub (`main` branch)
2. GitHub Actions automatically builds APK
3. Download APK from Actions artifacts
4. Install on your phone and test
5. When ready: sign and submit to Play Store

---

## Build Process (GitHub Actions)

### What Happens Automatically

Every push to `main` triggers a build that:

1. **Checks out your code** — pulls latest from GitHub
2. **Sets up Flutter 3.41.2** — installs on Ubuntu runner with caching
3. **Verifies installation** — runs `flutter doctor` to confirm everything works
4. **Gets dependencies** — runs `flutter pub get`
5. **Analyzes code** — checks for errors with `flutter analyze`
6. **Builds APKs** — creates:
   - **Split APKs** (3 files optimized for different phone architectures)
   - **Release APK unsigned** (for manual signing and Play Store submission)

### Build Triggers

The workflow runs automatically on:
- **Every push to `main`** — enables continuous delivery
- **Manual trigger** — go to Actions tab → "Run workflow" button

### What Gets Built

| Output | Purpose | Architecture |
|--------|---------|--------------|
| `app-armeabi-v7a-release.apk` | 32-bit phones (older devices) | ARM 32-bit |
| `app-arm64-v8a-release.apk` | 64-bit phones (most modern devices) | ARM 64-bit |
| `app-x86_64-release.apk` | Android emulator or x86 tablets | x86 64-bit |
| `app-release.apk` | Universal APK (larger file, all architectures) | Universal |

**Recommendation:** Use the `arm64-v8a` version for your phone (most modern Android devices are 64-bit).

---

## Download APK for Testing

### Step 1: Go to GitHub Actions

1. Visit: https://github.com/Wintermute8426/biohacker-flutter/actions
2. Click the **latest green checkmark** build (Build APK)
3. Scroll down to **Artifacts** section

### Step 2: Download APK

- For **testing on your phone**: Download `biohacker-apk-artifacts` → extract → use the **`app-arm64-v8a-release.apk`** file
- For **Play Store submission**: Download `biohacker-apk-release-unsigned`

### Step 3: Install on Phone

```bash
# Via ADB (if you have Android SDK installed)
adb install -r app-arm64-v8a-release.apk

# Or: Manually transfer APK and tap to install
# - Email yourself the file
# - Download on phone
# - Tap to install
# - Allow installation from unknown sources when prompted
```

---

## Testing Checklist

After installing on your phone, verify:

- [ ] **App opens** without crashes
- [ ] **Login works** (test with existing account)
- [ ] **Sign up works** (create test account)
- [ ] **Supabase connection** works (can see data from database)
- [ ] **Navigation** works (can move between Cycles, Labs, Settings)
- [ ] **Add peptide** feature works
- [ ] **UI renders properly** (colors, fonts, layout)
- [ ] **No crashes** during basic usage

If any issues: screenshot the error and send to me.

---

## Signing for Google Play Store

### When You're Ready to Submit

The current builds are **unsigned**. To submit to Play Store, you need:

1. **Create a signing keystore** (one-time only)
2. **Add credentials to GitHub Secrets**
3. **Update workflow** to sign automatically

### Step 1: Create Upload Keystore (One-time)

On your machine (Windows, Mac, or Linux):

```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

This creates `upload-keystore.jks`. Keep this file **private** — don't commit to Git.

**You'll be asked for:**
- Keystore password
- Key password
- Name, organization, etc.

### Step 2: Add to GitHub Secrets

1. Go to: https://github.com/Wintermute8426/biohacker-flutter/settings/secrets/actions
2. Create new secrets:
   - `KEYSTORE_BASE64`: (base64 encode the .jks file)
   - `KEYSTORE_PASSWORD`: (the password from step 1)
   - `KEY_ALIAS`: `upload`
   - `KEY_PASSWORD`: (same as keystore password from step 1)

To encode keystore:
```bash
# On Mac/Linux
base64 upload-keystore.jks | tr -d '\n'

# On Windows (PowerShell)
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes("upload-keystore.jks"))
```

### Step 3: Update Workflow (When Ready)

I'll update the GitHub Actions workflow to sign automatically once you have the keystore configured.

---

## Troubleshooting

### Build Failed: "Permission denied"

This happens on GitHub's servers when permissions aren't set correctly. Solution: Check that `key.properties` has correct path to keystore file.

### Build Failed: "AndroidManifest.xml error"

**We just fixed this:** Added `<uses-permission android:name="android.permission.INTERNET" />` for Supabase.

### APK Won't Install: "App not installed"

Usually means:
- Phone architecture doesn't match APK architecture
- Phone has older Android version than `minSdk` in `pubspec.yaml`
- Storage is full

**Try:** Install the `app-release.apk` (universal) instead. It's larger but works on all phones.

### App Crashes on Launch: "Supabase Connection Failed"

Check that:
- Phone has internet connection (WiFi or mobile data)
- Supabase URL is correct in `lib/main.dart`
- Supabase project is active (check dashboard.supabase.com)

---

## File Locations

**On GitHub:**
- Workflow file: `.github/workflows/build.yml`
- Source code: `lib/` directory
- Android config: `android/` directory
- Dependencies: `pubspec.yaml`

**In Actions artifacts:**
- Debug APKs: `build/app/outputs/flutter-apk/` (all 3 split versions)
- Release APK: `build/app/outputs/flutter-apk/app-release.apk`

---

## Command Reference (If Building Locally)

For reference only — you shouldn't need to do this, but here's what the workflow runs:

```bash
# Get Flutter
flutter pub get

# Check for errors
flutter analyze

# Build split APKs (optimized for each phone architecture)
flutter build apk --split-per-abi

# Build single universal APK (all architectures in one file)
flutter build apk --release

# Build signed release APK (after keystore is configured)
flutter build apk --release --sign-release
```

---

## FAQ

**Q: How often does it build?**
A: Every time you push to `main`. If you don't want automatic builds, use manual trigger (`workflow_dispatch`).

**Q: Can I test on Android 16 (my phone)?**
A: Yes. The app targets Android 16+. Minimum is defined by Flutter's defaults (usually API 21+).

**Q: How long does a build take?**
A: ~8-12 minutes on GitHub Actions (first run caches dependencies for faster builds).

**Q: Can I use the APK on multiple phones?**
A: Yes, the APK works on any Android phone with the same architecture (or universal APK works on all).

**Q: Do I need a Google Play Store account yet?**
A: Not until submission. You can test with the unsigned APK indefinitely.

**Q: What's the difference between unsigned and signed?**
A: **Unsigned** = fine for testing. **Signed** = required for Play Store. We'll handle signing when you're ready to submit.

---

## Next Steps

1. **Push your changes** to GitHub (I've updated the workflow)
2. **Go to Actions** and watch the build
3. **Download the APK** when it completes
4. **Install on your phone**
5. **Test all features**
6. **Report any issues**

Once testing passes, we'll move to Play Store submission.

---

**Build status:** [View GitHub Actions](https://github.com/Wintermute8426/biohacker-flutter/actions)
