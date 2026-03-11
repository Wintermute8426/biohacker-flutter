import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/wintermute_styles.dart';
import '../../services/onboarding_service.dart';
import 'baseline_metrics_screen.dart';

class HealthGoalsScreen extends StatefulWidget {
  final OnboardingData data;

  const HealthGoalsScreen({Key? key, required this.data}) : super(key: key);

  @override
  State<HealthGoalsScreen> createState() => _HealthGoalsScreenState();
}

class _HealthGoalsScreenState extends State<HealthGoalsScreen> {
  final List<String> _selectedGoals = [];

  final List<Map<String, String>> _goals = [
    {'emoji': '💪', 'name': 'Muscle Growth', 'slug': 'muscle', 'desc': 'Build lean mass'},
    {'emoji': '🩹', 'name': 'Injury Recovery', 'slug': 'recovery', 'desc': 'Heal faster'},
    {'emoji': '🧬', 'name': 'Longevity', 'slug': 'longevity', 'desc': 'Anti-aging & healthspan'},
    {'emoji': '⚡', 'name': 'Energy & Performance', 'slug': 'energy', 'desc': 'Metabolic optimization'},
    {'emoji': '😴', 'name': 'Sleep Quality', 'slug': 'sleep', 'desc': 'Better rest & recovery'},
    {'emoji': '🛡️', 'name': 'Immune Support', 'slug': 'immune', 'desc': 'Stronger immunity'},
    {'emoji': '🧠', 'name': 'Cognitive Enhancement', 'slug': 'cognitive', 'desc': 'Mental clarity'},
    {'emoji': '🔥', 'name': 'Fat Loss', 'slug': 'fat_loss', 'desc': 'Body recomposition'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedGoals.addAll(widget.data.healthGoals);
  }

  void _continue() {
    if (_selectedGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select at least one goal',
            style: WintermmuteStyles.bodyStyle,
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    widget.data.healthGoals = _selectedGoals;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BaselineMetricsScreen(data: widget.data),
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
          'STEP 3 OF 6',
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
                  value: 3 / 6,
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
                      'What are your primary health goals?',
                      style: WintermmuteStyles.headerStyle.copyWith(
                        fontSize: 22,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Select all that apply (2-5 recommended)',
                      style: WintermmuteStyles.smallStyle.copyWith(
                        color: AppColors.textMid,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Goals grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.1,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _goals.length,
                      itemBuilder: (context, index) {
                        final goal = _goals[index];
                        return _buildGoalCard(goal);
                      },
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

  Widget _buildGoalCard(Map<String, String> goal) {
    final isSelected = _selectedGoals.contains(goal['slug']);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedGoals.remove(goal['slug']);
          } else {
            _selectedGoals.add(goal['slug']!);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              goal['emoji']!,
              style: TextStyle(fontSize: 36),
            ),
            const SizedBox(height: 8),
            Text(
              goal['name']!,
              style: WintermmuteStyles.bodyStyle.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSelected ? AppColors.primary : AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              goal['desc']!,
              style: WintermmuteStyles.tinyStyle.copyWith(
                color: AppColors.textMid,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
