# HEADER CONTAINER PROPERTY COMPARISON

## EXACT COMPARISON OF HEADER CONTAINERS

### LABS SCREEN (lib/screens/labs_screen.dart)

**Line 279-292: Header Container**

```dart
Container(
  color: AppColors.surface.withOpacity(0.3),
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  child: Row(
    children: [
      Icon(Icons.science, color: WintermmuteStyles.colorOrange, size: 28),
      const SizedBox(width: 12),
      Text(
        'LABS',
        style: WintermmuteStyles.titleStyle,
      ),
    ],
  ),
),
```

**Properties:**
- **Padding:** `EdgeInsets.symmetric(horizontal: 16, vertical: 12)`
- **Margin:** NONE
- **Color:** `AppColors.surface.withOpacity(0.3)`
- **Decoration:** NONE (just plain `color`)
- **Constraints:** NONE
- **Alignment:** NONE
- **Row MainAxisAlignment:** DEFAULT (start)
- **Row CrossAxisAlignment:** DEFAULT (center)
- **Row Padding:** NONE

**Above Container:**
- **SafeArea:** YES (line 255)
- **Scaffold:** YES (line 274)
- **Column:** YES (line 276)
- **Column Padding:** NONE
- **SizedBox before Container:** NONE
- **Positioned:** NO

---

### CALENDAR SCREEN (lib/screens/calendar_screen.dart)

**Line 143-228: Header Container**

```dart
Container(
  color: AppColors.surface.withOpacity(0.3),
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  child: Row(
    children: [
      Icon(Icons.calendar_month, color: WintermmuteStyles.colorCyan, size: 28),
      const SizedBox(width: 12),
      Text(
        'DOSE CALENDAR',
        style: WintermmuteStyles.titleStyle,
      ),
      const Spacer(),
      // View toggle button - switches between week and month view
      Container(...),
      IconButton(...),
      // SYNC FIX: Aggressive refresh button
      Container(...),
    ],
  ),
),
```

**Properties:**
- **Padding:** `EdgeInsets.symmetric(horizontal: 16, vertical: 12)` ✅ MATCHES LABS
- **Margin:** NONE ✅ MATCHES LABS
- **Color:** `AppColors.surface.withOpacity(0.3)` ✅ MATCHES LABS
- **Decoration:** NONE (just plain `color`) ✅ MATCHES LABS
- **Constraints:** NONE ✅ MATCHES LABS
- **Alignment:** NONE ✅ MATCHES LABS
- **Row MainAxisAlignment:** DEFAULT (start) ✅ MATCHES LABS
- **Row CrossAxisAlignment:** DEFAULT (center) ✅ MATCHES LABS
- **Row Padding:** NONE ✅ MATCHES LABS

**Above Container:**
- **SafeArea:** YES (line 118) ✅ MATCHES LABS
- **Scaffold:** YES (line 138) ✅ MATCHES LABS
- **Column:** YES (line 140) ✅ MATCHES LABS
- **Column Padding:** NONE ✅ MATCHES LABS
- **SizedBox before Container:** NONE ✅ MATCHES LABS
- **Positioned:** NO ✅ MATCHES LABS

---

### RESEARCH SCREEN (lib/screens/research_screen.dart)

**Line 777-790: Header Container**

```dart
Container(
  color: AppColors.surface.withOpacity(0.3),
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  child: Row(
    children: [
      Icon(Icons.biotech, color: WintermmuteStyles.colorOrange, size: 28),
      const SizedBox(width: 12),
      Text(
        'RESEARCH',
        style: WintermmuteStyles.titleStyle,
      ),
    ],
  ),
),
```

**Properties:**
- **Padding:** `EdgeInsets.symmetric(horizontal: 16, vertical: 12)` ✅ MATCHES LABS
- **Margin:** NONE ✅ MATCHES LABS
- **Color:** `AppColors.surface.withOpacity(0.3)` ✅ MATCHES LABS
- **Decoration:** NONE (just plain `color`) ✅ MATCHES LABS
- **Constraints:** NONE ✅ MATCHES LABS
- **Alignment:** NONE ✅ MATCHES LABS
- **Row MainAxisAlignment:** DEFAULT (start) ✅ MATCHES LABS
- **Row CrossAxisAlignment:** DEFAULT (center) ✅ MATCHES LABS
- **Row Padding:** NONE ✅ MATCHES LABS

**Above Container:**
- **SafeArea:** YES (line 752) ✅ MATCHES LABS
- **Scaffold:** YES (line 771) ✅ MATCHES LABS
- **Column:** YES (line 773) ✅ MATCHES LABS
- **Column Padding:** NONE ✅ MATCHES LABS
- **SizedBox before Container:** NONE ✅ MATCHES LABS
- **Positioned:** NO ✅ MATCHES LABS

---

### PROFILE SCREEN (lib/screens/profile_screen.dart)

**Line 298-320: Header Container**

```dart
Container(
  color: AppColors.surface.withOpacity(0.3),
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  child: Row(
    children: [
      IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
        color: AppColors.textLight,
      ),
      Icon(Icons.person, color: WintermmuteStyles.colorOrange, size: 28),
      const SizedBox(width: 12),
      Text('PROFILE', style: WintermmuteStyles.titleStyle),
      const Spacer(),
      if (!_isEditMode)
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => setState(() => _isEditMode = true),
          color: AppColors.textLight,
        ),
    ],
  ),
),
```

**Properties:**
- **Padding:** `EdgeInsets.symmetric(horizontal: 16, vertical: 12)` ✅ MATCHES LABS
- **Margin:** NONE ✅ MATCHES LABS
- **Color:** `AppColors.surface.withOpacity(0.3)` ✅ MATCHES LABS
- **Decoration:** NONE (just plain `color`) ✅ MATCHES LABS
- **Constraints:** NONE ✅ MATCHES LABS
- **Alignment:** NONE ✅ MATCHES LABS
- **Row MainAxisAlignment:** DEFAULT (start) ✅ MATCHES LABS
- **Row CrossAxisAlignment:** DEFAULT (center) ✅ MATCHES LABS
- **Row Padding:** NONE ✅ MATCHES LABS

**Above Container:**
- **SafeArea:** YES (line 276) ✅ MATCHES LABS
- **Scaffold:** NO ❌ **DIFFERENCE!**
- **Column:** YES (line 295) ✅ MATCHES LABS
- **Column Padding:** NONE ✅ MATCHES LABS
- **SizedBox before Container:** NONE ✅ MATCHES LABS
- **Positioned:** NO ✅ MATCHES LABS

---

## CRITICAL FINDING: PROFILE SCREEN IS MISSING SCAFFOLD!

### Widget Tree Comparison

**Labs, Calendar, Research:**
```
SafeArea
└── Stack
    └── Scaffold (backgroundColor: Colors.transparent)
        └── Column
            └── Container (header)
```

**Profile:**
```
SafeArea
└── Stack
    └── Column  ❌ NO SCAFFOLD HERE!
        └── Container (header)
```

### The Problem

Profile screen has:
- Line 276: `SafeArea`
- Line 277: `Stack` (for background layers)
- Line 295: `Column` **DIRECTLY** - no Scaffold wrapper!
- Line 298: `Container` (header)

All other screens have:
- SafeArea → Stack → **Scaffold** → Column → Container

### Why This Causes Different Header Position

Without Scaffold, the Profile screen's header:
1. May render at a different vertical position due to missing Scaffold's internal layout constraints
2. Scaffold applies MediaQuery padding adjustments that affect child positioning
3. Scaffold manages AppBar and body layout in specific ways that influence vertical spacing

---

## CONCLUSION

**ALL header Container properties are IDENTICAL across all pages.**

**The ONLY difference is:**
- **Profile screen is missing Scaffold wrapper around Column**
- Labs, Calendar, Research all have: `Scaffold(backgroundColor: Colors.transparent, body: Column(...))`
- Profile has: `Stack → Column` (no Scaffold)

This is why the header appears at a different vertical position on Profile even though the Container itself is identical.

---

## FIX NEEDED

Profile screen needs Scaffold added:

```dart
SafeArea(
  child: Stack(
    children: [
      // Background layers...
      Scaffold(  // ← ADD THIS
        backgroundColor: Colors.transparent,  // ← ADD THIS
        body: Column(  // ← WRAP Column
          children: [
            Container(...), // header
            Expanded(...),
          ],
        ),
      ),
    ],
  ),
)
```
