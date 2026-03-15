# Performance Optimization Quick Reference

Quick checklist for maintaining optimal performance in the biohacker-flutter app.

## ✅ Quick Checklist

### When Adding New Widgets
- [ ] Use `const` for static widgets (Text, Icon, SizedBox, Padding with const values)
- [ ] Add `key: ValueKey(id)` to list items
- [ ] Use `mainAxisSize: MainAxisSize.min` for Rows/Columns that shouldn't expand

### When Adding New Lists
- [ ] Use `ListView.builder` instead of `Column` with `.map().toList()`
- [ ] Use `GridView.builder` instead of `GridView.count/extent` with children list
- [ ] Set `addAutomaticKeepAlives: false` for simple, non-interactive items
- [ ] Set `addRepaintBoundaries: true` for complex or interactive items
- [ ] Add keys: `itemBuilder: (context, index) => MyWidget(key: ValueKey(items[index].id))`

### When Using Providers
- [ ] Use `ref.watch()` in build method for reactive data
- [ ] Use `ref.read()` in callbacks and event handlers
- [ ] Never use `ref.watch()` inside event handlers

### When Adding CustomPaint
- [ ] Make painter const if it doesn't take parameters: `const _MyPainter()`
- [ ] Return `false` from `shouldRepaint()` if painter is static

### When Adding Expensive Computations
- [ ] Cache results in a Map if computation is based on an ID
- [ ] Clear cache when data is reloaded
- [ ] Example:
  ```dart
  final Map<String, double> _cache = {};

  double expensiveCalc(String id) {
    if (_cache.containsKey(id)) return _cache[id]!;
    final result = /* expensive calculation */;
    _cache[id] = result;
    return result;
  }

  void _loadData() {
    // ... load data ...
    _cache.clear(); // Clear cache on data reload
  }
  ```

## 🚫 Common Anti-Patterns to Avoid

### DON'T: Build entire list eagerly
```dart
// ❌ Bad - builds all widgets at once
Column(
  children: items.map((item) => ItemWidget(item)).toList(),
)
```

### DO: Use ListView.builder
```dart
// ✅ Good - builds only visible items
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(
    key: ValueKey(items[index].id),
    item: items[index],
  ),
)
```

---

### DON'T: Recreate same widget instance
```dart
// ❌ Bad - new Text widget on every build
Text('Static Label', style: TextStyle(color: Colors.white))
```

### DO: Use const
```dart
// ✅ Good - same Text widget instance reused
const Text('Static Label', style: TextStyle(color: Colors.white))
```

---

### DON'T: Watch provider in event handler
```dart
// ❌ Bad - causes unnecessary rebuilds
onPressed: () {
  final service = ref.watch(myServiceProvider);
  service.doSomething();
}
```

### DO: Read provider in event handler
```dart
// ✅ Good - one-time read, no rebuild
onPressed: () {
  final service = ref.read(myServiceProvider);
  service.doSomething();
}
```

---

### DON'T: Repeat expensive calculations
```dart
// ❌ Bad - calculates progress on every build
Widget build(BuildContext context) {
  return Text('${_calculateProgress(cycle)}%');
}
```

### DO: Cache expensive calculations
```dart
// ✅ Good - calculates once, caches result
final Map<String, double> _progressCache = {};

double _getProgress(Cycle cycle) {
  if (_progressCache.containsKey(cycle.id)) {
    return _progressCache[cycle.id]!;
  }
  final progress = _calculateProgress(cycle);
  _progressCache[cycle.id] = progress;
  return progress;
}
```

## 📊 Performance Testing Commands

### Check Widget Rebuild Count
```bash
# Enable repaint rainbow in Flutter DevTools
# Look for excessive flashing during interactions
```

### Check FPS
```bash
# Flutter DevTools > Performance tab
# Target: Consistent 60 FPS during scrolling
```

### Check Memory Usage
```bash
# Flutter DevTools > Memory tab
# Watch for memory leaks (increasing baseline)
```

## 🎯 High-Impact Optimizations (Priority Order)

1. **Add const to static widgets** (5 min, high impact)
2. **Convert eager lists to ListView.builder** (10 min, high impact)
3. **Add keys to list items** (5 min, medium impact)
4. **Cache expensive computations** (15 min, medium impact)
5. **Optimize GridView.builder flags** (5 min, low impact)

## 📝 Code Review Checklist

When reviewing PRs, check for:
- [ ] Lists use `ListView.builder` or `GridView.builder`
- [ ] List items have unique keys
- [ ] Static widgets use `const`
- [ ] Provider usage follows watch/read pattern
- [ ] No expensive computations in build methods
- [ ] CustomPaint widgets have const painters where possible

## 🔧 Quick Fixes

### Fix: List performance issues
```dart
// Find this pattern:
Column(children: items.map((item) => Widget(item)).toList())

// Replace with:
ListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: items.length,
  itemBuilder: (context, index) => Widget(
    key: ValueKey(items[index].id),
    item: items[index],
  ),
)
```

### Fix: Missing const
```dart
// Run this command to find opportunities:
grep -r "SizedBox(width: " lib/ | grep -v "const SizedBox"
grep -r "SizedBox(height: " lib/ | grep -v "const SizedBox"
grep -r "Padding(" lib/ | grep -v "const Padding"
```

## 📚 Resources

- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Flutter Performance Profiling](https://docs.flutter.dev/perf/ui-performance)
- [Understanding Keys in Flutter](https://docs.flutter.dev/development/ui/widgets-intro#keys)

## 💡 Tips

1. **Use Flutter DevTools Performance Overlay**
   - Shows FPS in real-time
   - Highlights rebuilt widgets

2. **Profile on Real Devices**
   - Debug mode is slower than release
   - Test on lower-end devices

3. **Watch for Red Flags**
   - Choppy scrolling
   - Delayed interactions
   - Memory growth over time

4. **Measure Before Optimizing**
   - Use DevTools to identify bottlenecks
   - Don't optimize without profiling first
