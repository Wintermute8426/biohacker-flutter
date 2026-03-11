# Phase 10D: Dashboard Insights

## Overview
Advanced analytics dashboard with 6 key visualization components for biohacker app.

## Components Implemented

### 1. Compliance Ring (Top Center)
- **Visual**: Large circular progress indicator (180x180 pixels)
- **Data**: Doses logged / doses scheduled (percentage)
- **Color Gradient**:
  - Red (0-33%) - Poor compliance
  - Orange (33-66%) - Moderate compliance
  - Green (66-100%) - Excellent compliance
- **Display**: Percentage + "X/Y doses" text
- **Query**: COUNT(dose_logs) / estimated scheduled doses from cycles

### 2. Top Peptide Card (Top Right)
- **Visual**: Compact card with glow effect
- **Data**: Most logged peptide (proxy for effectiveness)
- **Display**: Peptide name, rating (0-10), star visual
- **Calculation**: Normalized log count to 10-point scale

### 3. 30-Day Dose Timeline (Center)
- **Visual**: 7x4 grid heatmap (4 weeks × 7 days)
- **Data**: Last 30 days of dose logs
- **Colors**:
  - Green cell = Dose logged that day
  - Gray cell = No dose logged
- **Hover**: Shows date + peptides taken

### 4. Side Effects Heatmap (Lower)
- **Visual**: Matrix: Peptides (rows) × Severity 1-5 (columns)
- **Data**: side_effects_log grouped by peptide + severity
- **Colors**: Darker = more incidents at that severity
- **Purpose**: Identify problematic peptides

### 5. Lab Correlations (Lower)
- **Visual**: List of top 3 biomarker changes
- **Data**: Compare latest labs_results vs baseline
- **Display**: "Biomarker ↑/↓ X% (Peptide1, Peptide2)"
- **Colors**: Green arrows for improvements, red for declines
- **Requirement**: At least 2 lab results needed

### 6. Cost Efficiency (Bottom)
- **Visual**: Summary card
- **Data**: cycle_expenses table
- **Display**:
  - Monthly cost: $/month
  - Cost per logged dose
  - Best value peptide (future: $/mg)
  - Least cost-effective peptide (future)

## Database Schema

### dashboard_snapshots Table
```sql
CREATE TABLE dashboard_snapshots (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),

  -- Compliance metrics
  compliance_rate FLOAT,
  total_doses_logged INTEGER,
  total_doses_scheduled INTEGER,

  -- Top peptide
  top_peptide TEXT,
  top_peptide_rating FLOAT,

  -- Side effects data (JSONB)
  side_effects_data JSONB,

  -- Lab correlations (JSONB)
  lab_correlations JSONB,

  -- Cost efficiency
  cost_per_dose FLOAT,
  monthly_cost FLOAT,
  best_value_peptide TEXT,
  least_cost_effective_peptide TEXT,

  -- Timeline data
  logged_dates TEXT[],

  -- Metadata
  created_at TIMESTAMP,
  expires_at TIMESTAMP, -- 24h cache expiry
  updated_at TIMESTAMP
);
```

## Caching Logic

### Auto-refresh Rules
1. **On screen load**: Check if cached data exists and is < 24 hours old
2. **If cached & fresh**: Use cached data (fast)
3. **If expired or missing**: Generate fresh data, cache it
4. **Manual refresh**: Force regenerate + clear old cache

### Cache Benefits
- Reduces database load (complex aggregations)
- Faster UI loads
- Still updates daily automatically

## Empty State Handling

### Scenarios
1. **No cycles**: "NO DATA YET - Create your first cycle"
2. **No doses**: "Complete your first week to see insights"
3. **No labs**: "Upload lab results to see correlations"
4. **No expenses**: Cost section hidden entirely

### Empty State UI
- Large icon (analytics_outlined)
- Primary text: "NO DATA YET"
- Secondary text: Action suggestions
- Action buttons:
  - Create a cycle
  - Log your first dose
  - Upload labs

## Files Created/Modified

### New Files
1. `lib/services/dashboard_analytics_service.dart`
   - DashboardAnalyticsService class
   - Data models (ComplianceData, TopPeptideData, etc.)
   - All 6 component calculation methods
   - Caching logic
   - Riverpod providers

2. `lib/screens/dashboard_insights_screen.dart`
   - Main dashboard UI
   - All 6 visualization widgets
   - Empty state handling
   - Refresh functionality

3. `dashboard_snapshots_migration.sql`
   - Database table creation
   - RLS policies
   - Indexes
   - Triggers

4. `cycle_expenses_table.sql` (optional)
   - For cost tracking feature

### Modified Files
1. `lib/screens/dashboard_screen.dart`
   - Added prominent "DASHBOARD INSIGHTS" link
   - Replaced NEWS section with insights gateway

## Technical Details

### Data Aggregation Queries

**Compliance**:
```dart
- Count dose_logs in last 30 days
- Estimate scheduled doses from cycles.frequency
- Calculate percentage
```

**Top Peptide**:
```dart
- Group dose_logs by cycle_id
- Join with cycles to get peptide_name
- Count logs per peptide
- Normalize to 10-point scale
```

**Timeline**:
```dart
- Get all dose_logs in last 30 days
- Generate 30-day date range
- Mark each day as logged/not logged
```

**Side Effects Heatmap**:
```dart
- Get all side_effects_log
- Group by (cycle_id → peptide_name, severity)
- Build matrix: {peptide: {1: count, 2: count, ...}}
```

**Lab Correlations**:
```dart
- Get latest 2+ lab results
- Compare biomarkers: (latest - baseline) / baseline
- Filter significant changes (> 5%)
- Get active peptides during period
- Attribute changes to peptides
```

**Cost Efficiency**:
```dart
- SUM cycle_expenses (all time)
- SUM cycle_expenses (last 30 days)
- COUNT dose_logs
- Calculate cost per dose
```

## Usage

### User Flow
1. User logs in
2. Navigates to Dashboard (home screen)
3. Taps "DASHBOARD INSIGHTS" card
4. Views all 6 analytics components
5. Taps refresh icon to force reload

### Developer Usage
```dart
// Get dashboard data
final userId = Supabase.instance.client.auth.currentUser?.id;
final dashboardData = ref.watch(dashboardDataProvider(userId));

// Force refresh
final service = ref.read(dashboardAnalyticsServiceProvider);
await service.forceRefresh(userId);
```

## Styling

### Cyberpunk Wintermute Aesthetic
- **Primary**: Cyan (#00FFFF)
- **Accent**: Neon Green (#39FF14)
- **Error**: Red (side effects)
- **Secondary**: Purple/pink (labs, costs)
- **Background**: Dark (#0A0A0A)
- **Surface**: Dark gray (#1A1A1A)

### Visual Effects
- Glowing borders (boxShadow with color.withOpacity)
- Monospace fonts for numbers
- Scanlines overlay (optional, from main dashboard)
- Sharp edges (borderRadius: 4)

## Performance Considerations

### Optimizations
1. **Caching**: 24h snapshot reduces DB queries
2. **Parallel Queries**: All 6 components fetch data concurrently
3. **Lazy Loading**: Only load when screen opened
4. **Graceful Degradation**: Empty states for missing data

### Query Complexity
- Most queries: O(n) where n = rows in table
- Heatmap: O(n × m) where n = peptides, m = severities (small)
- Lab correlations: Limited to 10 most recent results

## Testing Checklist

- [ ] Empty state displays correctly
- [ ] Compliance ring shows accurate percentage
- [ ] Top peptide calculated correctly
- [ ] Timeline shows last 30 days
- [ ] Side effects heatmap renders
- [ ] Lab correlations compute changes
- [ ] Cost efficiency displays when data exists
- [ ] Refresh button works
- [ ] Cache expires after 24h
- [ ] No data leaks between users (RLS policies)

## Future Enhancements

### Possible Additions
1. **Effectiveness Score**: Incorporate cycle_reviews table
2. **Cost per mg**: Calculate actual value efficiency
3. **Trend Lines**: Show compliance over time (line chart)
4. **Biomarker Charts**: fl_chart line graphs for lab changes
5. **Export PDF**: Generate report of all insights
6. **Push Notifications**: Alert when compliance drops below threshold
7. **AI Suggestions**: "Based on your data, consider..."

## SQL Migration Instructions

1. Open Supabase SQL Editor
2. Run `dashboard_snapshots_migration.sql`
3. (Optional) Run `cycle_expenses_table.sql` if cost tracking needed
4. Verify tables created: `SELECT * FROM dashboard_snapshots LIMIT 1;`
5. Verify RLS policies: Check Supabase dashboard → Authentication → Policies

## Troubleshooting

### Common Issues

**"No data" when I have cycles:**
- Check that doses are logged (not just scheduled)
- Verify user_id matches in all tables
- Check RLS policies are correct

**Dashboard not refreshing:**
- Force refresh via icon
- Check expires_at timestamp
- Clear cache manually: DELETE FROM dashboard_snapshots WHERE user_id = '...'

**Side effects heatmap empty:**
- Ensure side_effects_log has data
- Check cycle_id references are valid
- Verify severity is between 1-10

**Lab correlations not showing:**
- Need at least 2 lab results
- Check biomarkers JSONB format
- Verify upload_date is set correctly

## Commit Message
```
feat: Phase 10D - dashboard insights with compliance, effectiveness, and analytics

- Add dashboard_snapshots table with 24h caching
- Implement 6 analytics components:
  1. Compliance ring (circular progress)
  2. Top peptide card (most logged)
  3. 30-day dose timeline (heatmap)
  4. Side effects heatmap (peptide × severity)
  5. Lab correlations (biomarker changes)
  6. Cost efficiency ($/month, $/dose)
- Create DashboardAnalyticsService with parallel data fetching
- Add DashboardInsightsScreen with Wintermute aesthetic
- Implement empty state handling for new users
- Add manual refresh functionality
- Link from main dashboard screen

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

## Status
✅ Phase 10D Complete - Ready for user testing
