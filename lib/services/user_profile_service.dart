import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Models
class UserProfile {
  final String userId;
  final String experienceLevel; // beginner, intermediate, advanced
  final List<String> healthGoals; // muscle, recovery, longevity, metabolic, sleep, immune
  final double? baselineWeight;
  final double? baselineBodyFat;
  final Map<String, dynamic>? baselineLabs;
  final String timezone;
  final bool onboardingCompleted;
  final DateTime? onboardingCompletedAt;

  UserProfile({
    required this.userId,
    required this.experienceLevel,
    required this.healthGoals,
    this.baselineWeight,
    this.baselineBodyFat,
    this.baselineLabs,
    required this.timezone,
    required this.onboardingCompleted,
    this.onboardingCompletedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['id'] ?? '',
      experienceLevel: json['experience_level'] ?? 'beginner',
      healthGoals: List<String>.from(json['health_goals'] ?? []),
      baselineWeight: json['baseline_weight']?.toDouble(),
      baselineBodyFat: json['baseline_body_fat']?.toDouble(),
      baselineLabs: json['baseline_labs'],
      timezone: json['timezone'] ?? 'America/New_York',
      onboardingCompleted: json['onboarding_completed'] ?? false,
      onboardingCompletedAt: json['onboarding_completed_at'] != null
          ? DateTime.parse(json['onboarding_completed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': userId,
      'experience_level': experienceLevel,
      'health_goals': healthGoals,
      'baseline_weight': baselineWeight,
      'baseline_body_fat': baselineBodyFat,
      'baseline_labs': baselineLabs,
      'timezone': timezone,
      'onboarding_completed': onboardingCompleted,
      'onboarding_completed_at': onboardingCompletedAt?.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? experienceLevel,
    List<String>? healthGoals,
    double? baselineWeight,
    double? baselineBodyFat,
    Map<String, dynamic>? baselineLabs,
    String? timezone,
    bool? onboardingCompleted,
    DateTime? onboardingCompletedAt,
  }) {
    return UserProfile(
      userId: userId,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      healthGoals: healthGoals ?? this.healthGoals,
      baselineWeight: baselineWeight ?? this.baselineWeight,
      baselineBodyFat: baselineBodyFat ?? this.baselineBodyFat,
      baselineLabs: baselineLabs ?? this.baselineLabs,
      timezone: timezone ?? this.timezone,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      onboardingCompletedAt: onboardingCompletedAt ?? this.onboardingCompletedAt,
    );
  }
}

// Service
class UserProfileService {
  final SupabaseClient _supabase;

  UserProfileService(this._supabase);

  // Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Create user profile (first-time setup)
  Future<UserProfile?> createUserProfile(String userId) async {
    try {
      final now = DateTime.now();
      final response = await _supabase
          .from('user_profiles')
          .insert({
            'id': userId,
            'experience_level': 'beginner',
            'health_goals': [],
            'timezone': 'America/New_York',
            'onboarding_completed': false,
          })
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error creating user profile: $e');
      return null;
    }
  }

  // Update user profile (during onboarding)
  Future<UserProfile?> updateUserProfile(String userId, {
    String? experienceLevel,
    List<String>? healthGoals,
    double? baselineWeight,
    double? baselineBodyFat,
    Map<String, dynamic>? baselineLabs,
    String? timezone,
    bool? onboardingCompleted,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (experienceLevel != null) updates['experience_level'] = experienceLevel;
      if (healthGoals != null) updates['health_goals'] = healthGoals;
      if (baselineWeight != null) updates['baseline_weight'] = baselineWeight;
      if (baselineBodyFat != null) updates['baseline_body_fat'] = baselineBodyFat;
      if (baselineLabs != null) updates['baseline_labs'] = baselineLabs;
      if (timezone != null) updates['timezone'] = timezone;
      if (onboardingCompleted != null) {
        updates['onboarding_completed'] = onboardingCompleted;
        if (onboardingCompleted) {
          updates['onboarding_completed_at'] = DateTime.now().toIso8601String();
        }
      }

      final response = await _supabase
          .from('user_profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error updating user profile: $e');
      return null;
    }
  }

  // Initialize notification preferences
  Future<void> initializeNotificationPreferences(String userId) async {
    try {
      await _supabase
          .from('notification_preferences')
          .insert({
            'user_id': userId,
            'dose_reminders_enabled': true,
            'dose_reminder_minutes': 60,
            'missed_dose_alerts': true,
            'lab_alerts': true,
            'protocol_review_reminders': true,
            'quiet_hours_enabled': false,
            'quiet_hours_start': '22:00',
            'quiet_hours_end': '08:00',
          })
          .onConflict('user_id');
    } catch (e) {
      print('Error initializing notification preferences: $e');
    }
  }
}

// Riverpod Providers
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return UserProfileService(supabase);
});

final currentUserIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final service = ref.watch(userProfileServiceProvider);
  return service.getUserProfile(userId);
});

final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return profile?.onboardingCompleted ?? false;
});
