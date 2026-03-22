import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/wintermute_styles.dart';

class OnboardingScaffold extends StatelessWidget {
  final int currentStep;
  final String stepLabel;
  final Widget child;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final String nextLabel;
  final bool isLoading;
  final bool canProceed;

  const OnboardingScaffold({
    Key? key,
    required this.currentStep,
    required this.stepLabel,
    required this.child,
    required this.onNext,
    this.onBack,
    this.onSkip,
    this.nextLabel = 'NEXT >>',
    this.isLoading = false,
    this.canProceed = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // CRT scanlines overlay
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ScanlinesPainter(opacity: 0.04),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                _buildProgressBar(),
                Expanded(child: child),
                _buildBottomBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (onBack != null)
            GestureDetector(
              onTap: onBack,
              child: Row(
                children: [
                  Icon(Icons.chevron_left, color: AppColors.textDim, size: 18),
                  Text(
                    'BACK',
                    style: WintermmuteStyles.tinyStyle.copyWith(
                      color: AppColors.textDim,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(width: 60),
          const Spacer(),
          Text(
            '[$currentStep/6]',
            style: WintermmuteStyles.smallStyle.copyWith(
              color: AppColors.primary,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          if (onSkip != null)
            GestureDetector(
              onTap: onSkip,
              child: Text(
                'SKIP >>',
                style: WintermmuteStyles.tinyStyle.copyWith(
                  color: AppColors.textDim,
                  letterSpacing: 1.5,
                ),
              ),
            )
          else
            const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(6, (i) {
              final filled = i < currentStep;
              return Expanded(
                child: Container(
                  height: 3,
                  margin: EdgeInsets.only(right: i < 5 ? 3 : 0),
                  decoration: BoxDecoration(
                    color: filled
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.12),
                    boxShadow: filled
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 4,
                            )
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            '// $stepLabel',
            style: WintermmuteStyles.tinyStyle.copyWith(
              color: AppColors.primary.withOpacity(0.4),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withOpacity(0.12),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (canProceed && !isLoading) ? onNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.15),
              disabledForegroundColor: AppColors.background.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.background,
                    ),
                  )
                : Text(
                    nextLabel,
                    style: WintermmuteStyles.bodyStyle.copyWith(
                      color: AppColors.background,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Cyberpunk glitch text effect - colored displacement shadows
class GlitchText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final double offset;

  const GlitchText({
    Key? key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.left,
    this.offset = 1.5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Transform.translate(
          offset: Offset(offset, 0),
          child: Text(
            text,
            style: style.copyWith(
              color: AppColors.secondary.withOpacity(0.35),
            ),
            textAlign: textAlign,
          ),
        ),
        Transform.translate(
          offset: Offset(-offset, 0),
          child: Text(
            text,
            style: style.copyWith(
              color: AppColors.primary.withOpacity(0.35),
            ),
            textAlign: textAlign,
          ),
        ),
        Text(text, style: style, textAlign: textAlign),
      ],
    );
  }
}

/// Matte card container with scanlines for onboarding
class OnboardingCard extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final bool isSelected;
  final bool expand;
  final VoidCallback? onTap;

  const OnboardingCard({
    Key? key,
    required this.child,
    this.borderColor = AppColors.primary,
    this.isSelected = false,
    this.expand = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: expand ? StackFit.expand : StackFit.loose,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? borderColor.withOpacity(0.08)
                  : AppColors.surface,
              border: Border.all(
                color: isSelected
                    ? borderColor
                    : borderColor.withOpacity(0.2),
                width: isSelected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            child: child,
          ),
          // Subtle scanlines
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: CustomPaint(
                  painter: ScanlinesPainter(opacity: 0.03),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
