import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../services/user_profile_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  
  // Form state
  String _experienceLevel = 'beginner';
  List<String> _selectedGoals = [];
  double? _weight;
  double? _bodyFat;
  String _timezone = 'America/New_York';
  bool _doseReminders = true;
  bool _labAlerts = true;
  bool _isLoading = false;

  final List<String> _goals = [
    'Muscle',
    'Recovery',
    'Longevity',
    'Metabolic',
    'Sleep',
    'Immune'
  ];

  final List<String> _timezones = [
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'Europe/London',
    'Europe/Paris',
    'Asia/Tokyo',
    'Australia/Sydney',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 6) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(userProfileServiceProvider);
      
      // Update user profile
      final profile = await service.updateUserProfile(
        userId,
        experienceLevel: _experienceLevel,
        healthGoals: _selectedGoals,
        baselineWeight: _weight,
        baselineBodyFat: _bodyFat,
        timezone: _timezone,
        onboardingCompleted: true,
      );

      if (profile == null) {
        throw Exception('Failed to save profile');
      }

      // Initialize notification preferences
      await service.initializeNotificationPreferences(userId);

      // Refresh both providers
      ref.refresh(userProfileProvider);
      ref.refresh(onboardingCompletedProvider);

      // Small delay to ensure providers update
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate back to home
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      print('Error completing onboarding: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            children: [
              _buildWelcomePage(),
              _buildExperiencePage(),
              _buildGoalsPage(),
              _buildMetricsPage(),
              _buildTimezonePage(),
              _buildNotificationsPage(),
              _buildConfirmationPage(),
            ],
          ),
          // Progress indicator
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SETUP ${_currentPage + 1}/7',
                  style: WintermmuteStyles.smallStyle.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (_currentPage + 1) / 7,
                    minHeight: 3,
                    backgroundColor: AppColors.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          // Navigation buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: AppColors.background,
              padding: const EdgeInsets.all(16).copyWith(
                bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Row(
                children: [
                  // Back button
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'BACK',
                          style: WintermmuteStyles.bodyStyle.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 12),
                  // Next/Complete button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : (_currentPage == 6 ? _completeOnboarding : _nextPage),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.background,
                                ),
                              ),
                            )
                          : Text(
                              _currentPage == 6 ? 'COMPLETE' : 'NEXT',
                              style: WintermmuteStyles.bodyStyle.copyWith(
                                color: AppColors.background,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20).copyWith(bottom: 120, top: 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '🧊 BIOHACKER',
                style: WintermmuteStyles.titleStyle.copyWith(fontSize: 36),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'Set up your biohacker profile',
                style: WintermmuteStyles.headerStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'Let\'s get to know your peptide protocol, goals, and preferences.\n\nThis takes 3 minutes.',
                style: WintermmuteStyles.bodyStyle.copyWith(
                  color: AppColors.textLight,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What we\'ll cover:',
                      style: WintermmuteStyles.headerStyle.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    ...[
                      'Your experience level with peptides',
                      'Health and performance goals',
                      'Baseline metrics (weight, labs)',
                      'Timezone and notification preferences',
                    ].map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            '✓ ',
                            style: WintermmuteStyles.bodyStyle.copyWith(
                              color: AppColors.accent,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item,
                              style: WintermmuteStyles.bodyStyle,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExperiencePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20).copyWith(bottom: 120, top: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your experience with peptides?',
            style: WintermmuteStyles.headerStyle,
          ),
          const SizedBox(height: 20),
          ...[
            ('beginner', 'Beginner', 'New to peptides, learning fundamentals'),
            ('intermediate', 'Intermediate', 'Have run several cycles, understand dosing'),
            ('advanced', 'Advanced', 'Experienced with complex stacks and protocols'),
          ].map((option) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => setState(() => _experienceLevel = option.$1),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _experienceLevel == option.$1
                      ? AppColors.primary.withOpacity(0.15)
                      : AppColors.surface,
                  border: Border.all(
                    color: _experienceLevel == option.$1
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.2),
                    width: _experienceLevel == option.$1 ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.$2,
                      style: WintermmuteStyles.bodyStyle.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.$3,
                      style: WintermmuteStyles.smallStyle.copyWith(
                        color: AppColors.textMid,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildGoalsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20).copyWith(bottom: 120, top: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your health goals?',
            style: WintermmuteStyles.headerStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'Select all that apply',
            style: WintermmuteStyles.smallStyle.copyWith(
              color: AppColors.textMid,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _goals.map((goal) {
              final isSelected = _selectedGoals.contains(goal);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedGoals.remove(goal);
                    } else {
                      _selectedGoals.add(goal);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.surface,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    goal,
                    style: WintermmuteStyles.bodyStyle.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.textLight,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          if (_selectedGoals.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Select at least one goal to continue',
                style: WintermmuteStyles.smallStyle.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20).copyWith(bottom: 120, top: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Baseline metrics',
            style: WintermmuteStyles.headerStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'Current weight & body composition',
            style: WintermmuteStyles.smallStyle.copyWith(
              color: AppColors.textMid,
            ),
          ),
          const SizedBox(height: 24),
          // Weight
          TextField(
            keyboardType: TextInputType.number,
            onChanged: (val) => setState(() => _weight = double.tryParse(val)),
            decoration: InputDecoration(
              labelText: 'Weight (lbs)',
              labelStyle: const TextStyle(color: AppColors.textMid, fontSize: 13),
              hintText: '185',
              hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            style: const TextStyle(color: AppColors.textLight, fontSize: 14),
          ),
          const SizedBox(height: 16),
          // Body Fat
          TextField(
            keyboardType: TextInputType.number,
            onChanged: (val) => setState(() => _bodyFat = double.tryParse(val)),
            decoration: InputDecoration(
              labelText: 'Body Fat % (optional)',
              labelStyle: const TextStyle(color: AppColors.textMid, fontSize: 13),
              hintText: '12.5',
              hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            style: const TextStyle(color: AppColors.textLight, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Tip: You can add baseline lab values (testosterone, IGF-1, etc.) anytime in Settings.',
              style: WintermmuteStyles.smallStyle.copyWith(
                color: AppColors.textMid,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimezonePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20).copyWith(bottom: 120, top: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your timezone',
            style: WintermmuteStyles.headerStyle,
          ),
          const SizedBox(height: 24),
          DropdownButton<String>(
            value: _timezone,
            isExpanded: true,
            dropdownColor: AppColors.surface,
            style: WintermmuteStyles.bodyStyle,
            onChanged: (val) {
              if (val != null) setState(() => _timezone = val);
            },
            items: _timezones.map((tz) {
              return DropdownMenuItem<String>(
                value: tz,
                child: Text(tz, style: WintermmuteStyles.bodyStyle),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'We use this for scheduling dose reminders and displaying times in the calendar.',
              style: WintermmuteStyles.smallStyle.copyWith(
                color: AppColors.textMid,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20).copyWith(bottom: 120, top: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification preferences',
            style: WintermmuteStyles.headerStyle,
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            value: _doseReminders,
            onChanged: (val) => setState(() => _doseReminders = val),
            title: Text(
              'Dose reminders',
              style: WintermmuteStyles.bodyStyle,
            ),
            subtitle: Text(
              '1 hour before each scheduled dose',
              style: WintermmuteStyles.smallStyle.copyWith(
                color: AppColors.textMid,
              ),
            ),
            activeColor: AppColors.primary,
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _labAlerts,
            onChanged: (val) => setState(() => _labAlerts = val),
            title: Text(
              'Lab result alerts',
              style: WintermmuteStyles.bodyStyle,
            ),
            subtitle: Text(
              'When new lab results are available',
              style: WintermmuteStyles.smallStyle.copyWith(
                color: AppColors.textMid,
              ),
            ),
            activeColor: AppColors.primary,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'You can customize these anytime in Settings.',
              style: WintermmuteStyles.smallStyle.copyWith(
                color: AppColors.textMid,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20).copyWith(bottom: 120, top: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'All set! 🚀',
            style: WintermmuteStyles.titleStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildConfirmationItem('Experience', _experienceLevel),
                const SizedBox(height: 16),
                _buildConfirmationItem(
                  'Goals',
                  _selectedGoals.join(', '),
                ),
                const SizedBox(height: 16),
                if (_weight != null)
                  _buildConfirmationItem('Weight', '${_weight!.toStringAsFixed(1)} lbs'),
                if (_weight != null) const SizedBox(height: 16),
                if (_bodyFat != null)
                  _buildConfirmationItem('Body Fat', '${_bodyFat!.toStringAsFixed(1)}%'),
                if (_bodyFat != null) const SizedBox(height: 16),
                _buildConfirmationItem('Timezone', _timezone),
                const SizedBox(height: 16),
                _buildConfirmationItem(
                  'Notifications',
                  'Dose reminders ${_doseReminders ? '✓' : '✗'}, Lab alerts ${_labAlerts ? '✓' : '✗'}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Your profile is ready. Start logging doses and we\'ll help you optimize your protocol.',
            style: WintermmuteStyles.bodyStyle.copyWith(
              color: AppColors.textMid,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: WintermmuteStyles.bodyStyle.copyWith(
            color: AppColors.textMid,
          ),
        ),
        Text(
          value,
          style: WintermmuteStyles.bodyStyle.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
