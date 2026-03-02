# Build Verification Checklist

## Pre-Build Verification (✅ Completed)

### Code Structure
- [x] **Flutter project exists** at `/home/wintermute/.openclaw/workspace/biohacker-flutter`
- [x] **All Dart files present**: main.dart, screens, providers, theme/colors.dart
- [x] **pubspec.yaml exists** with correct dependencies (supabase_flutter, provider, google_fonts, intl)
- [x] **Android config present**: build.gradle.kts, AndroidManifest.xml, gradle.properties

### Android Configuration
- [x] **Android namespace** correct: `com.biohacker.biohacker_app`
- [x] **Min SDK configured**: Flutter defaults (API 21+)
- [x] **Target SDK configured**: Flutter defaults
- [x] **Internet permission added** for Supabase connectivity
- [x] **Android Manifest is valid** XML with proper structure

### Supabase Integration
- [x] **Supabase URL correct**: `https://dfiewtwbxqfrrmyiqhqo.supabase.co`
- [x] **Supabase anon key correct**: `sb_publishable_swGU8s8l_FgSo2GuKbGkfA_00Wd9zIV`
- [x] **Auth provider implemented**: `AuthProvider` with login/signup logic
- [x] **Internet permission in AndroidManifest**: Required for API calls

### GitHub Actions Workflow
- [x] **Workflow file exists**: `.github/workflows/build.yml`
- [x] **Flutter action version correct**: `subosito/flutter-action@v2`
- [x] **Flutter version pinned**: 3.41.2 (stable)
- [x] **Build steps correct**:
  - ✅ Checkout code
  - ✅ Install Flutter
  - ✅ Get dependencies
  - ✅ Analyze code
  - ✅ Build split APKs
  - ✅ Upload artifacts
  - ✅ Build unsigned release APK

### Documentation
- [x] **CI/CD Guide created**: Explains workflow, testing, signing process
- [x] **Artifact retention**: 30 days for debug, 7 days for release
- [x] **Caching enabled**: Speeds up subsequent builds

---

## Build Output Expected

When the workflow completes, you will find:

### Debug Artifacts (from split-per-abi build)
Located in: `biohacker-apk-artifacts` artifact

- `app-armeabi-v7a-release.apk` (32-bit, older phones)
- `app-arm64-v8a-release.apk` (64-bit, most phones) **← Use this for your Android 16 phone**
- `app-x86_64-release.apk` (x86, emulators/tablets)

**File size**: ~50-60 MB each

### Release APK (unsigned)
Located in: `biohacker-apk-release-unsigned` artifact

- `app-release.apk` (universal, all architectures)

**File size**: ~90-100 MB

---

## Next Steps (For You)

1. **Check GitHub Actions**: https://github.com/Wintermute8426/biohacker-flutter/actions
2. **Wait for build to complete** (~10 minutes)
3. **Download `app-arm64-v8a-release.apk`** from artifacts
4. **Install on your phone**:
   - Email file to yourself, or
   - Use ADB: `adb install -r app-arm64-v8a-release.apk`, or
   - Transfer via USB
5. **Test**:
   - App opens without crash
   - Login/signup works
   - Supabase connection works (can see data)
   - Navigation between screens works
   - UI looks correct

6. **Report back with**:
   - Any crashes (screenshot error)
   - Any missing features
   - UI feedback (colors, spacing, fonts)
   - Functionality issues

---

## Build Triggers

The workflow automatically builds when:
- ✅ Code pushed to `main` branch
- ✅ Manual trigger via Actions page (Re-run jobs button)

To manually trigger:
1. Go to https://github.com/Wintermute8426/biohacker-flutter/actions
2. Click "Build APK" workflow on the left
3. Click "Run workflow" button
4. Select "main" branch
5. Click green "Run workflow" button

---

## Troubleshooting During Build

### Build Failed at "Analyze code" step
- Check `.flutter_plugins_dependencies` file (auto-generated, should be fixed)
- Usually transient, retry the build

### Build Failed at "Build APK" step
- Check that pubspec.yaml has correct syntax
- Ensure all Dart files compile without errors
- Run locally: `flutter pub get && flutter analyze` for more details

### Artifacts not showing up
- Build might still be running (wait ~10 minutes)
- Check Actions log for errors
- Reload the Actions page

---

## What's Installed for You

The GitHub Actions workflow **automatically installs**:

- ✅ Flutter 3.41.2 (stable channel)
- ✅ Dart SDK (bundled with Flutter)
- ✅ Android SDK (for building APK)
- ✅ Gradle (Android build tool)
- ✅ JDK (Java runtime for Gradle)

You **don't need** anything installed locally on the Linux server or your PC.

---

## Signing for Play Store (Later)

When ready to submit to Google Play Store:

1. Create upload keystore (one-time):
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Add keystore to GitHub Secrets (see CI_CD_GUIDE.md for details)

3. I'll update workflow to sign automatically

4. Submit signed APK to Play Store

---

## File Reference

| File | Purpose | Status |
|------|---------|--------|
| `.github/workflows/build.yml` | GitHub Actions workflow | ✅ Updated |
| `lib/main.dart` | Entry point with Supabase init | ✅ Correct |
| `android/app/src/main/AndroidManifest.xml` | Android manifest with permissions | ✅ Updated |
| `pubspec.yaml` | Dependencies and version | ✅ Correct |
| `CI_CD_GUIDE.md` | Complete build/test/submit guide | ✅ Created |
| `BUILD_VERIFICATION.md` | This file | ✅ Complete |

---

## Ready to Build

**Status: ✅ READY**

All components are configured correctly. The next build will:
1. Download Flutter 3.41.2 on GitHub's servers
2. Compile your Dart code to native Android
3. Build APKs for arm64 (and other architectures)
4. Upload artifacts for download

**You can now:**
1. Push code to `main` branch (already done)
2. Monitor at https://github.com/Wintermute8426/biohacker-flutter/actions
3. Download APK when complete
4. Install on your phone
5. Test and report back

---

Last verified: 2026-03-02
