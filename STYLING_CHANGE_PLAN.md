# STYLING CHANGE PLAN - Dashboard Matte Style Consistency

**Date:** 2026-03-13
**Objective:** Apply exact dashboard matte styling across Labs, Reports, and Protocols screens

---

## REFERENCE STYLING (Dashboard Standard)

### ✅ CORRECT MATTE CARD STYLE (from WintermmuteStyles.cardDecoration)
```dart
BoxDecoration(
  color: AppColors.surface.withOpacity(0.15),  // Matte dark background
  border: Border.all(
    color: colorCyan.withOpacity(0.2),          // Subtle border - 0.2 opacity
    width: 1,
  ),
  borderRadius: BorderRadius.circular(4),
  // NO boxShadow for matte cards!
)
```

**Key characteristics:**
- Background: `AppColors.surface.withOpacity(0.15)` - very translucent
- Border opacity: **0.2** (subtle, not bright)
- Border width: **1px**
- NO glow effects for standard cards
- NO bright backgrounds or high-opacity colors

---

## ISSUE SUMMARY

### 1. **Labs Screen** (lib/screens/labs_screen.dart)
✅ **ALREADY CORRECT** - Uses `WintermmuteStyles.cardDecoration` properly
- Line 481: Uses `WintermmuteStyles.cardDecoration` ✓
- All BoxDecorations follow matte pattern with 0.15-0.2 opacity ✓
- No changes needed

### 2. **Reports Screen** (lib/screens/reports_screen.dart)
⚠️ **NEEDS FIXES** - Contains bright colors with excessive opacity

**Issues Found:**

#### A. High-opacity backgrounds (>=0.5)
- **Line 578-579:** ExpansionTile backgrounds
  ```dart
  backgroundColor: AppColors.surface.withOpacity(0.5),              // ❌ TOO BRIGHT
  collapsedBackgroundColor: AppColors.surface.withOpacity(0.5),    // ❌ TOO BRIGHT
  ```
  **FIX:** Change to `0.15` opacity

- **Line 933:** Border glow
  ```dart
  color: data.maxSeverity > 0
      ? AppColors.error.withOpacity(0.5)    // ❌ TOO BRIGHT
      : AppColors.border,
  ```
  **FIX:** Change to `0.2` opacity

- **Line 1044-1046:** Severity colors (heatmap)
  ```dart
  if (severity <= 6) return Colors.orange.withOpacity(0.5);     // ❌ TOO BRIGHT
  if (severity <= 8) return AppColors.error.withOpacity(0.6);   // ❌ TOO BRIGHT
  return AppColors.error.withOpacity(0.8);                      // ❌ WAY TOO BRIGHT
  ```
  **FIX:** Reduce to 0.15, 0.2, 0.3 respectively

- **Line 1150:** Primary color glow
  ```dart
  color: AppColors.primary.withOpacity(0.6),    // ❌ TOO BRIGHT
  ```
  **FIX:** Change to `0.2` opacity

- **Line 1465:** Border side
  ```dart
  side: BorderSide(color: AppColors.primary.withOpacity(0.5)),  // ❌ TOO BRIGHT
  ```
  **FIX:** Change to `0.2` opacity

- **Line 1625:** Highlight background
  ```dart
  color: isHighlight ? AppColors.surface.withOpacity(0.7) : AppColors.surface,  // ❌ TOO BRIGHT
  ```
  **FIX:** Change to `0.15` opacity

- **Line 2357:** Status color
  ```dart
  color: statusColor.withOpacity(0.5),    // ❌ TOO BRIGHT
  ```
  **FIX:** Change to `0.2` opacity

#### B. Missing WintermmuteStyles.cardDecoration usage
Many places use custom BoxDecoration instead of the standard `WintermmuteStyles.cardDecoration`

**Recommended pattern:**
```dart
// Instead of custom BoxDecoration, use:
decoration: WintermmuteStyles.cardDecoration,

// Or for custom borders:
decoration: WintermmuteStyles.customCardDecoration(
  borderColor: AppColors.primary,  // Will auto-apply 0.3 opacity
  borderRadius: 4,
),
```

### 3. **Protocols Screen** (lib/screens/protocols_screen.dart)
✅ **CLEAN** - No text decoration underlines found
✅ Cards appear to use proper matte styling

---

## DETAILED CHANGE LIST

### Reports Screen Changes (7 locations)

| Line | Current Code | Fixed Code | Priority |
|------|-------------|------------|----------|
| 578 | `backgroundColor: AppColors.surface.withOpacity(0.5)` | `backgroundColor: AppColors.surface.withOpacity(0.15)` | HIGH |
| 579 | `collapsedBackgroundColor: AppColors.surface.withOpacity(0.5)` | `collapsedBackgroundColor: AppColors.surface.withOpacity(0.15)` | HIGH |
| 933 | `AppColors.error.withOpacity(0.5)` | `AppColors.error.withOpacity(0.2)` | MEDIUM |
| 1044 | `Colors.orange.withOpacity(0.5)` | `Colors.orange.withOpacity(0.15)` | MEDIUM |
| 1045 | `AppColors.error.withOpacity(0.6)` | `AppColors.error.withOpacity(0.2)` | MEDIUM |
| 1046 | `AppColors.error.withOpacity(0.8)` | `AppColors.error.withOpacity(0.3)` | MEDIUM |
| 1150 | `AppColors.primary.withOpacity(0.6)` | `AppColors.primary.withOpacity(0.2)` | HIGH |
| 1465 | `AppColors.primary.withOpacity(0.5)` | `AppColors.primary.withOpacity(0.2)` | MEDIUM |
| 1625 | `AppColors.surface.withOpacity(0.7)` | `AppColors.surface.withOpacity(0.15)` | HIGH |
| 2357 | `statusColor.withOpacity(0.5)` | `statusColor.withOpacity(0.2)` | MEDIUM |

**Total Changes Required: 10 opacity adjustments**

---

## VISUAL COMPARISON

### Before (Current Bright Style)
```
Card Background: surface @ 0.5-0.7 opacity  ❌ Too visible
Border Colors: primary @ 0.5-0.6 opacity    ❌ Too bright
Glow Effects: 0.6-0.8 opacity               ❌ Too intense
```

### After (Dashboard Matte Style)
```
Card Background: surface @ 0.15 opacity     ✅ Subtle, matte
Border Colors: primary @ 0.2 opacity        ✅ Clean, dim
Glow Effects: None or 0.08 opacity          ✅ Minimal/none
```

---

## IMPLEMENTATION STRATEGY

### Phase 1: High Priority Fixes (3 changes)
1. Lines 578-579: ExpansionTile backgrounds
2. Line 1150: Primary color glow
3. Line 1625: Highlight background

**Impact:** Immediately fixes most visible bright areas

### Phase 2: Medium Priority Fixes (7 changes)
1. Lines 933, 1044-1046: Severity/error colors
2. Lines 1465, 2357: Border and status colors

**Impact:** Completes matte styling across all components

---

## VERIFICATION CHECKLIST

After implementing changes, verify:

- [ ] All card backgrounds use `AppColors.surface.withOpacity(0.15)` or less
- [ ] All border colors use opacity between `0.2-0.3` (never above 0.3)
- [ ] No boxShadow effects on standard cards (only CyberpunkFrame has glows)
- [ ] Colors appear matte and subtle, matching dashboard
- [ ] Reports screen feels cohesive with dashboard design
- [ ] No bright/glowing backgrounds that distract from content

---

## ESTIMATED IMPACT

**Files to modify:** 1 (reports_screen.dart)
**Lines to change:** 10
**Risk level:** LOW (only opacity value changes)
**Visual impact:** HIGH (major improvement in consistency)

---

## NOTES

1. **Labs screen is already perfect** - uses WintermmuteStyles.cardDecoration properly
2. **Protocols screen is clean** - no underlines, matte styling appears correct
3. **Dashboard is the reference** - all screens should match its subtle matte aesthetic
4. **Key principle:** Opacity values should rarely exceed 0.3 for borders/glows
5. **Background opacity:** Should be 0.15 or less for matte effect

---

## OPENCLAW COMPLETION COMMAND

```bash
openclaw system event --text 'Done: Styling review complete - see STYLING_CHANGE_PLAN.md' --mode now
```
