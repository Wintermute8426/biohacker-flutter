# Subscription System - Quick Start Guide

**TL;DR:** Get the subscription system running in 30 minutes.

## Prerequisites

- ✅ Flutter project with Supabase configured
- ✅ Google Play Developer account
- ✅ Supabase CLI installed (`npm install -g supabase`)

---

## Step 1: Database Setup (5 min)

1. Open Supabase dashboard → SQL Editor
2. Copy contents of `lib/migrations/add_subscription_fields.sql`
3. Paste and execute
4. Verify tables created:
   ```sql
   SELECT * FROM users LIMIT 1; -- Should have subscription columns
   SELECT * FROM subscription_purchases; -- Should exist (empty)
   ```

✅ **Done:** Database ready for subscriptions

---

## Step 2: Google Play Console (10 min)

### A. Create Products

1. [Play Console](https://play.google.com/console) → Your App → **Monetize** → **Subscriptions**
2. Click **Create subscription**

**Monthly:**
- Product ID: `biohacker_monthly_sub`
- Name: Biohacker Premium Monthly
- Price: $9.99 USD
- Billing: 1 month
- Save & activate

**Annual (optional):**
- Product ID: `biohacker_annual_sub`
- Name: Biohacker Premium Annual
- Price: $99.99 USD
- Billing: 12 months
- Save & activate

### B. Add Test Accounts

1. Play Console → **Setup** → **License testing**
2. Add your Gmail accounts (comma-separated)
3. Save

✅ **Done:** Products created, test accounts added

---

## Step 3: Deploy Edge Function (5 min)

```bash
# Login to Supabase
supabase login

# Link project (get ref from dashboard URL)
supabase link --project-ref YOUR_PROJECT_REF

# Deploy function
cd /path/to/biohacker-flutter
supabase functions deploy verify-subscription

# Optional: Set Google API key (for production)
# supabase secrets set GOOGLE_PLAY_API_KEY=your_key_here
```

✅ **Done:** Edge function deployed

---

## Step 4: Update Package Name (2 min)

Edit `supabase/functions/verify-subscription/index.ts`:

```typescript
const GOOGLE_PLAY_PACKAGE_NAME = 'com.biohacker.app' // ← Your package name
```

Redeploy:
```bash
supabase functions deploy verify-subscription
```

✅ **Done:** Edge function configured

---

## Step 5: Install Dependencies (1 min)

```bash
flutter pub get
```

✅ **Done:** Dependencies installed

---

## Step 6: Integrate into App (5 min)

### A. Add to `main.dart`

At top:
```dart
import 'services/subscription_service.dart';
import 'screens/paywall_screen.dart';
```

Before `runApp()`:
```dart
final subscriptionServiceProvider = ChangeNotifierProvider<SubscriptionService>(
  (ref) => SubscriptionService(),
);
```

### B. Add to Profile Screen

```dart
import '../screens/subscription_settings_screen.dart';

// Add to your profile list
ListTile(
  leading: Icon(Icons.workspace_premium, color: AppColors.electricPurple),
  title: Text('Subscription'),
  subtitle: Text('Manage your plan'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => SubscriptionSettingsScreen()),
  ),
),
```

### C. Add Banner to Home Screen

```dart
import '../widgets/subscription_banner.dart';

// In your home screen build:
Column(
  children: [
    SubscriptionBanner(), // ← Add this
    // ... rest of your content
  ],
)
```

✅ **Done:** UI integrated

---

## Step 7: Test (7 min)

### Build & Install

```bash
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### Test Flow

1. **Sign up with test Gmail account**
   - Trial should auto-start (30 days)
   - Check profile → should show "FREE TRIAL"

2. **Manually expire trial** (in Supabase SQL Editor):
   ```sql
   UPDATE users 
   SET subscription_ends_at = NOW() - INTERVAL '1 day'
   WHERE email = 'your_test_email@gmail.com';
   ```

3. **Restart app**
   - Paywall should appear
   - Tap "SUBSCRIBE" → Google Play payment sheet
   - Complete test purchase (not charged)
   - Paywall should dismiss
   - Profile should show "PREMIUM"

4. **Test restore purchases**
   - Uninstall app
   - Reinstall
   - Login with same account
   - Settings → "Restore Purchases"
   - Should restore premium status

✅ **Done:** Subscription system working!

---

## Verification Checklist

- [ ] Database migration executed
- [ ] Products created in Play Console (`biohacker_monthly_sub`, `biohacker_annual_sub`)
- [ ] Test accounts added to license testing
- [ ] Edge function deployed
- [ ] Package name updated in edge function
- [ ] Dependencies installed (`in_app_purchase`)
- [ ] Profile screen shows subscription
- [ ] Banner shows on home screen
- [ ] Trial auto-starts on signup
- [ ] Paywall blocks access when trial expires
- [ ] Purchase flow completes (test account)
- [ ] Premium access granted after purchase
- [ ] Restore purchases works

---

## Troubleshooting

### "Products not found"
→ Publish app to internal/closed testing track in Play Console  
→ Wait 24h for products to propagate

### "Purchase doesn't complete"
→ Check `android/app/src/main/AndroidManifest.xml` has:
```xml
<uses-permission android:name="com.android.vending.BILLING" />
```

### "Subscription doesn't restore"
→ Verify signed in with same Google account  
→ Check Play Console → Order management for purchase

### "Paywall always shows"
→ Check Supabase logs for errors  
→ Verify edge function deployed: `supabase functions list`

### "Edge function fails"
→ Check logs: `supabase functions logs verify-subscription`  
→ Verify project linked: `supabase projects list`

---

## What's Next?

### Production Release

Before going live:

1. **Remove test mode** in `verify-subscription/index.ts`:
   ```typescript
   // REMOVE THIS LINE:
   return true; // TEMPORARY: Remove in production!
   ```

2. **Set up Google Play API**
   - Create service account in Google Cloud Console
   - Grant "Google Play Android Developer" role
   - Add key to Supabase secrets

3. **Configure RTDNs**
   - Set up Pub/Sub topic
   - Add webhook in Play Console
   - Handle renewal/cancellation events

4. **Test with real money**
   - Make small real purchase ($0.99 test product)
   - Verify entire flow works

5. **Add analytics**
   - Track trial starts, conversions, churns
   - Monitor funnel performance

### Optional Enhancements

- Add promotional offers (first month discount)
- Implement referral program (bonus trial days)
- Create re-engagement campaigns (expired trials)
- Add push notifications (trial ending, payment failed)
- Build analytics dashboard (conversion tracking)

---

## Support Resources

- **Setup Guide:** `SUBSCRIPTION_SETUP.md` (complete instructions)
- **Testing Guide:** `SUBSCRIPTION_TESTING.md` (test checklist)
- **Integration Examples:** `SUBSCRIPTION_INTEGRATION_EXAMPLES.md` (copy-paste code)
- **Summary:** `SUBSCRIPTION_IMPLEMENTATION_SUMMARY.md` (what was built)

---

## Need Help?

**Common questions:**

Q: How do I cancel a test subscription?  
A: Play Console → Order management → Cancel

Q: Can I change the price later?  
A: Yes, but existing subscribers keep their old price

Q: What happens when payment fails?  
A: Grace period (3 days), then access revoked

Q: How do refunds work?  
A: User requests via Google Play, access revoked immediately

Q: Can I offer discounts?  
A: Yes, via promotional offers in Play Console

---

**Status:** Ready to test! 🚀

**Next:** Build debug APK → Test with license account → Verify trial auto-starts
