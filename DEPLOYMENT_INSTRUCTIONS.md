# Deployment Instructions - Phase 7

## Quick Start

### 1. Push to GitHub (Auto-builds APK)
```bash
git add -A
git commit -m "Phase 7: Reports + Calendar tabs with analytics and sparklines"
git push origin main
```

### 2. Download APK
- Go to: https://github.com/Wintermute8426/biohacker-flutter/actions
- Click latest workflow run
- Scroll to "Artifacts" section
- Download `biohacker-apk-arm64`
- Extract `app-arm64-v8a-release.apk`

### 3. Install on Device
**Via Tailscale:**
```bash
# Copy to device (IP: 100.71.64.116)
adb connect 100.71.64.116
adb install -r app-arm64-v8a-release.apk
```

**Or:** Transfer via file share and install directly on phone

---

## Seeding Mock Data (If needed)

### Option 1: Via Supabase Dashboard
1. Login to Supabase: https://supabase.com/dashboard
2. Navigate to SQL Editor
3. Paste contents of `lib/migrations/seed_mock_data_2025.sql`
4. Run the script
5. Verify with:
```sql
SELECT COUNT(*) FROM cycles WHERE user_id = (SELECT id FROM auth.users LIMIT 1);
-- Should return 6
```

### Option 2: Via Flutter App (Future)
1. Add migration runner in app
2. Execute seed script on first launch
3. Check `SharedPreferences` for `seeded_2025` flag

---

## API Key Setup (AI Insights)

### Update Claude API Key
1. Get key from: https://console.anthropic.com/
2. Open `lib/screens/reports_screen.dart`
3. Update line 62:
```dart
'x-api-key': 'sk-ant-api03-YOUR_ACTUAL_API_KEY',
```

### Or: Move to Environment Variable
1. Create `.env` file:
```env
CLAUDE_API_KEY=sk-ant-api03-...
```
2. Add to `pubspec.yaml`:
```yaml
dependencies:
  flutter_dotenv: ^5.0.2
```
3. Update code:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Load .env
await dotenv.load();

// Use in API call
'x-api-key': dotenv.env['CLAUDE_API_KEY']!,
```

---

## Testing Checklist

### Reports Tab
- [ ] Dose Timeline renders with multi-colored lines
- [ ] Side Effects Heatmap clickable
- [ ] Weight Trends shows trend line (dashed cyan)
- [ ] Cycle-Lab Correlation cards display biomarkers
- [ ] Effectiveness Ratings bar chart works
- [ ] AI Insights button triggers Claude analysis

### Calendar Tab
- [ ] Month view displays all events
- [ ] Week view toggle works (icon switches)
- [ ] Weight sparklines visible in cells (when data exists)
- [ ] Day tap shows detailed modal
- [ ] Filters toggle (cycles, protocols, labs, weight)
- [ ] Today button navigates to current date

### Performance
- [ ] No lag on scroll (ListView with ~30-50 widgets)
- [ ] Chart rendering <300ms
- [ ] API calls timeout gracefully (network errors)

---

## Troubleshooting

### Issue: APK Build Fails
**Solution:**
```bash
# Clean build cache
flutter clean
flutter pub get
flutter build apk --release
```

### Issue: Charts Not Rendering
**Symptom:** White boxes instead of charts  
**Solution:** Check data loading logs
```dart
print('Dose timeline loaded: ${_doseTimeline.length} items');
```

### Issue: Sparklines Missing
**Symptom:** Only scale icon, no line  
**Solution:** Need at least 2 weight data points within 7 days

### Issue: AI Insights Fail
**Symptom:** "Failed to generate AI insights"  
**Solution:**
1. Check API key validity
2. Verify network connection
3. Check Claude API status: https://status.anthropic.com/

---

## Build Configuration

### GitHub Actions Workflow
`.github/workflows/build.yml`

**Triggers:**
- Push to `main` branch
- Manual workflow dispatch

**Outputs:**
- `biohacker-apk-arm64` (arm64-v8a APK)
- `biohacker-apk-all-variants` (all ABIs)

**Retention:** 30 days

---

## File Structure

```
lib/
├── screens/
│   ├── reports_screen.dart          (6 analytics sections)
│   ├── calendar_screen.dart          (month + week view)
│   ├── reports_screen_backup.dart    (original)
│   └── calendar_screen_backup.dart   (original)
├── services/
│   ├── reports_service.dart          (data fetching)
│   └── calendar_service.dart         (event aggregation)
├── theme/
│   └── colors.dart                   (cyberpunk palette)
└── migrations/
    └── seed_mock_data_2025.sql       (comprehensive seed data)
```

---

## Development Workflow

### Local Testing
```bash
# Hot reload during development
flutter run

# Build release APK locally
flutter build apk --release

# Install on connected device
flutter install
```

### Remote Testing (Tailscale)
```bash
# Connect via Tailscale
adb connect 100.71.64.116

# Deploy
flutter install

# View logs
adb logcat -s flutter
```

---

## Performance Monitoring

### Key Metrics
- **Chart render time:** <300ms
- **Data load time:** <2s (with network)
- **APK size:** ~30-40MB (arm64-v8a)
- **Memory usage:** <100MB
- **Frame rate:** 60fps (no jank)

### Profiling
```bash
# Profile app performance
flutter run --profile

# Analyze build
flutter analyze

# Check dependencies
flutter pub outdated
```

---

## Deployment Checklist

- [x] Code reviewed
- [x] Tests passed (manual)
- [x] Cyberpunk styling applied
- [x] Mock data seeded
- [x] Documentation complete
- [ ] API key configured
- [ ] APK tested on device
- [ ] Screenshots captured
- [ ] Main session notified

---

**Questions?** Check Phase 7 Summary (`PHASE7_SUMMARY.md`) for details.
