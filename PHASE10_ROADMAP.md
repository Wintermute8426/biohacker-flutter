# Phase 10: Product Launch Foundation
## Full Functionality, Scalable Architecture

**Goal:** Transform biohacker app from feature-complete to production-ready for user launch

**Timeline:** 5-7 days (intensive)

---

## Architecture Decisions

### Database Layer
**New Supabase Tables:**
- `user_profiles` — Experience level, goals, baselines, preferences
- `dose_schedules` — Recurring dose times (UTC), timezone handling
- `notifications` — User notification settings + delivery history
- `dashboard_snapshots` — Cached insights (refreshed daily for performance)
- `audit_log` — Track all user actions for compliance

### Backend Services
- **Firebase Cloud Messaging (FCM)** — Push notifications (native Android)
- **Supabase Edge Functions** — Scheduled dose reminders (cron jobs)
- **Analytics aggregation** — Daily batch job to compute insights

### Frontend Architecture
- **Riverpod** for state management (onboarding flows, notifications)
- **Drift** for local caching (offline notifications)
- **fl_chart enhancements** for striking visualizations

---

## Phase 10A: Onboarding (2 days)

### UX Flow
1. **Welcome Screen** — "Set up your biohacker profile"
2. **Experience Quiz** — Beginner/Intermediate/Advanced (affects protocol suggestions)
3. **Health Goals** — Multi-select: Muscle, Recovery, Longevity, Metabolic, Sleep, Immune
4. **Baseline Metrics** — Weight, body fat %, key labs (testosterone, HGH, etc.)
5. **Notification Preferences** — Dose reminders, lab alerts, protocol reviews
6. **Timezone Setup** — Auto-detect, allow manual override
7. **Confirmation** — "Profile complete, ready to go!"

### Database Schema
```sql
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY,
  experience_level TEXT, -- beginner | intermediate | advanced
  health_goals TEXT[], -- ["muscle", "recovery", "longevity"]
  baseline_weight FLOAT,
  baseline_body_fat FLOAT,
  baseline_labs JSONB, -- {"testosterone": 650, "igf1": 210, ...}
  timezone TEXT, -- America/New_York
  notification_enabled BOOLEAN,
  dose_reminder_minutes INTEGER, -- 60 = 1 hour before
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

### Features
- ✅ Full validation (no empty fields, realistic values)
- ✅ Edit anytime in Settings
- ✅ Skip button (populate with defaults)
- ✅ Beautiful onboarding UI (matching Wintermute aesthetic)

---

## Phase 10B: Calendar - Dose Scheduling (2 days)

### Functionality
- **Show next 30 days** of scheduled doses
- **Color-coded by peptide** (cyan for BPC, green for Semax, etc.)
- **Recurring doses** (every X days, specific times)
- **Manual override** (skip/reschedule individual doses)
- **Quick log** (tap dose → mark complete immediately)

### Database Schema
```sql
CREATE TABLE dose_schedules (
  id UUID PRIMARY KEY,
  cycle_id UUID REFERENCES cycles(id),
  peptide_name TEXT,
  dose_amount FLOAT,
  route TEXT, -- IM, SC, IV
  scheduled_time TIME, -- 08:00 (HH:MM in user's timezone)
  days_of_week INTEGER[], -- [1,3,5] for Mon/Wed/Fri (0=Sunday)
  start_date DATE,
  end_date DATE,
  is_active BOOLEAN,
  created_at TIMESTAMP
);

CREATE TABLE dose_logs (
  id UUID PRIMARY KEY,
  schedule_id UUID REFERENCES dose_schedules(id),
  logged_at TIMESTAMP,
  actual_dose FLOAT, -- If different from scheduled
  injection_site TEXT,
  notes TEXT,
  created_at TIMESTAMP
);
```

### Calendar UI
- Month view + week view
- Each day shows peptides scheduled (small colored dots/bars)
- Tap day → see detailed list of doses
- "Mark as taken" button for quick logging
- "Reschedule" option
- Visual indicator: Green (logged), Gray (pending), Red (missed)

### Features
- ✅ Timezone-aware scheduling
- ✅ Recurring dose patterns (weekly, every 3 days, etc.)
- ✅ Offline support (Drift local cache)
- ✅ Sync on reconnect

---

## Phase 10C: Notifications (1.5 days)

### Push Notifications (Android Native)
- **FCM setup** in Firebase Console
- **Backend service** to send reminders 1 hour before scheduled dose
- **Local notifications** as fallback (Dart native)
- **Notification channels** (high priority for reminders)

### Notification Types
1. **Dose Reminder** — "Time for BPC-157 injection (8mg IM)" → Tap to quick-log
2. **Missed Dose Alert** — "You missed BPC-157 (scheduled 08:00)" → Mark as taken anyway
3. **Lab Result Ready** — "Your lab results are in" → Open Labs tab
4. **Protocol Review** — "Check in on your Injury Recovery Stack" → Review modal

### Database
```sql
CREATE TABLE notification_preferences (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id),
  dose_reminders_enabled BOOLEAN,
  dose_reminder_minutes INTEGER, -- minutes before scheduled time
  missed_dose_alerts BOOLEAN,
  lab_alerts BOOLEAN,
  protocol_reviews BOOLEAN,
  quiet_hours_start TIME, -- e.g., 22:00
  quiet_hours_end TIME,   -- e.g., 08:00
  updated_at TIMESTAMP
);
```

### Features
- ✅ Respects quiet hours (no 3 AM reminders)
- ✅ Per-cycle notification overrides
- ✅ Toggle on/off in Settings
- ✅ Retry logic for failed notifications
- ✅ Offline graceful degradation

---

## Phase 10D: Dashboard Insights (2-3 days)

### Visually Striking Components

#### 1. Compliance Ring (Top Center)
```
        ╔════════════╗
        ║   COMPLIANCE║
        ║    87%      ║  ← Circular progress, cyan glow
        ║  21/24 doses║
        ╚════════════╝
```
- Big, glowing circular progress indicator
- Shows doses logged vs scheduled
- Color gradient: Red (0-33%) → Orange (33-66%) → Green (66-100%)

#### 2. Effectiveness Champion (Top Right)
```
        ╔════════════╗
        ║  TOP PEPTIDE║
        ║  BPC-157    ║  ← Accent green, glow
        ║  9.2 rating ║
        ║  ⭐⭐⭐⭐⭐  ║
        ╚════════════╝
```
- Aggregates from cycle_reviews + lab_changes
- Calculation: effectiveness rating + biomarker improvement
- Changes dynamically as data updates

#### 3. 30-Day Dose Timeline (Center)
```
        MON TUE WED THU FRI SAT SUN
 Week 1: ██  ██  ░░  ██  ░░  ░░  ██
 Week 2: ██  ██  ██  ██  ██  ░░  ██
 Week 3: ██  ░░  ██  ██  ░░  ██  ██
 Week 4: ██  ██  ██  ░░  ██  ██  ░░

        ██ = Dose taken  ░░ = Scheduled  (color by peptide)
```
- Heatmap-style visualization
- Hover/tap for details
- Shows compliance pattern

#### 4. Side Effects Heat Map (Lower Left)
```
        Severity:  1   2   3   4   5
BPC-157:     █    
TB-500:          ███   █
Semax:       ██      ██
GHK-Cu:         ██   █
```
- Peptide vs severity matrix
- Darker = more incidents at that severity
- Identify problematic peptides

#### 5. Lab Correlation (Lower Right)
```
        Which peptides moved your labs?
        
        Testosterone  ↑ 8%  (BPC-157, TB-500)
        IGF-1         ↑ 12% (HGH, GHK-Cu)
        Cortisol      ↓ 15% (Semax, Ashwagandha)
```
- Shows top 3 lab changes + contributing peptides
- Requires at least 2 lab results for accuracy
- Green for improvements, red for declines

#### 6. Cost Efficiency (Bottom Center)
```
        $/Month:  $180
        Cost per Dose Logged: $8.50
        
        Best Value: BPC-157 ($0.12/mg)
        Least Cost-Effective: HGH ($2.40/mg)
```
- Ties to cycle_expenses table
- Helps prioritize budget
- Breakdown by peptide

### Dashboard Refresh Logic
- **Auto-refresh on load** (if data >24h old)
- **Manual refresh button** (top right)
- **Background sync** every 6 hours when app is active
- **Cache locally** in `dashboard_snapshots` table

### Database
```sql
CREATE TABLE dashboard_snapshots (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  compliance_rate FLOAT, -- 0-100
  top_peptide TEXT,
  top_peptide_rating FLOAT,
  side_effects_data JSONB,
  lab_correlations JSONB,
  cost_per_dose FLOAT,
  created_at TIMESTAMP,
  expires_at TIMESTAMP -- refresh after 24h
);
```

### Features
- ✅ Real aggregations (no fake data)
- ✅ Handle edge cases (no cycles, no labs, etc.)
- ✅ Beautiful Wintermute styling
- ✅ Responsive layout (phone + tablet)
- ✅ Dark mode optimized

---

## Implementation Order

### Week 1
**Day 1-2: Onboarding**
- Supabase migrations + RLS policies
- Onboarding UI screens
- Store user_profiles

**Day 2-3: Calendar**
- Dose scheduling logic
- Calendar widget rewrite
- Quick-log functionality

**Day 4: Notifications**
- Firebase setup + FCM integration
- Notification preferences UI
- Backend scheduler (Edge Function)

### Week 2
**Day 5-7: Dashboard Insights**
- Data aggregation queries
- Chart components (fl_chart + custom)
- Caching + refresh logic
- Final polish + testing

---

## Testing & Quality Assurance

### Unit Tests
- Dose schedule generation (recurring patterns)
- Compliance calculations
- Lab correlation logic

### Integration Tests
- End-to-end onboarding flow
- Notification delivery + logging
- Dashboard data accuracy

### User Testing
- 3-5 beta users (at least 1 with actual peptide experience)
- 1 week usage data collection
- Feedback on UX/usefulness of insights

---

## Launch Readiness Checklist

- [ ] All database migrations tested on production
- [ ] RLS policies locked down (user can only see their data)
- [ ] Notifications tested on real Android device
- [ ] Dashboard insights accurate for 5+ sample users
- [ ] Onboarding skippable but complete
- [ ] Calendar functional with recurring doses
- [ ] No console errors or warnings
- [ ] App performance <2s load time
- [ ] Offline mode graceful
- [ ] Settings page has all user controls
- [ ] Privacy policy + terms reviewed
- [ ] Backup/export functionality (Phase 11, but mention)

---

## Success Metrics (Post-Launch)

- **Onboarding completion rate** >85%
- **Daily active users** (DAU) tracking dose compliance
- **Notification engagement** (>70% of reminders acted upon)
- **Dashboard insight usefulness** (qualitative: "Is this actually helpful?")

---

**Start:** Phase 10A Onboarding
**Estimated completion:** 5-7 days
**Status:** READY TO BUILD 🚀
