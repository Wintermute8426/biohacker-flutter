import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription_status.dart';

/// Subscription service managing Google Play Billing and subscription state
/// Handles 30-day free trial → $9.99/month paid subscription flow
class SubscriptionService with ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  final supabase = Supabase.instance.client;

  // Product IDs (use test IDs during development)
  // In production, replace with real product IDs from Play Console
  static const String monthlySubId = 'biohacker_monthly_sub';
  static const String annualSubId = 'biohacker_annual_sub';

  SubscriptionStatus? _status;
  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  bool _isAvailable = false;
  bool _isLoading = true;
  String? _error;

  SubscriptionStatus? get status => _status;
  List<ProductDetails> get products => _products;
  bool get isAvailable => _isAvailable;
  bool get isLoading => _isLoading;
  String? get error => _error;

  SubscriptionService() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _isAvailable = await _iap.isAvailable();
      
      if (_isAvailable) {
        // Load products from Play Store
        await _loadProducts();
        
        // Listen to purchase updates
        _purchaseSubscription = _iap.purchaseStream.listen(
          _handlePurchaseUpdates,
          onDone: () => _purchaseSubscription?.cancel(),
          onError: (error) => _setError('Purchase stream error: $error'),
        );
      }

      // Load subscription status from database
      await refreshStatus();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _setError('Initialization error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProducts() async {
    try {
      final productIds = {monthlySubId, annualSubId};
      final response = await _iap.queryProductDetails(productIds);

      if (response.error != null) {
        _setError('Failed to load products: ${response.error}');
        return;
      }

      _products = response.productDetails;
      notifyListeners();
    } catch (e) {
      _setError('Product load error: $e');
    }
  }

  /// Get current subscription status (with lazy load)
  Future<SubscriptionStatus?> getSubscriptionStatus() async {
    if (_status == null) {
      await refreshStatus();
    }
    return _status;
  }

  /// Refresh subscription status from Supabase
  Future<void> refreshStatus() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        _status = null;
        notifyListeners();
        return;
      }

      final response = await supabase
          .from('user_profiles')
          .select('subscription_tier, subscription_starts_at, subscription_ends_at, user_number')
          .eq('id', userId)
          .single();

      _status = SubscriptionStatus.fromJson(response);
      notifyListeners();
    } catch (e) {
      _setError('Failed to refresh status: $e');
    }
  }

  /// Start free 30-day trial for new user
  Future<void> startFreeTrial() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final trialEnd = now.add(const Duration(days: 30));

      await supabase.from('user_profiles').update({
        'subscription_tier': 'trial',
        'subscription_starts_at': now.toIso8601String(),
        'subscription_ends_at': trialEnd.toIso8601String(),
      }).eq('id', userId);

      await refreshStatus();
    } catch (e) {
      _setError('Failed to start trial: $e');
      rethrow;
    }
  }

  /// Purchase monthly subscription
  Future<void> purchaseMonthlySubscription() async {
    await _initiatePurchase(monthlySubId);
  }

  /// Purchase annual subscription
  Future<void> purchaseAnnualSubscription() async {
    await _initiatePurchase(annualSubId);
  }

  Future<void> _initiatePurchase(String productId) async {
    try {
      final product = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Product not found: $productId'),
      );

      final purchaseParam = PurchaseParam(productDetails: product);
      
      if (Platform.isAndroid) {
        // Android subscription purchase
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      } else if (Platform.isIOS) {
        // iOS subscription purchase
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      _setError('Purchase failed: $e');
      rethrow;
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
      await refreshStatus();
    } catch (e) {
      _setError('Restore failed: $e');
      rethrow;
    }
  }

  /// Handle purchase updates from the store
  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        // Purchase is pending, show loading indicator
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        _setError('Purchase error: ${purchase.error}');
        await _iap.completePurchase(purchase);
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Verify purchase server-side and update subscription status
        final success = await _verifyAndActivateSubscription(purchase);
        
        if (success) {
          await refreshStatus();
        } else {
          _setError('Purchase verification failed');
        }
      }

      // Complete the purchase
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  /// Verify purchase with server and activate subscription
  Future<bool> _verifyAndActivateSubscription(PurchaseDetails purchase) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Call Supabase edge function to verify purchase server-side
      // This prevents tampering and ensures secure validation
      final response = await supabase.functions.invoke(
        'verify-subscription',
        body: {
          'user_id': userId,
          'purchase_token': purchase.verificationData.serverVerificationData,
          'product_id': purchase.productID,
          'platform': Platform.isAndroid ? 'android' : 'ios',
        },
      );

      if (response.data['success'] == true) {
        // Update local database with subscription status
        final now = DateTime.now();
        final endDate = purchase.productID == annualSubId
            ? now.add(const Duration(days: 365))
            : now.add(const Duration(days: 30));

        await supabase.from('user_profiles').update({
          'subscription_tier': 'premium',
          'subscription_starts_at': now.toIso8601String(),
          'subscription_ends_at': endDate.toIso8601String(),
        }).eq('id', userId);

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Verification error: $e');
      return false;
    }
  }

  /// Check if paywall should be shown
  bool shouldShowPaywall() {
    if (_status == null) return false;
    return !_status!.hasPremiumAccess;
  }

  void _setError(String error) {
    _error = error;
    debugPrint('[SubscriptionService] $error');
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
