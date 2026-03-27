# Biohacker Subscription System Setup Guide

## Overview

The Biohacker app uses a **30-day free trial** followed by a **$9.99/month** subscription model, powered by Google Play Billing.

## Architecture

### Client-Side (Flutter)
- `lib/services/subscription_service.dart` - Core billing logic
- `lib/models/subscription_status.dart` - Status tracking model
- `lib/screens/paywall_screen.dart` - Upgrade prompt (cyberpunk styled)
- `lib/screens/subscription_settings_screen.dart` - Manage subscription
- `lib/widgets/subscription_banner.dart` - Trial countdown banner

### Server-Side (Supabase)
- Database: Users table with subscription fields
- Edge Function: `verify-subscription` for secure purchase validation
- Purchases table: Track verified transactions

## 🚀 Setup Instructions

### 1. Install Dependencies

```bash
flutter pub get
```

The `in_app_purchase: ^3.1.0` package is already added to `pubspec.yaml`.

### 2. Configure Google Play Console

#### A. Create Subscription Products

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app → **Monetize** → **Subscriptions**
3. Create two subscription products:

**Monthly Subscription:**
- Product ID: `biohacker_monthly_sub`
- Name: Biohacker Premium Monthly
- Price: $9.99 USD
- Billing period: 1 month
- Grace period: 3 days (recommended)
- Auto-renew: Yes

**Annual Subscription (Optional):**
- Product ID: `biohacker_annual_sub`
- Name: Biohacker Premium Annual
- Price: $99.99 USD (20% discount)
- Billing period: 12 months
- Grace period: 3 days
- Auto-renew: Yes

#### B. Set Up License Testing (Development)

1. In Play Console → **Setup** → **License testing**
2. Add test Gmail accounts
3. These accounts can make test purchases without being charged

#### C. Enable Real-time Developer Notifications (RTDNs)

1. Create Google Cloud Pub/Sub topic
2. Configure in Play Console → **Monetize** → **Subscriptions** → **Real-time developer notifications**
3. This enables subscription renewal/cancellation webhooks

### 3. Configure Android Manifest

Add billing permission to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Billing permission -->
    <uses-permission android:name="com.android.vending.BILLING" />
    
    <application ...>
        ...
    </application>
</manifest>
```

### 4. Set Up Supabase Database

#### A. Run Migration

Execute the migration SQL in Supabase SQL Editor:

```bash
# Copy contents of lib/migrations/add_subscription_fields.sql
# Paste into Supabase dashboard → SQL Editor → New query
# Execute
```

This creates:
- Subscription columns on `users` table
- `subscription_purchases` table for tracking
- Triggers for auto-starting trials on signup

#### B. Deploy Edge Function

```bash
# Install Supabase CLI if not already installed
npm install -g supabase

# Login
supabase login

# Link project
supabase link --project-ref YOUR_PROJECT_REF

# Deploy function
supabase functions deploy verify-subscription

# Set environment variables
supabase secrets set GOOGLE_PLAY_API_KEY=your_api_key_here
```

### 5. Configure Google Play API Access (Server-Side Verification)

#### A. Create Service Account

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select project linked to Play Console
3. **APIs & Services** → **Credentials**
4. Create service account
5. Grant **Google Play Android Developer** role
6. Download JSON key file

#### B. Link to Play Console

1. Play Console → **Setup** → **API access**
2. Link Google Cloud project
3. Grant service account **Manage subscriptions** permission

#### C. Add API Key to Supabase

```bash
# Upload service account JSON as secret
supabase secrets set GOOGLE_PLAY_API_KEY=$(cat service-account-key.json)
```

### 6. Update Product IDs (Production)

In `lib/services/subscription_service.dart`, verify product IDs match Play Console:

```dart
static const String monthlySubId = 'biohacker_monthly_sub';
static const String annualSubId = 'biohacker_annual_sub';
```

Also update package name in `supabase/functions/verify-subscription/index.ts`:

```typescript
const GOOGLE_PLAY_PACKAGE_NAME = 'com.biohacker.app'
```

### 7. Integrate into App

#### A. Add to Main App

In `lib/main.dart`, initialize subscription service:

```dart
import 'services/subscription_service.dart';
import 'screens/paywall_screen.dart';

// Add provider
final subscriptionServiceProvider = ChangeNotifierProvider<SubscriptionService>(
  (ref) => SubscriptionService(),
);
```

#### B. Add to Profile Screen

Show subscription status card in profile:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/subscription_settings_screen.dart';
import 'services/subscription_service.dart';

// In your profile screen build method:
final subscriptionService = ref.watch(subscriptionServiceProvider);
final status = subscriptionService.status;

// Add subscription status card
ListTile(
  leading: Icon(Icons.workspace_premium),
  title: Text(status?.tier == 'premium' ? 'Premium' : 'Free Trial'),
  subtitle: Text(status?.isInTrial ? '${status?.trialDaysRemaining} days left' : 'Manage subscription'),
  trailing: Icon(Icons.arrow_forward_ios),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => SubscriptionSettingsScreen()),
  ),
)
```

#### C. Add Subscription Banner

Add banner to home screen to show trial countdown:

```dart
import 'widgets/subscription_banner.dart';

// In your home screen:
Column(
  children: [
    SubscriptionBanner(), // Shows when trial is ending
    // ... rest of your content
  ],
)
```

#### D. Check Access Before Features

Gate premium features behind subscription check:

```dart
final subscriptionService = ref.watch(subscriptionServiceProvider);

if (!subscriptionService.status?.hasPremiumAccess ?? false) {
  // Show paywall
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PaywallScreen(canDismiss: false),
      fullscreenDialog: true,
    ),
  );
  return;
}

// Continue with premium feature
```

## 🧪 Testing

### Test Purchase Flow

1. Add your Gmail account to Play Console license testers
2. Build and install debug APK:
   ```bash
   flutter build apk --debug
   adb install build/app/outputs/flutter-apk/app-debug.apk
   ```
3. Sign in with test account
4. Trigger paywall and attempt purchase
5. Verify purchase completes without charging
6. Check subscription status updates in app

### Test Trial Expiry

Manually update database to test expired trial:

```sql
UPDATE users 
SET subscription_ends_at = NOW() - INTERVAL '1 day'
WHERE id = 'YOUR_USER_ID';
```

Restart app and verify paywall appears.

### Test Restore Purchases

1. Complete test purchase
2. Uninstall app
3. Reinstall and login
4. Tap "Restore Purchases"
5. Verify subscription status restores

## 📊 Monitoring

### Check Subscription Status

Query Supabase:

```sql
SELECT 
  id,
  email,
  subscription_tier,
  subscription_starts_at,
  subscription_ends_at,
  user_number
FROM users
WHERE subscription_tier = 'premium'
ORDER BY subscription_starts_at DESC;
```

### Track Conversions

```sql
SELECT 
  COUNT(*) FILTER (WHERE subscription_tier = 'trial') as trial_users,
  COUNT(*) FILTER (WHERE subscription_tier = 'premium') as premium_users,
  COUNT(*) FILTER (WHERE subscription_tier = 'free') as free_users
FROM users;
```

### Monitor Purchases

```sql
SELECT 
  sp.*,
  u.email
FROM subscription_purchases sp
JOIN users u ON sp.user_id = u.id
WHERE sp.is_active = true
ORDER BY sp.created_at DESC;
```

## 🔒 Security Notes

1. **Never store subscription logic client-side only** - Always verify server-side
2. **Purchase tokens are sensitive** - Never log or expose them
3. **Use edge functions** - Verification must happen on server
4. **Validate on app launch** - Check subscription status on every session
5. **Handle edge cases** - Refunds, cancellations, expired cards, etc.

## 🐛 Troubleshooting

### "Product not found" error
- Verify product IDs match Play Console exactly
- Ensure app is published to internal/closed testing track
- Wait 24h after creating products for propagation

### Purchase doesn't complete
- Check Google Play account has valid payment method
- Verify billing permission in AndroidManifest.xml
- Check Play Console → Order management for transaction status

### Subscription doesn't restore
- Verify user is signed in with same Google account
- Check Play Console for purchase history
- Ensure `restorePurchases()` is calling Google Play API

### Trial doesn't start
- Check Supabase trigger is enabled
- Verify `initialize_free_trial()` function exists
- Check user record in database manually

## 📈 Next Steps

1. **Analytics**: Add Firebase Analytics to track conversion funnel
2. **A/B Testing**: Test different price points ($9.99 vs $14.99)
3. **Promotional Offers**: Set up intro pricing in Play Console
4. **Churned Users**: Re-engagement campaigns for expired trials
5. **Referral Program**: Give bonus trial days for referrals

## 📚 Resources

- [Google Play Billing Docs](https://developer.android.com/google/play/billing)
- [in_app_purchase Package](https://pub.dev/packages/in_app_purchase)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [Play Console Guide](https://support.google.com/googleplay/android-developer)

---

**Pricing Recommendation:** $9.99/month is competitive for health/peptide tracking niche. Monitor conversion rates and adjust if needed.

**Support:** For subscription issues, direct users to subscription_settings_screen.dart → "Manage in Google Play" button.
