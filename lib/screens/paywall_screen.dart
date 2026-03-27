import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/subscription_service.dart';
import '../widgets/scanline_overlay.dart';
import '../theme/colors.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

final subscriptionServiceProvider = ChangeNotifierProvider<SubscriptionService>(
  (ref) => SubscriptionService(),
);

/// Cyberpunk-themed paywall screen
/// Shows when trial expires or user needs to upgrade
class PaywallScreen extends ConsumerStatefulWidget {
  final bool canDismiss;

  const PaywallScreen({
    Key? key,
    this.canDismiss = false,
  }) : super(key: key);

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final subscriptionService = ref.watch(subscriptionServiceProvider);
    final products = subscriptionService.products;

    return WillPopScope(
      onWillPop: () async => widget.canDismiss,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        body: Stack(
          children: [
            // Scanline overlay
            const ScanlineOverlay(),

            // Main content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.canDismiss)
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: AppColors.neonCyan),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Title
                    _buildTerminalHeader(),

                    const SizedBox(height: 40),

                    // Feature comparison
                    _buildFeatureComparison(),

                    const SizedBox(height: 40),

                    // Pricing cards
                    if (products.isNotEmpty) ...[
                      _buildPricingCard(
                        products.firstWhere(
                          (p) => p.id == SubscriptionService.monthlySubId,
                          orElse: () => products.first,
                        ),
                        isRecommended: true,
                      ),
                      const SizedBox(height: 16),
                      if (products.any((p) => p.id == SubscriptionService.annualSubId))
                        _buildPricingCard(
                          products.firstWhere((p) => p.id == SubscriptionService.annualSubId),
                          isRecommended: false,
                          savings: '20% OFF',
                        ),
                    ] else
                      const Center(
                        child: CircularProgressIndicator(color: AppColors.neonCyan),
                      ),

                    const SizedBox(height: 24),

                    // Restore purchases button
                    TextButton(
                      onPressed: _isProcessing ? null : _restorePurchases,
                      child: Text(
                        'Restore Purchases',
                        style: TextStyle(
                          color: AppColors.neonCyan.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Terms
                    Text(
                      'Subscription auto-renews unless canceled. Cancel anytime in Google Play.',
                      style: TextStyle(
                        color: AppColors.matteWhite.withOpacity(0.5),
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    if (subscriptionService.error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          subscriptionService.error!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F17),
        border: Border.all(color: AppColors.neonCyan.withOpacity(0.3), width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonCyan.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '> ',
                style: TextStyle(
                  color: AppColors.neonCyan,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              Expanded(
                child: Text(
                  'UPGRADE_REQUIRED',
                  style: TextStyle(
                    color: AppColors.neonCyan,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your trial has ended. Upgrade to premium to continue optimizing your biohacking protocols.',
            style: TextStyle(
              color: AppColors.matteWhite.withOpacity(0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureComparison() {
    final features = [
      'Unlimited peptide protocols',
      'Advanced dosing calculator',
      'Lab result tracking & AI insights',
      'Cycle reviews & analytics',
      'Custom dose schedules',
      'Cloud backup & sync',
      'Priority support',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PREMIUM_FEATURES',
          style: TextStyle(
            color: AppColors.electricPurple,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        ...features.map((feature) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.neonCyan, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  feature,
                  style: TextStyle(
                    color: AppColors.matteWhite.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildPricingCard(ProductDetails product, {
    bool isRecommended = false,
    String? savings,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F17),
        border: Border.all(
          color: isRecommended
              ? AppColors.electricPurple
              : AppColors.neonCyan.withOpacity(0.3),
          width: isRecommended ? 3 : 2,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isRecommended
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
          if (isRecommended || savings != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isRecommended
                    ? AppColors.electricPurple
                    : AppColors.neonCyan,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Text(
                savings ?? 'RECOMMENDED',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 1.5,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  product.id == SubscriptionService.monthlySubId
                      ? 'MONTHLY'
                      : 'ANNUAL',
                  style: TextStyle(
                    color: AppColors.matteWhite.withOpacity(0.7),
                    fontSize: 14,
                    fontFamily: 'monospace',
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.price,
                  style: const TextStyle(
                    color: AppColors.neonCyan,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.id == SubscriptionService.monthlySubId
                      ? 'per month'
                      : 'per year',
                  style: TextStyle(
                    color: AppColors.matteWhite.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : () => _subscribe(product),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRecommended
                          ? AppColors.electricPurple
                          : AppColors.neonCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'SUBSCRIBE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _subscribe(ProductDetails product) async {
    setState(() => _isProcessing = true);

    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      
      if (product.id == SubscriptionService.monthlySubId) {
        await subscriptionService.purchaseMonthlySubscription();
      } else {
        await subscriptionService.purchaseAnnualSubscription();
      }

      // Wait for purchase to complete
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      // Error is handled by subscription service
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isProcessing = true);

    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      await subscriptionService.restorePurchases();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchases restored successfully'),
            backgroundColor: AppColors.neonCyan,
          ),
        );
        
        // Check if user now has access
        if (subscriptionService.status?.hasPremiumAccess ?? false) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore purchases: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
