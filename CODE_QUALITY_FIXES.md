# Code Quality Fixes: Dashboard Redesign

**File:** `lib/screens/dashboard_screen.dart`  
**Date:** March 10, 2026

---

## 🔍 Issues Identified

### 1. Unused Import Statement

**Issue:**
```dart
import '../main.dart'; // ❌ Likely unused
```

**Verification:**
No symbols from `main.dart` are used in `dashboard_screen.dart`. The import appears to be leftover from previous implementation.

**Fix:**
```dart
// Remove this line:
import '../main.dart';
```

---

### 2. Missing Navigation Handler (Weight Tracker)

**Issue:**
Weight tracker button is missing `GestureDetector` wrapper and `onTap` handler.

**Current Code:**
```dart
Expanded(
  child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      border: Border.all(
        color: AppColors.accent.withOpacity(0.4),
        width: 1,
      ),
      borderRadius: BorderRadius.circular(4),
      color: AppColors.surface,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.scale_outlined,
          color: AppColors.accent,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          'WEIGHT',
          style: WintermmuteStyles.smallStyle.copyWith(
            color: AppColors.accent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  ),
),
```

**Fixed Code:**
```dart
Expanded(
  child: GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const WeightTrackerScreen(),
        ),
      );
    },
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.accent.withOpacity(0.4),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
        color: AppColors.surface,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.scale_outlined,
            color: AppColors.accent,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'WEIGHT',
            style: WintermmuteStyles.smallStyle.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  ),
),
```

---

### 3. Missing Error Handling in FutureBuilder

**Issue:**
FutureBuilder doesn't handle error state.

**Current Code:**
```dart
FutureBuilder<List<Cycle>>(
  future: activeCycles,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return Container(
        // ... empty state
      );
    }

    final cycles = snapshot.data!;
    return GridView.builder(
      // ... grid
    );
  },
),
```

**Fixed Code:**
```dart
FutureBuilder<List<Cycle>>(
  future: activeCycles,
  builder: (context, snapshot) {
    // Handle loading state
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    // Handle error state ✅ NEW
    if (snapshot.hasError) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: WintermmuteStyles.cardDecoration,
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'Error loading cycles',
                style: WintermmuteStyles.bodyStyle.copyWith(
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                snapshot.error.toString(),
                style: WintermmuteStyles.tinyStyle.copyWith(
                  color: AppColors.textDim,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Handle empty state
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return Container(
        // ... existing empty state code
      );
    }

    // Render grid
    final cycles = snapshot.data!;
    return GridView.builder(
      // ... existing grid code
    );
  },
),
```

---

## 🚀 Performance Improvements

### 1. Replace FutureBuilder with Riverpod Provider (Optional)

**Issue:**
`activeCycles` is a `Future` stored in widget state, which means:
- Every `setState()` call re-runs the FutureBuilder
- No caching or state management
- Inefficient if dashboard is navigated to frequently

**Current Approach:**
```dart
class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late Future<List<Cycle>> activeCycles;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    activeCycles = cycleDb.getActiveCycles();
    setState(() {});
  }
}
```

**Suggested Improvement (Riverpod):**
```dart
// Create a provider in lib/providers/cycles_provider.dart
final activeCyclesProvider = FutureProvider<List<Cycle>>((ref) async {
  final cycleDb = CyclesDatabase();
  return cycleDb.getActiveCycles();
});

// In dashboard_screen.dart, replace FutureBuilder with:
final activeCycles = ref.watch(activeCyclesProvider);

activeCycles.when(
  data: (cycles) {
    if (cycles.isEmpty) {
      return Container(/* empty state */);
    }
    return GridView.builder(/* grid */);
  },
  loading: () => Center(
    child: CircularProgressIndicator(color: AppColors.primary),
  ),
  error: (error, stack) => Container(/* error state */),
);
```

**Benefits:**
- ✅ Automatic caching
- ✅ Built-in error/loading/data states
- ✅ Refresh with `ref.refresh(activeCyclesProvider)`
- ✅ No manual `setState()` management

---

## 🎨 Refactoring Suggestions

### 1. Extract Cycle Card to Separate Widget

**Current:** `_buildCycleCard(Cycle cycle)` is a private method ✅

**Suggested:** Extract to reusable widget if used elsewhere

```dart
// lib/widgets/cycle_card.dart
class CycleCard extends StatelessWidget {
  final Cycle cycle;

  const CycleCard({Key? key, required this.cycle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
        color: AppColors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cycle.peptideName,
                style: WintermmuteStyles.smallStyle.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${cycle.dose}mg',
                style: WintermmuteStyles.smallStyle.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  cycle.frequency,
                  style: WintermmuteStyles.tinyStyle.copyWith(
                    color: AppColors.textMid,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Usage in dashboard:
itemBuilder: (context, index) {
  final cycle = cycles[index];
  return CycleCard(cycle: cycle);
},
```

**When to extract:**
- ✅ If `CycleCard` is used in other screens
- ❌ If only used in dashboard, keep as method

---

### 2. Extract News Card to Separate Widget

**Current:** `_buildNewsCard()` is a private method ✅

**Suggested:** Extract if reused or if logic grows

```dart
// lib/widgets/news_card.dart
class NewsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const NewsCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
          color: AppColors.surface,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: WintermmuteStyles.smallStyle.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: WintermmuteStyles.tinyStyle.copyWith(
                      color: AppColors.textMid,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward,
                color: color.withOpacity(0.5),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}

// Usage:
NewsCard(
  title: 'BPC-157 Research',
  subtitle: 'New study on muscle repair',
  icon: Icons.science_outlined,
  color: AppColors.secondary,
  onTap: () {
    // Navigate to article or show modal
  },
),
```

---

## 📋 Summary of Fixes

### Must-Fix (Breaking Issues)
1. ✅ **Remove unused import:** `import '../main.dart';`
2. ✅ **Add weight tracker navigation:** Wrap button in GestureDetector
3. ✅ **Add error handling:** FutureBuilder error state

### Nice-to-Have (Optimizations)
4. ⚠️ **Switch to Riverpod provider:** Replace Future with FutureProvider
5. ⚠️ **Extract widgets:** CycleCard and NewsCard (if reused elsewhere)
6. ⚠️ **Add news card navigation:** Make cards interactive or remove arrow icon

### All Code Quality Checks Passed
- ✅ No unused variables
- ✅ Null safety handled correctly
- ✅ TextDecoration.none explicitly set
- ✅ Follows Dart/Flutter conventions
- ✅ Widget composition is clean
