import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/wintermute_styles.dart';
import '../../services/onboarding_service.dart';
import 'health_goals_screen.dart';

class ExperienceScreen extends StatefulWidget {
  final OnboardingData? data;

  const ExperienceScreen({Key? key, this.data}) : super(key: key);

  @override
  State<ExperienceScreen> createState() => _ExperienceScreenState();
}

class _ExperienceScreenState extends State<ExperienceScreen> {
  late OnboardingData _data;
  String _selectedLevel = 'beginner';

  @override
  void initState() {
    super.initState();
    _data = widget.data ?? OnboardingData();
    _selectedLevel = _data.experienceLevel;
  }

  void _continue() {
    _data.experienceLevel = _selectedLevel;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthGoalsScreen(data: _data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'STEP 2 OF 6',
          style: WintermmuteStyles.smallStyle.copyWith(
            color: AppColors.primary,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: 2 / 6,
                  minHeight: 3,
                  backgroundColor: AppColors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Question
                    Text(
                      'What\'s your experience with peptides?',
                      style: WintermmuteStyles.headerStyle.copyWith(
                        fontSize: 22,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'This helps us tailor your experience',
                      style: WintermmuteStyles.smallStyle.copyWith(
                        color: AppColors.textMid,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Options
                    _buildOption(
                      value: 'beginner',
                      emoji: '🆕',
                      title: 'Beginner',
                      description: 'First time using peptides',
                    ),

                    const SizedBox(height: 16),

                    _buildOption(
                      value: 'intermediate',
                      emoji: '💪',
                      title: 'Intermediate',
                      description: 'Used 1-3 peptides before',
                    ),

                    const SizedBox(height: 16),

                    _buildOption(
                      value: 'advanced',
                      emoji: '🔬',
                      title: 'Advanced',
                      description: 'Experienced with stacks & protocols',
                    ),
                  ],
                ),
              ),
            ),

            // Bottom button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'NEXT',
                    style: WintermmuteStyles.bodyStyle.copyWith(
                      color: AppColors.background,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required String value,
    required String emoji,
    required String title,
    required String description,
  }) {
    final isSelected = _selectedLevel == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedLevel = value),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.surface,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Text(
              emoji,
              style: TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: WintermmuteStyles.bodyStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? AppColors.primary : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: WintermmuteStyles.smallStyle.copyWith(
                      color: AppColors.textMid,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
