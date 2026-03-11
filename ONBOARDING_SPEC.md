# Phase 10A: Onboarding Flow Specification

**Goal:** Create a beginner-friendly first-time user experience that collects essential data and educates users about peptide tracking.

**Target User:** Someone starting their first peptide cycle, needs guidance and structure.

---

## Flow Overview

**Trigger:** First app launch after sign-up (check `user_profiles` table - if no profile exists, show onboarding)

**Screens:**
1. Welcome
2. Experience Level
3. Health Goals
4. Baseline Metrics
5. Notification Preferences
6. Setup Complete

**Total Time:** ~3-5 minutes

---

## Screen-by-Screen Breakdown

### 1. Welcome Screen

**Content:**
```
🧊 WELCOME TO BIOHACKER

Track your peptide cycles with precision.
Monitor progress. Optimize results.

This quick setup takes 3 minutes.

[GET STARTED] button
[Skip for now] link (bottom)
```

**Styling:**
- Full-screen with Wintermute branding
- Neon green accent on button
- Dark background with subtle grid pattern

**Action:**
- GET STARTED → Next screen
- Skip → Go to main app (save profile with defaults)

---

### 2. Experience Level

**Question:** "What's your experience with peptides?"

**Options (single select):**
- 🆕 **Beginner** - First time using peptides
- 🔬 **Intermediate** - Used 1-3 peptides before
- 🏆 **Advanced** - Experienced with stacks & protocols

**Why we ask:** Affects protocol suggestions and tooltips throughout app

**Action:** Select → Next screen

---

### 3. Health Goals

**Question:** "What are your primary health goals?"

**Options (multi-select, 2-5 recommended):**
- 💪 **Muscle Growth** - Build lean mass
- 🩹 **Injury Recovery** - Heal faster
- 🧬 **Longevity** - Anti-aging & healthspan
- ⚡ **Energy & Performance** - Metabolic optimization
- 😴 **Sleep Quality** - Better rest & recovery
- 🛡️ **Immune Support** - Stronger immunity
- 🧠 **Cognitive Enhancement** - Mental clarity
- 🔥 **Fat Loss** - Body recomposition

**Visual:** Checkbox grid, 2 columns

**Action:** Select 2+ → Next screen

---

### 4. Baseline Metrics

**Question:** "Let's record your starting point"

**Fields:**
```
Current Weight: [___] lbs  (or kg based on units preference)
Body Fat %: [___] % (optional, "Skip if unknown")
Height: [_] ft [__] in  (already have this from profile)
```

**Optional Labs Section (collapsible):**
```
"Have recent bloodwork? (Optional)"
[+] Add Baseline Labs

If expanded:
- Testosterone: [___] ng/dL
- IGF-1: [___] ng/mL
- HGH: [___] ng/mL
- Cortisol: [___] μg/dL
[Skip this step] link
```

**Why we ask:** Track progress over time, calculate effectiveness

**Action:** Fill weight (required) → Next screen

---

### 5. Notification Preferences

**Question:** "Stay on track with reminders"

**Toggles:**
```
📱 Dose Reminders
   Notify me before scheduled doses
   [Toggle ON/OFF]
   
   Time before dose: [60] minutes ▼
   
🔕 Quiet Hours
   No notifications during:
   [22:00] to [08:00] ▼

🧪 Lab Alerts
   Remind me every 3 months
   [Toggle ON/OFF]

📊 Weekly Progress
   Summary of the week
   [Toggle ON/OFF]
```

**Action:** Configure → Next screen

---

### 6. Setup Complete

**Content:**
```
✅ ALL SET!

Your profile is ready.
Ready to start your first cycle?

[START TRACKING] button
[Explore First] link
```

**Celebration moment:** Brief confetti animation or success glow effect

**Action:**
- START TRACKING → Navigate to Cycles screen (empty state with "Create Your First Cycle" CTA)
- Explore First → Navigate to Dashboard

---

## Database Schema

**user_profiles table additions:**
```sql
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS experience_level TEXT CHECK (experience_level IN ('beginner', 'intermediate', 'advanced'));

ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS health_goals TEXT[]; -- Array of goal slugs

ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS baseline_weight FLOAT;

ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS baseline_body_fat FLOAT;

ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS baseline_labs JSONB; -- {"testosterone": 650, "igf1": 210, ...}

ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT FALSE;

ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS onboarding_completed_at TIMESTAMP;
```

**notification_preferences table** (new):
```sql
CREATE TABLE IF NOT EXISTS notification_preferences (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  dose_reminders_enabled BOOLEAN DEFAULT TRUE,
  dose_reminder_minutes INTEGER DEFAULT 60,
  quiet_hours_start TIME DEFAULT '22:00',
  quiet_hours_end TIME DEFAULT '08:00',
  lab_alerts_enabled BOOLEAN DEFAULT TRUE,
  weekly_progress_enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own notification preferences"
  ON notification_preferences FOR ALL
  USING (auth.uid() = user_id);
```

---

## Technical Implementation

### Files to Create/Modify

1. **lib/screens/onboarding/** (new directory)
   - `welcome_screen.dart`
   - `experience_screen.dart`
   - `health_goals_screen.dart`
   - `baseline_metrics_screen.dart`
   - `notification_prefs_screen.dart`
   - `complete_screen.dart`

2. **lib/services/onboarding_service.dart** (new)
   - Check if onboarding completed
   - Save onboarding data to user_profiles
   - Navigation logic

3. **lib/main.dart** (modify)
   - Check onboarding status on app launch
   - Route to onboarding if not completed

4. **lib/migrations/** (new)
   - `update_user_profiles_onboarding.sql`
   - `create_notification_preferences.sql`

---

## Navigation Flow

```
main.dart
  ↓
  Check: user_profiles.onboarding_completed?
  ↓
  NO → WelcomeScreen
         ↓
         ExperienceScreen
         ↓
         HealthGoalsScreen
         ↓
         BaselineMetricsScreen
         ↓
         NotificationPrefsScreen
         ↓
         CompleteScreen
         ↓
         Save to DB (onboarding_completed = TRUE)
         ↓
         Navigate to Dashboard
  
  YES → Dashboard (skip onboarding)
```

---

## UX Polish

1. **Progress Indicator**
   - Show at top: "Step 2 of 6" or progress dots
   - Neon green progress bar

2. **Back Button**
   - Allow going back to previous screen
   - Don't lose entered data

3. **Skip Option**
   - Available on every screen
   - Saves defaults for skipped fields

4. **Validation**
   - Weight: Must be > 0
   - Body fat: 0-50% range (if provided)
   - Health goals: At least 1 selected
   - Notification times: Valid time format

5. **Animations**
   - Smooth screen transitions
   - Button press feedback
   - Success confetti on completion

---

## Copy Tone

- **Direct & clear** (not overly technical)
- **Beginner-friendly** (explain why we ask)
- **Motivational** (you're starting a journey)
- **Cyberpunk flavor** (but readable)

Examples:
- ❌ "Configure temporal dose administration parameters"
- ✅ "When should we remind you?"

---

## Testing Checklist

- [ ] First launch shows onboarding
- [ ] Skip functionality works
- [ ] Back navigation preserves data
- [ ] All fields save correctly to database
- [ ] Onboarding doesn't show again after completion
- [ ] Validation works on all screens
- [ ] Progress indicator updates correctly
- [ ] Success screen navigates to correct destination

---

## Post-Onboarding

**Empty State on Cycles Screen:**
```
NO CYCLES YET

Ready to start tracking?
Create your first cycle and we'll help you
stay on schedule.

[+ CREATE CYCLE] button
```

**Dashboard with No Data:**
- Show tutorial cards explaining each section
- "Complete your first week to see insights"

---

## Future Enhancements (Phase 11+)

- Video tutorial on first launch
- Interactive peptide picker guide
- Sample cycles/protocols for beginners
- Community success stories
- Referral program entry point

---

**This spec is ready to hand to Claude Code for implementation.**
