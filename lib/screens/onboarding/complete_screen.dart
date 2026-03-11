import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../theme/colors.dart';
import '../../theme/wintermute_styles.dart';
import '../../services/onboarding_service.dart';
import '../../services/user_profile_service.dart';
import '../cycles_screen.dart';
import '../home_screen.dart';

class CompleteScreen extends ConsumerStatefulWidget {
  final OnboardingData data;

  const CompleteScreen({Key? key, required this.data}) : super(key: key);

  @override
  ConsumerState<CompleteScreen> createState() => _CompleteScreenState();
}

class _CompleteScreenState extends ConsumerState<CompleteScreen> {
  late ConfettiController _confettiController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    // Trigger confetti after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding({bool goToCycles = true}) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User not found. Please log in again.',
            style: WintermmuteStyles.bodyStyle,
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = ref.read(onboardingServiceProvider);
      final success = await service.completeOnboarding(userId, widget.data);

      if (!success) {
        throw Exception('Failed to save onboarding data');
      }

      // Refresh providers
      ref.invalidate(userProfileProvider);
      ref.invalidate(isOnboardingCompletedProvider);

      // Wait a moment for state to update
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        // Navigate to the appropriate screen
        if (goToCycles) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
          // After navigation, open cycles screen
          Future.delayed(const Duration(milliseconds: 500), () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CyclesScreen()),
            );
          });
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print('[CompleteScreen] Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving profile: $e',
              style: WintermmuteStyles.bodyStyle,
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),

                  // Success checkmark
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accent,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        Icons.check,
                        color: AppColors.accent,
                        size: 60,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  Text(
                    '✅ ALL SET!',
                    style: WintermmuteStyles.titleStyle.copyWith(
                      fontSize: 28,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Your profile is ready.\nReady to start your first cycle?',
                    style: WintermmuteStyles.bodyStyle.copyWith(
                      fontSize: 16,
                      height: 1.6,
                      color: AppColors.textMid,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Summary box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR PROFILE',
                          style: WintermmuteStyles.smallStyle.copyWith(
                            color: AppColors.primary,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryRow(
                          'Experience',
                          widget.data.experienceLevel.toUpperCase(),
                        ),
                        const Divider(color: AppColors.border, height: 24),
                        _buildSummaryRow(
                          'Goals',
                          '${widget.data.healthGoals.length} selected',
                        ),
                        if (widget.data.baselineWeight != null) ...[
                          const Divider(color: AppColors.border, height: 24),
                          _buildSummaryRow(
                            'Baseline Weight',
                            '${widget.data.baselineWeight!.toStringAsFixed(1)} lbs',
                          ),
                        ],
                        if (widget.data.baselineBodyFat != null) ...[
                          const Divider(color: AppColors.border, height: 24),
                          _buildSummaryRow(
                            'Body Fat',
                            '${widget.data.baselineBodyFat!.toStringAsFixed(1)}%',
                          ),
                        ],
                        const Divider(color: AppColors.border, height: 24),
                        _buildSummaryRow(
                          'Notifications',
                          widget.data.doseRemindersEnabled ? 'Enabled' : 'Disabled',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Start tracking button
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _completeOnboarding(goToCycles: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      elevation: 0,
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
                            'START TRACKING',
                            style: WintermmuteStyles.bodyStyle.copyWith(
                              color: AppColors.background,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Explore first link
                  TextButton(
                    onPressed: _isLoading ? null : () => _completeOnboarding(goToCycles: false),
                    child: Text(
                      'Explore First',
                      style: WintermmuteStyles.bodyStyle.copyWith(
                        color: AppColors.textMid,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2, // Down
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
              shouldLoop: false,
              colors: const [
                AppColors.primary,
                AppColors.accent,
                AppColors.secondary,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
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
            color: AppColors.accent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
