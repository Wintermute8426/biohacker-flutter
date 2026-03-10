# Database Migration Instructions

## ⚠️ IMPORTANT: Run This Migration Before Testing Profile Screen

The Profile Screen feature requires new database columns. You **MUST** run the migration SQL before the app will work correctly.

### How to Apply Migration

1. **Go to Supabase Dashboard**
   - Open: https://dfiewtwbxqfrrmyiqhqo.supabase.co/project/dfiewtwbxqfrrmyiqhqo
   - Navigate to: **SQL Editor**

2. **Copy and paste the migration SQL** from `DATABASE_MIGRATION.sql`

3. **Click "Run"** to execute the migration

4. **Verify the migration** by running this query:
```sql
SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'user_profiles'
  AND column_name IN ('username', 'age', 'gender', 'height_cm', 'allergies', 'medical_conditions')
ORDER BY ordinal_position;
```

You should see 6 new columns.

### What the Migration Does

Adds these columns to `user_profiles` table:
- `username` (TEXT, UNIQUE) - User's unique username
- `age` (INTEGER) - Age in years (10-120)
- `gender` (TEXT) - Gender selection
- `height_cm` (INTEGER) - Height in centimeters (50-300)
- `allergies` (TEXT, nullable) - Allergy information
- `medical_conditions` (JSONB) - Array of medical conditions

### Rollback (if needed)

If you need to undo the migration:
```sql
ALTER TABLE user_profiles DROP COLUMN IF EXISTS username CASCADE;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS age CASCADE;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS gender CASCADE;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS height_cm CASCADE;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS allergies CASCADE;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS medical_conditions CASCADE;
DROP INDEX IF EXISTS idx_user_profiles_username;
```

**⚠️ WARNING: This will delete all profile data!**

### Testing After Migration

1. Run the Flutter app: `flutter run`
2. Login and tap the hamburger menu (☰)
3. Tap "Profile"
4. Fill in the form and save
5. Verify that data persists after closing and reopening the screen

### Troubleshooting

**Error: "column does not exist"**
→ Run the migration SQL in Supabase

**Error: "duplicate key value violates unique constraint"**
→ Username already exists, try a different username

**Error: "value out of range"**
→ Check age (10-120) and height (50-300) are within valid ranges
