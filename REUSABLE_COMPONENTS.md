# Reusable Components Library

> **Comprehensive widget library for consistent, maintainable UI across the Biohacker Flutter app**

This document catalogs all reusable widgets created for maximum code reusability and design consistency.

---

## 📦 Quick Import

```dart
import 'package:biohacker/widgets/common/common_widgets.dart';
```

This single import gives you access to all reusable components.

---

## 🎨 Component Catalog

### 1. MatteCard

**Purpose:** Standard container for content with matte Wintermute styling

**Location:** `lib/widgets/common/matte_card.dart`

**Parameters:**
- `child` (Widget, required) - Content to display
- `padding` (EdgeInsets?, optional) - Internal padding (default: 12px all)
- `borderColor` (Color?, optional) - Border color (default: primary cyan)
- `decoration` (BoxDecoration?, optional) - Custom decoration override
- `margin` (EdgeInsets?, optional) - External margin (default: bottom 12px)

**Usage:**
```dart
MatteCard(
  child: Text('Content here'),
  borderColor: AppColors.accent,
)
```

**Used in:**
- Dashboard (dose cards, cycle cards)
- Labs (lab result cards)
- Cycles (cycle detail cards)
- Protocols (protocol cards)

---

### 2. EmptyState

**Purpose:** Consistent empty state display when no content exists

**Location:** `lib/widgets/common/empty_state.dart`

**Parameters:**
- `icon` (IconData, required) - Icon to display
- `title` (String, required) - Main title text
- `message` (String?, optional) - Additional message
- `action` (Widget?, optional) - Call-to-action button
- `iconColor` (Color?, optional) - Icon color (default: primary)

**Usage:**
```dart
EmptyState(
  icon: Icons.event_available,
  title: 'No cycles',
  message: 'Create your first cycle to get started',
)
```

**Used in:**
- Dashboard (no doses today)
- Cycles (no active cycles)
- Labs (no lab results)

---

### 3. CyberLoading

**Purpose:** Loading indicator with optional message

**Location:** `lib/widgets/common/cyber_loading.dart`

**Parameters:**
- `message` (String?, optional) - Loading message text
- `color` (Color?, optional) - Spinner color (default: primary)
- `size` (double, optional) - Spinner size (default: 40px)

**Usage:**
```dart
CyberLoading(message: 'Loading data...')
```

**Used in:**
- All screens during data loading
- File uploads
- API requests

---

### 4. SectionHeader

**Purpose:** Consistent section headers with optional icon and trailing widget

**Location:** `lib/widgets/common/section_header.dart`

**Parameters:**
- `title` (String, required) - Header text
- `icon` (IconData?, optional) - Leading icon
- `trailing` (Widget?, optional) - Trailing widget (buttons, etc.)
- `iconColor` (Color?, optional) - Icon color
- `textColor` (Color?, optional) - Text color
- `padding` (EdgeInsets?, optional) - Container padding

**Usage:**
```dart
SectionHeader(
  title: 'TODAY\'S DOSES',
  icon: Icons.medication_outlined,
  iconColor: AppColors.primary,
)
```

**Used in:**
- Dashboard (Today's Doses, Cycle Progress, Quick Actions)
- Cycles (Active Cycles, Completed Cycles)
- Labs (All Results, Out of Range)

---

### 5. InfoChip

**Purpose:** Small labeled information displays (route, frequency, etc.)

**Location:** `lib/widgets/common/info_chip.dart`

**Parameters:**
- `icon` (IconData?, optional) - Leading icon
- `label` (String, required) - Chip text
- `backgroundColor` (Color?, optional) - Background color
- `borderColor` (Color?, optional) - Border color
- `textColor` (Color?, optional) - Text color
- `iconColor` (Color?, optional) - Icon color
- `padding` (EdgeInsets?, optional) - Internal padding

**Usage:**
```dart
InfoChip(
  icon: Icons.route,
  label: 'SC (subcutaneous)',
)
```

**Used in:**
- Dashboard (dose cards - route, site)
- Cycles (frequency, route indicators)
- Labs (biomarker categories)

---

### 6. CyberProgressBar

**Purpose:** Progress bars with labels and percentage/value display

**Location:** `lib/widgets/common/cyber_progress_bar.dart`

**Parameters:**
- `label` (String, required) - Progress bar label
- `progress` (double, required) - Progress value (0.0 to 1.0)
- `valueText` (String?, optional) - Custom value text
- `fillColor` (Color?, optional) - Fill color
- `gradient` (Gradient?, optional) - Gradient fill
- `backgroundColor` (Color?, optional) - Background color
- `borderColor` (Color?, optional) - Border color
- `height` (double, optional) - Bar height (default: 24px)
- `showPercentage` (bool, optional) - Show percentage (default: true)
- `icon` (IconData?, optional) - Label icon

**Usage:**
```dart
CyberProgressBar(
  label: 'DOSE AMOUNT',
  progress: 0.75,
  valueText: '7.5mg',
  icon: Icons.vaccines_outlined,
)
```

**Used in:**
- Dashboard (dose amount, cycle progress)
- Cycles (cycle completion percentage)

---

### 7. CyberButton

**Purpose:** Consistent button styling with multiple variants

**Location:** `lib/widgets/common/cyber_button.dart`

**Styles:**
- `CyberButtonStyle.primary` - Cyan filled
- `CyberButtonStyle.accent` - Green filled
- `CyberButtonStyle.secondary` - Orange filled
- `CyberButtonStyle.outlined` - Transparent with border
- `CyberButtonStyle.text` - Text only

**Parameters:**
- `text` (String, required) - Button text
- `onPressed` (VoidCallback?, optional) - Tap handler
- `style` (CyberButtonStyle, optional) - Button style (default: primary)
- `icon` (IconData?, optional) - Leading icon
- `isLoading` (bool, optional) - Show loading spinner (default: false)
- `fullWidth` (bool, optional) - Expand to full width (default: false)
- `padding` (EdgeInsets?, optional) - Button padding

**Usage:**
```dart
CyberButton(
  text: 'MARK MISSED',
  icon: Icons.cancel_outlined,
  style: CyberButtonStyle.outlined,
  onPressed: () => markMissed(),
)
```

**Used in:**
- Dashboard (Mark Missed, Log Effects buttons)
- Cycles (Create Cycle, Edit, Complete buttons)
- All forms and modals

---

### 8. BadgeWidget

**Purpose:** Status badges and category labels

**Location:** `lib/widgets/common/badge_widget.dart`

**Styles:**
- `BadgeStyle.primary` - Cyan
- `BadgeStyle.accent` - Green
- `BadgeStyle.warning` - Orange
- `BadgeStyle.error` - Red
- `BadgeStyle.neutral` - Gray

**Parameters:**
- `text` (String, required) - Badge text
- `style` (BadgeStyle, optional) - Badge style (default: primary)
- `icon` (IconData?, optional) - Leading icon
- `padding` (EdgeInsets?, optional) - Internal padding
- `outlined` (bool, optional) - Outlined style (default: false)

**Usage:**
```dart
BadgeWidget(
  text: 'COMPLETED',
  style: BadgeStyle.accent,
  icon: Icons.check_circle,
)
```

**Used in:**
- Dashboard (dose status badges)
- Cycles (cycle status)
- Research (peptide categories)

---

### 9. QuickActionCard

**Purpose:** Large action cards for dashboard quick actions

**Location:** `lib/widgets/common/quick_action_card.dart`

**Parameters:**
- `icon` (IconData, required) - Card icon
- `label` (String, required) - Card label
- `color` (Color, required) - Theme color
- `onTap` (VoidCallback, required) - Tap handler
- `width` (double?, optional) - Card width

**Usage:**
```dart
QuickActionCard(
  icon: Icons.scale_outlined,
  label: 'LOG WEIGHT',
  color: AppColors.accent,
  onTap: () => showWeightModal(),
)
```

**Used in:**
- Dashboard (Quick Actions section)

---

### 10. ScanlinesPainter & ScanlinesOverlay

**Purpose:** CRT-style scanlines overlay for cyberpunk aesthetic

**Location:** `lib/widgets/common/scanlines_painter.dart`

**Parameters:**
- `opacity` (double, optional) - Scanline opacity (default: 0.07)
- `spacing` (double, optional) - Line spacing (default: 3px)

**Usage:**
```dart
Stack(
  children: [
    // Your content
    ScanlinesOverlay(opacity: 0.07),
  ],
)
```

**Used in:**
- All screens as overlay effect
- Replaces duplicated _ScanlinesPainter classes

---

## 🎯 Already Using Reusable Widgets

### AppHeader
**Location:** `lib/widgets/app_header.dart`

**Used in:**
- Dashboard
- Cycles
- Labs
- Protocols
- Research

This was created during the rapid-valley session and is already widely adopted.

### BaseScreen
**Status:** In progress (rapid-valley session)
**Purpose:** Will standardize screen structure with consistent background, scanlines, and header

---

## 🚀 Migration Status

### ✅ Components Created
- [x] MatteCard
- [x] EmptyState
- [x] CyberLoading
- [x] SectionHeader
- [x] InfoChip
- [x] CyberProgressBar
- [x] CyberButton
- [x] BadgeWidget
- [x] QuickActionCard
- [x] ScanlinesPainter & ScanlinesOverlay

### 🔄 Screens to Migrate (Future Work)
- [ ] Dashboard - Replace inline card styling with MatteCard
- [ ] Cycles - Use EmptyState, InfoChip, CyberButton
- [ ] Labs - Use MatteCard, BadgeWidget
- [ ] Protocols - Use MatteCard, CyberButton
- [ ] Research - Use BadgeWidget for categories
- [ ] All screens - Replace _ScanlinesPainter with ScanlinesOverlay

---

## 📝 Best Practices

### When to Use Each Component

**MatteCard:**
- Any content container that needs consistent styling
- List items, detail cards, summary cards

**EmptyState:**
- No data to display
- Empty lists
- Missing content scenarios

**CyberLoading:**
- Data fetching
- File uploads
- Long-running operations

**SectionHeader:**
- Dividing content sections
- Page subsections with titles

**InfoChip:**
- Displaying metadata (route, frequency, etc.)
- Small labeled values
- Tags and categories

**CyberProgressBar:**
- Showing completion percentage
- Dose amounts
- Cycle progress
- Any quantitative progress

**CyberButton:**
- Primary actions (create, save, submit)
- Secondary actions (cancel, delete)
- Outlined for tertiary actions

**BadgeWidget:**
- Status indicators (completed, missed, active)
- Categories and tags
- Small labels

**QuickActionCard:**
- Dashboard action buttons
- Large, prominent action items

**ScanlinesOverlay:**
- All screens for consistent CRT effect
- Replace individual _ScanlinesPainter classes

---

## 🎨 Design System Alignment

All components follow the Wintermute design system:

**Colors:**
- Primary: Cyan (#00FFFF)
- Accent: Green (#39FF14)
- Secondary: Magenta (#FF00FF)
- Warning: Orange (#FF6B00)
- Error: Red (#FF0040)

**Typography:**
- Font: JetBrains Mono
- Consistent letter spacing
- Bold for emphasis

**Borders:**
- Matte style (no glow by default)
- 2px border width standard
- 0.35 opacity for visibility
- Border radius: 4-8px

**Spacing:**
- Consistent 8px grid
- Standard padding: 12-16px
- Standard margin: 12px bottom

---

## 🔧 Future Enhancements

### Planned Components
- [ ] CycleCard - Specialized card for cycle display
- [ ] DoseCard - Specialized card for dose instances
- [ ] ModalHeader - Consistent modal headers
- [ ] FormField - Styled text fields
- [ ] DropdownButton - Styled dropdowns
- [ ] DateTimePicker - Custom date/time picker

### Planned Features
- [ ] Animation support for all components
- [ ] Dark/light theme variants
- [ ] Accessibility improvements
- [ ] Component playground/preview screen

---

## 📚 Examples

### Dashboard Quick Actions (Before & After)

**Before:**
```dart
Widget _buildQuickActionCard({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: WintermmuteStyles.bodyStyle.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
```

**After:**
```dart
import '../widgets/common/common_widgets.dart';

QuickActionCard(
  icon: Icons.scale_outlined,
  label: 'LOG WEIGHT',
  color: AppColors.accent,
  onTap: _showWeightLogModal,
)
```

**Result:** 35 lines → 6 lines (83% reduction)

---

### Empty State (Before & After)

**Before:**
```dart
Container(
  padding: const EdgeInsets.all(24),
  decoration: BoxDecoration(
    border: Border.all(
      color: AppColors.primary.withOpacity(0.3),
      width: 2,
    ),
    borderRadius: BorderRadius.circular(8),
    color: AppColors.surface,
  ),
  child: Column(
    children: [
      Icon(
        Icons.add_circle_outline,
        color: AppColors.primary,
        size: 48,
      ),
      const SizedBox(height: 12),
      Text(
        'No active cycles',
        style: WintermmuteStyles.titleStyle.copyWith(
          color: AppColors.primary,
          fontSize: 18,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Create your first cycle to get started',
        style: WintermmuteStyles.bodyStyle.copyWith(
          color: AppColors.textMid,
        ),
        textAlign: TextAlign.center,
      ),
    ],
  ),
)
```

**After:**
```dart
import '../widgets/common/common_widgets.dart';

EmptyState(
  icon: Icons.add_circle_outline,
  title: 'No active cycles',
  message: 'Create your first cycle to get started',
)
```

**Result:** 35 lines → 5 lines (86% reduction)

---

## 💡 Tips for Maximum Reusability

1. **Import once:** Use `common_widgets.dart` for all common widgets
2. **Customize via parameters:** Use optional parameters instead of copying
3. **Compose:** Build complex UIs by combining simple widgets
4. **Follow patterns:** Look at existing usage before creating new components
5. **Update docs:** Add new widgets to this file when created

---

## 📞 Support

For questions or suggestions about reusable components:
- Check this document first
- Review existing usage in screens
- Look at component source code for full parameter list
- Propose new components via PR

---

**Last Updated:** 2026-03-13
**Total Components:** 10 core widgets + AppHeader (11 total)
**Code Reduction:** ~80% average when using reusable components
