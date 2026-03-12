# Cyberpunk Effects Visual Guide

Quick reference for where effects are applied and their settings.

## Effect Distribution Map

```
┌──────────────────────────────────────────────────────────┐
│                    BIOHACKER APP                         │
│              Cyberpunk Effects Status                    │
└──────────────────────────────────────────────────────────┘

🌆 = City Background Present
💧 = Rain Effect Present
🔆 = High Intensity
🔅 = Low Intensity
❌ = No Effects

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  SCREEN              │  CITY  │  RAIN  │  INTENSITY   ┃
┣━━━━━━━━━━━━━━━━━━━━━━╋━━━━━━━━╋━━━━━━━━╋━━━━━━━━━━━━━━┫
┃  Login Screen        │   🌆   │   💧   │     🔆 HIGH   ┃
┃  Signup Screen       │   🌆   │   💧   │     🔆 HIGH   ┃
┃  Dashboard           │   🌆   │   💧   │     🔅 LOW    ┃
┃  Profile Screen      │   🌆   │   💧   │     🔅 LOW    ┃
┃  Calendar            │   ❌   │   ❌   │     NONE      ┃
┃  Cycles              │   ❌   │   ❌   │     NONE      ┃
┃  Protocols           │   ❌   │   ❌   │     NONE      ┃
┃  Research            │   ❌   │   ❌   │     NONE      ┃
┃  Labs                │   ❌   │   ❌   │     NONE      ┃
┗━━━━━━━━━━━━━━━━━━━━━━┻━━━━━━━━┻━━━━━━━━┻━━━━━━━━━━━━━━┛
```

## Effect Settings by Screen

### 🔆 HIGH INTENSITY (Login/Signup)

**Purpose**: Set the mood, create atmosphere
**User Context**: First impression, welcome experience
**Settings**:
```dart
CityBackground(
  enabled: true,
  animateLights: true,
  opacity: 0.5,        // More visible
)

CyberpunkRain(
  enabled: true,
  particleCount: 60,   // More particles
  opacity: 0.35,       // More visible
)
```

**Visual Impact**: Strong, atmospheric, mood-setting
**Rationale**: These screens are brief and immersive effects enhance experience

---

### 🔅 LOW INTENSITY (Dashboard/Profile)

**Purpose**: Subtle ambiance, doesn't interfere with content
**User Context**: High engagement, reading data
**Settings**:
```dart
CityBackground(
  enabled: true,
  animateLights: true,
  opacity: 0.3,        // Subtle
)

CyberpunkRain(
  enabled: true,
  particleCount: 40,   // Fewer particles
  opacity: 0.25,       // Subtle
)
```

**Visual Impact**: Subtle, non-distracting, background ambiance
**Rationale**: User needs to focus on important data and interactions

---

### ❌ NO EFFECTS (Calendar/Cycles/Protocols/Research/Labs)

**Purpose**: Maximum clarity for data-heavy screens
**User Context**: Information consumption, decision making
**Settings**: None applied

**Visual Impact**: Clean, clear, focused
**Rationale**: These screens show complex data that needs full user attention

## Adding Effects to New Screens

### Template: High Intensity
```dart
body: Stack(
  children: [
    // City background layer
    const Positioned.fill(
      child: CityBackground(
        enabled: true,
        animateLights: true,
        opacity: 0.5,
      ),
    ),
    // Rain effect layer
    const Positioned.fill(
      child: CyberpunkRain(
        enabled: true,
        particleCount: 60,
        opacity: 0.35,
      ),
    ),
    // Your screen content
    YourContent(),
  ],
)
```

### Template: Low Intensity
```dart
body: Stack(
  children: [
    // City background layer
    const Positioned.fill(
      child: CityBackground(
        enabled: true,
        animateLights: true,
        opacity: 0.3,
      ),
    ),
    // Rain effect layer
    const Positioned.fill(
      child: CyberpunkRain(
        enabled: true,
        particleCount: 40,
        opacity: 0.25,
      ),
    ),
    // Your screen content
    YourContent(),
  ],
)
```

### Import Statement
```dart
import '../widgets/cyberpunk_rain.dart';
import '../widgets/city_background.dart';
```

## Intensity Guidelines

### Choose HIGH intensity for:
- ✅ Welcome/onboarding screens
- ✅ Authentication screens
- ✅ Splash screens
- ✅ Marketing/promotional screens
- ✅ Empty states with minimal content
- ✅ Success/celebration screens

### Choose LOW intensity for:
- ✅ Dashboard/home screens
- ✅ Profile/settings screens
- ✅ List views with some content
- ✅ Forms with moderate complexity
- ✅ Screens with mixed content types

### Choose NO effects for:
- ✅ Data-heavy screens
- ✅ Complex forms
- ✅ Charts and analytics
- ✅ Calendar/scheduling interfaces
- ✅ Text-heavy content
- ✅ Screens requiring high focus

## Layer Order (Z-Index)

Always maintain this order in your Stack:
```
1. CityBackground     ← Bottom layer
2. CyberpunkRain      ← Middle layer
3. Content            ← Your UI
4. Scanlines (if any) ← Top overlay
```

Example:
```dart
Stack(
  children: [
    const Positioned.fill(child: CityBackground(...)),  // 1
    const Positioned.fill(child: CyberpunkRain(...)),   // 2
    YourContent(),                                       // 3
    Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(painter: ScanlinesPainter()), // 4
      ),
    ),
  ],
)
```

## Quick Toggle

To quickly disable effects for testing:
```dart
// Disable city
CityBackground(
  enabled: false,  // ← Change this
  ...
)

// Disable rain
CyberpunkRain(
  enabled: false,  // ← Change this
  ...
)
```

## Performance Tips

### If experiencing lag:
1. Reduce `particleCount` by 20-30%
2. Reduce `opacity` by 0.1
3. Set `animateLights: false` on CityBackground
4. Disable effects on older devices

### Performance levels:
```dart
// HIGH PERFORMANCE (newer devices)
particleCount: 60, opacity: 0.35

// MEDIUM PERFORMANCE (average devices)
particleCount: 40, opacity: 0.25

// LOW PERFORMANCE (older devices)
particleCount: 20, opacity: 0.15

// MINIMAL (very old devices)
enabled: false
```

## Visual Testing Checklist

When adding effects to a new screen, verify:

- [ ] Effects don't obscure important text
- [ ] Buttons remain clearly visible
- [ ] Forms are easy to read
- [ ] Performance is smooth (60fps)
- [ ] Effects match screen's purpose
- [ ] Layer order is correct
- [ ] Both light and dark content visible
- [ ] Animations don't distract from actions

## Future: User Settings

Planned addition to allow users to control effects:

```dart
// Example future implementation
final effectsEnabled = userSettings.cyberpunkEffectsEnabled;
final effectsIntensity = userSettings.effectsIntensity; // 0.0-1.0

CyberpunkRain(
  enabled: effectsEnabled,
  particleCount: (40 * effectsIntensity).round(),
  opacity: 0.25 * effectsIntensity,
)
```

Settings UI location: Profile → Settings → Display → Cyberpunk Effects

---

**Last Updated**: 2026-03-12
**Version**: 1.0.0
**Status**: ✅ Implemented
