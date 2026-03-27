# Subscription System Integration Examples

Quick copy-paste examples for integrating the subscription system into your existing screens.

## 1. Profile Screen Integration

Add subscription status card to your profile screen:

```dart
// At top of file
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/subscription_service.dart';
import '../screens/subscription_settings_screen.dart';
import '../theme/colors.dart';

// In your profile screen (convert to ConsumerWidget or ConsumerStatefulWidget)
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionService = ref.watch(subscriptionServiceProvider);
    final status = subscriptionService.status;

    return Scaffold(
      // ... your existing scaffold
      body: ListView(
        children: [
          // ... your existing profile items
          
          // Add subscription card
          _buildSubscriptionCard(context, status),
          
          // ... rest of your items
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, status) {
    final isPremium = status?.tier == 'premium';
    final isTrial = status?.tier == 'trial';

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F17),
        border: Border.all(
          color: isPremium 
            ? AppColors.electricPurple 
            : AppColors.neonCyan.withOpacity(0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          isPremium ? Icons.workspace_premium : Icons.access_time,
          color: isPremium ? AppColors.electricPurple : AppColors.neonCyan,
          size: 32,
        ),
        title: Text(
          isPremium ? 'PREMIUM' : isTrial ? 'FREE TRIAL' : 'FREE',
          style: TextStyle(
            color: isPremium ? AppColors.electricPurple : AppColors.neonCyan,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        subtitle: Text(
          isTrial && status?.trialDaysRemaining != null
            ? '${status!.trialDaysRemaining} days remaining'
            : isPremium
              ? 'All features unlocked'
              : 'Tap to upgrade',
          style: TextStyle(
            color: AppColors.matteWhite.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppColors.neonCyan,
          size: 16,
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SubscriptionSettingsScreen(),
          ),
        ),
      ),
    );
  }
}
```

## 2. Home Screen Integration

Add subscription banner to home screen:

```dart
// At top of file
import '../widgets/subscription_banner.dart';

// In your home screen build method
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        // Add banner at top (or wherever makes sense)
        const SubscriptionBanner(),
        
        // Your existing home screen content
        Expanded(
          child: ListView(
            children: [
              // ... your content
            ],
          ),
        ),
      ],
    ),
  );
}
```

## 3. Feature Gating

Block premium features behind subscription check:

```dart
// At top of file
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/subscription_service.dart';
import '../screens/paywall_screen.dart';

// In your feature screen (convert to ConsumerWidget)
class AdvancedAnalyticsScreen extends ConsumerWidget {
  const AdvancedAnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionService = ref.watch(subscriptionServiceProvider);
    
    // Check premium access
    if (!subscriptionService.status?.hasPremiumAccess ?? false) {
      // Show paywall instead
      return const PaywallScreen(canDismiss: false);
    }

    // Premium feature content
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced Analytics')),
      body: _buildPremiumContent(),
    );
  }

  Widget _buildPremiumContent() {
    // Your premium feature UI
    return const Center(child: Text('Premium Content'));
  }
}
```

## 4. Conditional Feature Access

Show preview or lock icon for premium features:

```dart
// In any screen
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/subscription_service.dart';
import '../screens/paywall_screen.dart';

class MyFeatureButton extends ConsumerWidget {
  const MyFeatureButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionService = ref.watch(subscriptionServiceProvider);
    final hasPremium = subscriptionService.status?.hasPremiumAccess ?? false;

    return ElevatedButton(
      onPressed: () => _handleTap(context, hasPremium),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Advanced Feature'),
          if (!hasPremium) ...[
            const SizedBox(width: 8),
            const Icon(Icons.lock, size: 16),
          ],
        ],
      ),
    );
  }

  void _handleTap(BuildContext context, bool hasPremium) {
    if (!hasPremium) {
      // Show paywall
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const PaywallScreen(canDismiss: true),
          fullscreenDialog: true,
        ),
      );
    } else {
      // Access premium feature
      Navigator.of(context).pushNamed('/advanced-feature');
    }
  }
}
```

## 5. App Bar Badge

Show subscription status in app bar:

```dart
// In your app bar
AppBar(
  title: const Text('Biohacker'),
  actions: [
    Consumer(
      builder: (context, ref, child) {
        final status = ref.watch(subscriptionServiceProvider).status;
        final isPremium = status?.tier == 'premium';

        if (isPremium) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.electricPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    ),
  ],
)
```

## 6. Onboarding Integration

Show subscription info during onboarding:

```dart
// In your onboarding flow
class OnboardingSubscriptionScreen extends ConsumerWidget {
  const OnboardingSubscriptionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(subscriptionServiceProvider).status;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.workspace_premium, size: 80, color: AppColors.electricPurple),
              const SizedBox(height: 24),
              const Text(
                'Welcome to Biohacker!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'You have 30 days of FREE premium access',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.matteWhite.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              if (status?.trialDaysRemaining != null) ...[
                const SizedBox(height: 24),
                Text(
                  '${status!.trialDaysRemaining} days remaining',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neonCyan,
                  ),
                ),
              ],
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                ),
                child: const Text('GET STARTED'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionSettingsScreen(),
                    ),
                  );
                },
                child: const Text('View subscription details'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## 7. Settings Menu Integration

Add subscription management to settings:

```dart
// In your settings screen
ListTile(
  leading: const Icon(Icons.payment),
  title: const Text('Subscription'),
  subtitle: Consumer(
    builder: (context, ref, child) {
      final status = ref.watch(subscriptionServiceProvider).status;
      final isPremium = status?.tier == 'premium';
      return Text(isPremium ? 'Premium member' : 'Manage subscription');
    },
  ),
  trailing: const Icon(Icons.arrow_forward_ios),
  onTap: () => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const SubscriptionSettingsScreen(),
    ),
  ),
),
```

## 8. Custom Paywall Trigger

Trigger paywall from anywhere:

```dart
// Create a helper function
void showUpgradePrompt(BuildContext context, {bool canDismiss = true}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PaywallScreen(canDismiss: canDismiss),
      fullscreenDialog: true,
    ),
  );
}

// Use it anywhere
ElevatedButton(
  onPressed: () => showUpgradePrompt(context),
  child: const Text('Upgrade to Premium'),
)
```

## 9. Trial Countdown Widget

Show days remaining inline:

```dart
class TrialCountdown extends ConsumerWidget {
  const TrialCountdown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(subscriptionServiceProvider).status;

    if (status == null || !status.isInTrial) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: status.isTrialExpiringSoon
          ? Colors.orange.withOpacity(0.2)
          : AppColors.neonCyan.withOpacity(0.2),
        border: Border.all(
          color: status.isTrialExpiringSoon ? Colors.orange : AppColors.neonCyan,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 16,
            color: status.isTrialExpiringSoon ? Colors.orange : AppColors.neonCyan,
          ),
          const SizedBox(width: 6),
          Text(
            '${status.trialDaysRemaining}d left',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: status.isTrialExpiringSoon ? Colors.orange : AppColors.neonCyan,
            ),
          ),
        ],
      ),
    );
  }
}

// Use it anywhere
Row(
  children: [
    const Text('Features'),
    const SizedBox(width: 8),
    const TrialCountdown(),
  ],
)
```

## 10. Initialize on App Start

Ensure subscription service loads on app start:

```dart
// In main.dart, add to your main app widget
class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize subscription service
    ref.read(subscriptionServiceProvider);

    return MaterialApp(
      // ... your app config
    );
  }
}
```

---

## Complete Example: Convert Existing Screen

Before (without subscription):
```dart
class AnalyticsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Analytics')),
      body: ListView(children: [...]),
    );
  }
}
```

After (with subscription):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/subscription_service.dart';
import '../screens/paywall_screen.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionService = ref.watch(subscriptionServiceProvider);
    
    // Gate feature behind subscription
    if (!subscriptionService.status?.hasPremiumAccess ?? false) {
      return const PaywallScreen(canDismiss: false);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(children: [...]),
    );
  }
}
```

---

**Pro Tips:**

1. **Always use `ref.watch`** for reactive updates when subscription status changes
2. **Use `const` constructors** where possible to improve performance
3. **Test both trial and premium states** to ensure UI updates correctly
4. **Show clear upgrade CTAs** - make it easy for users to subscribe
5. **Don't be annoying** - banner is dismissible for 24h for a reason

**Common Mistake:**

```dart
// ❌ DON'T: Check status only once
final hasPremium = subscriptionService.status?.hasPremiumAccess ?? false;
// This won't update when subscription changes!

// ✅ DO: Use Consumer or ref.watch
Consumer(builder: (context, ref, _) {
  final hasPremium = ref.watch(subscriptionServiceProvider)
    .status?.hasPremiumAccess ?? false;
  // This updates reactively!
})
```
