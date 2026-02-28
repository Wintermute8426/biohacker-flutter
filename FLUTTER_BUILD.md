# Biohacker Flutter - Build & Run Guide

## ✅ What's Built

**Complete Flutter MVP** ready to test:
- ✅ Supabase auth (sign up, login, logout)
- ✅ 5 screens (Login, Dashboard, Cycles, Labs, Settings)
- ✅ State management with Provider
- ✅ Wintermute cyberpunk design (cyan/black/green)
- ✅ Android 16 compatible
- ✅ iOS compatible

---

## 🚀 Quick Start (Windows PC)

### Prerequisites
- Flutter SDK installed: https://flutter.dev/docs/get-started/install
- Android Studio OR Android SDK set up (for emulator/APK)

### Step 1: Clone & Install
```bash
cd C:\Users\ebbad\Downloads
git clone https://github.com/Wintermute8426/biohacker-flutter.git
cd biohacker-flutter
flutter pub get
```

### Step 2: Run on Emulator
```bash
flutter run
```

This launches the app on your Android emulator or connected device with **hot reload** (changes appear instantly without rebuilding).

### Step 3: Test
1. Sign up: test@biohacker.com / TestPass123
2. See Dashboard with empty cycles
3. Go to Cycles tab → create a cycle
4. Test all tabs (Dashboard, Cycles, Labs, Settings)

---

## 📱 Build APK for Android Phone

```bash
flutter build apk --release
```

APK will be at: `build/app/outputs/flutter-app/release/app-release.apk`

Copy to phone and install.

---

## 🎯 Hot Reload (Development)

**Every change is live:**
1. Edit a file in `lib/`
2. Press `r` in terminal
3. App reloads instantly (no rebuild)

This makes iteration **super fast**.

---

## 📁 Project Structure

```
lib/
├── main.dart              # App entry point
├── providers/
│   └── auth_provider.dart # Auth state
├── screens/
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── dashboard_screen.dart
│   ├── cycles_screen.dart
│   ├── labs_screen.dart
│   └── settings_screen.dart
└── theme/
    └── colors.dart        # Wintermute cyberpunk colors
```

---

## 🔧 Next: Expand Features

Once this MVP is working:

1. **Add Cycle Creation** (Cycles tab)
   - Modal form with peptide selection
   - Save to Supabase `user_cycles` table

2. **Add Lab Results** (Labs tab)
   - Manual entry form
   - PDF upload with AI extraction

3. **Add Reminders** (Smart notifications)
   - Calendar integration
   - Cycle end notifications

---

## 🐛 Troubleshooting

**"Flutter command not found"**
- Add Flutter to PATH: https://flutter.dev/docs/get-started/install

**"Android SDK not found"**
- Set ANDROID_SDK_ROOT environment variable
- Or use `flutter doctor -v` to see what's needed

**App crashes on startup**
- Check Supabase credentials in `lib/main.dart`
- Run `flutter doctor` to verify setup

**Hot reload not working**
- Kill the app and run `flutter run` again

---

## 🚀 Autonomous Workflow

**For building independently:**
1. Edit screens/providers in `lib/`
2. Use hot reload to test instantly
3. Commit changes: `git add . && git commit -m "..."`
4. Push: `git push`
5. Build APK: `flutter build apk --release`

No Expo, no EAS, no complexity. Pure Flutter toolchain. 🧊

---

## Resources

- Flutter docs: https://flutter.dev/docs
- Provider state management: https://pub.dev/packages/provider
- Supabase Flutter: https://supabase.com/docs/reference/flutter/introduction

Ready to test? Run `flutter run` on your Windows PC! 🚀
