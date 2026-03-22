import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/wintermute_styles.dart';
import '../../services/onboarding_service.dart';
import 'onboarding_scaffold.dart';
import 'current_status_screen.dart';

class HealthGoalsScreen extends StatefulWidget {
  final OnboardingData data;

  const HealthGoalsScreen({Key? key, required this.data}) : super(key: key);

  @override
  State<HealthGoalsScreen> createState() => _HealthGoalsScreenState();
}

class _HealthGoalsScreenState extends State<HealthGoalsScreen> {
  final List<String> _selectedGoals = [];

  static const List<Map<String, dynamic>> _goals = [
    {
      'icon': Icons.fitness_center,
      'name': 'MUSCLE GROWTH & RECOVERY',
      'slug': 'muscle',
      'desc': 'Lean mass synthesis',
      'color': AppColors.primary,
    },
    {
      'icon': Icons.local_fire_department,
      'name': 'FAT LOSS & METABOLISM',
      'slug': 'fat_loss',
      'desc': 'Metabolic optimization',
      'color': AppColors.amber,
    },
    {
      'icon': Icons.auto_awesome,
      'name': 'LONGEVITY & ANTI-AGING',
      'slug': 'longevity',
      'desc': 'Healthspan extension',
      'color': AppColors.accent,
    },
    {
      'icon': Icons.healing,
      'name': 'INJURY & TISSUE REPAIR',
      'slug': 'recovery',
      'desc': 'Accelerated healing',
      'color': AppColors.secondary,
    },
    {
      'icon': Icons.psychology,
      'name': 'COGNITIVE ENHANCEMENT',
      'slug': 'cognitive',
      'desc': 'Neural optimization',
      'color': AppColors.primary,
    },
    {
      'icon': Icons.speed,
      'name': 'ATHLETIC PERFORMANCE',
      'slug': 'performance',
      'desc': 'Peak output protocols',
      'color': AppColors.amber,
    },
    {
      'icon': Icons.nightlight_round,
      'name': 'SLEEP OPTIMIZATION',
      'slug': 'sleep',
      'desc': 'Recovery architecture',
      'color': AppColors.secondary,
    },
    {
      'icon': Icons.shield,
      'name': 'IMMUNE SUPPORT',
      'slug': 'immune',
      'desc': 'Defense systems',
      'color': AppColors.accent,
    },
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
            'SELECT AT LEAST ONE OPTIMIZATION VECTOR',
            style: WintermmuteStyles.smallStyle.copyWith(color: AppColors.background),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    widget.data.healthGoals = List.from(_selectedGoals);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CurrentStatusScreen(data: widget.data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 2,
      stepLabel: 'OPTIMIZATION_VECTORS',
      onNext: _continue,
      onBack: () => Navigator.pop(context),
      canProceed: _selectedGoals.isNotEmpty,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            GlitchText(
              text: 'TARGET ACQUISITION',
              style: WintermmuteStyles.headerStyle.copyWith(
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Select all optimization vectors // multi-select enabled',
              style: WintermmuteStyles.tinyStyle.copyWith(
                color: AppColors.textDim,
              ),
            ),

            const SizedBox(height: 8),

            // Selection count
            Text(
              '[${_selectedGoals.length}] SELECTED',
              style: WintermmuteStyles.tinyStyle.copyWith(
                color: _selectedGoals.isNotEmpty
                    ? AppColors.accent
                    : AppColors.textDim,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            // Goals grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _goals.length,
              itemBuilder: (context, index) {
                final goal = _goals[index];
                return _buildGoalCard(goal);
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final isSelected = _selectedGoals.contains(goal['slug']);
    final Color color = goal['color'] as Color;

    return OnboardingCard(
      isSelected: isSelected,
      expand: true,
      borderColor: color,
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedGoals.remove(goal['slug']);
          } else {
            _selectedGoals.add(goal['slug'] as String);
          }
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            goal['icon'] as IconData,
            color: isSelected ? color : color.withOpacity(0.5),
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            goal['name'] as String,
            style: WintermmuteStyles.tinyStyle.copyWith(
              color: isSelected ? color : AppColors.textLight,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            goal['desc'] as String,
            style: WintermmuteStyles.tinyStyle.copyWith(
              color: AppColors.textDim,
              fontSize: 8,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
