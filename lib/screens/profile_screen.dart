import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_profile_service.dart';
import '../theme/colors.dart';

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
      final weight = await profileService.getLatestWeight(userId);
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
        username: _usernameController.text.trim(),
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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: AppColors.background,
        ),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.background,
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
              style: TextStyle(color: AppColors.textLight),
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(color: AppColors.textMid),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.textDim),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Username is required';
                }
                if (value.trim().length < 1 || value.trim().length > 50) {
                  return 'Username must be 1-50 characters';
                }
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                  return 'Only letters, numbers, and underscores allowed';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Section: Health Basics
            Text(
              'HEALTH BASICS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textMid,
              ),
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Latest Weight (Read-only)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.textDim),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latest Weight (Read-only)',
                    style: TextStyle(fontSize: 12, color: AppColors.textMid),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _latestWeight,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Age
            TextFormField(
              controller: _ageController,
              style: TextStyle(color: AppColors.textLight),
              decoration: InputDecoration(
                labelText: 'Age',
                labelStyle: TextStyle(color: AppColors.textMid),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.textDim),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
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
              style: TextStyle(color: AppColors.textLight),
              dropdownColor: AppColors.surface,
              decoration: InputDecoration(
                labelText: 'Gender',
                labelStyle: TextStyle(color: AppColors.textMid),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.textDim),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
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
              style: TextStyle(color: AppColors.textLight),
              decoration: InputDecoration(
                labelText: 'Height (cm)',
                labelStyle: TextStyle(color: AppColors.textMid),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.textDim),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
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
              style: TextStyle(color: AppColors.textLight),
              dropdownColor: AppColors.surface,
              decoration: InputDecoration(
                labelText: 'Timezone',
                labelStyle: TextStyle(color: AppColors.textMid),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.textDim),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
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
            Text(
              'MEDICAL INFORMATION',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textMid,
              ),
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Allergies
            TextFormField(
              controller: _allergiesController,
              style: TextStyle(color: AppColors.textLight),
              decoration: InputDecoration(
                labelText: 'Allergies (optional)',
                labelStyle: TextStyle(color: AppColors.textMid),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.textDim),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                hintText: 'e.g., Penicillin, Peanuts',
                hintStyle: TextStyle(color: AppColors.textDim),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: 16),

            // Medical Conditions
            Text(
              'Medical Conditions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 8),
            ..._medicalConditions.keys.map((key) {
              return CheckboxListTile(
                title: Text(
                  _capitalizeCondition(key),
                  style: TextStyle(color: AppColors.textLight),
                ),
                value: _medicalConditions[key],
                activeColor: AppColors.primary,
                checkColor: AppColors.background,
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
                  style: TextStyle(color: AppColors.textLight),
                  decoration: InputDecoration(
                    labelText: 'Specify other condition',
                    labelStyle: TextStyle(color: AppColors.textMid),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.textDim),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
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
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.textDim,
              ),
              child: _isSaving
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.background),
                      ),
                    )
                  : Text(
                      'Save Profile',
                      style: TextStyle(
                        color: AppColors.background,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Success/Error Messages
            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accent),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: TextStyle(color: AppColors.accent),
                      ),
                    ),
                  ],
                ),
              ),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _capitalizeCondition(String key) {
    return key
        .split('_')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
