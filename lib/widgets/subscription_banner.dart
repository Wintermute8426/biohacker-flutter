import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/subscription_service.dart';
import '../screens/paywall_screen.dart';
import '../theme/colors.dart';

/// Banner showing trial countdown or upgrade prompt
/// Dismissible but reappears periodically
class SubscriptionBanner extends ConsumerStatefulWidget {
  const SubscriptionBanner({Key? key}) : super(key: key);

  @override
  ConsumerState<SubscriptionBanner> createState() => _SubscriptionBannerState();
}

class _SubscriptionBannerState extends ConsumerState<SubscriptionBanner> {
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadDismissedState();
  }

  Future<void> _loadDismissedState() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedUntil = prefs.getInt('subscription_banner_dismissed_until');
    
    if (dismissedUntil != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now < dismissedUntil) {
        setState(() => _isDismissed = true);
      }
    }
  }

  Future<void> _dismissBanner() async {
    final prefs = await SharedPreferences.getInstance();
    // Dismiss for 24 hours
    final dismissUntil = DateTime.now()
        .add(const Duration(hours: 24))
        .millisecondsSinceEpoch;
    await prefs.setInt('subscription_banner_dismissed_until', dismissUntil);
    setState(() => _isDismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    final subscriptionService = ref.watch(subscriptionServiceProvider);
    final status = subscriptionService.status;

    // Don't show if premium or loading
    if (status == null || status.tier == 'premium') {
      return const SizedBox.shrink();
    }

    // Don't show if trial has plenty of time left (> 14 days)
    if (status.isInTrial && (status.trialDaysRemaining ?? 0) > 14) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.2),
            AppColors.accent.withOpacity(0.2),
          ],
        ),
        border: Border.all(
          color: status.isTrialExpiringSoon
              ? Colors.orange
              : AppColors.primary.withOpacity(0.5),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (status.isTrialExpiringSoon ? Colors.orange : AppColors.primary)
                .withOpacity(0.1),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            status.isTrialExpiringSoon ? Icons.warning : Icons.workspace_premium,
            color: status.isTrialExpiringSoon ? Colors.orange : AppColors.primary,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.isInTrial
                      ? 'Trial: ${status.trialDaysRemaining} days left'
                      : 'Trial expired',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status.isInTrial
                      ? 'Upgrade now to keep your data & features'
                      : 'Upgrade to continue using Biohacker',
                  style: TextStyle(
                    color: AppColors.textLight.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              ElevatedButton(
                onPressed: () => _showPaywall(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'UPGRADE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              TextButton(
                onPressed: _dismissBanner,
                child: Text(
                  'Later',
                  style: TextStyle(
                    color: AppColors.textLight.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPaywall(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PaywallScreen(canDismiss: true),
        fullscreenDialog: true,
      ),
    );
  }
}
