import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/colors.dart';
import '../../theme/wintermute_styles.dart';
import '../../services/onboarding_service.dart';
import '../../services/user_profile_service.dart';
import 'onboarding_scaffold.dart';
import 'health_goals_screen.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  final OnboardingData _data = OnboardingData();
  String _selectedLevel = 'beginner';
  late AnimationController _bootController;
  late Animation<double> _bootAnimation;

  @override
  void initState() {
    super.initState();
    _bootController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _bootAnimation = CurvedAnimation(
      parent: _bootController,
      curve: Curves.easeOut,
    );
    _bootController.forward();
  }

  @override
  void dispose() {
    _bootController.dispose();
    super.dispose();
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

  void _skip() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    try {
      final service = ref.read(onboardingServiceProvider);
      await service.skipOnboarding(userId);
      ref.invalidate(isOnboardingCompletedProvider);
      ref.invalidate(userProfileProvider);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 1,
      stepLabel: 'CLEARANCE_LEVEL',
      onNext: _continue,
      onSkip: _skip,
      nextLabel: 'PROCEED >>',
      child: AnimatedBuilder(
        animation: _bootAnimation,
        builder: (context, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // Boot sequence header
                FadeTransition(
                  opacity: _bootAnimation,
                  child: _buildBootHeader(),
                ),

                const SizedBox(height: 12),

                // Subtitle
                FadeTransition(
                  opacity: _bootAnimation,
                  child: Text(
                    'Peptide cycle tracking & optimization.\nBiomarker surveillance. Protocol management.',
                    style: WintermmuteStyles.smallStyle.copyWith(
                      color: AppColors.textMid,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 36),

                // Divider line
                Container(
                  height: 1,
                  color: AppColors.primary.withOpacity(0.15),
                ),

                const SizedBox(height: 28),

                // Section label
                Text(
                  'SELECT CLEARANCE LEVEL',
                  style: WintermmuteStyles.smallStyle.copyWith(
                    color: AppColors.amber,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'This determines your onboarding path',
                  style: WintermmuteStyles.tinyStyle.copyWith(
                    color: AppColors.textDim,
                  ),
                ),

                const SizedBox(height: 20),

                // Experience level options
                _buildLevelOption(
                  value: 'beginner',
                  tag: 'N',
                  title: 'NEW TO PEPTIDES',
                  description: 'First contact with peptide protocols. Guided path with full context.',
                  color: AppColors.accent,
                ),
                const SizedBox(height: 12),
                _buildLevelOption(
                  value: 'intermediate',
                  tag: 'E',
                  title: 'EXPERIENCED USER',
                  description: 'Prior deployment with compounds. Streamlined configuration.',
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                _buildLevelOption(
                  value: 'advanced',
                  tag: 'R',
                  title: 'ADVANCED RESEARCHER',
                  description: 'Full spectrum protocol knowledge. Unrestricted system access.',
                  color: AppColors.secondary,
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBootHeader() {
    return Column(
      children: [
        GlitchText(
          text: 'INITIALIZING PROTOCOL',
          style: WintermmuteStyles.titleStyle.copyWith(
            fontSize: 20,
            letterSpacing: 3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'SOVEREIGN HEALTH SYSTEM v2.6',
          style: WintermmuteStyles.tinyStyle.copyWith(
            color: AppColors.primary.withOpacity(0.5),
            letterSpacing: 3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLevelOption({
    required String value,
    required String tag,
    required String title,
    required String description,
    required Color color,
  }) {
    final isSelected = _selectedLevel == value;

    return OnboardingCard(
      isSelected: isSelected,
      borderColor: color,
      onTap: () => setState(() => _selectedLevel = value),
      child: Row(
        children: [
          // Tag badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
              border: Border.all(
                color: isSelected ? color : color.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Center(
              child: Text(
                tag,
                style: WintermmuteStyles.bodyStyle.copyWith(
                  color: isSelected ? color : color.withOpacity(0.5),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: WintermmuteStyles.bodyStyle.copyWith(
                    color: isSelected ? color : AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: WintermmuteStyles.tinyStyle.copyWith(
                    color: AppColors.textMid,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Icon(Icons.check, color: color, size: 20),
        ],
      ),
    );
  }
}
