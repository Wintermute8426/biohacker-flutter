# Cyberpunk Background Implementation Plan

## Executive Summary
Add animated cyberpunk cityscape + Matrix rain background throughout the Biohacker app, matching the aesthetic at biohacker.systems. Existing widgets (`CityBackground`, `CyberpunkRain`) already provide the core functionality — task is to integrate properly and update asset references.

---

## Current State Analysis

### ✅ Assets Present
- `assets/images/biohacker_logo.png` - New transparent logo (1377KB, already saved)
- Existing widgets:
  - `lib/widgets/city_background.dart` - Pixel art cityscape with animated lights
  - `lib/widgets/cyberpunk_rain.dart` - Matrix-style falling rain effect
  - `lib/widgets/cyberpunk_animations.dart` - Additional effects (data streams, scanlines, glitch)

### 🔄 Current Integration
- **Login/Signup screens**: Already use `CityBackground` + `CyberpunkRain` stacked
- **Logo**: Currently uses `biohacker-neon-logo-vectorized.png`, needs to switch to new `biohacker_logo.png`
- **Main screens**: No consistent background implementation (Cycles screen has imports but may not be actively rendering)

---

## Implementation Plan

### Phase 1: Asset Configuration ✅ (5 min)
**File:** `pubspec.yaml`

**Action:**
Add `assets/images/biohacker_logo.png` to the assets list.

**Why:**
Current asset list only has icon/logo variants in `assets/logo/` and `assets/icon/`. New logo is in `assets/images/`.

---

### Phase 2: Create Reusable Background Widget (10 min)
**File:** `lib/widgets/cyberpunk_background.dart` (NEW)

**Purpose:**
Single source of truth for app-wide cyberpunk background (cityscape + rain).

**Design:**
```dart
class CyberpunkBackground extends StatelessWidget {
  final Widget child;
  final bool showCity;
  final bool showRain;
  final double cityOpacity;
  final double rainOpacity;
  final int rainParticleCount;
  
  const CyberpunkBackground({
    required this.child,
    this.showCity = true,
    this.showRain = true,
    this.cityOpacity = 0.4,
    this.rainOpacity = 0.35,
    this.rainParticleCount = 50,
  });
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // City skyline (bottom ~30% of screen)
        if (showCity)
          Positioned.fill(
            child: CityBackground(
              enabled: true,
              animateLights: true,
              opacity: cityOpacity,
            ),
          ),
        // Matrix rain overlay
        if (showRain)
          Positioned.fill(
            child: CyberpunkRain(
              enabled: true,
              particleCount: rainParticleCount,
              opacity: rainOpacity,
            ),
          ),
        // Content on top
        child,
      ],
    );
  }
}
```

**Why this approach:**
- Consistent visual language across all screens
- Easy to tune performance (reduce particles on lower-end devices)
- Can disable individually for screens that need it (e.g., camera views)

**Performance optimization:**
- Default 50 particles (tested in login — smooth at 60fps)
- `CityBackground` uses `shouldRepaint` optimization (only repaints on animation progress change)
- `CyberpunkRain` uses time-based updates (frame-independent)

---

### Phase 3: Update Login/Signup Screens (15 min)

#### 3.1 Login Screen
**File:** `lib/screens/login_screen.dart`

**Changes:**
1. Replace logo path:
   ```dart
   // OLD:
   'assets/logo/biohacker-neon-logo-vectorized.png'
   
   // NEW:
   'assets/images/biohacker_logo.png'
   ```

2. Simplify background stack (currently duplicates logic):
   ```dart
   // OLD:
   Stack(
     children: [
       const Positioned.fill(child: CityBackground(...)),
       const Positioned.fill(child: CyberpunkRain(...)),
       SingleChildScrollView(...),
       Positioned.fill(child: CustomPaint(painter: _ScanlinesPainter())),
     ],
   )
   
   // NEW:
   CyberpunkBackground(
     cityOpacity: 0.5,
     rainOpacity: 0.35,
     rainParticleCount: 60,
     child: Stack(
       children: [
         SingleChildScrollView(...),
         Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _ScanlinesPainter()))),
       ],
     ),
   )
   ```

#### 3.2 Signup Screen
**File:** `lib/screens/signup_screen.dart`

**Changes:**
Same as login — replace background stack with `CyberpunkBackground` wrapper.

**Why:**
- Removes code duplication
- Ensures consistent visual tuning across auth screens
- Easier to maintain (change opacity/particle count in one place)

---

### Phase 4: Apply to Main Screens (30 min)

**Target screens:**
1. `lib/screens/cycles_screen.dart`
2. `lib/screens/labs_screen.dart`
3. `lib/screens/protocols_screen.dart`
4. `lib/screens/research_screen.dart`
5. `lib/screens/profile_screen.dart`

**Pattern (for each):**

```dart
@override
Widget build(BuildContext context) {
  return CyberpunkBackground(
    // Subtle background for main screens (content readability first)
    cityOpacity: 0.3,
    rainOpacity: 0.25,
    rainParticleCount: 40,
    child: Scaffold(
      backgroundColor: Colors.transparent, // CRITICAL: let background show through
      // ... rest of screen content
    ),
  );
}
```

**Content readability strategy:**
- Cards already use `AppColors.surface` with some transparency
- If content becomes hard to read, add semi-transparent overlay to card backgrounds:
  ```dart
  Container(
    decoration: BoxDecoration(
      color: AppColors.surface.withOpacity(0.95), // was 0.85 or transparent
      borderRadius: BorderRadius.circular(12),
    ),
    // ... card content
  )
  ```

**Performance tuning per screen:**
- Cycles/Labs/Profile: 40 particles (moderate activity)
- Research: 30 particles (lots of scrolling text)
- Protocols: 40 particles

**Why lower opacity on main screens:**
- Login/signup are hero moments (immersive, high visual impact)
- Main app screens prioritize data visibility and usability
- Background should enhance atmosphere, not compete with content

---

### Phase 5: Test & Tune (20 min)

**Visual checks:**
1. Logo displays correctly (transparent PNG, no background artifacts)
2. Cityscape sits at bottom ~30% of screen (not cut off)
3. Rain particles animate smoothly (no stuttering)
4. Content remains readable on all screens (text contrast, card visibility)

**Performance checks:**
1. Run `flutter run --profile` on physical device
2. Monitor FPS during navigation (target: 60fps, acceptable: 55fps+)
3. Check memory usage (target: <150MB for background widgets)
4. Test on lower-end device if available (e.g., older Android)

**Tuning knobs (if performance issues):**
- Reduce `rainParticleCount` (40 → 30 → 20)
- Lower opacity (less GPU blending)
- Disable rain on specific screens (`showRain: false`)
- Consider static cityscape on low-end devices (detect via `MediaQuery`)

---

## File Structure Summary

```
lib/
├── widgets/
│   ├── cyberpunk_background.dart       [NEW] Reusable wrapper widget
│   ├── city_background.dart            [EXISTS] Pixelated cityscape
│   ├── cyberpunk_rain.dart             [EXISTS] Matrix rain effect
│   └── cyberpunk_animations.dart       [EXISTS] Additional effects
├── screens/
│   ├── login_screen.dart               [EDIT] Logo path + background wrapper
│   ├── signup_screen.dart              [EDIT] Logo path + background wrapper
│   ├── cycles_screen.dart              [EDIT] Add background wrapper
│   ├── labs_screen.dart                [EDIT] Add background wrapper
│   ├── protocols_screen.dart           [EDIT] Add background wrapper
│   ├── research_screen.dart            [EDIT] Add background wrapper
│   └── profile_screen.dart             [EDIT] Add background wrapper
└── ...

assets/
└── images/
    └── biohacker_logo.png              [EXISTS] New transparent logo

pubspec.yaml                            [EDIT] Add logo to assets
```

---

## Widget Architecture

```
┌─────────────────────────────────────────┐
│  CyberpunkBackground (wrapper)          │
│  ├─ CityBackground (bottom ~30%)        │
│  │  └─ Animated building lights         │
│  ├─ CyberpunkRain (full screen)         │
│  │  └─ Matrix falling characters        │
│  └─ child (screen content)              │
│     └─ Scaffold (transparent bg)        │
│        └─ Screen-specific content       │
└─────────────────────────────────────────┘
```

**Layer order (bottom to top):**
1. Dark gradient background (`WintermmuteBackground` or `AppColors.background`)
2. City skyline (pixelated buildings, ~30% screen height, bottom-aligned)
3. Matrix rain (full screen, green falling characters)
4. Screen content (cards, text, buttons)
5. Optional: Scanlines overlay (login/signup only)

---

## Animation Strategy

### CityBackground
- **Type:** Oscillating light animation
- **Controller:** 3-second AnimationController with `repeat(reverse: true)`
- **Target:** Window lights, neon accents, antenna blinks
- **Performance:** Only repaints when `progress` changes (optimized `shouldRepaint`)

### CyberpunkRain
- **Type:** Continuous particle system
- **Controller:** 1-second looping AnimationController
- **Physics:** Time-based position updates (`dt * speed`)
- **Optimization:** Drops reset when off-screen (no memory accumulation)
- **Gradient:** Bright head, fading tail (like Matrix code)

**Combined performance impact:**
- Two AnimationControllers per screen
- ~50-60 paint operations per frame (rain particles)
- Minimal CPU (no complex math, pre-computed positions)
- GPU: Standard blend operations (well-optimized by Flutter)

**Expected FPS:** 60fps on mid-range devices, 55fps+ on budget Android

---

## Performance Considerations

### Memory
- Static building positions (seeded Random in `CityBackground`)
- Rain drops reused (List<RainDrop> with in-place updates)
- No image assets loaded for backgrounds (pure CustomPaint)

### GPU
- Gradients use shader caching (Flutter optimization)
- Blur effects limited (only on lights, 3-5px radius)
- No expensive operations (clipping, masks, complex paths)

### Battery
- Animations run only when screen visible
- Consider adding motion detection later (pause when idle)

### Fallback strategy (if needed)
```dart
// In CyberpunkBackground:
final isLowEndDevice = MediaQuery.of(context).size.width < 360;
rainParticleCount: isLowEndDevice ? 20 : 50,
showRain: !isLowEndDevice, // Disable rain on very low-end devices
```

---

## Asset Requirements

### Current
✅ Logo: `assets/images/biohacker_logo.png` (1377KB transparent PNG)

### Potential future additions (not in scope)
- Optional: Pixelated city PNG (if CustomPaint performance issues)
- Optional: Matrix character font (currently uses built-in rendering)

---

## Design Reference Compliance

**From biohacker.systems:**
- ✅ Pixelated cityscape (16-bit aesthetic) → `CityBackground` CustomPaint
- ✅ Matrix rain (green falling characters) → `CyberpunkRain` with gradient trails
- ✅ Magenta/cyan color scheme → `AppColors.primary` (cyan), `AppColors.accent` (magenta)
- ✅ Dystopian cyberpunk vibe → Dark gradients, neon accents, terminal fonts

**Differences (intentional):**
- App uses more muted opacity (readability)
- Website uses horizontal parallax (not needed for mobile)
- App keeps rain behind content (website has interactive layers)

---

## Commit Strategy

Single atomic commit after full implementation:

```
git add -A
git commit -m "Add cyberpunk cityscape + Matrix rain background app-wide

- Created CyberpunkBackground reusable widget
- Updated login/signup to use new biohacker_logo.png
- Applied animated background to all main screens (Cycles, Labs, Protocols, Research, Profile)
- Optimized particle counts for 60fps performance
- Ensured content readability with semi-transparent overlays

Matches biohacker.systems aesthetic: pixelated city + green Matrix rain."
```

---

## Testing Checklist

- [ ] Logo displays correctly on login/signup
- [ ] Cityscape renders at bottom ~30% of screen
- [ ] Matrix rain animates smoothly (no stuttering)
- [ ] All main screens have background applied
- [ ] Content remains readable (text contrast OK)
- [ ] Navigation transitions smooth (60fps)
- [ ] No memory leaks (check with DevTools)
- [ ] Tested on physical device (not just simulator)

---

## Rollback Plan (if performance issues)

1. Reduce particle count globally (50 → 30)
2. Lower opacity (less GPU blending)
3. Disable rain on specific screens
4. Replace CustomPaint cityscape with static image
5. If still issues: feature flag to disable entirely

---

## Estimated Time
- **Planning:** 15 min ✅ (this document)
- **Implementation:** 60 min
  - Phase 1 (pubspec): 5 min
  - Phase 2 (widget): 10 min
  - Phase 3 (login/signup): 15 min
  - Phase 4 (main screens): 30 min
- **Testing:** 20 min
- **Total:** ~95 min

---

## Success Criteria

✅ All screens have unified cyberpunk background  
✅ Logo updated to new transparent PNG  
✅ Maintains 55fps+ on mid-range devices  
✅ Content remains readable  
✅ Matches biohacker.systems aesthetic  
✅ Single clean commit with comprehensive message
