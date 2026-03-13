# DEBUG: Build Verification for Matte Styling

**Commit:** 6776654 (debug version indicators)
**Parent:** 736e8bc (matte styling implementation)
**Date:** 2026-03-13

## PROBLEM

User reports last 4 builds show **NO visual changes** to reports/labs/protocols/research screens:
- Screens still look **bright** (not matte)
- Expected: 0.15 opacity backgrounds, 0.2 opacity borders
- Actual: Appears unchanged from previous builds

## CODE VERIFICATION ✅

All code has CORRECT matte values:

### WintermmuteStyles (lib/theme/wintermute_styles.dart)
```dart
// Line 152-158: Standard card
static BoxDecoration cardDecoration = BoxDecoration(
  color: AppColors.surface.withOpacity(0.15),  // ✅ MATTE
  border: Border.all(
    color: colorCyan.withOpacity(0.2),         // ✅ MATTE
    width: 1,
  ),
  borderRadius: BorderRadius.circular(4),
);
```

### Screen Files
All four screens use WintermmuteStyles or explicit matte values:
- ✅ reports_screen.dart - Uses WintermmuteStyles.cardDecoration
- ✅ labs_screen.dart - Uses `withOpacity(0.2)` borders
- ✅ protocols_screen.dart - Uses WintermmuteStyles.cardDecoration
- ✅ research_screen.dart - Uses WintermmuteStyles.cardDecoration

### No Conflicts Found
- ❌ No duplicate screen files (only reports_screen_backup.dart exists)
- ❌ No theme overrides in main.dart that would override BoxDecoration
- ✅ All imports point to correct screen files

## HYPOTHESIS

One of these issues:

### 1. **Flutter Build Cache** (MOST LIKELY)
- Flutter is using cached styling from old build
- APK doesn't reflect code changes despite successful build
- **Solution:** Clean rebuild required

### 2. **User Testing Wrong APK**
- User downloaded wrong APK file
- Testing old build from previous commit
- **Solution:** Verify APK filename/version

### 3. **Hot Reload Not Working**
- Changes not applied during development
- Requires full app restart
- **Solution:** Full rebuild + reinstall

## DEBUG SOLUTION: Version Indicators

**Added visual proof to screen titles:**

```dart
// BEFORE
'REPORTS'
'LABS'
'PROTOCOLS'
'RESEARCH'

// AFTER (commit 6776654)
'REPORTS v736e8bc'
'LABS v736e8bc'
'PROTOCOLS v736e8bc'
'RESEARCH v736e8bc'
```

## VERIFICATION STEPS FOR USER

1. **Build new APK** from commit `6776654`
2. **Install on device** (full reinstall, not update)
3. **Check screen titles** - should show `v736e8bc`
4. **If version shows:**
   - Version IS visible → Code is loading, styling should be matte
   - Version NOT visible → Still running old build, cache issue confirmed

## NEXT STEPS IF VERSION SHOWS BUT STILL BRIGHT

If user sees `v736e8bc` but screens are STILL bright:

1. **Add temporary debug colors** - Make backgrounds BRIGHT RED (0.9 opacity)
2. **Check for platform-specific rendering issues** - Android might render opacity differently
3. **Check device settings** - Developer options, GPU rendering
4. **Add logging** - Print styling values at runtime to verify they're being read correctly

## BUILD COMMANDS

To ensure clean rebuild:

```bash
# Clean all caches
flutter clean

# Get dependencies
flutter pub get

# Build fresh APK
flutter build apk --release

# Output location
build/app/outputs/flutter-apk/app-release.apk
```

## FILES CHANGED

This debug commit (6776654):
- lib/screens/reports_screen.dart (line 197)
- lib/screens/labs_screen.dart (line 258)
- lib/screens/protocols_screen.dart (line 731)
- lib/screens/research_screen.dart (line 763)

## CONCLUSION

The code is **100% correct** with matte values. The issue is either:
1. Build cache not reflecting changes
2. Wrong APK being tested
3. Platform rendering issue (unlikely)

The version indicators will **definitively prove** which build is running.
