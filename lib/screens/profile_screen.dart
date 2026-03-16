import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/user_profile_service.dart';
import '../services/profile_photo_service.dart';
import '../services/cycles_database.dart';
import '../services/labs_database.dart';
import '../services/dose_logs_database.dart';
import '../providers/auth_provider.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../widgets/cyberpunk_rain.dart';
import '../widgets/city_background.dart';
import '../widgets/app_header.dart';
import '../widgets/common/matte_card.dart';
import '../widgets/common/cyber_button.dart';
import '../utils/user_feedback.dart';
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

  // Notification preferences (simplified)
  bool _doseReminders = true;

  // Notification preferences (old - kept for compatibility)
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

  // Stats
  int _cycleCount = 0;
  int _labReportCount = 0;
  int _doseLogCount = 0;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _ageController = TextEditingController();
    _heightFeetController = TextEditingController();
    _heightInchesController = TextEditingController();
    _bioController = TextEditingController();
    _loadSettings();
    _loadProfile();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _doseReminders = prefs.getBool('dose_reminders') ?? true;
      });
    } catch (e) {
      print('[ProfileScreen] Error loading settings: $e');
    }
  }

  Future<void> _saveDoseReminders(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dose_reminders', value);
      setState(() => _doseReminders = value);

      if (mounted) {
        UserFeedback.showSuccess(context, 'Dose reminders ${value ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      print('[ProfileScreen] Error saving dose reminders: $e');
      if (mounted) {
        UserFeedback.showError(context, 'Failed to save setting');
      }
    }
  }

  Future<void> _showUnitsDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'UNITS PREFERENCE',
          style: TextStyle(
            color: AppColors.primary,
            fontFamily: 'monospace',
            letterSpacing: 1,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Imperial (lbs, ft/in)', style: TextStyle(color: Colors.white)),
              trailing: _selectedUnits == 'imperial'
                  ? Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.pop(context, 'imperial'),
            ),
            ListTile(
              title: Text('Metric (kg, cm)', style: TextStyle(color: Colors.white)),
              trailing: _selectedUnits == 'metric'
                  ? Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.pop(context, 'metric'),
            ),
          ],
        ),
      ),
    );

    if (result != null && result != _selectedUnits) {
      setState(() => _selectedUnits = result);
      // Save to profile
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final profileService = ref.read(userProfileServiceProvider);
        await profileService.updateUserProfile(userId, unitsPreference: result);
        if (mounted) {
          UserFeedback.showSuccess(context, 'Units preference updated');
        }
      }
    }
  }

  Future<void> _exportData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // Show loading
      UserFeedback.showLoadingDialog(context, message: 'Exporting data...');

      // Fetch all data
      final cyclesDb = CyclesDatabase();
      final labsDb = LabsDatabase();
      final doseLogsDb = DoseLogsDatabase();

      final cycles = await cyclesDb.getUserCycles();
      final labs = await labsDb.getUserLabResults(userId);
      final doses = await doseLogsDb.getAllDoseLogs();

      // Create JSON export
      final export = {
        'exported_at': DateTime.now().toIso8601String(),
        'user_id': userId,
        'cycles': cycles.map((c) => {
          'id': c.id,
          'name': c.name,
          'start_date': c.startDate.toIso8601String(),
          'end_date': c.endDate?.toIso8601String(),
          'status': c.status,
          'notes': c.notes,
        }).toList(),
        'labs': labs.map((l) => {
          'id': l.id,
          'test_date': l.testDate.toIso8601String(),
          'biomarker_id': l.biomarkerId,
          'value': l.value,
          'unit': l.unit,
          'notes': l.notes,
        }).toList(),
        'doses': doses.map((d) => {
          'id': d.id,
          'timestamp': d.timestamp.toIso8601String(),
          'compound_name': d.compoundName,
          'dose_amount': d.doseAmount,
          'dose_unit': d.doseUnit,
          'notes': d.notes,
        }).toList(),
      };

      final jsonString = JsonEncoder.withIndent('  ').convert(export);

      // Close loading
      Navigator.pop(context);

      // Share the data
      final result = await Share.shareXFiles(
        [
          XFile.fromData(
            utf8.encode(jsonString),
            mimeType: 'application/json',
            name: 'biohacker_export_${DateTime.now().millisecondsSinceEpoch}.json',
          ),
        ],
        subject: 'Biohacker Data Export',
        text: 'Your Biohacker app data export',
      );

      if (result.status == ShareResultStatus.success) {
        UserFeedback.showSuccess(context, 'Data exported successfully');
      }
    } catch (e) {
      print('[ProfileScreen] Error exporting data: $e');
      Navigator.pop(context); // Close loading if still open
      if (mounted) {
        UserFeedback.showError(context, 'Failed to export data: ${e.toString()}');
      }
    }
  }

  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      if (mounted) {
        UserFeedback.showError(context, 'Could not open link');
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Delete Account?',
          style: TextStyle(
            color: AppColors.error,
            fontFamily: 'monospace',
            letterSpacing: 1,
          ),
        ),
        content: Text(
          'This will permanently delete:\n\n'
          '• All your cycles\n'
          '• All lab reports\n'
          '• All dose logs\n'
          '• Your account\n\n'
          'This action cannot be undone.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCEL',
              style: TextStyle(
                color: AppColors.textMid,
                fontFamily: 'monospace',
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'DELETE EVERYTHING',
              style: TextStyle(
                color: AppColors.error,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Show loading
        UserFeedback.showLoadingDialog(context, message: 'Deleting account...');

        // Delete all user data from database
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          // Note: This should ideally be a server-side function that cascades deletes
          // For now, we'll just sign out
          await Supabase.instance.client.auth.signOut();
        }

        // Navigate to login
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        Navigator.pop(context); // Close loading
        if (mounted) {
          UserFeedback.showError(context, 'Failed to delete account: ${e.toString()}');
        }
      }
    }
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

      // Load stats in parallel
      await _loadStats(userId);

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

  Future<void> _loadStats(String userId) async {
    try {
      final cyclesDb = CyclesDatabase();
      final labsDb = LabsDatabase();
      final doseLogsDb = DoseLogsDatabase();

      // Load all stats in parallel
      final results = await Future.wait([
        cyclesDb.getUserCycles(),
        labsDb.getUserLabResults(userId),
        doseLogsDb.getAllDoseLogs(),
      ]);

      setState(() {
        _cycleCount = results[0].length;
        _labReportCount = results[1].length;
        _doseLogCount = results[2].length;
      });
    } catch (e) {
      print('[ProfileScreen] Error loading stats: $e');
      // Don't show error to user, just log it
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
        });

        if (mounted) {
          UserFeedback.showSuccess(context, 'Profile photo updated successfully');
        }
      }
    } catch (e) {
      print('[ProfileScreen] Error uploading photo: $e');
      if (mounted) {
        UserFeedback.showError(
          context,
          UserFeedback.getFriendlyErrorMessage(e),
        );
      }
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
        _isEditMode = false; // Switch to ID card view after save
      });

      if (mounted) {
        UserFeedback.showSuccess(context, 'Profile saved successfully');
      }
    } catch (e) {
      print('[ProfileScreen] Error saving profile: $e');

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        UserFeedback.showError(
          context,
          UserFeedback.getFriendlyErrorMessage(e),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    return SafeArea(
      child: Stack(
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
          Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                // Header using reusable widget
                AppHeader(
                  icon: Icons.person,
                  iconColor: WintermmuteStyles.colorOrange,
                  title: 'PROFILE',
                ),
                Expanded(
                  child: Stack(
                    children: [
                      _isEditMode ? _buildForm() : _buildIDCard(),
                      // Scanlines overlay
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _ScanlinesPainter(),
                          ),
                        ),
                      ),
                      // Edit button (floating)
                      if (!_isEditMode)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() => _isEditMode = true);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      color: AppColors.background,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'EDIT',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.background,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
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

          // STATS SECTION
          MatteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'ACTIVITY STATS',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        label: 'CYCLES',
                        value: _cycleCount.toString(),
                        icon: Icons.autorenew,
                        color: WintermmuteStyles.colorGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        label: 'LAB REPORTS',
                        value: _labReportCount.toString(),
                        icon: Icons.science,
                        color: WintermmuteStyles.colorOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        label: 'TOTAL DOSES',
                        value: _doseLogCount.toString(),
                        icon: Icons.medical_services,
                        color: WintermmuteStyles.colorMagenta,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        label: 'APP VERSION',
                        value: '2.0',
                        icon: Icons.info_outline,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

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
                    onPressed: () async {
                      final confirmed = await UserFeedback.showConfirmDialog(
                        context: context,
                        title: 'Sign Out',
                        message: 'Are you sure you want to sign out?',
                        confirmText: 'SIGN OUT',
                        isDangerous: true,
                      );

                      if (confirmed && context.mounted) {
                        try {
                          await ref.read(authProviderProvider).signOut();
                          if (context.mounted) {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            UserFeedback.showError(
                              context,
                              'Failed to sign out - please try again',
                            );
                          }
                        }
                      }
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

          // NOTIFICATION SETTINGS
          MatteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'NOTIFICATION SETTINGS',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInteractiveToggle(
                  'Dose Reminders',
                  'Get notified when it\'s time to take your doses',
                  _doseReminders,
                  (value) => _saveDoseReminders(value),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // APP SETTINGS
          MatteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.settings, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'APP SETTINGS',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildActionTile(
                  'Dark Mode',
                  'Always enabled in Wintermute theme',
                  Icons.dark_mode,
                  null,
                  enabled: false,
                ),
                const Divider(height: 24, color: AppColors.textDim),
                _buildActionTile(
                  'Units',
                  _selectedUnits == 'imperial' ? 'Imperial (lbs, ft/in)' : 'Metric (kg, cm)',
                  Icons.straighten,
                  _showUnitsDialog,
                ),
                const Divider(height: 24, color: AppColors.textDim),
                _buildActionTile(
                  'Data Export',
                  'Export all your data as JSON',
                  Icons.download,
                  _exportData,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // APP INFO
          MatteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'APP INFO',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Version', '2.0.0'),
                const Divider(height: 24, color: AppColors.textDim),
                _buildActionTile(
                  'Privacy Policy',
                  'View our privacy policy',
                  Icons.privacy_tip,
                  () => _launchURL('https://example.com/privacy'),
                ),
                const Divider(height: 24, color: AppColors.textDim),
                _buildActionTile(
                  'Terms of Service',
                  'View our terms of service',
                  Icons.description,
                  () => _launchURL('https://example.com/terms'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // DANGER ZONE
          MatteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'DANGER ZONE',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildActionTile(
                  'Delete Account',
                  'Permanently delete all your data',
                  Icons.delete_forever,
                  _confirmDeleteAccount,
                  isDanger: true,
                ),
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

  // FORM VIEW - Simplified inline editing
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Info Card
          MatteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'EDIT PROFILE',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),

                // Save and Cancel Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                                'SAVE CHANGES',
                                style: TextStyle(
                                  color: AppColors.background,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_usernameController.text.isNotEmpty &&
                        _ageController.text.isNotEmpty &&
                        _selectedGender != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () {
                                  setState(() => _isEditMode = false);
                                },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: AppColors.textMid),
                          ),
                          child: Text(
                            'CANCEL',
                            style: TextStyle(
                              color: AppColors.textMid,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
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

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: color,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveToggle(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppColors.textMid,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withOpacity(0.5),
                inactiveThumbColor: AppColors.textDim,
                inactiveTrackColor: AppColors.textDim.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap, {
    bool isDanger = false,
    bool enabled = true,
  }) {
    final color = isDanger ? AppColors.error : AppColors.textLight;
    final iconColor = isDanger ? AppColors.error : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppColors.textMid,
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled && onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textDim,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.07)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
