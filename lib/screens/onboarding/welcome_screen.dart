import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/wintermute_styles.dart';
import 'experience_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),

              // Title with emoji
              Text(
                '🧊 WELCOME TO BIOHACKER',
                style: WintermmuteStyles.titleStyle.copyWith(
                  fontSize: 28,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Tagline
              Text(
                'Track your peptide cycles with precision.\nMonitor progress. Optimize results.',
                style: WintermmuteStyles.bodyStyle.copyWith(
                  fontSize: 16,
                  height: 1.6,
                  color: AppColors.textMid,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Info box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'This quick setup takes 3 minutes',
                          style: WintermmuteStyles.bodyStyle.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'What we\'ll cover:',
                      style: WintermmuteStyles.bodyStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...[
                      'Your experience level with peptides',
                      'Health and performance goals',
                      'Baseline metrics (weight, body composition)',
                      'Notification preferences',
                    ].map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '✓ ',
                            style: WintermmuteStyles.bodyStyle.copyWith(
                              color: AppColors.accent,
                              fontSize: 16,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item,
                              style: WintermmuteStyles.bodyStyle.copyWith(
                                color: AppColors.textLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Get Started button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExperienceScreen(),
                    ),
                  );
                },
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
                  'GET STARTED',
                  style: WintermmuteStyles.bodyStyle.copyWith(
                    color: AppColors.background,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Skip link
              TextButton(
                onPressed: () {
                  // Skip onboarding - will be handled in main flow
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                  );
                },
                child: Text(
                  'Skip for now',
                  style: WintermmuteStyles.smallStyle.copyWith(
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
    );
  }
}
