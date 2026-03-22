import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_profile_service.dart';

class OnboardingData {
  // Screen 1 - Experience Level
  String experienceLevel; // 'beginner', 'intermediate', 'advanced'

  // Screen 2 - Health Goals
  List<String> healthGoals;

  // Screen 3 - Current Status
  bool usedPeptidesBefore;
  List<String> previousPeptides;
  String peptideExperienceDuration; // '<3_months', '3-6_months', '6-12_months', '1+_years'
  String cycleStatus; // 'not_on_cycle', 'active_cycle'
  String trainingLevel; // 'sedentary', 'moderate', 'active', 'athlete'

  // Screen 4 - Lab Work Habits
  String bloodworkFrequency; // 'never', 'every_6_months', 'every_3_months', 'monthly'
  String? lastLabDate;

  // Screen 5 - Notifications
  bool doseRemindersEnabled;
  String doseReminderTime; // '06:00', '08:00', '12:00', '18:00', '22:00'
  String labReminderFrequency; // 'never', 'every_6_months', 'every_3_months', 'monthly'
  bool cycleMilestonesEnabled;
  bool researchUpdatesEnabled;

  // Screen 6 - Profile Details
  String? displayName;
  int? age;
  double? weight;
  int? heightFeet;
  int? heightInches;
  String? gender; // 'male', 'female', 'other', 'prefer_not_to_say'

  OnboardingData({
    this.experienceLevel = 'beginner',
    this.healthGoals = const [],
    this.usedPeptidesBefore = false,
    this.previousPeptides = const [],
    this.peptideExperienceDuration = '',
    this.cycleStatus = 'not_on_cycle',
    this.trainingLevel = 'moderate',
    this.bloodworkFrequency = 'never',
    this.lastLabDate,
    this.doseRemindersEnabled = true,
    this.doseReminderTime = '08:00',
    this.labReminderFrequency = 'every_3_months',
    this.cycleMilestonesEnabled = true,
    this.researchUpdatesEnabled = true,
    this.displayName,
    this.age,
    this.weight,
    this.heightFeet,
    this.heightInches,
    this.gender,
  });

  Map<String, dynamic> toJson() {
    return {
      'experienceLevel': experienceLevel,
      'healthGoals': healthGoals,
      'usedPeptidesBefore': usedPeptidesBefore,
      'previousPeptides': previousPeptides,
      'peptideExperienceDuration': peptideExperienceDuration,
      'cycleStatus': cycleStatus,
      'trainingLevel': trainingLevel,
      'bloodworkFrequency': bloodworkFrequency,
      'lastLabDate': lastLabDate,
      'doseRemindersEnabled': doseRemindersEnabled,
      'doseReminderTime': doseReminderTime,
      'labReminderFrequency': labReminderFrequency,
      'cycleMilestonesEnabled': cycleMilestonesEnabled,
      'researchUpdatesEnabled': researchUpdatesEnabled,
      'displayName': displayName,
      'age': age,
      'weight': weight,
      'heightFeet': heightFeet,
      'heightInches': heightInches,
      'gender': gender,
    };
  }
}

class OnboardingService {
  final SupabaseClient _supabase;

  OnboardingService(this._supabase);

  Future<bool> isOnboardingCompleted(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('onboarding_completed')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return false;
      return response['onboarding_completed'] ?? false;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[OnboardingService] Error checking onboarding status: $e');
        print('[OnboardingService] Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  Future<bool> completeOnboarding(String userId, OnboardingData data) async {
    try {
      if (kDebugMode) {
        print('[OnboardingService] Starting onboarding completion for user: $userId');
        print('[OnboardingService] Data: ${data.toJson()}');
      }

      final profileData = {
        'experience_level': data.experienceLevel,
        'health_goals': data.healthGoals,
        'used_peptides_before': data.usedPeptidesBefore,
        'previous_peptides': data.previousPeptides,
        'peptide_experience_duration': data.peptideExperienceDuration,
        'cycle_status': data.cycleStatus,
        'training_level': data.trainingLevel,
        'bloodwork_frequency': data.bloodworkFrequency,
        'last_lab_date': data.lastLabDate,
        'username': data.displayName,
        'age': data.age,
        'baseline_weight': data.weight,
        'height_feet': data.heightFeet,
        'height_inches': data.heightInches,
        'gender': data.gender,
        'timezone': 'America/New_York',
        'onboarding_completed': true,
        'onboarding_completed_at': DateTime.now().toIso8601String(),
      };

      // Upsert profile
      final existingProfile = await _supabase
          .from('user_profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existingProfile == null) {
        await _supabase.from('user_profiles').insert({
          'id': userId,
          ...profileData,
        });
      } else {
        await _supabase
            .from('user_profiles')
            .update(profileData)
            .eq('id', userId);
      }

      // Save notification preferences
      final notifData = {
        'dose_reminders_enabled': data.doseRemindersEnabled,
        'dose_reminder_time': data.doseReminderTime,
        'lab_reminder_frequency': data.labReminderFrequency,
        'cycle_milestones_enabled': data.cycleMilestonesEnabled,
        'research_updates_enabled': data.researchUpdatesEnabled,
        'lab_alerts_enabled': true,
        'weekly_progress_enabled': true,
      };

      final existingPrefs = await _supabase
          .from('notification_preferences')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existingPrefs == null) {
        await _supabase.from('notification_preferences').insert({
          'user_id': userId,
          ...notifData,
        });
      } else {
        await _supabase
            .from('notification_preferences')
            .update(notifData)
            .eq('user_id', userId);
      }

      if (kDebugMode) {
        print('[OnboardingService] Onboarding completed successfully');
      }
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[OnboardingService] Error completing onboarding: $e');
        print('[OnboardingService] Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  Future<bool> skipOnboarding(String userId) async {
    try {
      final defaultData = OnboardingData();
      return await completeOnboarding(userId, defaultData);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[OnboardingService] Error skipping onboarding: $e');
        print('[OnboardingService] Stack trace: $stackTrace');
      }
      rethrow;
    }
  }
}

// Riverpod Providers
final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return OnboardingService(supabase);
});

final isOnboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return true;

  final service = ref.watch(onboardingServiceProvider);
  return service.isOnboardingCompleted(userId);
});
