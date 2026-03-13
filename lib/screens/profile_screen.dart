import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../services/user_profile_service.dart';
import '../services/profile_photo_service.dart';
import '../providers/auth_provider.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../widgets/cyberpunk_rain.dart';
import '../widgets/city_background.dart';
import '../main.dart';

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
  late TextEditingController _heightFeetController;
  late TextEditingController _heightInchesController;
  late TextEditingController _bioController;

  // Dropdown values
  String? _selectedGender;
  String? _selectedTimezone;
  String _selectedUnits = 'imperial';

  // Notification preferences
  final Map<String, bool> _notificationPreferences = {
    'email': true,
    'push': false,
    'sms': false,
  };

  // Health goals
  List<String> _healthGoalsFromOnboarding = [];

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditMode = false; // NEW: Toggle between ID card and form
  bool _isUploadingPhoto = false;
  String? _successMessage;
  String? _errorMessage;
  String? _latestWeight;
  String _heightDisplay = 'Not set';
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _ageController = TextEditingController();
    _heightFeetController = TextEditingController();
    _heightInchesController = TextEditingController();
    _bioController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _ageController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _errorMessage = 'Not authenticated';
          _isLoading = false;
          _isEditMode = true; // Show form if not authenticated
        });
        return;
      }

      final profileService = ref.read(userProfileServiceProvider);
      final profile = await profileService.getUserProfile(userId);

      if (profile != null) {
        setState(() {
          _usernameController.text = profile.username ?? '';
          _ageController.text = profile.age?.toString() ?? '';
          _heightFeetController.text = profile.heightFeet?.toString() ?? '';
          _heightInchesController.text = profile.heightInches?.toString() ?? '';
          _bioController.text = profile.bio ?? '';
          _selectedGender = profile.gender;
          _selectedTimezone = profile.timezone;
          _selectedUnits = profile.unitsPreference ?? 'imperial';
          _heightDisplay = profile.heightFormatted;
          _photoUrl = profile.photoUrl;

          if (profile.notificationPreferences != null) {
            profile.notificationPreferences!.forEach((key, value) {
              if (_notificationPreferences.containsKey(key)) {
                _notificationPreferences[key] = value as bool;
              }
            });
          }

          _healthGoalsFromOnboarding = profile.healthGoals;

          // If profile is incomplete, show form
          _isEditMode = profile.username == null || 
                         profile.age == null || 
                         profile.gender == null;
        });
      } else {
        // No profile exists, show form
        setState(() {
          _isEditMode = true;
        });
      }

      // Load latest weight
      try {
        final weight = await profileService.getLatestWeight(userId);
        if (!weight.contains('Error')) {
          setState(() {
            _latestWeight = weight;
          });
        }
      } catch (e) {
        print('[ProfileScreen] Weight loading error: $e');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('[ProfileScreen] Error loading profile: $e');
      setState(() {
        _errorMessage = 'Error loading profile: $e';
        _isLoading = false;
        _isEditMode = true;
      });
    }
  }

  void _updateHeightDisplay() {
    final feet = _heightFeetController.text;
    final inches = _heightInchesController.text;
    if (feet.isNotEmpty && inches.isNotEmpty) {
      setState(() {
        _heightDisplay = '$feet\'$inches"';
      });
    } else {
      setState(() {
        _heightDisplay = 'Not set';
      });
    }
  }

  Future<void> _uploadProfilePhoto() async {
    setState(() => _isUploadingPhoto = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final photoService = ProfilePhotoService();
      final newPhotoUrl = await photoService.pickAndUploadPhoto(userId, oldPhotoUrl: _photoUrl);

      if (newPhotoUrl != null) {
        setState(() {
          _photoUrl = newPhotoUrl;
          _successMessage = 'Profile photo updated successfully';
        });

        // Clear success message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _successMessage = null);
          }
        });
      }
    } catch (e) {
      print('[ProfileScreen] Error uploading photo: $e');
      setState(() {
        _errorMessage = 'Failed to upload photo: ${e.toString()}';
      });
    } finally {
      setState(() => _isUploadingPhoto = false);
    }
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
        heightFeet: int.tryParse(_heightFeetController.text),
        heightInches: int.tryParse(_heightInchesController.text),
        timezone: _selectedTimezone,
        unitsPreference: _selectedUnits,
        bio: _bioController.text.isEmpty ? null : _bioController.text,
        notificationPreferences: _notificationPreferences,
      );

      _updateHeightDisplay();

      setState(() {
        _isSaving = false;
        _successMessage = 'Profile saved successfully';
        _isEditMode = false; // Switch to ID card view after save
      });

      // Clear success message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _successMessage = null);
        }
      });
    } catch (e) {
      print('[ProfileScreen] Error saving profile: $e');
      
      String errorMsg;
      if (e.toString().contains('duplicate')) {
        errorMsg = 'Username already taken';
      } else if (e.toString().contains('column') && e.toString().contains('does not exist')) {
        errorMsg = 'Database error: Missing columns';
      } else {
        errorMsg = 'Could not save profile';
      }
      
      setState(() {
        _isSaving = false;
        _errorMessage = errorMsg;
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
      body: Stack(
        children: [
          // City background layer
          const Positioned.fill(
            child: CityBackground(
              enabled: true,
              animateLights: true,
              opacity: 0.3,
            ),
          ),
          // Rain effect layer
          const Positioned.fill(
            child: CyberpunkRain(
              enabled: true,
              particleCount: 40,
              opacity: 0.25,
            ),
          ),
          Column(
            children: [
              // Header with dark background bar
              Container(
                color: AppColors.surface.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      color: AppColors.textLight,
                    ),
                    Icon(Icons.person, color: WintermmuteStyles.colorOrange, size: 28),
                    const SizedBox(width: 12),
                    Text('PROFILE', style: WintermmuteStyles.titleStyle),
                    const Spacer(),
                    if (!_isEditMode)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => setState(() => _isEditMode = true),
                        color: AppColors.textLight,
                      ),
                  ],
                ),
              ),
              Divider(color: AppColors.primary.withOpacity(0.3), thickness: 1, height: 1),
              Expanded(
                child: _isEditMode ? _buildForm() : _buildIDCard(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // CYBERPUNK ID CARD VIEW
  Widget _buildIDCard() {
    final user = Supabase.instance.client.auth.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ID Card Container (matte Wintermute style)
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.15), // Matte dark background
              border: Border.all(
                color: AppColors.primary.withOpacity(0.25), // Subtle border
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08), // Subtle glow
                  blurRadius: 6,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: USERNAME + ID Number
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BIOHACKER ID',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          letterSpacing: 2,
                          color: AppColors.textMid,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _usernameController.text.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'ID: ${Supabase.instance.client.auth.currentUser?.id.substring(0, 8).toUpperCase() ?? 'UNKNOWN'}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: AppColors.textDim,
                        ),
                      ),
                    ],
                  ),
                ),

                // Scanline effect (decorative)
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.accent,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Profile Photo Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Stack(
                      children: [
                        // Profile photo with cyan glow
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.1),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _photoUrl != null && _photoUrl!.isNotEmpty
                                ? Image.network(
                                    _photoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildDefaultAvatar();
                                    },
                                  )
                                : _buildDefaultAvatar(),
                          ),
                        ),
                        // Edit button
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _isUploadingPhoto ? null : _uploadProfilePhoto,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withOpacity(0.1),
                                    blurRadius: 6,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: _isUploadingPhoto
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.background,
                                      ),
                                    )
                                  : Icon(
                                      Icons.camera_alt,
                                      color: AppColors.background,
                                      size: 16,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Stats Grid
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bio
                      if (_bioController.text.isNotEmpty) ...[
                        _buildStatRow('BIO', _bioController.text),
                        const Divider(height: 24),
                      ],

                      // Core Stats
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatBlock(
                              'AGE',
                              _ageController.text,
                              Icons.calendar_today,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatBlock(
                              'GENDER',
                              _formatGender(_selectedGender),
                              Icons.person,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatBlock(
                              'HEIGHT',
                              _heightDisplay,
                              Icons.straighten,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatBlock(
                              'WEIGHT',
                              _latestWeight ?? 'N/A',
                              Icons.monitor_weight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildStatBlock(
                        'TIMEZONE',
                        _selectedTimezone?.split('/').last ?? 'Not set',
                        Icons.access_time,
                      ),

                      // Health Goals
                      if (_healthGoalsFromOnboarding.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          'OBJECTIVES',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMid,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _healthGoalsFromOnboarding.map((goal) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.accent,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _capitalizeGoal(goal).toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  color: AppColors.accent,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      // Footer: Status indicator
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withOpacity(0.1),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              color: AppColors.accent,
                              letterSpacing: 1,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'BIOHACKER V2',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9,
                              color: AppColors.textDim,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ACCOUNT SECTION
          _buildSectionCard(
            'ACCOUNT',
            Column(
              children: [
                _buildInfoRow('Email', user?.email ?? 'N/A'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(authProviderProvider).signOut();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'SIGN OUT',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // NOTIFICATIONS SECTION
          _buildSectionCard(
            'NOTIFICATIONS',
            Column(
              children: [
                _buildToggleRow('Dose Reminders', _notificationPreferences['email'] ?? true, 'email'),
                const Divider(height: 24, color: AppColors.textDim),
                _buildToggleRow('Lab Alerts', _notificationPreferences['push'] ?? false, 'push'),
                const Divider(height: 24, color: AppColors.textDim),
                _buildToggleRow('Quiet Hours', _notificationPreferences['sms'] ?? false, 'sms'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // APP SETTINGS SECTION
          _buildSectionCard(
            'APP SETTINGS',
            Column(
              children: [
                _buildInfoRow('Units', _selectedUnits == 'imperial' ? 'Imperial (lbs, ft/in)' : 'Metric (kg, cm)'),
                const Divider(height: 24, color: AppColors.textDim),
                _buildInfoRow('Theme', 'Cyberpunk (default)'),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.15), // Matte background
        border: Border.all(color: AppColors.primary.withOpacity(0.2)), // Subtle border
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05), // Very subtle glow
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: AppColors.textMid,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleRow(String label, bool value, String key) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: AppColors.textMid,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: value ? AppColors.accent.withOpacity(0.2) : AppColors.textDim.withOpacity(0.2),
            border: Border.all(
              color: value ? AppColors.accent : AppColors.textDim,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value ? 'ON' : 'OFF',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: value ? AppColors.accent : AppColors.textDim,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            color: AppColors.textMid,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBlock(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.15), // Matte background
        border: Border.all(color: AppColors.textDim.withOpacity(0.2)), // Subtle border
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppColors.textMid),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: AppColors.textMid,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatGender(String? gender) {
    if (gender == null) return 'N/A';
    switch (gender) {
      case 'male':
        return 'M';
      case 'female':
        return 'F';
      case 'other':
        return 'X';
      case 'prefer_not_to_say':
        return 'N/A';
      default:
        return 'N/A';
    }
  }

  // FORM VIEW (existing form code)
  Widget _buildForm() {
    return Form(
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

          // Health Basics Section
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
          if (_latestWeight != null) ...[
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
                    'Latest Weight',
                    style: TextStyle(fontSize: 12, color: AppColors.textMid),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _latestWeight!,
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
          ],

          // Height Display
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
                  'Current Height',
                  style: TextStyle(fontSize: 12, color: AppColors.textMid),
                ),
                const SizedBox(height: 4),
                Text(
                  _heightDisplay,
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

          // Height Input
          Text(
            'Update Height',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _heightFeetController,
                  style: TextStyle(color: AppColors.textLight),
                  decoration: InputDecoration(
                    labelText: 'Feet',
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
                    hintText: '3-7',
                    hintStyle: TextStyle(color: AppColors.textDim),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _updateHeightDisplay(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    final feet = int.tryParse(value);
                    if (feet == null || feet < 3 || feet > 7) {
                      return '3-7';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _heightInchesController,
                  style: TextStyle(color: AppColors.textLight),
                  decoration: InputDecoration(
                    labelText: 'Inches',
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
                    hintText: '0-11',
                    hintStyle: TextStyle(color: AppColors.textDim),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _updateHeightDisplay(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    final inches = int.tryParse(value);
                    if (inches == null || inches < 0 || inches > 11) {
                      return '0-11';
                    }
                    return null;
                  },
                ),
              ),
            ],
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

          // Preferences Section
          Text(
            'PREFERENCES',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textMid,
            ),
          ),
          const Divider(),
          const SizedBox(height: 16),

          // Units
          DropdownButtonFormField<String>(
            value: _selectedUnits,
            style: TextStyle(color: AppColors.textLight),
            dropdownColor: AppColors.surface,
            decoration: InputDecoration(
              labelText: 'Units Preference',
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
              DropdownMenuItem(value: 'imperial', child: Text('Imperial (lbs, ft/in, mg)')),
              DropdownMenuItem(value: 'metric', child: Text('Metric (kg, cm, ml)')),
            ],
            onChanged: (value) => setState(() => _selectedUnits = value!),
          ),
          const SizedBox(height: 16),

          // Notification Preferences
          Text(
            'Notification Preferences',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            title: Text('Email Notifications', style: TextStyle(color: AppColors.textLight)),
            value: _notificationPreferences['email'],
            activeColor: AppColors.primary,
            checkColor: AppColors.background,
            onChanged: (value) {
              setState(() => _notificationPreferences['email'] = value ?? false);
            },
          ),
          CheckboxListTile(
            title: Text('Push Notifications', style: TextStyle(color: AppColors.textLight)),
            value: _notificationPreferences['push'],
            activeColor: AppColors.primary,
            checkColor: AppColors.background,
            onChanged: (value) {
              setState(() => _notificationPreferences['push'] = value ?? false);
            },
          ),
          CheckboxListTile(
            title: Text('SMS Notifications', style: TextStyle(color: AppColors.textLight)),
            value: _notificationPreferences['sms'],
            activeColor: AppColors.primary,
            checkColor: AppColors.background,
            onChanged: (value) {
              setState(() => _notificationPreferences['sms'] = value ?? false);
            },
          ),
          const SizedBox(height: 16),

          // Health Goals (read-only)
          if (_healthGoalsFromOnboarding.isNotEmpty) ...[
            Text(
              'Health Goals',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 8),
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
                    'From Onboarding (Read-Only)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMid,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _healthGoalsFromOnboarding.map((goal) {
                      return Chip(
                        label: Text(
                          _capitalizeGoal(goal),
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        side: BorderSide(color: AppColors.primary, width: 1),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Bio
          TextFormField(
            controller: _bioController,
            style: TextStyle(color: AppColors.textLight),
            decoration: InputDecoration(
              labelText: 'Bio (optional)',
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
              hintText: 'Tell us a bit about yourself...',
              hintStyle: TextStyle(color: AppColors.textDim),
            ),
            maxLines: 3,
            maxLength: 200,
          ),
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
    );
  }

  String _capitalizeGoal(String key) {
    return key
        .split('_')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppColors.surface,
      child: Center(
        child: Icon(
          Icons.person,
          size: 48,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
