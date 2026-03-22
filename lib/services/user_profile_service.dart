import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Models
class UserProfile {
  final String userId;
  // Tier 1 fields (Profile Screen)
  final String? username;
  final int? age;
  final String? gender; // 'male', 'female', 'other', 'prefer_not_to_say'
  final int? heightFeet; // 0-9 feet
  final int? heightInches; // 0-11 inches
  final String? allergies;
  final List<String> medicalConditions; // ['diabetes', 'hypertension', ...]
  // Tier 3 fields (Profile Preferences)
  final Map<String, dynamic>? notificationPreferences; // {email: true, push: false, sms: false}
  final List<String> healthGoalsList; // ['longevity', 'recovery', 'hormone_optimization', ...]
  final String? unitsPreference; // 'metric' or 'imperial'
  final String? contactMethod; // 'email', 'phone', 'push'
  final String? bio; // optional bio text (max 200 chars)
  final String? photoUrl; // profile photo URL
  // Existing fields (Onboarding)
  final String experienceLevel; // beginner, intermediate, advanced
  final List<String> healthGoals; // muscle, recovery, longevity, metabolic, sleep, immune
  final double? baselineWeight;
  final double? baselineBodyFat;
  final Map<String, dynamic>? baselineLabs;
  final String timezone;
  final bool onboardingCompleted;
  final DateTime? onboardingCompletedAt;
  // Onboarding V2 fields
  final bool usedPeptidesBefore;
  final List<String> previousPeptides;
  final String? peptideExperienceDuration;
  final String? cycleStatus;
  final String? trainingLevel;
  final String? bloodworkFrequency;
  final String? lastLabDate;

  UserProfile({
    required this.userId,
    this.username,
    this.age,
    this.gender,
    this.heightFeet,
    this.heightInches,
    this.allergies,
    this.medicalConditions = const [],
    this.notificationPreferences,
    this.healthGoalsList = const [],
    this.unitsPreference,
    this.contactMethod,
    this.bio,
    this.photoUrl,
    required this.experienceLevel,
    required this.healthGoals,
    this.baselineWeight,
    this.baselineBodyFat,
    this.baselineLabs,
    required this.timezone,
    required this.onboardingCompleted,
    this.onboardingCompletedAt,
    this.usedPeptidesBefore = false,
    this.previousPeptides = const [],
    this.peptideExperienceDuration,
    this.cycleStatus,
    this.trainingLevel,
    this.bloodworkFrequency,
    this.lastLabDate,
  });

  // Helper: Get height as formatted string (e.g., "5'11\"")
  String get heightFormatted {
    if (heightFeet == null || heightInches == null) return 'Not set';
    return '$heightFeet\'$heightInches"';
  }

  // Helper: Convert height to centimeters
  double? get heightCm {
    if (heightFeet == null || heightInches == null) return null;
    return ((heightFeet! * 12) + heightInches!) * 2.54;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['id'] ?? '',
      username: json['username'],
      age: json['age'],
      gender: json['gender'],
      heightFeet: json['height_feet'],
      heightInches: json['height_inches'],
      allergies: json['allergies'],
      medicalConditions: json['medical_conditions'] != null
          ? List<String>.from(json['medical_conditions'])
          : [],
      notificationPreferences: json['notification_preferences'],
      healthGoalsList: json['health_goals_list'] != null
          ? List<String>.from(json['health_goals_list'])
          : [],
      unitsPreference: json['units_preference'],
      contactMethod: json['contact_method'],
      bio: json['bio'],
      photoUrl: json['photo_url'],
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
      usedPeptidesBefore: json['used_peptides_before'] ?? false,
      previousPeptides: json['previous_peptides'] != null
          ? List<String>.from(json['previous_peptides'])
          : [],
      peptideExperienceDuration: json['peptide_experience_duration'],
      cycleStatus: json['cycle_status'],
      trainingLevel: json['training_level'],
      bloodworkFrequency: json['bloodwork_frequency'],
      lastLabDate: json['last_lab_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': userId,
      'username': username,
      'age': age,
      'gender': gender,
      'height_feet': heightFeet,
      'height_inches': heightInches,
      'allergies': allergies,
      'medical_conditions': medicalConditions,
      'notification_preferences': notificationPreferences,
      'health_goals_list': healthGoalsList,
      'units_preference': unitsPreference,
      'contact_method': contactMethod,
      'bio': bio,
      'photo_url': photoUrl,
      'experience_level': experienceLevel,
      'health_goals': healthGoals,
      'baseline_weight': baselineWeight,
      'baseline_body_fat': baselineBodyFat,
      'baseline_labs': baselineLabs,
      'timezone': timezone,
      'onboarding_completed': onboardingCompleted,
      'onboarding_completed_at': onboardingCompletedAt?.toIso8601String(),
      'used_peptides_before': usedPeptidesBefore,
      'previous_peptides': previousPeptides,
      'peptide_experience_duration': peptideExperienceDuration,
      'cycle_status': cycleStatus,
      'training_level': trainingLevel,
      'bloodwork_frequency': bloodworkFrequency,
      'last_lab_date': lastLabDate,
    };
  }

  UserProfile copyWith({
    String? username,
    int? age,
    String? gender,
    int? heightFeet,
    int? heightInches,
    String? allergies,
    List<String>? medicalConditions,
    Map<String, dynamic>? notificationPreferences,
    List<String>? healthGoalsList,
    String? unitsPreference,
    String? contactMethod,
    String? bio,
    String? photoUrl,
    String? experienceLevel,
    List<String>? healthGoals,
    double? baselineWeight,
    double? baselineBodyFat,
    Map<String, dynamic>? baselineLabs,
    String? timezone,
    bool? onboardingCompleted,
    DateTime? onboardingCompletedAt,
    bool? usedPeptidesBefore,
    List<String>? previousPeptides,
    String? peptideExperienceDuration,
    String? cycleStatus,
    String? trainingLevel,
    String? bloodworkFrequency,
    String? lastLabDate,
  }) {
    return UserProfile(
      userId: userId,
      username: username ?? this.username,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightFeet: heightFeet ?? this.heightFeet,
      heightInches: heightInches ?? this.heightInches,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
      healthGoalsList: healthGoalsList ?? this.healthGoalsList,
      unitsPreference: unitsPreference ?? this.unitsPreference,
      contactMethod: contactMethod ?? this.contactMethod,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      healthGoals: healthGoals ?? this.healthGoals,
      baselineWeight: baselineWeight ?? this.baselineWeight,
      baselineBodyFat: baselineBodyFat ?? this.baselineBodyFat,
      baselineLabs: baselineLabs ?? this.baselineLabs,
      timezone: timezone ?? this.timezone,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      onboardingCompletedAt: onboardingCompletedAt ?? this.onboardingCompletedAt,
      usedPeptidesBefore: usedPeptidesBefore ?? this.usedPeptidesBefore,
      previousPeptides: previousPeptides ?? this.previousPeptides,
      peptideExperienceDuration: peptideExperienceDuration ?? this.peptideExperienceDuration,
      cycleStatus: cycleStatus ?? this.cycleStatus,
      trainingLevel: trainingLevel ?? this.trainingLevel,
      bloodworkFrequency: bloodworkFrequency ?? this.bloodworkFrequency,
      lastLabDate: lastLabDate ?? this.lastLabDate,
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
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[UserProfileService] Error fetching user profile: $e');
        print('[UserProfileService] Stack trace: $stackTrace');
      }
      rethrow;
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
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[UserProfileService] Error creating user profile: $e');
        print('[UserProfileService] Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  // Update user profile (during onboarding + Profile Screen)
  Future<UserProfile?> updateUserProfile(String userId, {
    String? username,
    int? age,
    String? gender,
    int? heightFeet,
    int? heightInches,
    String? allergies,
    List<String>? medicalConditions,
    Map<String, dynamic>? notificationPreferences,
    List<String>? healthGoalsList,
    String? unitsPreference,
    String? contactMethod,
    String? bio,
    String? photoUrl,
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
      
      // NEW: Profile screen fields (Tier 1)
      if (username != null) updates['username'] = username;
      if (age != null) updates['age'] = age;
      if (gender != null) updates['gender'] = gender;
      if (heightFeet != null) updates['height_feet'] = heightFeet;
      if (heightInches != null) updates['height_inches'] = heightInches;
      if (allergies != null) updates['allergies'] = allergies;
      if (medicalConditions != null) updates['medical_conditions'] = medicalConditions;
      
      // NEW: Profile preferences (Tier 3)
      if (notificationPreferences != null) updates['notification_preferences'] = notificationPreferences;
      if (healthGoalsList != null) updates['health_goals_list'] = healthGoalsList;
      if (unitsPreference != null) updates['units_preference'] = unitsPreference;
      if (contactMethod != null) updates['contact_method'] = contactMethod;
      if (bio != null) updates['bio'] = bio;
      if (photoUrl != null) updates['photo_url'] = photoUrl;

      // EXISTING: Onboarding fields
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

      if (kDebugMode) {
        print('[UserProfile] ========================================');
        print('[UserProfile] Updating profile for user: $userId');
        print('[UserProfile] Updates: $updates');
        print('[UserProfile] ========================================');
      }

      final response = await _supabase
          .from('user_profiles')
          .update(updates)
          .eq('id', userId)
          .select();

      if (kDebugMode) {
        print('[UserProfile] Update response: $response');
      }

      if (response.isEmpty) {
        if (kDebugMode) {
          print('[UserProfile] ⚠️  WARNING: Empty response from update.');
          print('[UserProfile] This usually means:');
          print('[UserProfile]   1. User profile does not exist (creating new one...)');
          print('[UserProfile]   2. RLS policy is blocking the UPDATE');
          print('[UserProfile]   3. Database columns do not exist (run migration!)');
        }

        // Try to create if doesn't exist
        return await createUserProfile(userId);
      }

      final profile = UserProfile.fromJson(response.first);
      if (kDebugMode) {
        print('[UserProfile] ✅ Successfully updated profile');
        print('[UserProfile] Profile data: ${profile.toJson()}');
      }
      return profile;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[UserProfile] ❌ ERROR updating user profile');
        print('[UserProfile] Error type: ${e.runtimeType}');
        print('[UserProfile] Error message: $e');
        print('[UserProfile] Stack trace:');
        print(stackTrace);

        // Check for specific error types
        if (e.toString().contains('column') && e.toString().contains('does not exist')) {
          print('[UserProfile] 🚨 DATABASE SCHEMA MISMATCH!');
          print('[UserProfile] Run DATABASE_MIGRATION_IMPERIAL.sql in Supabase SQL Editor');
        } else if (e.toString().contains('duplicate key')) {
          print('[UserProfile] 🚨 DUPLICATE USERNAME!');
          print('[UserProfile] Username already exists. Choose a different one.');
        } else if (e.toString().contains('violates check constraint')) {
          print('[UserProfile] 🚨 VALIDATION FAILED!');
          print('[UserProfile] Data does not meet database constraints.');
        }
      }

      rethrow; // Let caller handle the error
    }
  }

  // Get latest weight for profile display
  Future<String> getLatestWeight(String userId) async {
    try {
      final response = await _supabase
          .from('weight_logs')
          .select('weight_kg, logged_at')
          .eq('user_id', userId)
          .order('logged_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return 'No weight logged yet';
      }

      final weightKg = (response['weight_kg'] as num).toDouble();
      final loggedAt = DateTime.parse(response['logged_at']);
      final now = DateTime.now();
      final difference = now.difference(loggedAt);

      String timeAgo;
      if (difference.inMinutes < 60) {
        timeAgo = '${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        timeAgo = '${difference.inHours} hours ago';
      } else {
        timeAgo = '${difference.inDays} days ago';
      }

      return '$weightKg kg (logged $timeAgo)';
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[UserProfileService] Error fetching latest weight: $e');
        print('[UserProfileService] Stack trace: $stackTrace');
      }
      return 'Error loading weight';
    }
  }

  // Initialize notification preferences
  Future<void> initializeNotificationPreferences(String userId) async {
    try {
      // Try to insert, ignore if already exists
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
          });
    } catch (e, stackTrace) {
      // Ignore duplicate key errors (already exists)
      if (!e.toString().contains('duplicate key')) {
        if (kDebugMode) {
          print('[UserProfileService] Error initializing notification preferences: $e');
          print('[UserProfileService] Stack trace: $stackTrace');
        }
      }
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
