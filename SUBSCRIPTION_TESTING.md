# Subscription Testing Guide

## Quick Test Checklist

Use this checklist to verify the subscription system works correctly before production release.

### ✅ Pre-Testing Setup

- [ ] Product IDs created in Play Console (`biohacker_monthly_sub`, `biohacker_annual_sub`)
- [ ] License testing emails added in Play Console
- [ ] Supabase migration executed
- [ ] Edge function deployed
- [ ] App installed on test device with test account

### ✅ New User Flow

1. **First Launch**
   - [ ] User signs up with new account
   - [ ] Trial auto-starts (30 days)
   - [ ] Database shows `subscription_tier = 'trial'`
   - [ ] `subscription_ends_at` is 30 days from now
   - [ ] No paywall shows on first launch

2. **During Trial (Day 1-14)**
   - [ ] Subscription banner does NOT show (>14 days left)
   - [ ] All features accessible
   - [ ] Profile shows "Free Trial" status

3. **Trial Ending Soon (Day 15-30)**
   - [ ] Subscription banner shows with countdown
   - [ ] Banner says "X days left"
   - [ ] Banner dismissible (but reappears after 24h)
   - [ ] All features still accessible

4. **Trial Expired**
   - [ ] Paywall appears on app launch
   - [ ] Cannot dismiss paywall (canDismiss: false)
   - [ ] Features blocked until upgrade
   - [ ] Banner shows "Trial expired"

### ✅ Purchase Flow

1. **Monthly Subscription**
   - [ ] Tap "UPGRADE" button
   - [ ] Paywall screen loads
   - [ ] Products load from Play Store
   - [ ] Monthly shows as "RECOMMENDED"
   - [ ] Tap "SUBSCRIBE" on monthly plan
   - [ ] Google Play payment sheet appears
   - [ ] Complete test purchase (not charged as test account)
   - [ ] Purchase completes successfully
   - [ ] Paywall dismisses
   - [ ] Database updates: `subscription_tier = 'premium'`
   - [ ] Profile shows "Premium" status
   - [ ] Subscription settings shows billing cycle
   - [ ] `subscription_purchases` table has record

2. **Annual Subscription**
   - [ ] Annual card shows "20% OFF" badge
   - [ ] Price shown correctly
   - [ ] Purchase flow completes
   - [ ] Database shows 365-day expiry

### ✅ Restore Purchases

1. **Uninstall/Reinstall**
   - [ ] Complete purchase on test account
   - [ ] Note purchase details
   - [ ] Uninstall app
   - [ ] Reinstall app
   - [ ] Login with same account
   - [ ] Shows as trial/free (not premium)
   - [ ] Tap "Restore Purchases" in settings
   - [ ] Subscription restores successfully
   - [ ] Profile shows "Premium" status
   - [ ] Database updated correctly

2. **Different Device**
   - [ ] Purchase on Device A
   - [ ] Login on Device B with same account
   - [ ] Tap "Restore Purchases"
   - [ ] Premium access granted on Device B

### ✅ Edge Cases

1. **Purchase Cancellation**
   - [ ] Cancel subscription in Google Play
   - [ ] Access remains until expiry date
   - [ ] App shows "Expires on [date]"
   - [ ] After expiry, paywall reappears

2. **Payment Failure**
   - [ ] Subscription renews but payment fails
   - [ ] Grace period activates (3 days)
   - [ ] App still shows premium access during grace
   - [ ] After grace period, access revoked

3. **Refund**
   - [ ] Request refund in Google Play
   - [ ] Access immediately revoked
   - [ ] Database updates to free tier
   - [ ] Paywall appears

### ✅ UI/UX Testing

1. **Paywall Screen**
   - [ ] Cyberpunk theme consistent
   - [ ] Scanline overlay present
   - [ ] Terminal-style header renders
   - [ ] Feature list displays correctly
   - [ ] Pricing cards styled properly
   - [ ] CTA buttons clear and functional
   - [ ] Loading states work (processing purchase)
   - [ ] Error messages display if purchase fails
   - [ ] Can dismiss when `canDismiss: true`
   - [ ] Cannot dismiss when `canDismiss: false`

2. **Subscription Settings Screen**
   - [ ] Status card shows correct tier
   - [ ] Premium badge shows for premium users
   - [ ] Trial countdown accurate
   - [ ] Expiring soon warning shows (<7 days)
   - [ ] Plan details accurate (start/end dates)
   - [ ] "Manage in Google Play" button works
   - [ ] Opens Play Store subscription management
   - [ ] "Restore Purchases" button functional
   - [ ] Success/error messages display

3. **Subscription Banner**
   - [ ] Shows only when relevant (trial ending or expired)
   - [ ] Doesn't show for premium users
   - [ ] Doesn't show if trial >14 days
   - [ ] Dismissible
   - [ ] Reappears after 24h
   - [ ] "Upgrade" button goes to paywall
   - [ ] Warning icon for expiring soon
   - [ ] Text updates based on days remaining

### ✅ Database Verification

After each test, verify database state:

```sql
-- Check user subscription
SELECT 
  id,
  email,
  subscription_tier,
  subscription_starts_at,
  subscription_ends_at,
  user_number
FROM users
WHERE email = 'your_test_email@gmail.com';

-- Check purchases
SELECT * FROM subscription_purchases
WHERE user_id = 'YOUR_USER_ID'
ORDER BY created_at DESC;
```

Expected states:
- **New signup**: tier='trial', ends_at=+30 days
- **Active premium**: tier='premium', ends_at=+30 days (monthly) or +365 days (annual)
- **Expired trial**: tier='trial', ends_at < NOW()
- **Cancelled**: tier='premium', ends_at in future, is_active=false in purchases

### ✅ Server-Side Verification

1. **Edge Function**
   - [ ] Function deploys without errors
   - [ ] Test invocation succeeds
   - [ ] Logs show verification attempts
   - [ ] Google Play API called (if configured)
   - [ ] Purchase recorded in `subscription_purchases`
   - [ ] User tier updated after verification

2. **Security**
   - [ ] Cannot bypass paywall client-side
   - [ ] Cannot modify subscription tier directly
   - [ ] Purchase token validated server-side
   - [ ] Unauthorized requests rejected

### ✅ Performance Testing

1. **Load Times**
   - [ ] Products load <2 seconds
   - [ ] Subscription status loads <1 second
   - [ ] Paywall renders instantly
   - [ ] No lag when tapping buttons

2. **Offline Behavior**
   - [ ] Cached subscription status used when offline
   - [ ] Graceful error if purchase attempted offline
   - [ ] Retry logic works when connection restored

### ✅ Analytics (Optional)

If using Firebase Analytics:

- [ ] Track `trial_start` event
- [ ] Track `paywall_view` event
- [ ] Track `subscription_purchase` event
- [ ] Track `trial_conversion` (trial → premium)
- [ ] Track `churn` (cancelled subscriptions)

## Manual Test Scenarios

### Scenario 1: Happy Path
1. New user signs up → trial starts
2. Uses app for 20 days
3. Sees banner "10 days left"
4. Taps "Upgrade" → completes purchase
5. Premium access granted
6. Banner disappears

### Scenario 2: Trial Expiry
1. New user signs up → trial starts
2. Manually set expiry to yesterday in DB
3. Restart app
4. Paywall blocks access
5. User purchases → access restored

### Scenario 3: Device Switch
1. User A purchases on Phone 1
2. User A logs in on Phone 2
3. Taps "Restore Purchases"
4. Premium access on Phone 2

### Scenario 4: Cancellation
1. User purchases monthly
2. Cancels in Google Play
3. Access continues until expiry
4. After expiry, paywall shows
5. User can re-subscribe

## Automated Testing (Future)

Consider adding widget tests:

```dart
testWidgets('Paywall shows for expired trial', (tester) async {
  // Mock expired trial status
  // Verify paywall renders
  // Verify cannot dismiss
});

testWidgets('Banner shows for ending trial', (tester) async {
  // Mock trial with 5 days left
  // Verify banner appears
  // Verify countdown text
});
```

## Production Checklist

Before going live:

- [ ] Remove test product IDs (if using separate test/prod)
- [ ] Set `GOOGLE_PLAY_API_KEY` in production Supabase
- [ ] Update `GOOGLE_PLAY_PACKAGE_NAME` to production package
- [ ] Verify edge function deployed to production project
- [ ] Enable real-time developer notifications (RTDNs)
- [ ] Set up monitoring/alerting for failed purchases
- [ ] Document support process for subscription issues
- [ ] Add FAQ to app about subscriptions
- [ ] Test production purchase with real money (small amount)
- [ ] Set up refund policy in Play Console
- [ ] Add subscription terms to app's legal section

## Support Testing

Test user-facing support flows:

1. **User wants to cancel**
   - [ ] Clear instructions in settings screen
   - [ ] "Manage in Google Play" button works
   - [ ] Opens correct subscription management page

2. **User reports "not working after purchase"**
   - [ ] Check `subscription_purchases` table
   - [ ] Verify edge function logs
   - [ ] Try "Restore Purchases"
   - [ ] Verify Google account matches

3. **User wants refund**
   - [ ] Direct to Google Play support
   - [ ] Revoke access if refunded
   - [ ] Update database accordingly

## Common Issues & Fixes

| Issue | Likely Cause | Fix |
|-------|--------------|-----|
| Products not loading | Not in testing track | Publish to internal test |
| Purchase doesn't complete | Missing billing permission | Add to AndroidManifest.xml |
| Subscription doesn't restore | Wrong Google account | Verify account in Play Store |
| Database not updating | Edge function error | Check Supabase logs |
| Paywall always shows | Status not loading | Check auth state |

---

**Test Coverage Goal:** 100% of user flows tested before production.

**Regression Testing:** Re-run this checklist after any billing-related code changes.
