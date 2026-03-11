import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_profile_service.dart';

/// OnboardingData holds all the information collected during onboarding
class OnboardingData {
  String experienceLevel;
  List<String> healthGoals;
  double? baselineWeight;
  double? baselineBodyFat;
  Map<String, dynamic>? baselineLabs;

  // Notification preferences
  bool doseRemindersEnabled;
  int doseReminderMinutes;
  String quietHoursStart;
  String quietHoursEnd;
  bool labAlertsEnabled;
  bool weeklyProgressEnabled;

  OnboardingData({
    this.experienceLevel = 'beginner',
    this.healthGoals = const [],
    this.baselineWeight,
    this.baselineBodyFat,
    this.baselineLabs,
    this.doseRemindersEnabled = true,
    this.doseReminderMinutes = 60,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
    this.labAlertsEnabled = true,
    this.weeklyProgressEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'experienceLevel': experienceLevel,
      'healthGoals': healthGoals,
      'baselineWeight': baselineWeight,
      'baselineBodyFat': baselineBodyFat,
      'baselineLabs': baselineLabs,
      'doseRemindersEnabled': doseRemindersEnabled,
      'doseReminderMinutes': doseReminderMinutes,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'labAlertsEnabled': labAlertsEnabled,
      'weeklyProgressEnabled': weeklyProgressEnabled,
    };
  }
}

/// OnboardingService handles all onboarding-related operations
class OnboardingService {
  final SupabaseClient _supabase;

  OnboardingService(this._supabase);

  /// Check if user has completed onboarding
  Future<bool> isOnboardingCompleted(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('onboarding_completed')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return false;
      }

      return response['onboarding_completed'] ?? false;
    } catch (e) {
      print('[OnboardingService] Error checking onboarding status: $e');
      return false;
    }
  }

  /// Save onboarding data to database
  Future<bool> completeOnboarding(String userId, OnboardingData data) async {
    try {
      print('[OnboardingService] Starting onboarding completion for user: $userId');
      print('[OnboardingService] Data: ${data.toJson()}');

      // Step 1: Check if profile exists
      final existingProfile = await _supabase
          .from('user_profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existingProfile == null) {
        print('[OnboardingService] No profile found, creating new one...');
        // Create profile first
        await _supabase.from('user_profiles').insert({
          'id': userId,
          'experience_level': data.experienceLevel,
          'health_goals': data.healthGoals,
          'baseline_weight': data.baselineWeight,
          'baseline_body_fat': data.baselineBodyFat,
          'baseline_labs': data.baselineLabs,
          'timezone': 'America/New_York', // Default timezone
          'onboarding_completed': true,
          'onboarding_completed_at': DateTime.now().toIso8601String(),
        });
      } else {
        print('[OnboardingService] Profile exists, updating...');
        // Update existing profile
        await _supabase.from('user_profiles').update({
          'experience_level': data.experienceLevel,
          'health_goals': data.healthGoals,
          'baseline_weight': data.baselineWeight,
          'baseline_body_fat': data.baselineBodyFat,
          'baseline_labs': data.baselineLabs,
          'onboarding_completed': true,
          'onboarding_completed_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);
      }

      // Step 2: Save notification preferences
      final existingPrefs = await _supabase
          .from('notification_preferences')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existingPrefs == null) {
        print('[OnboardingService] Creating notification preferences...');
        await _supabase.from('notification_preferences').insert({
          'user_id': userId,
          'dose_reminders_enabled': data.doseRemindersEnabled,
          'dose_reminder_minutes': data.doseReminderMinutes,
          'quiet_hours_start': data.quietHoursStart,
          'quiet_hours_end': data.quietHoursEnd,
          'lab_alerts_enabled': data.labAlertsEnabled,
          'weekly_progress_enabled': data.weeklyProgressEnabled,
        });
      } else {
        print('[OnboardingService] Updating notification preferences...');
        await _supabase.from('notification_preferences').update({
          'dose_reminders_enabled': data.doseRemindersEnabled,
          'dose_reminder_minutes': data.doseReminderMinutes,
          'quiet_hours_start': data.quietHoursStart,
          'quiet_hours_end': data.quietHoursEnd,
          'lab_alerts_enabled': data.labAlertsEnabled,
          'weekly_progress_enabled': data.weeklyProgressEnabled,
        }).eq('user_id', userId);
      }

      print('[OnboardingService] ✅ Onboarding completed successfully!');
      return true;
    } catch (e, stackTrace) {
      print('[OnboardingService] ❌ Error completing onboarding: $e');
      print('[OnboardingService] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Skip onboarding (save defaults)
  Future<bool> skipOnboarding(String userId) async {
    try {
      print('[OnboardingService] Skipping onboarding for user: $userId');

      final defaultData = OnboardingData();
      return await completeOnboarding(userId, defaultData);
    } catch (e) {
      print('[OnboardingService] Error skipping onboarding: $e');
      return false;
    }
  }
}

// Riverpod Providers
final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return OnboardingService(supabase);
});

/// Provider to check if onboarding is completed
/// This will be used in main.dart to determine initial route
final isOnboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return true; // If no user, don't show onboarding

  final service = ref.watch(onboardingServiceProvider);
  return service.isOnboardingCompleted(userId);
});
