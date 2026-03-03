# Database Migrations

## Setup: Create cycle_reviews Table

To enable the Effectiveness Ratings feature in the Reports tab, you need to create the `cycle_reviews` table in your Supabase project.

### Option 1: Via Supabase Dashboard (Recommended)

1. Go to https://supabase.com/dashboard
2. Select your project: `dfiewtwbxqfrrmyiqhqo`
3. Navigate to **SQL Editor** in the left sidebar
4. Click **New Query**
5. Copy and paste the contents of `create_cycle_reviews_table.sql`
6. Click **Run**

### Option 2: Via Supabase CLI

```bash
# If you have Supabase CLI installed
supabase db push
```

### What the Migration Does

The migration creates:
- **Table**: `cycle_reviews` with columns:
  - `id` (UUID, primary key)
  - `cycle_id` (UUID, references `cycles.id`)
  - `user_id` (UUID, references `auth.users.id`)
  - `effectiveness_rating` (INTEGER, 1-10)
  - `notes` (TEXT, optional)
  - `created_at` (TIMESTAMPTZ)
  - `updated_at` (TIMESTAMPTZ)

- **Indexes**: For fast queries on `user_id` and `cycle_id`

- **Row Level Security (RLS)**: Users can only access their own cycle reviews

- **Auto-update trigger**: `updated_at` timestamp updates automatically

### Verification

After running the migration, verify it worked:

```sql
-- Check if table exists
SELECT * FROM cycle_reviews LIMIT 1;

-- Should return empty result set (no error)
```

## Phase 7 Features

With this migration complete, the app includes:

### Reports Tab
- **Dose Timeline**: Last 90 days of doses, grouped by peptide
- **Side Effects Heatmap**: Calendar view with severity color-coding
- **Weight Trends**: 6-month weight history with cycle overlays
- **Cycle-Lab Correlation**: 90-day context before each lab report
- **Effectiveness Ratings**: User ratings (1-10) per completed cycle
- **AI Insights**: Data-driven analysis and recommendations

### Calendar Tab
- **Month view** with cycle overlays (color-coded bars)
- **Protocol tags** (green dots)
- **Lab markers** (red dots)
- **Weight tracking** (scale icons)
- **Tap any day** to see full details: cycles, protocols, doses, weight, side effects
- **Filter view**: Show/hide cycles, protocols, labs, weight

## Testing

After deploying the APK:
1. Open the **Reports** tab - verify all 6 sections load
2. Open the **Calendar** tab - verify month view shows overlays
3. Tap a day with activity - verify detail sheet shows data
4. Try adding a cycle review (effectiveness rating) from Reports → Effectiveness Ratings
5. Verify all charts render smoothly without lag

## Build Information

- **Build trigger**: Automatic via GitHub Actions on push to `main`
- **APK location**: GitHub Actions artifacts (arm64 for testing)
- **Deploy target**: Android 16 phone via Tailscale (100.71.64.116)
