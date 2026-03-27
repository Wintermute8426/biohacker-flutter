import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/subscription_service.dart';
import '../widgets/scanline_overlay.dart';
import '../theme/colors.dart';
import 'paywall_screen.dart';

/// Subscription management screen
/// Shows current plan, billing cycle, and manage options
class SubscriptionSettingsScreen extends ConsumerWidget {
  const SubscriptionSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionService = ref.watch(subscriptionServiceProvider);
    final status = subscriptionService.status;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F17),
        elevation: 0,
        title: Text(
          'SUBSCRIPTION',
          style: TextStyle(
            color: AppColors.neonCyan,
            fontFamily: 'monospace',
            letterSpacing: 2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.neonCyan),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          const ScanlineOverlay(),
          SafeArea(
            child: status == null
                ? const Center(child: CircularProgressIndicator(color: AppColors.neonCyan))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildStatusCard(context, status),
                        const SizedBox(height: 24),
                        _buildPlanDetails(status),
                        const SizedBox(height: 24),
                        _buildActionButtons(context, ref, status),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, status) {
    final isPremium = status.tier == 'premium';
    final isTrial = status.tier == 'trial';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F17),
        border: Border.all(
          color: isPremium
              ? AppColors.electricPurple
              : isTrial
                  ? AppColors.neonCyan
                  : AppColors.matteWhite.withOpacity(0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isPremium
            ? [
                BoxShadow(
                  color: AppColors.electricPurple.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isPremium ? Icons.workspace_premium : Icons.access_time,
                color: isPremium ? AppColors.electricPurple : AppColors.neonCyan,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPremium
                          ? 'PREMIUM'
                          : isTrial
                              ? 'FREE TRIAL'
                              : 'FREE',
                      style: TextStyle(
                        color: isPremium
                            ? AppColors.electricPurple
                            : isTrial
                                ? AppColors.neonCyan
                                : AppColors.matteWhite,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (isTrial && status.trialDaysRemaining != null)
                      Text(
                        '${status.trialDaysRemaining} days remaining',
                        style: TextStyle(
                          color: AppColors.matteWhite.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (isTrial && status.isTrialExpiringSoon) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your trial is ending soon! Upgrade to keep access.',
                      style: TextStyle(
                        color: AppColors.matteWhite.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanDetails(status) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F17),
        border: Border.all(color: AppColors.neonCyan.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PLAN_DETAILS',
            style: TextStyle(
              color: AppColors.neonCyan,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Status', status.isActive ? 'Active' : 'Inactive'),
          if (status.subscriptionStartsAt != null)
            _buildDetailRow('Started', dateFormat.format(status.subscriptionStartsAt!)),
          if (status.subscriptionEndsAt != null)
            _buildDetailRow(
              status.tier == 'premium' ? 'Renews on' : 'Expires on',
              dateFormat.format(status.subscriptionEndsAt!),
            ),
          if (status.tier == 'premium')
            _buildDetailRow('Billing cycle', 'Monthly'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.matteWhite.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.matteWhite.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, status) {
    final isPremium = status.tier == 'premium';
    final isTrial = status.tier == 'trial';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isPremium)
          ElevatedButton(
            onPressed: () => _showPaywall(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricPurple,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'UPGRADE TO PREMIUM',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        
        const SizedBox(height: 12),

        OutlinedButton(
          onPressed: () => _restorePurchases(context, ref),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.neonCyan,
            side: BorderSide(color: AppColors.neonCyan.withOpacity(0.5)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'RESTORE PURCHASES',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),

        if (isPremium) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _manageSubscriptionInPlayStore,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.matteWhite,
              side: BorderSide(color: AppColors.matteWhite.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'MANAGE IN GOOGLE PLAY',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),

        Text(
          isPremium
              ? 'To cancel your subscription, manage it through Google Play Store.'
              : isTrial
                  ? 'Upgrade before trial ends to maintain access to all features.'
                  : 'Subscribe to unlock all premium features.',
          style: TextStyle(
            color: AppColors.matteWhite.withOpacity(0.5),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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

  Future<void> _restorePurchases(BuildContext context, WidgetRef ref) async {
    final subscriptionService = ref.read(subscriptionServiceProvider);
    
    try {
      await subscriptionService.restorePurchases();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchases restored successfully'),
            backgroundColor: AppColors.neonCyan,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _manageSubscriptionInPlayStore() async {
    final uri = Uri.parse('https://play.google.com/store/account/subscriptions');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
