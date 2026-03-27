# Subscription System - Flow Diagrams

Visual reference for how the subscription system works.

## 📱 User Journey

```
┌─────────────────────────────────────────────────────────────┐
│                    NEW USER SIGNUP                          │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  Database Trigger: initialize_free_trial()                  │
│    - subscription_tier = 'trial'                            │
│    - subscription_starts_at = NOW()                         │
│    - subscription_ends_at = NOW() + 30 days                 │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│               TRIAL PERIOD (Days 1-14)                      │
│  ✓ Full access to all features                             │
│  ✓ No banner shown (>14 days left)                         │
│  ✓ Profile shows "Free Trial"                              │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│            TRIAL ENDING SOON (Days 15-30)                   │
│  ✓ Full access continues                                   │
│  ⚠️ Banner appears: "X days left"                          │
│  ⚠️ Warning icon if <7 days                                │
│  🔼 "Upgrade" button in banner                             │
└─────────────────────────────────────────────────────────────┘
                          ↓
                    ┌─────┴─────┐
                    │           │
              User upgrades   Trial expires
                    │           │
                    ↓           ↓
┌─────────────────────────────────────┐   ┌─────────────────┐
│         PREMIUM ACCESS              │   │  PAYWALL SHOWN  │
│  ✓ subscription_tier = 'premium'    │   │  ❌ Access blocked│
│  ✓ Full feature access              │   │  🔒 Must upgrade │
│  ✓ Billing via Google Play          │   └─────────────────┘
│  ✓ Auto-renews monthly              │           │
└─────────────────────────────────────┘           │
                                                  ↓
                                         User subscribes
                                                  ↓
                                    ┌─────────────────────────┐
                                    │   PREMIUM ACCESS        │
                                    └─────────────────────────┘
```

---

## 💳 Purchase Flow

```
┌──────────────────────────────────────────────────────────────┐
│  USER TAPS "SUBSCRIBE" ON PAYWALL                           │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│  SubscriptionService.purchaseMonthlySubscription()           │
│    - Load product details from Google Play                   │
│    - Verify product exists                                   │
│    - Call in_app_purchase.buyNonConsumable()                │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│  GOOGLE PLAY BILLING                                         │
│    - Show payment sheet                                      │
│    - User confirms purchase                                  │
│    - Payment processed                                       │
│    - Purchase token generated                                │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│  in_app_purchase.purchaseStream EMITS EVENT                  │
│    - PurchaseDetails with token                              │
│    - Status: purchased                                       │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│  SubscriptionService._handlePurchaseUpdates()                │
│    - Receives purchase details                               │
│    - Calls _verifyAndActivateSubscription()                 │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│  CALL SUPABASE EDGE FUNCTION                                 │
│  POST /verify-subscription                                   │
│  Body: {                                                     │
│    user_id: '...',                                           │
│    purchase_token: '...',                                    │
│    product_id: 'biohacker_monthly_sub',                     │
│    platform: 'android'                                       │
│  }                                                           │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│  EDGE FUNCTION: verify-subscription                          │
│    1. Verify user is authenticated                           │
│    2. Call Google Play Developer API                         │
│    3. Validate purchase token                                │
│    4. Check subscription is active                           │
└──────────────────────────────────────────────────────────────┘
                          ↓
                    ┌─────┴─────┐
                    │           │
                Valid       Invalid
                    │           │
                    ↓           ↓
┌─────────────────────────────────────┐   ┌─────────────────┐
│  EDGE FUNCTION SUCCESS              │   │  ERROR RETURNED │
│    1. Insert to subscription_purchases│  │  Purchase fails │
│    2. Update users table:            │   └─────────────────┘
│       - subscription_tier = 'premium'│
│       - subscription_starts_at = NOW()│
│       - subscription_ends_at = +30d  │
│    3. Return success to client       │
└─────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────────────────────┐
│  CLIENT RECEIVES SUCCESS                                     │
│    - SubscriptionService.refreshStatus()                    │
│    - Update UI (dismiss paywall)                             │
│    - Show "Premium" in profile                               │
│    - Remove banner                                           │
└──────────────────────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────────────────────┐
│  PREMIUM ACCESS GRANTED ✓                                    │
└──────────────────────────────────────────────────────────────┘
```

---

## 🔄 Restore Purchases Flow

```
┌──────────────────────────────────────────────────────────────┐
│  USER TAPS "RESTORE PURCHASES"                              │
│  (New device, reinstall, or purchase not showing)           │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│  SubscriptionService.restorePurchases()                      │
│    - Call in_app_purchase.restorePurchases()                │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│  GOOGLE PLAY QUERIES PAST PURCHASES                          │
│    - Check signed-in Google account                          │
│    - Find all active subscriptions                           │
│    - Return purchase details                                 │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│  purchaseStream EMITS RESTORED PURCHASES                     │
│    - PurchaseDetails with status: restored                   │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│  SAME VERIFICATION FLOW AS NEW PURCHASE                      │
│    - Call edge function                                      │
│    - Verify with Google Play API                             │
│    - Update database                                         │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│  SUBSCRIPTION STATUS RESTORED ✓                              │
│    - User sees "Premium" in profile                          │
│    - Full access granted                                     │
└──────────────────────────────────────────────────────────────┘
```

---

## 🗄️ Database State Transitions

```
NEW USER SIGNUP
    ↓
┌──────────────────────────────────┐
│ subscription_tier: 'trial'       │
│ subscription_starts_at: NOW()    │
│ subscription_ends_at: +30 days   │
│ user_number: auto-increment      │
└──────────────────────────────────┘
    ↓ (User subscribes)
┌──────────────────────────────────┐
│ subscription_tier: 'premium'     │
│ subscription_starts_at: NOW()    │
│ subscription_ends_at: +30 days   │  ← Auto-renews
│ user_number: unchanged           │
└──────────────────────────────────┘
    ↓ (User cancels)
┌──────────────────────────────────┐
│ subscription_tier: 'premium'     │
│ subscription_starts_at: unchanged│
│ subscription_ends_at: unchanged  │  ← Access until expiry
│ [subscription_purchases:         │
│   is_active: false]              │
└──────────────────────────────────┘
    ↓ (Expiry date passes)
┌──────────────────────────────────┐
│ subscription_tier: 'free'        │
│ subscription_starts_at: NULL     │
│ subscription_ends_at: (past)     │
│ [Paywall shown]                  │
└──────────────────────────────────┘
```

---

## 🎨 UI Component Visibility

```
TRIAL ACTIVE (>14 days left)
┌──────────────────────────────┐
│ Profile: "Free Trial"        │ ✓ Visible
│ Banner: Hidden               │ ✗ Hidden
│ Paywall: Hidden              │ ✗ Hidden
│ Features: Unlocked           │ ✓ Accessible
└──────────────────────────────┘

TRIAL ENDING (<14 days left)
┌──────────────────────────────┐
│ Profile: "Free Trial - Xd"   │ ✓ Visible
│ Banner: "X days left"        │ ✓ Visible
│ Paywall: Hidden              │ ✗ Hidden
│ Features: Unlocked           │ ✓ Accessible
└──────────────────────────────┘

TRIAL EXPIRED
┌──────────────────────────────┐
│ Profile: "Free"              │ ✓ Visible
│ Banner: "Trial expired"      │ ✓ Visible
│ Paywall: Blocking access     │ ✓ Visible
│ Features: Locked             │ ✗ Blocked
└──────────────────────────────┘

PREMIUM ACTIVE
┌──────────────────────────────┐
│ Profile: "Premium"           │ ✓ Visible
│ Banner: Hidden               │ ✗ Hidden
│ Paywall: Hidden              │ ✗ Hidden
│ Features: Unlocked           │ ✓ Accessible
└──────────────────────────────┘
```

---

## 🔐 Security Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        CLIENT                               │
│  ❌ NO subscription tier stored locally                    │
│  ❌ NO purchase validation client-side                     │
│  ❌ NO access control client-side                          │
│  ✓ Only displays UI based on server state                  │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                   GOOGLE PLAY BILLING                       │
│  ✓ Handles payment processing                              │
│  ✓ Generates purchase tokens                               │
│  ✓ Manages subscription lifecycle                          │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                 SUPABASE EDGE FUNCTION                      │
│  ✓ Verifies purchase tokens with Google API                │
│  ✓ Validates subscription status                           │
│  ✓ Single source of truth for access                       │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                    SUPABASE DATABASE                        │
│  ✓ Stores verified subscription state                      │
│  ✓ subscription_tier controls access                       │
│  ✓ subscription_purchases logs all transactions            │
└─────────────────────────────────────────────────────────────┘
```

**Attack Prevention:**

❌ **Cannot bypass paywall** - Access controlled by database, not client  
❌ **Cannot fake purchase** - Tokens verified with Google Play API  
❌ **Cannot modify tier** - Only edge function can update database  
❌ **Cannot intercept/replay** - Tokens are one-time use and validated  

---

## 📊 Data Flow

```
┌────────────┐      ┌────────────┐      ┌────────────┐
│   Client   │◄────►│  Supabase  │◄────►│ Google API │
└────────────┘      └────────────┘      └────────────┘
      │                   │                     │
      │ 1. Purchase       │                     │
      │────────────────►  │                     │
      │                   │ 2. Verify token     │
      │                   │────────────────────►│
      │                   │ 3. Valid response   │
      │                   │◄────────────────────│
      │                   │ 4. Update DB        │
      │                   │ (tier = premium)    │
      │ 5. Success        │                     │
      │◄────────────────  │                     │
      │ 6. Refresh status │                     │
      │────────────────►  │                     │
      │ 7. Premium access │                     │
      │◄────────────────  │                     │
```

---

## 🔔 Subscription Lifecycle

```
Day 0: SIGNUP
    ↓
    Trial starts (30 days)
    ↓
Day 14: BANNER APPEARS
    ↓
    "16 days left" countdown
    ↓
Day 23: WARNING
    ↓
    "7 days left" - orange warning
    ↓
Day 30: TRIAL EXPIRES
    ↓
┌───────┴────────┐
│                │
User             User
subscribes       ignores
│                │
↓                ↓
PREMIUM      PAYWALL SHOWN
(Day 31)     (Access blocked)
│                │
↓                │
Auto-renew       │
every 30d        │
│                │
↓                ↓
Premium      User subscribes
continues    → Premium granted
```

---

## 💰 Revenue Flow

```
USER SUBSCRIBES ($9.99)
         ↓
┌────────────────────────┐
│   Google Play Store    │
│   - 15% fee = $1.50    │ (30% if <$1M revenue/year)
│   - You get: $8.49     │
└────────────────────────┘
         ↓
Monthly payouts to bank account
         ↓
Track in Play Console:
- Active subscribers
- Churn rate
- MRR (Monthly Recurring Revenue)
- LTV (Lifetime Value)
```

---

## 📈 Key Metrics to Track

```
┌─────────────────────────────────────┐
│ TRIAL METRICS                       │
├─────────────────────────────────────┤
│ • Trial signups                     │
│ • Trial completion rate (day 30)    │
│ • Trial→Premium conversion %        │
│ • Average days before conversion    │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ SUBSCRIPTION METRICS                │
├─────────────────────────────────────┤
│ • Active subscribers                │
│ • Monthly churn rate                │
│ • MRR (Monthly Recurring Revenue)   │
│ • ARPU (Avg Revenue Per User)       │
│ • LTV (Lifetime Value)              │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ FUNNEL METRICS                      │
├─────────────────────────────────────┤
│ • Paywall views                     │
│ • Paywall→Purchase conversion       │
│ • Purchase completion rate          │
│ • Payment failure rate              │
└─────────────────────────────────────┘
```

**Target KPIs:**

- Trial→Premium: **>20%** conversion
- Monthly churn: **<5%** churn rate
- LTV: **>$150** (15+ months retention)
- Paywall→Purchase: **>10%** conversion

---

## 🎯 Decision Tree: When to Show Paywall

```
                    User opens app
                          ↓
                 Check subscription status
                          ↓
        ┌─────────────────┴─────────────────┐
        │                                   │
   tier = 'premium'                   tier = 'trial'
   is_active = true                          │
        │                                    ↓
        ↓                          ends_at > NOW()?
   ALLOW ACCESS                              │
                                  ┌──────────┴──────────┐
                                  │                     │
                                 YES                   NO
                                  │                     │
                                  ↓                     ↓
                            ALLOW ACCESS           SHOW PAYWALL
                                                   (canDismiss: false)

                              tier = 'free'
                                  │
                                  ↓
                            SHOW PAYWALL
                            (canDismiss: false)
```

---

**Next:** See `SUBSCRIPTION_QUICK_START.md` to get the system running in 30 minutes!
