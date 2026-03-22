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
import 'legal_screen.dart';
import 'about_screen.dart';
import 'onboarding/welcome_screen.dart';
import '../assets/legal_documents.dart';

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
  late TextEditingController _goalsController;

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
  String? _profilePhotoUrl;

  // Stats

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _ageController = TextEditingController();
    _heightFeetController = TextEditingController();
    _heightInchesController = TextEditingController();
    _bioController = TextEditingController();
    _goalsController = TextEditingController();
    _loadSettings();
    _loadProfile();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _doseReminders = prefs.getBool('dose_reminders') ?? true;
        _goalsController.text = prefs.getString('user_goals') ?? '';
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

  Future<void> _editGoals() async {
    final controller = TextEditingController(text: _goalsController.text);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'EDIT GOALS',
          style: TextStyle(
            color: AppColors.primary,
            fontFamily: 'monospace',
            letterSpacing: 1,
          ),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: AppColors.textLight),
          decoration: InputDecoration(
            hintText: 'Enter your goals...',
            hintStyle: TextStyle(color: AppColors.textDim),
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
          maxLines: 3,
          maxLength: 200,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: TextStyle(
                color: AppColors.textMid,
                fontFamily: 'monospace',
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(
              'SAVE',
              style: TextStyle(
                color: AppColors.primary,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_goals', result);
        setState(() {
          _goalsController.text = result;
        });
        if (mounted) {
          UserFeedback.showSuccess(context, 'Goals updated');
        }
      } catch (e) {
        print('[ProfileScreen] Error saving goals: $e');
        if (mounted) {
          UserFeedback.showError(context, 'Failed to save goals');
        }
      }
    }

    controller.dispose();
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
          'peptide_name': c.peptideName,
          'dose': c.dose,
          'route': c.route,
          'frequency': c.frequency,
          'duration_weeks': c.durationWeeks,
          'start_date': c.startDate.toIso8601String(),
          'end_date': c.endDate.toIso8601String(),
          'is_active': c.isActive,
          'created_at': c.createdAt.toIso8601String(),
          'advanced_schedule': c.advancedSchedule,
        }).toList(),
        'labs': labs.map((l) => {
          'id': l.id,
          'user_id': l.userId,
          'cycle_id': l.cycleId,
          'pdf_path': l.pdfPath,
          'extracted_data': l.extractedData,
          'upload_date': l.uploadDate.toIso8601String(),
          'processed_date': l.processedDate?.toIso8601String(),
          'notes': l.notes,
        }).toList(),
        'doses': doses.map((d) => {
          'id': d.id,
          'user_id': d.userId,
          'cycle_id': d.cycleId,
          'dose_amount': d.doseAmount,
          'logged_at': d.loggedAt.toIso8601String(),
          'route': d.route,
          'location': d.location,
          'notes': d.notes,
          'created_at': d.createdAt.toIso8601String(),
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

  String? _timezoneAbbreviation(String? timezone) {
    if (timezone == null) return null;
    const abbreviations = {
      'America/New_York': {'std': 'EST', 'dst': 'EDT'},
      'America/Chicago': {'std': 'CST', 'dst': 'CDT'},
      'America/Denver': {'std': 'MST', 'dst': 'MDT'},
      'America/Los_Angeles': {'std': 'PST', 'dst': 'PDT'},
      'America/Anchorage': {'std': 'AKST', 'dst': 'AKDT'},
      'Pacific/Honolulu': {'std': 'HST', 'dst': 'HST'},
      'America/Phoenix': {'std': 'MST', 'dst': 'MST'},
    };
    final mapping = abbreviations[timezone];
    if (mapping == null) return timezone.split('/').last.replaceAll('_', ' ');
    final now = DateTime.now();
    final utcNow = now.toUtc();
    // Approximate DST: second Sunday in March to first Sunday in November (US)
    final marchSecondSunday = DateTime(utcNow.year, 3, 8 + (7 - DateTime(utcNow.year, 3, 8).weekday) % 7, 2);
    final novFirstSunday = DateTime(utcNow.year, 11, 1 + (7 - DateTime(utcNow.year, 11, 1).weekday) % 7, 2);
    final isDst = utcNow.isAfter(marchSecondSunday) && utcNow.isBefore(novFirstSunday);
    return isDst ? mapping['dst'] : mapping['std'];
  }

  Future<void> _confirmResetOnboarding() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Reset Onboarding?',
          style: TextStyle(
            color: AppColors.error,
            fontFamily: 'monospace',
            letterSpacing: 1,
          ),
        ),
        content: Text(
          'This will reset your onboarding status and take you back through the setup flow.\n\n'
          'Your existing data will not be deleted.',
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
              'RESET',
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
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          await Supabase.instance.client
              .from('user_profiles')
              .update({'onboarding_completed': false})
              .eq('id', userId);
        }

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          UserFeedback.showError(context, 'Failed to reset onboarding: ${e.toString()}');
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
    _goalsController.dispose();
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
        // Load profile photo URL from database (persists across reinstalls)
        // Also check SharedPreferences as fallback for backwards compatibility
        final prefs = await SharedPreferences.getInstance();
        String? photoUrl = profile.photoUrl;
        if (photoUrl == null || photoUrl.isEmpty) {
          photoUrl = prefs.getString('profile_photo_url');
        }

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
          _profilePhotoUrl = photoUrl;

          if (profile.notificationPreferences != null) {
            profile.notificationPreferences!.forEach((key, value) {
              if (_notificationPreferences.containsKey(key)) {
                _notificationPreferences[key] = value as bool;
              }
            });
          }

          _healthGoalsFromOnboarding = profile.healthGoals;

          // Populate goals from database if not already set in SharedPreferences
          if (_goalsController.text.isEmpty && profile.healthGoals.isNotEmpty) {
            _goalsController.text = profile.healthGoals.join(', ');
            // Save to SharedPreferences for future loads
            prefs.setString('user_goals', _goalsController.text);
          }

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
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) {
        setState(() => _isUploadingPhoto = false);
        return;
      }

      // Read image bytes
      final bytes = await image.readAsBytes();

      // Upload to Supabase Storage
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await Supabase.instance.client.storage
          .from('profiles')
          .uploadBinary(fileName, bytes);

      // Get public URL
      final photoUrl = Supabase.instance.client.storage
          .from('profiles')
          .getPublicUrl(fileName);

      // Save URL to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_photo_url', photoUrl);
      
      // CRITICAL: Save URL to database so it persists across reinstalls
      final profileService = ref.read(userProfileServiceProvider);
      await profileService.updateUserProfile(
        userId,  // Positional parameter
        photoUrl: photoUrl,
      );

      setState(() {
        _profilePhotoUrl = photoUrl;
      });

      if (mounted) {
        UserFeedback.showSuccess(context, 'Profile photo updated successfully');
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

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  IconData _getGoalIcon(String goal) {
    final goalLower = goal.toLowerCase();

    // Match against common onboarding goals
    if (goalLower.contains('weight') || goalLower.contains('lose') || goalLower.contains('lean')) {
      return Icons.monitor_weight;
    } else if (goalLower.contains('muscle') || goalLower.contains('gain') || goalLower.contains('build')) {
      return Icons.fitness_center;
    } else if (goalLower.contains('energy') || goalLower.contains('vitality')) {
      return Icons.bolt;
    } else if (goalLower.contains('sleep') || goalLower.contains('rest')) {
      return Icons.bedtime;
    } else if (goalLower.contains('recovery') || goalLower.contains('heal')) {
      return Icons.healing;
    } else if (goalLower.contains('performance') || goalLower.contains('athletic')) {
      return Icons.speed;
    } else if (goalLower.contains('longevity') || goalLower.contains('aging') || goalLower.contains('anti-aging')) {
      return Icons.favorite;
    } else if (goalLower.contains('cognitive') || goalLower.contains('mental') || goalLower.contains('focus')) {
      return Icons.psychology;
    } else if (goalLower.contains('mood') || goalLower.contains('stress')) {
      return Icons.sentiment_satisfied;
    } else {
      return Icons.flag; // Default
    }
  }

  Color _getGoalColor(String goal) {
    final goalLower = goal.toLowerCase();

    if (goalLower.contains('weight') || goalLower.contains('lose')) {
      return Color(0xFF00FFFF); // Cyan
    } else if (goalLower.contains('muscle') || goalLower.contains('gain')) {
      return Color(0xFFFF6600); // Orange
    } else if (goalLower.contains('energy')) {
      return Color(0xFFFFFF00); // Yellow
    } else if (goalLower.contains('recovery')) {
      return Color(0xFF00FF99); // Mint
    } else if (goalLower.contains('longevity')) {
      return Color(0xFFFF00FF); // Magenta
    } else {
      return Color(0xFF00FF00); // Green default
    }
  }

  // CYBERPUNK ID CARD VIEW - Blade Runner Style
  Widget _buildIDCard() {
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id ?? '';

    // CRT orange colors
    final Color crtOrange = Color(0xFFFF9800); // Amber CRT orange
    final Color crtGlow = Color(0xFFFF6600);   // Darker orange for glow

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        children: [
          // BLADE RUNNER STYLE ID CARD - Compact horizontal layout
          Container(
            height: 140,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.black,  // Pure black background like CRT
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: crtOrange.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                // Heavy CRT glow
                BoxShadow(
                  color: crtOrange.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: crtGlow.withOpacity(0.3),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Stack(
              children: [
                // HEAVY scanlines overlay
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CustomPaint(
                      painter: HeavyScanlinesPainter(color: crtOrange),
                    ),
                  ),
                ),

                // CRT flicker/glow overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.2,
                        colors: [
                          crtOrange.withOpacity(0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // ID card content - horizontal layout
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Left: Profile photo/avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: crtOrange.withOpacity(0.7),  // Orange border
                            width: 2,
                          ),
                          image: _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(_profilePhotoUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        ),
                        child: Stack(
                          children: [
                            // Avatar (show only if no photo)
                            if (_profilePhotoUrl == null || _profilePhotoUrl!.isEmpty)
                              Center(
                                child: Text(
                                  _getInitials(_usernameController.text),
                                  style: TextStyle(
                                    color: crtOrange,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),

                            // Biometric scan overlay (if photo exists)
                            if (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty)
                              Positioned(
                                top: 2,
                                left: 2,
                                child: Icon(
                                  Icons.fingerprint,
                                  color: crtOrange.withOpacity(0.4),
                                  size: 14,
                                ),
                              ),

                            // BIO classification tag
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.8),
                                  border: Border.all(color: crtOrange.withOpacity(0.6), width: 1),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                                child: Text(
                                  'BIO',
                                  style: TextStyle(
                                    color: crtOrange,
                                    fontSize: 6,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            // Camera button for photo upload
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: _isUploadingPhoto ? null : _uploadProfilePhoto,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: crtOrange,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: _isUploadingPhoto
                                      ? SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            color: Colors.black,
                                          ),
                                        )
                                      : Icon(
                                          Icons.camera_alt,
                                          color: Colors.black,
                                          size: 12,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Right: ID info (compact, horizontal layout)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // ID header bar
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: crtOrange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    'CITIZEN ID',
                                    style: TextStyle(
                                      color: crtOrange,  // Orange instead of cyan
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Holographic shimmer icon
                                Icon(
                                  Icons.verified,
                                  color: crtOrange.withOpacity(0.5),
                                  size: 16,
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            // Name
                            Text(
                              _usernameController.text.toUpperCase(),
                              style: TextStyle(
                                color: crtOrange,  // Orange
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                letterSpacing: 1,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 3),

                            // Email (compact)
                            Text(
                              user?.email ?? '',
                              style: TextStyle(
                                color: crtOrange.withOpacity(0.7),  // Orange with transparency
                                fontSize: 9,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 8),

                            // Demographics row - text labels instead of icons
                            Wrap(
                              spacing: 12,
                              children: [
                                // Age
                                Text(
                                  'AGE: ${_ageController.text.isEmpty ? '--' : _ageController.text}',
                                  style: TextStyle(
                                    color: crtOrange.withOpacity(0.8),
                                    fontSize: 9,
                                    fontFamily: 'monospace',
                                  ),
                                ),

                                // Height
                                Text(
                                  'HT: ${_heightDisplay == 'Not set' ? '--' : _heightDisplay}',
                                  style: TextStyle(
                                    color: crtOrange.withOpacity(0.8),
                                    fontSize: 9,
                                    fontFamily: 'monospace',
                                  ),
                                ),

                                // Gender
                                Text(
                                  'SEX: ${_selectedGender != null ? _formatGender(_selectedGender).toUpperCase() : '--'}',
                                  style: TextStyle(
                                    color: crtOrange.withOpacity(0.8),
                                    fontSize: 9,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),

                            const Spacer(),

                            // Bottom section: Clearance, ID, and issue date
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Security clearance
                                Row(
                                  children: [
                                    Icon(Icons.security, color: crtOrange, size: 10),
                                    SizedBox(width: 4),
                                    Text(
                                      'CLEARANCE: DELTA-4',
                                      style: TextStyle(
                                        color: crtOrange.withOpacity(0.8),
                                        fontSize: 8,
                                        fontFamily: 'monospace',
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 3),

                                // ID number (generated from user ID)
                                Row(
                                  children: [
                                    Text(
                                      'ID: ',
                                      style: TextStyle(
                                        color: crtOrange.withOpacity(0.7),
                                        fontSize: 9,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    Text(
                                      userId.length >= 8 ? userId.substring(0, 8).toUpperCase() : userId.toUpperCase(),
                                      style: TextStyle(
                                        color: crtOrange,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 2),

                                // Issue date
                                Row(
                                  children: [
                                    Text(
                                      'ISSUED: ',
                                      style: TextStyle(
                                        color: crtOrange.withOpacity(0.6),
                                        fontSize: 8,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    Text(
                                      '2026.03.16',
                                      style: TextStyle(
                                        color: crtOrange,
                                        fontSize: 8,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Holographic corner accent
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          crtOrange.withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(topRight: Radius.circular(8)),
                    ),
                  ),
                ),

                // Government authority badge (top-right)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: crtOrange, width: 1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield, color: crtOrange, size: 10),
                        SizedBox(width: 3),
                        Text(
                          'AUTHORIZED',
                          style: TextStyle(
                            color: crtOrange,
                            fontSize: 7,
                            fontFamily: 'monospace',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Barcode at bottom-right
                Positioned(
                  bottom: 4,
                  right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // QR code icon
                      Icon(Icons.qr_code_2, color: crtOrange.withOpacity(0.6), size: 14),
                      SizedBox(width: 4),
                      // Barcode lines
                      CustomPaint(
                        size: Size(40, 10),
                        painter: BarcodePainter(color: crtOrange),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),


          // GOALS CARD - Green CRT aesthetic
          Container(
            height: 120,
            margin: EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black,
                  Color(0xFF001a00), // Dark green tint
                  Colors.black,
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Color(0xFF00FF00).withOpacity(0.6),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF00FF00).withOpacity(0.4),
                  blurRadius: 25,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Scanlines
                Positioned.fill(
                  child: CustomPaint(
                    painter: HeavyScanlinesPainter(color: Color(0xFF00FF00)),
                  ),
                ),

                // Content
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(Icons.flag, color: Color(0xFF00FF00), size: 12),
                          SizedBox(width: 6),
                          Text(
                            'MISSION OBJECTIVES',
                            style: TextStyle(
                              color: Color(0xFF00FF00),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 8),

                      // Goals text with icons
                      Expanded(
                        child: _goalsController.text.isEmpty
                          ? Center(
                              child: Text(
                                '[ NO OBJECTIVES SET ]',
                                style: TextStyle(
                                  color: Color(0xFF00FF00).withOpacity(0.4),
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _goalsController.text
                                    .split('\n')
                                    .where((line) => line.trim().isNotEmpty)
                                    .map((goal) {
                                      final icon = _getGoalIcon(goal);
                                      final color = _getGoalColor(goal);

                                      return Padding(
                                        padding: EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              icon,
                                              color: color.withOpacity(0.8),
                                              size: 12,
                                            ),
                                            SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                goal.toUpperCase(),
                                                style: TextStyle(
                                                  color: color.withOpacity(0.9),
                                                  fontSize: 9,
                                                  fontFamily: 'monospace',
                                                  height: 1.3,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                      ),
                    ],
                  ),
                ),

                // Classification badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF00FF00), width: 1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      'PRIORITY-1',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontSize: 7,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
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
                  'Timezone',
                  _timezoneAbbreviation(_selectedTimezone) ?? 'Not set',
                  Icons.access_time,
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
                  'About',
                  'Learn about Biohacker',
                  Icons.info,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  ),
                ),
                const Divider(height: 24, color: AppColors.textDim),
                _buildActionTile(
                  'Privacy Policy',
                  'View our privacy policy',
                  Icons.privacy_tip,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LegalScreen(
                        title: 'PRIVACY POLICY',
                        content: LegalDocuments.privacyPolicy,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 24, color: AppColors.textDim),
                _buildActionTile(
                  'Terms of Service',
                  'View our terms of service',
                  Icons.description,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LegalScreen(
                        title: 'TERMS OF SERVICE',
                        content: LegalDocuments.termsOfService,
                      ),
                    ),
                  ),
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
                const SizedBox(height: 8),
                _buildActionTile(
                  'Reset Onboarding',
                  'Re-run the onboarding setup flow',
                  Icons.restart_alt,
                  _confirmResetOnboarding,
                  isDanger: true,
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _isEditMode = true),
                    icon: Icon(Icons.edit, size: 16),
                    label: Text(
                      'EDIT PROFILE',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF9800).withOpacity(0.15),
                      foregroundColor: Color(0xFFFF9800),
                      side: BorderSide(color: Color(0xFFFF9800).withOpacity(0.6), width: 2),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
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

class _IDCardScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.05)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 2) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HeavyScanlinesPainter extends CustomPainter {
  final Color color;

  HeavyScanlinesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.15)  // Heavier opacity
      ..strokeWidth = 2.0;  // Thicker lines

    // Draw horizontal scanlines every 3 pixels (dense)
    for (double i = 0; i < size.height; i += 3) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }

    // Add vertical scanlines for CRT effect (light)
    final verticalPaint = Paint()
      ..color = color.withOpacity(0.05)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.width; i += 2) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        verticalPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BarcodePainter extends CustomPainter {
  final Color color;

  BarcodePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 1.0;

    // Draw random-width barcode lines
    double x = 0;
    final random = [2.0, 1.0, 3.0, 1.0, 2.0, 1.0, 4.0, 2.0, 1.0, 3.0, 1.0, 2.0];
    int index = 0;

    while (x < size.width && index < random.length) {
      final width = random[index % random.length];
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
      x += width + 1;
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
