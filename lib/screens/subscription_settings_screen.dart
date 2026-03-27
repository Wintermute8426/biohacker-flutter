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
            color: AppColors.accent,
            fontFamily: 'monospace',
            letterSpacing: 2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.accent),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ScanlineOverlay(
          child: SafeArea(
            child: status == null
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
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
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, status) {
    final isPremium = status.tier == 'premium';
    final isTrial = status.tier == 'trial';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border.all(
          color: isPremium
              ? AppColors.amber.withOpacity(0.3)
              : isTrial
                  ? AppColors.primary.withOpacity(0.3)
                  : AppColors.textLight.withOpacity(0.15),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                color: isPremium
                    ? AppColors.amber.withOpacity(0.6)
                    : isTrial
                        ? AppColors.primary.withOpacity(0.6)
                        : AppColors.textLight.withOpacity(0.3),
              ),
              const SizedBox(width: 12),
              Icon(
                isPremium ? Icons.workspace_premium : Icons.access_time,
                color: isPremium ? AppColors.amber : AppColors.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPremium
                          ? '> PREMIUM'
                          : isTrial
                              ? '> FREE TRIAL'
                              : '> FREE',
                      style: TextStyle(
                        color: isPremium
                            ? AppColors.amber
                            : isTrial
                                ? AppColors.primary
                                : AppColors.textLight,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (isTrial && status.trialDaysRemaining != null)
                      Text(
                        '${status.trialDaysRemaining} days remaining',
                        style: TextStyle(
                          color: AppColors.textLight.withOpacity(0.7),
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
                color: const Color(0xFF0A0A0A),
                border: Border.all(
                  color: AppColors.amber.withOpacity(0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    color: AppColors.amber.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.warning, color: AppColors.amber, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your trial is ending soon! Upgrade to keep access.',
                      style: TextStyle(
                        color: AppColors.textLight.withOpacity(0.9),
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
        color: const Color(0xFF0A0A0A),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 14,
                color: AppColors.primary.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Text(
                '> PLAN_DETAILS',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 1.2,
                ),
              ),
            ],
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
              color: AppColors.textLight.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textLight.withOpacity(0.9),
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
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(
                color: AppColors.amber.withOpacity(0.5),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showPaywall(context, ref),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: Text(
                    'UPGRADE TO PREMIUM',
                    style: TextStyle(
                      color: AppColors.amber,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.5),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _restorePurchases(context, ref),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                child: Text(
                  'RESTORE PURCHASES',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),

        if (isPremium) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(
                color: AppColors.textLight.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _manageSubscriptionInPlayStore,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: Text(
                    'MANAGE IN GOOGLE PLAY',
                    style: TextStyle(
                      color: AppColors.textMid,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
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
            color: AppColors.textLight.withOpacity(0.5),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _showPaywall(BuildContext context, WidgetRef ref) async {
    final subscriptionService = ref.read(subscriptionServiceProvider);
    
    // Check if products are loaded
    if (subscriptionService.products.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF0A0A0A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: AppColors.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          title: Row(
            children: [
              Container(
                width: 4,
                height: 14,
                color: AppColors.primary.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Text(
                '> SETUP REQUIRED',
                style: TextStyle(
                  color: AppColors.primary,
                  fontFamily: 'monospace',
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          content: Text(
            'Subscription products are not configured yet. '
            'Please complete Google Play Console setup.',
            style: TextStyle(
              color: AppColors.textMid,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.amber,
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'monospace',
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }
    
    // Navigate to paywall if products exist
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
            backgroundColor: AppColors.accent,
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
