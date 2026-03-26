import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../services/user_profile_service.dart';
import '../services/cycles_database.dart';
import '../services/notification_service.dart';
import '../services/notification_scheduler.dart';
import '../services/labs_database.dart';
import '../services/dose_logs_database.dart';
import '../services/biometric_auth_service.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../widgets/cyberpunk_background.dart';
import '../widgets/app_header.dart';
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

  // Controllers - Operator Profile
  late TextEditingController _usernameController;
  late TextEditingController _ageController;
  late TextEditingController _bioController;

  // Controllers - Physical Metrics
  late TextEditingController _heightFeetController;
  late TextEditingController _heightInchesController;

  // Controllers - Medical
  late TextEditingController _allergiesController;
  late TextEditingController _medicalConditionsController;

  // Goals (legacy)
  late TextEditingController _goalsController;

  // Dropdown values
  String? _selectedGender;
  String? _selectedTimezone;
  String _selectedUnits = 'imperial';
  String _selectedExperienceLevel = 'beginner';
  String? _selectedTrainingLevel;
  String? _selectedBloodworkFrequency;
  String? _selectedCycleStatus;
  String? _selectedContactMethod;
  String? _selectedLastLabDate;
  bool _usedPeptidesBefore = false;
  List<String> _previousPeptides = [];

  // Health goals
  List<String> _healthGoalsFromOnboarding = [];

  // Legacy email/sms/push toggle (kept for profile update API compat)
  final Map<String, bool> _notificationPreferences = {
    'email': true,
    'push': false,
    'sms': false,
  };

  // Local notification preferences (from notification_preferences table)
  bool _doseReminders = true;
  String _doseReminderTime = '08:00';
  bool _cycleMilestones = true;
  bool _sideEffectsEnabled = true;
  bool _researchUpdates = true;
  String _labReminderFrequency = 'every_3_months';

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditMode = false;
  bool _isUploadingPhoto = false;
  String? _latestWeight;
  String _heightDisplay = 'Not set';
  String? _profilePhotoUrl;

  // Security settings
  bool _biometricEnabled = false;
  bool _biometricSupported = false;
  String _biometricType = 'Biometric';
  final BiometricAuthService _biometricAuth = BiometricAuthService();

  // Original values for cancel/discard
  Map<String, dynamic> _originalValues = {};

  // Common peptide compounds for selection
  static const List<String> _knownPeptides = [
    'BPC-157', 'TB-500', 'GHK-Cu', 'PT-141', 'CJC-1295',
    'Ipamorelin', 'Tesamorelin', 'Sermorelin', 'GHRP-6', 'GHRP-2',
    'Epithalon', 'Thymosin Alpha-1', 'AOD-9604', 'MOTS-c', 'SS-31',
    'Selank', 'Semax', 'Dihexa', 'KPV', 'LL-37',
    'Melanotan II', 'Kisspeptin-10', 'GLP-1', 'Semaglutide', 'Tirzepatide',
  ];

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _ageController = TextEditingController();
    _bioController = TextEditingController();
    _heightFeetController = TextEditingController();
    _heightInchesController = TextEditingController();
    _allergiesController = TextEditingController();
    _medicalConditionsController = TextEditingController();
    _goalsController = TextEditingController();
    _loadSettings();
    _loadProfile();
    _loadBiometricSettings();
  }

  Future<void> _loadBiometricSettings() async {
    final supported = await _biometricAuth.isDeviceSupported();
    final enabled = await _biometricAuth.isBiometricEnabled();
    final types = await _biometricAuth.getAvailableBiometrics();
    final typeName = _biometricAuth.getBiometricTypeName(types);

    if (mounted) {
      setState(() {
        _biometricSupported = supported;
        _biometricEnabled = enabled;
        _biometricType = typeName;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    _allergiesController.dispose();
    _medicalConditionsController.dispose();
    _goalsController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _goalsController.text = prefs.getString('user_goals') ?? '';
      });

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final notifPrefs =
            await NotificationScheduler().loadPrefs(userId);
        setState(() {
          _doseReminders = notifPrefs.doseRemindersEnabled;
          _doseReminderTime = notifPrefs.doseReminderTime;
          _cycleMilestones = notifPrefs.cycleMilestonesEnabled;
          _sideEffectsEnabled = notifPrefs.sideEffectsEnabled;
          _researchUpdates = notifPrefs.researchUpdatesEnabled;
          _labReminderFrequency = notifPrefs.labReminderFrequency;
        });
      }
    } catch (e) {
      print('[ProfileScreen] Error loading settings: $e');
    }
  }

  Future<void> _loadProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _isEditMode = true;
        });
        return;
      }

      final profileService = ref.read(userProfileServiceProvider);
      final profile = await profileService.getUserProfile(userId);

      if (profile != null) {
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
          _allergiesController.text = profile.allergies ?? '';
          _medicalConditionsController.text = profile.medicalConditions.join(', ');
          _selectedGender = profile.gender;
          _selectedTimezone = profile.timezone;
          _selectedUnits = profile.unitsPreference ?? 'imperial';
          _selectedExperienceLevel = profile.experienceLevel;
          _selectedTrainingLevel = profile.trainingLevel;
          _selectedBloodworkFrequency = profile.bloodworkFrequency;
          _selectedCycleStatus = profile.cycleStatus;
          _selectedContactMethod = profile.contactMethod;
          _selectedLastLabDate = profile.lastLabDate;
          _usedPeptidesBefore = profile.usedPeptidesBefore;
          _previousPeptides = List.from(profile.previousPeptides);
          _heightDisplay = profile.heightFormatted;
          _profilePhotoUrl = photoUrl;
          _healthGoalsFromOnboarding = profile.healthGoals;

          if (profile.notificationPreferences != null) {
            profile.notificationPreferences!.forEach((key, value) {
              if (_notificationPreferences.containsKey(key)) {
                _notificationPreferences[key] = value as bool;
              }
            });
          }

          if (_goalsController.text.isEmpty && profile.healthGoals.isNotEmpty) {
            _goalsController.text = profile.healthGoals.join(', ');
            prefs.setString('user_goals', _goalsController.text);
          }

          _isEditMode = profile.username == null ||
                         profile.age == null ||
                         profile.gender == null;
        });

        _captureOriginalValues();
      } else {
        setState(() => _isEditMode = true);
      }

      // Load latest weight
      try {
        final weight = await profileService.getLatestWeight(userId);
        if (!weight.contains('Error')) {
          setState(() => _latestWeight = weight);
        }
      } catch (e) {
        print('[ProfileScreen] Weight loading error: $e');
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('[ProfileScreen] Error loading profile: $e');
      setState(() {
        _isLoading = false;
        _isEditMode = true;
      });
    }
  }

  void _captureOriginalValues() {
    _originalValues = {
      'username': _usernameController.text,
      'age': _ageController.text,
      'bio': _bioController.text,
      'heightFeet': _heightFeetController.text,
      'heightInches': _heightInchesController.text,
      'allergies': _allergiesController.text,
      'medicalConditions': _medicalConditionsController.text,
      'gender': _selectedGender,
      'timezone': _selectedTimezone,
      'units': _selectedUnits,
      'experienceLevel': _selectedExperienceLevel,
      'trainingLevel': _selectedTrainingLevel,
      'bloodworkFrequency': _selectedBloodworkFrequency,
      'cycleStatus': _selectedCycleStatus,
      'contactMethod': _selectedContactMethod,
      'lastLabDate': _selectedLastLabDate,
      'usedPeptidesBefore': _usedPeptidesBefore,
      'previousPeptides': List.from(_previousPeptides),
    };
  }

  void _discardChanges() {
    setState(() {
      _usernameController.text = _originalValues['username'] ?? '';
      _ageController.text = _originalValues['age'] ?? '';
      _bioController.text = _originalValues['bio'] ?? '';
      _heightFeetController.text = _originalValues['heightFeet'] ?? '';
      _heightInchesController.text = _originalValues['heightInches'] ?? '';
      _allergiesController.text = _originalValues['allergies'] ?? '';
      _medicalConditionsController.text = _originalValues['medicalConditions'] ?? '';
      _selectedGender = _originalValues['gender'];
      _selectedTimezone = _originalValues['timezone'];
      _selectedUnits = _originalValues['units'] ?? 'imperial';
      _selectedExperienceLevel = _originalValues['experienceLevel'] ?? 'beginner';
      _selectedTrainingLevel = _originalValues['trainingLevel'];
      _selectedBloodworkFrequency = _originalValues['bloodworkFrequency'];
      _selectedCycleStatus = _originalValues['cycleStatus'];
      _selectedContactMethod = _originalValues['contactMethod'];
      _selectedLastLabDate = _originalValues['lastLabDate'];
      _usedPeptidesBefore = _originalValues['usedPeptidesBefore'] ?? false;
      _previousPeptides = List.from(_originalValues['previousPeptides'] ?? []);
      _isEditMode = false;
    });
  }

  void _updateHeightDisplay() {
    final feet = _heightFeetController.text;
    final inches = _heightInchesController.text;
    setState(() {
      _heightDisplay = (feet.isNotEmpty && inches.isNotEmpty)
          ? '$feet\'$inches"'
          : 'Not set';
    });
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
    final marchSecondSunday = DateTime(utcNow.year, 3, 8 + (7 - DateTime(utcNow.year, 3, 8).weekday) % 7, 2);
    final novFirstSunday = DateTime(utcNow.year, 11, 1 + (7 - DateTime(utcNow.year, 11, 1).weekday) % 7, 2);
    final isDst = utcNow.isAfter(marchSecondSunday) && utcNow.isBefore(novFirstSunday);
    return isDst ? mapping['dst'] : mapping['std'];
  }

  String _formatGender(String? gender) {
    if (gender == null) return 'N/A';
    switch (gender) {
      case 'male': return 'M';
      case 'female': return 'F';
      case 'other': return 'X';
      case 'prefer_not_to_say': return 'N/A';
      default: return 'N/A';
    }
  }

  String _capitalizeGoal(String key) {
    return key
        .split('_')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
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
    if (goalLower.contains('weight') || goalLower.contains('lose') || goalLower.contains('lean') || goalLower.contains('fat')) return Icons.monitor_weight;
    if (goalLower.contains('muscle') || goalLower.contains('gain') || goalLower.contains('build')) return Icons.fitness_center;
    if (goalLower.contains('energy') || goalLower.contains('vitality')) return Icons.bolt;
    if (goalLower.contains('sleep') || goalLower.contains('rest')) return Icons.bedtime;
    if (goalLower.contains('recovery') || goalLower.contains('heal')) return Icons.healing;
    if (goalLower.contains('performance') || goalLower.contains('athletic')) return Icons.speed;
    if (goalLower.contains('longevity') || goalLower.contains('aging') || goalLower.contains('anti-aging')) return Icons.favorite;
    if (goalLower.contains('cognitive') || goalLower.contains('mental') || goalLower.contains('focus')) return Icons.psychology;
    if (goalLower.contains('mood') || goalLower.contains('stress')) return Icons.sentiment_satisfied;
    if (goalLower.contains('immune')) return Icons.shield;
    return Icons.flag;
  }

  Color _getGoalColor(String goal) {
    final goalLower = goal.toLowerCase();
    if (goalLower.contains('weight') || goalLower.contains('lose') || goalLower.contains('fat')) return AppColors.primary;
    if (goalLower.contains('muscle') || goalLower.contains('gain')) return const Color(0xFFFF6600);
    if (goalLower.contains('energy')) return const Color(0xFFFFFF00);
    if (goalLower.contains('recovery')) return const Color(0xFF00FF99);
    if (goalLower.contains('longevity')) return AppColors.secondary;
    if (goalLower.contains('sleep')) return const Color(0xFF8B5CF6);
    if (goalLower.contains('cognitive') || goalLower.contains('focus')) return AppColors.primary;
    if (goalLower.contains('immune')) return AppColors.accent;
    if (goalLower.contains('performance')) return const Color(0xFFFFAA00);
    return const Color(0xFF00FF00);
  }

  // ==================== SAVE PROFILE ====================

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final profileService = ref.read(userProfileServiceProvider);

      // Parse medical conditions from comma-separated text
      final medicalConditions = _medicalConditionsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

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
        experienceLevel: _selectedExperienceLevel,
        trainingLevel: _selectedTrainingLevel,
        bloodworkFrequency: _selectedBloodworkFrequency,
        cycleStatus: _selectedCycleStatus,
        contactMethod: _selectedContactMethod,
        lastLabDate: _selectedLastLabDate,
        usedPeptidesBefore: _usedPeptidesBefore,
        previousPeptides: _previousPeptides,
        allergies: _allergiesController.text.isEmpty ? null : _allergiesController.text,
        medicalConditions: medicalConditions,
      );

      _updateHeightDisplay();
      _captureOriginalValues();

      setState(() {
        _isSaving = false;
        _isEditMode = false;
      });

      if (mounted) {
        UserFeedback.showSuccess(context, 'Profile saved successfully');
      }
    } catch (e) {
      print('[ProfileScreen] Error saving profile: $e');
      setState(() => _isSaving = false);
      if (mounted) {
        UserFeedback.showError(context, UserFeedback.getFriendlyErrorMessage(e));
      }
    }
  }

  // ==================== PHOTO UPLOAD ====================

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

      final bytes = await image.readAsBytes();
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await Supabase.instance.client.storage
          .from('profiles')
          .uploadBinary(fileName, bytes);

      final photoUrl = Supabase.instance.client.storage
          .from('profiles')
          .getPublicUrl(fileName);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_photo_url', photoUrl);

      final profileService = ref.read(userProfileServiceProvider);
      await profileService.updateUserProfile(userId, photoUrl: photoUrl);

      setState(() => _profilePhotoUrl = photoUrl);

      if (mounted) {
        UserFeedback.showSuccess(context, 'Profile photo updated successfully');
      }
    } catch (e) {
      print('[ProfileScreen] Error uploading photo: $e');
      if (mounted) {
        UserFeedback.showError(context, UserFeedback.getFriendlyErrorMessage(e));
      }
    } finally {
      setState(() => _isUploadingPhoto = false);
    }
  }

  // ==================== NOTIFICATION SETTINGS ====================

  Future<void> _saveNotificationPrefs() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final prefs = NotificationPrefs(
        doseRemindersEnabled: _doseReminders,
        doseReminderTime: _doseReminderTime,
        cycleMilestonesEnabled: _cycleMilestones,
        sideEffectsEnabled: _sideEffectsEnabled,
        researchUpdatesEnabled: _researchUpdates,
        labReminderFrequency: _labReminderFrequency,
      );

      await NotificationScheduler().savePrefs(userId, prefs);
      await NotificationScheduler().rescheduleAll();

      if (mounted) {
        UserFeedback.showSuccess(context, 'Notification settings saved');
      }
    } catch (e) {
      print('[ProfileScreen] Error saving notification prefs: $e');
      if (mounted) {
        UserFeedback.showError(context, 'Failed to save notification settings');
      }
    }
  }

  Future<void> _pickDoseReminderTime() async {
    final parts = _doseReminderTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: Colors.black,
            surface: AppColors.surface,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _doseReminderTime =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
      await _saveNotificationPrefs();
    }
  }

  // ==================== DATA EXPORT ====================

  Future<void> _exportData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      UserFeedback.showLoadingDialog(context, message: 'Exporting data...');

      final cyclesDb = CyclesDatabase();
      final labsDb = LabsDatabase();
      final doseLogsDb = DoseLogsDatabase();

      final cycles = await cyclesDb.getUserCycles();
      final labs = await labsDb.getUserLabResults(userId);
      final doses = await doseLogsDb.getAllDoseLogs();

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
      Navigator.pop(context);

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
      Navigator.pop(context);
      if (mounted) {
        UserFeedback.showError(context, 'Failed to export data: ${e.toString()}');
      }
    }
  }

  // ==================== DIALOGS ====================

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'DELETE ACCOUNT?',
          style: TextStyle(
            color: AppColors.error,
            fontFamily: 'monospace',
            letterSpacing: 1,
          ),
        ),
        content: Text(
          'This will permanently delete:\n\n'
          '- All your cycles\n'
          '- All lab reports\n'
          '- All dose logs\n'
          '- Your account\n\n'
          'This action cannot be undone.',
          style: TextStyle(color: AppColors.textLight, fontFamily: 'monospace', fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL', style: TextStyle(color: AppColors.textMid, fontFamily: 'monospace')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('DELETE EVERYTHING', style: TextStyle(color: AppColors.error, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        UserFeedback.showLoadingDialog(context, message: 'Deleting account...');
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          await Supabase.instance.client.auth.signOut();
        }
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        Navigator.pop(context);
        if (mounted) {
          UserFeedback.showError(context, 'Failed to delete account: ${e.toString()}');
        }
      }
    }
  }

  Future<void> _confirmResetOnboarding() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'RESET ONBOARDING?',
          style: TextStyle(color: AppColors.error, fontFamily: 'monospace', letterSpacing: 1),
        ),
        content: Text(
          'This will reset your onboarding status and take you back through the setup flow.\n\n'
          'Your existing data will not be deleted.',
          style: TextStyle(color: AppColors.textLight, fontFamily: 'monospace', fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL', style: TextStyle(color: AppColors.textMid, fontFamily: 'monospace')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('RESET', style: TextStyle(color: AppColors.error, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
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

  Future<void> _showHealthGoalsDialog() async {
    final allGoals = [
      {'slug': 'muscle', 'name': 'MUSCLE GROWTH & RECOVERY', 'icon': Icons.fitness_center},
      {'slug': 'fat_loss', 'name': 'FAT LOSS & METABOLISM', 'icon': Icons.local_fire_department},
      {'slug': 'longevity', 'name': 'LONGEVITY & ANTI-AGING', 'icon': Icons.auto_awesome},
      {'slug': 'recovery', 'name': 'INJURY & TISSUE REPAIR', 'icon': Icons.healing},
      {'slug': 'cognitive', 'name': 'COGNITIVE ENHANCEMENT', 'icon': Icons.psychology},
      {'slug': 'performance', 'name': 'ATHLETIC PERFORMANCE', 'icon': Icons.speed},
      {'slug': 'sleep', 'name': 'SLEEP OPTIMIZATION', 'icon': Icons.nightlight_round},
      {'slug': 'immune', 'name': 'IMMUNE SUPPORT', 'icon': Icons.shield},
    ];

    final selected = List<String>.from(_healthGoalsFromOnboarding);

    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0A0A0A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: AppColors.primary.withOpacity(0.4), width: 2),
          ),
          title: Row(
            children: [
              Icon(Icons.flag, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                'OPTIMIZATION VECTORS',
                style: TextStyle(color: AppColors.primary, fontFamily: 'monospace', fontSize: 14, letterSpacing: 1),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: allGoals.map((goal) {
                final isSelected = selected.contains(goal['slug']);
                final color = _getGoalColor(goal['slug'] as String);
                return ListTile(
                  dense: true,
                  leading: Icon(goal['icon'] as IconData, color: isSelected ? color : AppColors.textDim, size: 18),
                  title: Text(
                    goal['name'] as String,
                    style: TextStyle(
                      color: isSelected ? color : AppColors.textMid,
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_box, color: color, size: 18)
                      : Icon(Icons.check_box_outline_blank, color: AppColors.textDim, size: 18),
                  onTap: () {
                    setDialogState(() {
                      if (isSelected) {
                        selected.remove(goal['slug']);
                      } else {
                        selected.add(goal['slug'] as String);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL', style: TextStyle(color: AppColors.textMid, fontFamily: 'monospace', fontSize: 12)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selected),
              child: Text('CONFIRM', style: TextStyle(color: AppColors.primary, fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          final profileService = ref.read(userProfileServiceProvider);
          await profileService.updateUserProfile(userId, healthGoals: result);
          setState(() {
            _healthGoalsFromOnboarding = result;
            _goalsController.text = result.join(', ');
          });
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_goals', _goalsController.text);
          if (mounted) UserFeedback.showSuccess(context, 'Health goals updated');
        }
      } catch (e) {
        if (mounted) UserFeedback.showError(context, 'Failed to update goals');
      }
    }
  }

  Future<void> _showPeptideSelectionDialog() async {
    final selected = List<String>.from(_previousPeptides);

    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0A0A0A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: AppColors.secondary.withOpacity(0.4), width: 2),
          ),
          title: Row(
            children: [
              Icon(Icons.science, color: AppColors.secondary, size: 16),
              const SizedBox(width: 8),
              Text(
                'COMPOUND HISTORY',
                style: TextStyle(color: AppColors.secondary, fontFamily: 'monospace', fontSize: 14, letterSpacing: 1),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView(
              children: _knownPeptides.map((peptide) {
                final isSelected = selected.contains(peptide);
                return ListTile(
                  dense: true,
                  title: Text(
                    peptide,
                    style: TextStyle(
                      color: isSelected ? AppColors.secondary : AppColors.textMid,
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_box, color: AppColors.secondary, size: 18)
                      : Icon(Icons.check_box_outline_blank, color: AppColors.textDim, size: 18),
                  onTap: () {
                    setDialogState(() {
                      if (isSelected) {
                        selected.remove(peptide);
                      } else {
                        selected.add(peptide);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL', style: TextStyle(color: AppColors.textMid, fontFamily: 'monospace', fontSize: 12)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selected),
              child: Text('CONFIRM', style: TextStyle(color: AppColors.secondary, fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() => _previousPeptides = result);
    }
  }

  Future<void> _showLastLabDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedLastLabDate != null ? DateTime.tryParse(_selectedLastLabDate!) ?? DateTime.now() : DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              surface: const Color(0xFF0A0A0A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedLastLabDate = picked.toIso8601String().split('T').first;
      });
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'LOADING OPERATOR DOSSIER...',
                  style: TextStyle(color: AppColors.primary, fontFamily: 'monospace', fontSize: 12, letterSpacing: 2),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return CyberpunkBackground(
      cityOpacity: 0.3,
      rainOpacity: 0.25,
      rainParticleCount: 40,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              AppHeader(
                icon: Icons.person,
                iconColor: WintermmuteStyles.colorOrange,
                title: 'PROFILE',
              ),
              Expanded(
                child: Stack(
                  children: [
                    _isEditMode ? _buildEditView() : _buildDisplayView(),
                    // Scanlines overlay
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(painter: _ScanlinesPainter()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== DISPLAY VIEW (ID Card + Sections) ====================

  Widget _buildDisplayView() {
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id ?? '';
    final Color crtOrange = AppColors.amber;
    const Color crtGlow = Color(0xFFFF6600);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        children: [
          // ===== OPERATOR ID CARD =====
          _buildOperatorIDCard(user, userId, crtOrange, crtGlow),
          const SizedBox(height: 20),

          // ===== PHYSICAL METRICS =====
          _buildSection(
            'PHYSICAL METRICS',
            Icons.straighten,
            AppColors.primary,
            Column(
              children: [
                _buildDataRow('HEIGHT', _heightDisplay == 'Not set' ? '--' : _heightDisplay),
                _buildDataRow('WEIGHT', _latestWeight ?? '--'),
                _buildDataRow('UNITS', _selectedUnits == 'imperial' ? 'IMPERIAL' : 'METRIC'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ===== FIELD HISTORY =====
          _buildSection(
            'FIELD HISTORY',
            Icons.science,
            AppColors.secondary,
            Column(
              children: [
                _buildDataRow('EXPERIENCE', _selectedExperienceLevel.toUpperCase()),
                _buildDataRow('TRAINING', _selectedTrainingLevel?.toUpperCase() ?? '--'),
                _buildDataRow('CYCLE STATUS', _selectedCycleStatus?.toUpperCase() ?? '--'),
                _buildDataRow('PEPTIDE HISTORY', _usedPeptidesBefore ? 'YES' : 'NO'),
                if (_previousPeptides.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _previousPeptides.map((p) => _buildChip(p, AppColors.secondary)).toList(),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ===== DIAGNOSTIC INTEL =====
          _buildSection(
            'DIAGNOSTIC INTEL',
            Icons.biotech,
            AppColors.amber,
            Column(
              children: [
                _buildDataRow('BLOODWORK FREQ', _selectedBloodworkFrequency?.toUpperCase() ?? '--'),
                _buildDataRow('LAST LAB DATE', _selectedLastLabDate ?? '--'),
                _buildDataRow('ALLERGIES', _allergiesController.text.isEmpty ? '--' : _allergiesController.text.toUpperCase()),
                _buildDataRow('CONDITIONS', _medicalConditionsController.text.isEmpty ? '--' : _medicalConditionsController.text.toUpperCase()),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ===== OPTIMIZATION VECTORS =====
          _buildSection(
            'OPTIMIZATION VECTORS',
            Icons.flag,
            AppColors.accent,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_healthGoalsFromOnboarding.isEmpty)
                  Text(
                    '[ NO OBJECTIVES SET ]',
                    style: TextStyle(color: AppColors.textDim, fontFamily: 'monospace', fontSize: 11, fontStyle: FontStyle.italic),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _healthGoalsFromOnboarding.map((goal) {
                      return _buildGoalChip(goal);
                    }).toList(),
                  ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _showHealthGoalsDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, color: AppColors.accent, size: 14),
                        const SizedBox(width: 6),
                        Text('EDIT VECTORS', style: TextStyle(color: AppColors.accent, fontFamily: 'monospace', fontSize: 10, letterSpacing: 1)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ===== ACCOUNT =====
          _buildSection(
            'ACCOUNT',
            Icons.terminal,
            AppColors.primary,
            Column(
              children: [
                _buildDataRow('EMAIL', user?.email ?? 'N/A'),
                _buildDataRow('TIMEZONE', _timezoneAbbreviation(_selectedTimezone) ?? 'NOT SET'),
                _buildDataRow('CONTACT', _selectedContactMethod?.toUpperCase() ?? '--'),
                const SizedBox(height: 16),
                // Edit Profile button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _captureOriginalValues();
                      setState(() => _isEditMode = true);
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: Text(
                      'MODIFY DOSSIER',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12, letterSpacing: 1),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: crtOrange.withOpacity(0.15),
                      foregroundColor: crtOrange,
                      side: BorderSide(color: crtOrange.withOpacity(0.6), width: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Sign Out
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
                            UserFeedback.showError(context, 'Failed to sign out - please try again');
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error.withOpacity(0.15),
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withOpacity(0.6), width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Text(
                      'SIGN OUT',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ===== NOTIFICATION SETTINGS =====
          _buildSection(
            'NOTIFICATION SETTINGS',
            Icons.notifications,
            AppColors.primary,
            Column(children: [
              _buildInteractiveToggle(
                'Dose Reminders',
                'Alert at scheduled dose time',
                _doseReminders,
                (v) {
                  setState(() => _doseReminders = v);
                  _saveNotificationPrefs();
                },
              ),
              if (_doseReminders) ...[
                const Divider(height: 20, color: Color(0xFF1A1A1A)),
                _buildNotifActionRow(
                  'Reminder Time',
                  _doseReminderTime,
                  Icons.access_time,
                  _pickDoseReminderTime,
                ),
              ],
              const Divider(height: 20, color: Color(0xFF1A1A1A)),
              _buildInteractiveToggle(
                'Cycle Milestones',
                'Start, midpoint, pre-end, and completion alerts',
                _cycleMilestones,
                (v) {
                  setState(() => _cycleMilestones = v);
                  _saveNotificationPrefs();
                },
              ),
              const Divider(height: 20, color: Color(0xFF1A1A1A)),
              _buildInteractiveToggle(
                'Side Effect Check-ins',
                'Weekly protocol status prompts during active cycles',
                _sideEffectsEnabled,
                (v) {
                  setState(() => _sideEffectsEnabled = v);
                  _saveNotificationPrefs();
                },
              ),
              const Divider(height: 20, color: Color(0xFF1A1A1A)),
              _buildNotifDropdownRow(
                'Lab Reminders',
                _labReminderFrequency,
                {
                  'never': 'Never',
                  'monthly': 'Monthly',
                  'every_3_months': 'Every 3 Months',
                  'every_6_months': 'Every 6 Months',
                },
                (v) {
                  setState(() => _labReminderFrequency = v!);
                  _saveNotificationPrefs();
                },
              ),
              const Divider(height: 20, color: Color(0xFF1A1A1A)),
              _buildInteractiveToggle(
                'Research Updates',
                'New peptide studies and intelligence updates',
                _researchUpdates,
                (v) {
                  setState(() => _researchUpdates = v);
                  _saveNotificationPrefs();
                },
              ),
              const Divider(height: 20, color: Color(0xFF1A1A1A)),
              _buildActionTile(
                'Test Notification',
                'Fire a test notification to verify setup',
                Icons.bug_report,
                () async {
                  await NotificationService().showTestNotification();
                  if (mounted) {
                    UserFeedback.showSuccess(
                        context, 'Test notification sent');
                  }
                },
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // ===== DEBUG: NOTIFICATION TESTING =====
          if (kDebugMode)
            _buildSection(
              'DEBUG TESTING',
              Icons.science,
              Colors.red,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'FIRE IMMEDIATELY — NO SCHEDULING',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Colors.red.withOpacity(0.7),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDebugNotifButton('Dose Reminder', 'dose_reminder'),
                      _buildDebugNotifButton('Missed Dose', 'missed_dose'),
                      _buildDebugNotifButton('Cycle Start', 'cycle_start'),
                      _buildDebugNotifButton('Cycle Midpoint', 'cycle_mid'),
                      _buildDebugNotifButton('Cycle Ending', 'cycle_ending'),
                      _buildDebugNotifButton('Cycle Complete', 'cycle_complete'),
                      _buildDebugNotifButton('Lab Reminder', 'lab_reminder'),
                      _buildDebugNotifButton('Side Effect Check', 'side_effect'),
                    ],
                  ),
                ],
              ),
            ),
          if (kDebugMode) const SizedBox(height: 12),

          // ===== APP SETTINGS =====
          // ===== SECURITY SETTINGS =====
          _buildSection(
            'SECURITY',
            Icons.security,
            AppColors.primary,
            Column(
              children: [
                if (_biometricSupported) ...[
                  _buildSwitchTile(
                    'Biometric Authentication',
                    'Use $_biometricType to unlock the app',
                    Icons.fingerprint,
                    _biometricEnabled,
                    (value) => _toggleBiometric(value),
                  ),
                  const Divider(height: 24, color: Color(0xFF1A1A1A)),
                ],
                _buildDataRow('SESSION TIMEOUT', '30 minutes'),
                const SizedBox(height: 8),
                Text(
                  'Auto-logout after 30 minutes of inactivity',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _buildSection(
            'APP SETTINGS',
            Icons.settings,
            AppColors.primary,
            Column(
              children: [
                _buildActionTile('Dark Mode', 'Always enabled in Wintermute theme', Icons.dark_mode, null, enabled: false),
                const Divider(height: 24, color: Color(0xFF1A1A1A)),
                _buildActionTile('Data Export', 'Export all your data as JSON', Icons.download, _exportData),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ===== APP INFO =====
          _buildSection(
            'APP INFO',
            Icons.info,
            AppColors.primary,
            Column(
              children: [
                _buildDataRow('VERSION', '2.0.0'),
                const Divider(height: 24, color: Color(0xFF1A1A1A)),
                _buildActionTile(
                  'About', 'Learn about Biohacker', Icons.info,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                ),
                const Divider(height: 24, color: Color(0xFF1A1A1A)),
                _buildActionTile(
                  'Privacy Policy', 'View our privacy policy', Icons.privacy_tip,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => LegalScreen(title: 'PRIVACY POLICY', content: LegalDocuments.privacyPolicy))),
                ),
                const Divider(height: 24, color: Color(0xFF1A1A1A)),
                _buildActionTile(
                  'Terms of Service', 'View our terms of service', Icons.description,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => LegalScreen(title: 'TERMS OF SERVICE', content: LegalDocuments.termsOfService))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ===== DANGER ZONE =====
          _buildSection(
            'DANGER ZONE',
            Icons.warning,
            AppColors.error,
            Column(
              children: [
                _buildActionTile('Reset Onboarding', 'Re-run the onboarding setup flow', Icons.restart_alt, _confirmResetOnboarding, isDanger: true),
                const SizedBox(height: 8),
                _buildActionTile('Delete Account', 'Permanently delete all your data', Icons.delete_forever, _confirmDeleteAccount, isDanger: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ===== OPERATOR ID CARD (Blade Runner Style) =====

  Widget _buildOperatorIDCard(User? user, String userId, Color crtOrange, Color crtGlow) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: crtOrange.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(color: crtOrange.withOpacity(0.4), blurRadius: 30, spreadRadius: 5),
          BoxShadow(color: crtGlow.withOpacity(0.3), blurRadius: 50, spreadRadius: 10),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CustomPaint(painter: HeavyScanlinesPainter(color: crtOrange)),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [crtOrange.withOpacity(0.05), Colors.transparent],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile photo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: crtOrange.withOpacity(0.7), width: 2),
                    image: _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty
                        ? DecorationImage(image: NetworkImage(_profilePhotoUrl!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: Stack(
                    children: [
                      if (_profilePhotoUrl == null || _profilePhotoUrl!.isEmpty)
                        Center(
                          child: Text(
                            _getInitials(_usernameController.text),
                            style: TextStyle(color: crtOrange, fontSize: 36, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                          ),
                        ),
                      if (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty)
                        Positioned(top: 2, left: 2, child: Icon(Icons.fingerprint, color: crtOrange.withOpacity(0.4), size: 14)),
                      Positioned(
                        top: 2, right: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            border: Border.all(color: crtOrange.withOpacity(0.6), width: 1),
                            borderRadius: BorderRadius.circular(1),
                          ),
                          child: Text('BIO', style: TextStyle(color: crtOrange, fontSize: 6, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                        ),
                      ),
                      Positioned(
                        bottom: 2, right: 2,
                        child: GestureDetector(
                          onTap: _isUploadingPhoto ? null : _uploadProfilePhoto,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: crtOrange, borderRadius: BorderRadius.circular(2)),
                            child: _isUploadingPhoto
                                ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.black))
                                : Icon(Icons.camera_alt, color: Colors.black, size: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // ID info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: crtOrange.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
                            child: Text('CITIZEN ID', style: TextStyle(color: crtOrange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, fontFamily: 'monospace')),
                          ),
                          const Spacer(),
                          Icon(Icons.verified, color: crtOrange.withOpacity(0.5), size: 16),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _usernameController.text.toUpperCase(),
                        style: TextStyle(color: crtOrange, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'monospace', letterSpacing: 1),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(color: crtOrange.withOpacity(0.7), fontSize: 9, fontFamily: 'monospace'),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        children: [
                          Text('AGE: ${_ageController.text.isEmpty ? '--' : _ageController.text}', style: TextStyle(color: crtOrange.withOpacity(0.8), fontSize: 9, fontFamily: 'monospace')),
                          Text('HT: ${_heightDisplay == 'Not set' ? '--' : _heightDisplay}', style: TextStyle(color: crtOrange.withOpacity(0.8), fontSize: 9, fontFamily: 'monospace')),
                          Text('SEX: ${_selectedGender != null ? _formatGender(_selectedGender).toUpperCase() : '--'}', style: TextStyle(color: crtOrange.withOpacity(0.8), fontSize: 9, fontFamily: 'monospace')),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.security, color: crtOrange, size: 10),
                          const SizedBox(width: 4),
                          Text('CLEARANCE: DELTA-4', style: TextStyle(color: crtOrange.withOpacity(0.8), fontSize: 8, fontFamily: 'monospace', letterSpacing: 0.5)),
                          const Spacer(),
                          Text('ID: ', style: TextStyle(color: crtOrange.withOpacity(0.7), fontSize: 9, fontFamily: 'monospace')),
                          Text(
                            userId.length >= 8 ? userId.substring(0, 8).toUpperCase() : userId.toUpperCase(),
                            style: TextStyle(color: crtOrange, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace', letterSpacing: 1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Holographic corner
          Positioned(
            top: 0, right: 0,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: RadialGradient(colors: [crtOrange.withOpacity(0.4), Colors.transparent]),
                borderRadius: const BorderRadius.only(topRight: Radius.circular(8)),
              ),
            ),
          ),
          // Authorized badge
          Positioned(
            top: 8, right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: crtOrange, width: 1),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield, color: crtOrange, size: 10),
                  const SizedBox(width: 3),
                  Text('AUTHORIZED', style: TextStyle(color: crtOrange, fontSize: 7, fontFamily: 'monospace', letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
          // Barcode
          Positioned(
            bottom: 4, right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.qr_code_2, color: crtOrange.withOpacity(0.6), size: 14),
                const SizedBox(width: 4),
                CustomPaint(size: const Size(40, 10), painter: BarcodePainter(color: crtOrange)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== EDIT VIEW ====================

  Widget _buildEditView() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Sticky save/cancel bar at top
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
              border: Border(bottom: BorderSide(color: AppColors.primary.withOpacity(0.3), width: 1)),
            ),
            child: Row(
              children: [
                Icon(Icons.edit, color: AppColors.primary, size: 14),
                const SizedBox(width: 8),
                Text(
                  'MODIFYING DOSSIER',
                  style: TextStyle(color: AppColors.primary, fontFamily: 'monospace', fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                // Cancel
                GestureDetector(
                  onTap: _isSaving ? null : _discardChanges,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.textDim),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('DISCARD', style: TextStyle(color: AppColors.textMid, fontFamily: 'monospace', fontSize: 10, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(width: 8),
                // Save
                GestureDetector(
                  onTap: _isSaving ? null : _saveProfile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      border: Border.all(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: _isSaving
                        ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                        : Text('SAVE', style: TextStyle(color: AppColors.primary, fontFamily: 'monospace', fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          // Scrollable form
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                // ===== OPERATOR PROFILE =====
                _buildEditSection(
                  'OPERATOR PROFILE',
                  Icons.person,
                  AppColors.primary,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTerminalField(
                        controller: _usernameController,
                        label: 'CALLSIGN',
                        hint: 'operator_handle',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Callsign is required';
                          if (value.trim().length > 50) return 'Max 50 characters';
                          if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) return 'Letters, numbers, underscores only';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTerminalField(
                        controller: _ageController,
                        label: 'AGE',
                        hint: '18-120',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Age is required';
                          final age = int.tryParse(value);
                          if (age == null || age < 10 || age > 120) return 'Must be 10-120';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTerminalDropdown<String>(
                        label: 'GENDER',
                        value: _selectedGender,
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Male')),
                          DropdownMenuItem(value: 'female', child: Text('Female')),
                          DropdownMenuItem(value: 'other', child: Text('Other')),
                          DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefer not to say')),
                        ],
                        onChanged: (value) => setState(() => _selectedGender = value),
                        validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTerminalField(
                        controller: _bioController,
                        label: 'BIO',
                        hint: 'Resistance fighter, peptide researcher...',
                        maxLines: 3,
                        maxLength: 200,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ===== PHYSICAL METRICS =====
                _buildEditSection(
                  'PHYSICAL METRICS',
                  Icons.straighten,
                  AppColors.primary,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current height display
                      _buildReadOnlyField('CURRENT HEIGHT', _heightDisplay),
                      const SizedBox(height: 12),
                      if (_latestWeight != null)
                        _buildReadOnlyField('LATEST WEIGHT', _latestWeight!),
                      if (_latestWeight != null) const SizedBox(height: 12),
                      // Height inputs
                      _buildTerminalLabel('UPDATE HEIGHT'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTerminalField(
                              controller: _heightFeetController,
                              label: 'FEET',
                              hint: '3-7',
                              keyboardType: TextInputType.number,
                              onChanged: (_) => _updateHeightDisplay(),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Required';
                                final feet = int.tryParse(value);
                                if (feet == null || feet < 3 || feet > 7) return '3-7';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTerminalField(
                              controller: _heightInchesController,
                              label: 'INCHES',
                              hint: '0-11',
                              keyboardType: TextInputType.number,
                              onChanged: (_) => _updateHeightDisplay(),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Required';
                                final inches = int.tryParse(value);
                                if (inches == null || inches < 0 || inches > 11) return '0-11';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTerminalDropdown<String>(
                        label: 'UNITS PREFERENCE',
                        value: _selectedUnits,
                        items: const [
                          DropdownMenuItem(value: 'imperial', child: Text('Imperial (lbs, ft/in)')),
                          DropdownMenuItem(value: 'metric', child: Text('Metric (kg, cm)')),
                        ],
                        onChanged: (value) => setState(() => _selectedUnits = value!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ===== FIELD HISTORY =====
                _buildEditSection(
                  'FIELD HISTORY',
                  Icons.science,
                  AppColors.secondary,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTerminalDropdown<String>(
                        label: 'EXPERIENCE LEVEL',
                        value: _selectedExperienceLevel,
                        items: const [
                          DropdownMenuItem(value: 'beginner', child: Text('New Operator')),
                          DropdownMenuItem(value: 'intermediate', child: Text('Experienced')),
                          DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
                        ],
                        onChanged: (value) => setState(() => _selectedExperienceLevel = value!),
                      ),
                      const SizedBox(height: 16),
                      _buildTerminalDropdown<String>(
                        label: 'TRAINING LEVEL',
                        value: _selectedTrainingLevel,
                        items: const [
                          DropdownMenuItem(value: 'sedentary', child: Text('Sedentary')),
                          DropdownMenuItem(value: 'light', child: Text('Light (1-2x/week)')),
                          DropdownMenuItem(value: 'moderate', child: Text('Moderate (3-4x/week)')),
                          DropdownMenuItem(value: 'intense', child: Text('Intense (5-6x/week)')),
                          DropdownMenuItem(value: 'elite', child: Text('Elite (daily+)')),
                        ],
                        onChanged: (value) => setState(() => _selectedTrainingLevel = value),
                      ),
                      const SizedBox(height: 16),
                      _buildTerminalDropdown<String>(
                        label: 'CYCLE STATUS',
                        value: _selectedCycleStatus,
                        items: const [
                          DropdownMenuItem(value: 'not_started', child: Text('Not Started')),
                          DropdownMenuItem(value: 'on_cycle', child: Text('On Cycle')),
                          DropdownMenuItem(value: 'between_cycles', child: Text('Between Cycles')),
                          DropdownMenuItem(value: 'pct', child: Text('PCT / Recovery')),
                        ],
                        onChanged: (value) => setState(() => _selectedCycleStatus = value),
                      ),
                      const SizedBox(height: 16),
                      // Peptide history toggle
                      _buildTerminalLabel('USED PEPTIDES BEFORE'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildToggleChip('YES', _usedPeptidesBefore, () => setState(() => _usedPeptidesBefore = true)),
                          const SizedBox(width: 8),
                          _buildToggleChip('NO', !_usedPeptidesBefore, () => setState(() => _usedPeptidesBefore = false)),
                        ],
                      ),
                      if (_usedPeptidesBefore) ...[
                        const SizedBox(height: 16),
                        _buildTerminalLabel('PREVIOUS COMPOUNDS'),
                        const SizedBox(height: 8),
                        if (_previousPeptides.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _previousPeptides.map((p) => _buildChip(p, AppColors.secondary)).toList(),
                          ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _showPeptideSelectionDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, color: AppColors.secondary, size: 14),
                                const SizedBox(width: 6),
                                Text('SELECT COMPOUNDS', style: TextStyle(color: AppColors.secondary, fontFamily: 'monospace', fontSize: 10, letterSpacing: 1)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ===== DIAGNOSTIC INTEL =====
                _buildEditSection(
                  'DIAGNOSTIC INTEL',
                  Icons.biotech,
                  AppColors.amber,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTerminalDropdown<String>(
                        label: 'BLOODWORK FREQUENCY',
                        value: _selectedBloodworkFrequency,
                        items: const [
                          DropdownMenuItem(value: 'never', child: Text('Never')),
                          DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                          DropdownMenuItem(value: 'bi_annual', child: Text('Every 6 months')),
                          DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
                          DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                        ],
                        onChanged: (value) => setState(() => _selectedBloodworkFrequency = value),
                      ),
                      const SizedBox(height: 16),
                      _buildTerminalLabel('LAST LAB DATE'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _showLastLabDatePicker,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(color: AppColors.textDim),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _selectedLastLabDate ?? 'TAP TO SELECT DATE',
                            style: TextStyle(
                              color: _selectedLastLabDate != null ? AppColors.textLight : AppColors.textDim,
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTerminalField(
                        controller: _allergiesController,
                        label: 'ALLERGIES',
                        hint: 'e.g. Penicillin, shellfish...',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      _buildTerminalField(
                        controller: _medicalConditionsController,
                        label: 'MEDICAL CONDITIONS',
                        hint: 'Comma-separated: diabetes, hypertension...',
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ===== ACCOUNT =====
                _buildEditSection(
                  'ACCOUNT',
                  Icons.terminal,
                  AppColors.primary,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReadOnlyField('EMAIL', Supabase.instance.client.auth.currentUser?.email ?? 'N/A'),
                      const SizedBox(height: 16),
                      _buildTerminalDropdown<String>(
                        label: 'TIMEZONE',
                        value: _selectedTimezone,
                        items: const [
                          DropdownMenuItem(value: 'America/New_York', child: Text('Eastern Time')),
                          DropdownMenuItem(value: 'America/Chicago', child: Text('Central Time')),
                          DropdownMenuItem(value: 'America/Denver', child: Text('Mountain Time')),
                          DropdownMenuItem(value: 'America/Los_Angeles', child: Text('Pacific Time')),
                          DropdownMenuItem(value: 'America/Anchorage', child: Text('Alaska Time')),
                          DropdownMenuItem(value: 'Pacific/Honolulu', child: Text('Hawaii Time')),
                          DropdownMenuItem(value: 'Europe/London', child: Text('London')),
                          DropdownMenuItem(value: 'Europe/Paris', child: Text('Paris')),
                          DropdownMenuItem(value: 'Asia/Tokyo', child: Text('Tokyo')),
                        ],
                        onChanged: (value) => setState(() => _selectedTimezone = value),
                        validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTerminalDropdown<String>(
                        label: 'CONTACT METHOD',
                        value: _selectedContactMethod,
                        items: const [
                          DropdownMenuItem(value: 'email', child: Text('Email')),
                          DropdownMenuItem(value: 'push', child: Text('Push Notification')),
                          DropdownMenuItem(value: 'sms', child: Text('SMS')),
                        ],
                        onChanged: (value) => setState(() => _selectedContactMethod = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== REUSABLE DISPLAY WIDGETS ====================

  Widget _buildSection(String title, IconData icon, Color accentColor, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A).withOpacity(0.85),
        border: Border.all(color: accentColor.withOpacity(0.25), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                color: accentColor,
              ),
              const SizedBox(width: 8),
              Icon(icon, color: accentColor, size: 14),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildEditSection(String title, IconData icon, Color accentColor, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF050505).withOpacity(0.9),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 14, color: accentColor),
              const SizedBox(width: 8),
              Icon(icon, color: accentColor, size: 14),
              const SizedBox(width: 8),
              Text(
                '> $title',
                style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold, color: accentColor, letterSpacing: 2),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: AppColors.textDim, letterSpacing: 1),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 9, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildGoalChip(String goal) {
    final icon = _getGoalIcon(goal);
    final color = _getGoalColor(goal);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color.withOpacity(0.8), size: 12),
          const SizedBox(width: 4),
          Text(
            _capitalizeGoal(goal).toUpperCase(),
            style: TextStyle(color: color.withOpacity(0.9), fontFamily: 'monospace', fontSize: 9, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  // ==================== REUSABLE EDIT WIDGETS ====================

  Widget _buildTerminalLabel(String label) {
    return Text(
      label,
      style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: AppColors.textDim, letterSpacing: 1),
    );
  }

  Widget _buildTerminalField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTerminalLabel(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          style: TextStyle(color: AppColors.textLight, fontFamily: 'monospace', fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textDim.withOpacity(0.5), fontFamily: 'monospace', fontSize: 13),
            filled: true,
            fillColor: Colors.black,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.textDim),
              borderRadius: BorderRadius.circular(4),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.textDim.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(4),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.error),
              borderRadius: BorderRadius.circular(4),
            ),
            counterStyle: TextStyle(color: AppColors.textDim, fontFamily: 'monospace', fontSize: 10),
          ),
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTerminalDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTerminalLabel(label),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          style: TextStyle(color: AppColors.textLight, fontFamily: 'monospace', fontSize: 13),
          dropdownColor: const Color(0xFF0A0A0A),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.textDim),
              borderRadius: BorderRadius.circular(4),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.textDim.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(4),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          items: items,
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.textDim.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: AppColors.textDim, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _buildToggleChip(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
          border: Border.all(color: isActive ? AppColors.primary : AppColors.textDim, width: isActive ? 2 : 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.primary : AppColors.textDim,
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildNotifActionRow(
      String label, String value, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(value,
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Icon(icon, color: AppColors.primary, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotifDropdownRow(
    String label,
    String currentValue,
    Map<String, String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500)),
          ),
          DropdownButton<String>(
            value: currentValue,
            dropdownColor: AppColors.surface,
            style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: AppColors.primary),
            underline: const SizedBox(),
            items: options.entries
                .map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value,
                          style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: AppColors.primary)),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveToggle(String title, String subtitle, bool value, Function(bool) onChanged) {
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
                    Text(title, style: TextStyle(fontFamily: 'monospace', fontSize: 14, color: AppColors.textLight, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textMid)),
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

  Widget _buildDebugNotifButton(String label, String type) {
    return OutlinedButton(
      onPressed: () async {
        await NotificationService().showDebugNotification(type);
        if (mounted) UserFeedback.showSuccess(context, '$label sent');
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback? onTap, {bool isDanger = false, bool enabled = true}) {
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
                    Text(title, style: TextStyle(fontFamily: 'monospace', fontSize: 14, color: color, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textMid)),
                  ],
                ),
              ),
              if (enabled && onTap != null) Icon(Icons.chevron_right, color: AppColors.textDim, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontFamily: 'monospace', fontSize: 14, color: AppColors.textLight, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textMid)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBiometric(bool enabled) async {
    if (enabled) {
      // Test biometric authentication before enabling
      final authenticated = await _biometricAuth.authenticate(
        localizedReason: 'Verify your identity to enable biometric login',
      );

      if (authenticated) {
        await _biometricAuth.enableBiometric();
        setState(() {
          _biometricEnabled = true;
        });
        if (mounted) {
          UserFeedback.showSuccess(context, 'Biometric authentication enabled');
        }
      } else {
        if (mounted) {
          UserFeedback.showError(context, 'Biometric verification failed');
        }
      }
    } else {
      await _biometricAuth.disableBiometric();
      setState(() {
        _biometricEnabled = false;
      });
      if (mounted) {
        UserFeedback.showSuccess(context, 'Biometric authentication disabled');
      }
    }
  }
}

// ==================== CUSTOM PAINTERS ====================

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

class HeavyScanlinesPainter extends CustomPainter {
  final Color color;
  HeavyScanlinesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.15)
      ..strokeWidth = 2.0;
    for (double i = 0; i < size.height; i += 3) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
    final verticalPaint = Paint()
      ..color = color.withOpacity(0.05)
      ..strokeWidth = 1.0;
    for (double i = 0; i < size.width; i += 2) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), verticalPaint);
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
    double x = 0;
    final random = [2.0, 1.0, 3.0, 1.0, 2.0, 1.0, 4.0, 2.0, 1.0, 3.0, 1.0, 2.0];
    int index = 0;
    while (x < size.width && index < random.length) {
      final width = random[index % random.length];
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      x += width + 1;
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
