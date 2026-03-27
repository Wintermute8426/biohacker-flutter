# Subscription System

## Overview

The Biohacker app uses a **30-day free trial** followed by a **$9.99/month** subscription model.

### Key Features
- ✅ Automatic 30-day free trial for all new users
- ✅ Trial countdown banner (shows when <14 days remaining)
- ✅ Cyberpunk-themed paywall screen
- ✅ Google Play Billing integration
- ✅ Server-side purchase verification (Supabase Edge Function)
- ✅ Secure subscription status tracking
- ✅ Restore purchases support
- ✅ Subscription management settings

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Client (Flutter)                    │
├─────────────────────────────────────────────────────────┤
│  SubscriptionService                                    │
│    ↓                                                     │
│  Google Play Billing API (in_app_purchase package)     │
│    ↓                                                     │
│  Purchase → Server Verification                         │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                   Server (Supabase)                     │
├─────────────────────────────────────────────────────────┤
│  Edge Function: verify-subscription                     │
│    ↓                                                     │
│  Google Play Developer API                              │
│    ↓                                                     │
│  Database: subscription_purchases table                 │
│    ↓                                                     │
│  Update: users.subscription_tier = 'premium'            │
└─────────────────────────────────────────────────────────┘
```

## Files

### Services
- `lib/services/subscription_service.dart` - Core billing logic
- `lib/models/subscription_status.dart` - Subscription state model

### UI
- `lib/screens/paywall_screen.dart` - Upgrade prompt (cyberpunk styled)
- `lib/screens/subscription_settings_screen.dart` - Manage subscription
- `lib/widgets/subscription_banner.dart` - Trial countdown banner

### Backend
- `lib/migrations/add_subscription_fields.sql` - Database schema
- `supabase/functions/verify-subscription/index.ts` - Purchase verification

### Documentation
- `SUBSCRIPTION_SETUP.md` - Complete setup guide
- `SUBSCRIPTION_TESTING.md` - Testing checklist

## Quick Start

### 1. Setup (First Time)

See `SUBSCRIPTION_SETUP.md` for detailed instructions.

**TL;DR:**
1. Run database migration in Supabase
2. Create subscription products in Google Play Console
3. Deploy edge function: `supabase functions deploy verify-subscription`
4. Add test accounts for license testing

### 2. Integration

**Add to Profile Screen:**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/subscription_settings_screen.dart';
import 'services/subscription_service.dart';

final subscriptionService = ref.watch(subscriptionServiceProvider);
final status = subscriptionService.status;

ListTile(
  leading: Icon(Icons.workspace_premium),
  title: Text(status?.tier == 'premium' ? 'Premium' : 'Free Trial'),
  subtitle: Text(
    status?.isInTrial 
      ? '${status?.trialDaysRemaining} days left' 
      : 'Manage subscription'
  ),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => SubscriptionSettingsScreen()),
  ),
)
```

**Add Banner to Home:**

```dart
import 'widgets/subscription_banner.dart';

Column(
  children: [
    SubscriptionBanner(), // Shows when trial ending/expired
    // ... rest of content
  ],
)
```

**Gate Premium Features:**

```dart
final subscriptionService = ref.watch(subscriptionServiceProvider);

if (!subscriptionService.status?.hasPremiumAccess ?? false) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PaywallScreen(canDismiss: false),
      fullscreenDialog: true,
    ),
  );
  return;
}

// Continue with premium feature...
```

## User Flow

### New User
1. Signs up → **Trial auto-starts** (30 days)
2. Full access to all features
3. Day 15+ → **Banner appears** ("15 days left")
4. Day 30 → **Trial expires**
5. **Paywall blocks access**
6. User purchases → **Premium access granted**

### Returning User (Purchased)
1. Opens app → Status checked
2. If premium → Full access
3. If cancelled → Access until expiry date
4. After expiry → Paywall appears

## Subscription Tiers

| Tier | Access | Duration | Price |
|------|--------|----------|-------|
| **Trial** | Full access | 30 days | Free |
| **Premium** | Full access | Monthly/Annual | $9.99/month |
| **Free** | No access | N/A | Free |

## Product IDs

| Product | ID | Price | Billing |
|---------|----|----|----------|
| Monthly | `biohacker_monthly_sub` | $9.99 | Every 30 days |
| Annual | `biohacker_annual_sub` | $99.99 | Every 365 days |

## Testing

See `SUBSCRIPTION_TESTING.md` for complete test checklist.

**Quick Test:**
1. Add test Gmail to Play Console license testing
2. Build debug APK
3. Sign in with test account
4. Verify trial starts automatically
5. Trigger paywall (set expiry to past in DB)
6. Complete test purchase (not charged)
7. Verify premium access granted

## Security

✅ **Server-side verification** - All purchases validated by Supabase Edge Function  
✅ **Google Play API** - Purchase tokens verified with Google  
✅ **Database-driven** - Subscription status stored securely in Supabase  
✅ **No client-side bypass** - Paywall cannot be circumvented  

## Support

**User wants to cancel:**
- Settings → Subscription → "Manage in Google Play"
- Opens Play Store subscription management
- Cancel there (access continues until expiry)

**User reports purchase not working:**
1. Check `subscription_purchases` table in Supabase
2. Verify edge function logs
3. Try "Restore Purchases" in app
4. Verify Google account matches purchase account

**User wants refund:**
- Direct to Google Play support
- Access revoked immediately upon refund
- Database auto-updates via webhook (if RTDNs configured)

## Analytics

Recommended events to track:

- `trial_start` - User signs up, trial begins
- `paywall_view` - Paywall screen shown
- `subscription_purchase` - User completes purchase
- `trial_conversion` - Trial → Premium
- `churn` - Subscription cancelled

## Pricing Strategy

**Current:** $9.99/month  
**Rationale:** Competitive for health/biohacking niche

**Consider testing:**
- $14.99/month (premium positioning)
- $7.99/month (higher volume)
- Introductory offer: First month $4.99

Monitor conversion rates and adjust accordingly.

## Future Enhancements

- [ ] Promotional offers (first month discount)
- [ ] Referral program (bonus trial days)
- [ ] Lifetime purchase option
- [ ] Family plan (multiple users)
- [ ] Analytics dashboard (track conversions)
- [ ] Re-engagement campaigns (churned users)
- [ ] Push notifications (trial ending, payment failed)

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Products not loading | Publish to internal test track in Play Console |
| Purchase doesn't complete | Add billing permission to AndroidManifest.xml |
| Subscription doesn't restore | Verify same Google account, check Play Console |
| Database not updating | Check edge function logs in Supabase |
| Paywall always shows | Verify subscription status loading correctly |

## Resources

- [Setup Guide](SUBSCRIPTION_SETUP.md) - Complete installation instructions
- [Testing Guide](SUBSCRIPTION_TESTING.md) - Test checklist
- [Google Play Billing Docs](https://developer.android.com/google/play/billing)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)

---

**Questions?** See `SUBSCRIPTION_SETUP.md` for detailed documentation.
