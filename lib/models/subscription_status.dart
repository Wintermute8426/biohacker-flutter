/// Subscription status model for the Biohacker app
/// Tracks free trial and paid subscription state
class SubscriptionStatus {
  final String tier; // 'free', 'trial', 'premium'
  final DateTime? subscriptionStartsAt;
  final DateTime? subscriptionEndsAt;
  final int? userNumber;
  final bool isActive;

  SubscriptionStatus({
    required this.tier,
    this.subscriptionStartsAt,
    this.subscriptionEndsAt,
    this.userNumber,
    required this.isActive,
  });

  /// Check if user is in free trial period
  bool get isInTrial {
    if (tier != 'trial') return false;
    if (subscriptionEndsAt == null) return false;
    return DateTime.now().isBefore(subscriptionEndsAt!);
  }

  /// Check if user has premium access (trial or paid)
  bool get hasPremiumAccess {
    return isActive && (tier == 'premium' || isInTrial);
  }

  /// Days remaining in trial
  int? get trialDaysRemaining {
    if (!isInTrial) return null;
    final now = DateTime.now();
    final difference = subscriptionEndsAt!.difference(now);
    return difference.inDays;
  }

  /// Check if trial is expiring soon (< 7 days)
  bool get isTrialExpiringSoon {
    final daysLeft = trialDaysRemaining;
    return daysLeft != null && daysLeft > 0 && daysLeft <= 7;
  }

  /// Check if subscription has expired
  bool get isExpired {
    if (subscriptionEndsAt == null) return false;
    return DateTime.now().isAfter(subscriptionEndsAt!);
  }

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      tier: json['subscription_tier'] as String? ?? 'free',
      subscriptionStartsAt: json['subscription_starts_at'] != null
          ? DateTime.parse(json['subscription_starts_at'] as String)
          : null,
      subscriptionEndsAt: json['subscription_ends_at'] != null
          ? DateTime.parse(json['subscription_ends_at'] as String)
          : null,
      userNumber: json['user_number'] as int?,
      isActive: json['subscription_tier'] == 'premium' ||
          (json['subscription_tier'] == 'trial' &&
              json['subscription_ends_at'] != null &&
              DateTime.now().isBefore(
                  DateTime.parse(json['subscription_ends_at'] as String))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscription_tier': tier,
      'subscription_starts_at': subscriptionStartsAt?.toIso8601String(),
      'subscription_ends_at': subscriptionEndsAt?.toIso8601String(),
      'user_number': userNumber,
    };
  }

  @override
  String toString() {
    return 'SubscriptionStatus(tier: $tier, active: $isActive, trial: $isInTrial, daysLeft: $trialDaysRemaining)';
  }
}
