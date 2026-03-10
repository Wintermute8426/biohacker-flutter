// ============================================
// Profile Screen - Complete Code Examples
// Version: 1.0
// ============================================

// ============================================
// 1. UPDATED UserProfile MODEL
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String userId;
  final String? username;
  final int? age;
  final String? gender; // 'male', 'female', 'other', 'prefer_not_to_say'
  final int? heightCm;
  final String? allergies;
  final List<String> medicalConditions; // ['diabetes', 'hypertension', ...]
  final String experienceLevel;
  final List<String> healthGoals;
  final double? baselineWeight;
  final double? baselineBodyFat;
  final Map<String, dynamic>? baselineLabs;
  final String timezone;
  final bool onboardingCompleted;
  final DateTime? onboardingCompletedAt;

  UserProfile({
    required this.userId,
    this.username,
    this.age,
    this.gender,
    this.heightCm,
    this.allergies,
    this.medicalConditions = const [],
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
      username: json['username'],
      age: json['age'],
      gender: json['gender'],
      heightCm: json['height_cm'],
      allergies: json['allergies'],
      medicalConditions: json['medical_conditions'] != null
          ? List<String>.from(json['medical_conditions'])
          : [],
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
      'username': username,
      'age': age,
      'gender': gender,
      'height_cm': heightCm,
      'allergies': allergies,
      'medical_conditions': medicalConditions,
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
    String? username,
    int? age,
    String? gender,
    int? heightCm,
    String? allergies,
    List<String>? medicalConditions,
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
      username: username ?? this.username,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      healthGoals: healthGoals ?? this.healthGoals,
      baselineWeight: baselineWeight ?? this.baselineWeight,
      baselineBodyFat: baselineBodyFat ?? this.baselineBodyFat,
      baselineLabs: baselineLabs ?? this.baselineLabs,
      timezone: timezone ?? this.timezone,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      onboardingCompletedAt:
          onboardingCompletedAt ?? this.onboardingCompletedAt,
    );
  }
}

// ============================================
// 2. WEIGHT DISPLAY HELPER
// ============================================

import 'package:timeago/timeago.dart' as timeago;

class WeightDisplayHelper {
  final SupabaseClient _supabase;

  WeightDisplayHelper(this._supabase);

  Future<String> getLatestWeightDisplay(String userId) async {
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
      final timeAgo = timeago.format(loggedAt, locale: 'en_short');

      return '$weightKg kg (logged $timeAgo)';
    } catch (e) {
      print('Error fetching latest weight: $e');
      return 'Error loading weight';
    }
  }
}

// ============================================
// 3. PROFILE SCREEN UI
// ============================================

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _usernameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _allergiesController;
  late TextEditingController _otherConditionController;

  // Dropdown values
  String? _selectedGender;
  String? _selectedTimezone;

  // Medical conditions
  final Map<String, bool> _medicalConditions = {
    'diabetes': false,
    'hypertension': false,
    'heart_disease': false,
    'thyroid_issues': false,
    'none': false,
    'other': false,
  };

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  String? _successMessage;
  String? _errorMessage;
  String _latestWeight = 'Loading...';

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _ageController = TextEditingController();
    _heightController = TextEditingController();
    _allergiesController = TextEditingController();
    _otherConditionController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _allergiesController.dispose();
    _otherConditionController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _errorMessage = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Load profile
      final profileService = ref.read(userProfileServiceProvider);
      final profile = await profileService.getUserProfile(userId);

      if (profile != null) {
        setState(() {
          _usernameController.text = profile.username ?? '';
          _ageController.text = profile.age?.toString() ?? '';
          _heightController.text = profile.heightCm?.toString() ?? '';
          _allergiesController.text = profile.allergies ?? '';
          _selectedGender = profile.gender;
          _selectedTimezone = profile.timezone;

          // Load medical conditions
          for (var condition in profile.medicalConditions) {
            if (_medicalConditions.containsKey(condition)) {
              _medicalConditions[condition] = true;
            } else if (condition.startsWith('other:')) {
              _medicalConditions['other'] = true;
              _otherConditionController.text = condition.substring(6).trim();
            }
          }
        });
      }

      // Load latest weight
      final weightHelper = WeightDisplayHelper(Supabase.instance.client);
      final weight = await weightHelper.getLatestWeightDisplay(userId);
      setState(() {
        _latestWeight = weight;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading profile: $e';
        _isLoading = false;
      });
    }
  }

  List<String> _getSelectedMedicalConditions() {
    final selected = <String>[];
    _medicalConditions.forEach((key, value) {
      if (value) {
        if (key == 'other' && _otherConditionController.text.isNotEmpty) {
          selected.add('other: ${_otherConditionController.text}');
        } else if (key != 'other') {
          selected.add(key);
        }
      }
    });
    return selected;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _successMessage = null;
      _errorMessage = null;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final profileService = ref.read(userProfileServiceProvider);
      
      await profileService.updateUserProfile(
        userId,
        username: _usernameController.text,
        age: int.tryParse(_ageController.text),
        gender: _selectedGender,
        heightCm: int.tryParse(_heightController.text),
        allergies: _allergiesController.text.isEmpty ? null : _allergiesController.text,
        medicalConditions: _getSelectedMedicalConditions(),
        timezone: _selectedTimezone,
      );

      setState(() {
        _isSaving = false;
        _successMessage = 'Profile saved successfully';
      });

      // Clear success message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _successMessage = null);
        }
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString().contains('duplicate')
            ? 'Username already taken'
            : 'Could not save profile. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Username
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Username is required';
                }
                if (value.length < 1 || value.length > 50) {
                  return 'Username must be 1-50 characters';
                }
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                  return 'Only letters, numbers, and underscores allowed';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Section: Health Basics
            const Text(
              'HEALTH BASICS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Latest Weight (Read-only)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Latest Weight (Read-only)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _latestWeight,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Age
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Age is required';
                }
                final age = int.tryParse(value);
                if (age == null || age < 10 || age > 120) {
                  return 'Age must be between 10 and 120';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Gender
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
                DropdownMenuItem(
                    value: 'prefer_not_to_say',
                    child: Text('Prefer not to say')),
              ],
              onChanged: (value) => setState(() => _selectedGender = value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a gender';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Height
            TextFormField(
              controller: _heightController,
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Height is required';
                }
                final height = int.tryParse(value);
                if (height == null || height < 50 || height > 300) {
                  return 'Height must be between 50 and 300 cm';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Timezone
            DropdownButtonFormField<String>(
              value: _selectedTimezone,
              decoration: const InputDecoration(
                labelText: 'Timezone',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'America/New_York', child: Text('Eastern Time')),
                DropdownMenuItem(
                    value: 'America/Chicago', child: Text('Central Time')),
                DropdownMenuItem(
                    value: 'America/Denver', child: Text('Mountain Time')),
                DropdownMenuItem(
                    value: 'America/Los_Angeles', child: Text('Pacific Time')),
                DropdownMenuItem(
                    value: 'Europe/London', child: Text('London')),
                DropdownMenuItem(
                    value: 'Europe/Paris', child: Text('Paris')),
                DropdownMenuItem(
                    value: 'Asia/Tokyo', child: Text('Tokyo')),
              ],
              onChanged: (value) => setState(() => _selectedTimezone = value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a timezone';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Section: Medical Information
            const Text(
              'MEDICAL INFORMATION',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Allergies
            TextFormField(
              controller: _allergiesController,
              decoration: const InputDecoration(
                labelText: 'Allergies (optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., Penicillin, Peanuts',
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: 16),

            // Medical Conditions
            const Text(
              'Medical Conditions',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ..._medicalConditions.keys.map((key) {
              return CheckboxListTile(
                title: Text(key.replaceAll('_', ' ').capitalize()),
                value: _medicalConditions[key],
                onChanged: _medicalConditions['none'] == true && key != 'none'
                    ? null
                    : (value) {
                        setState(() {
                          if (key == 'none' && value == true) {
                            // Clear all other conditions
                            _medicalConditions.forEach((k, v) {
                              _medicalConditions[k] = k == 'none';
                            });
                          } else {
                            _medicalConditions[key] = value ?? false;
                            if (value == true) {
                              _medicalConditions['none'] = false;
                            }
                          }
                        });
                      },
              );
            }).toList(),
            if (_medicalConditions['other'] == true) ...[
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
                child: TextFormField(
                  controller: _otherConditionController,
                  decoration: const InputDecoration(
                    labelText: 'Specify other condition',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : const Text('Save Profile'),
            ),
            const SizedBox(height: 16),

            // Success/Error Messages
            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(_successMessage!),
                  ],
                ),
              ),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// 4. HELPER EXTENSION
// ============================================

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

// ============================================
// 5. RIVERPOD PROVIDER FOR WEIGHT HELPER
// ============================================

final weightDisplayHelperProvider = Provider<WeightDisplayHelper>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return WeightDisplayHelper(supabase);
});

// ============================================
// END OF CODE EXAMPLES
// ============================================
