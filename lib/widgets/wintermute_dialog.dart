import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';

class WintermmuteDialog extends StatelessWidget {
  final String title;
  final String content;
  final List<WintermmuteDialogAction> actions;
  final bool barrierDismissible;

  const WintermmuteDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.actions,
    this.barrierDismissible = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(
            color: AppColors.primary.withOpacity(0.4),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.primary.withOpacity(0.2),
                  ),
                ),
              ),
              child: Text(
                title,
                style: WintermmuteStyles.headerStyle.copyWith(
                  color: AppColors.primary,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                content,
                style: WintermmuteStyles.bodyStyle.copyWith(
                  color: AppColors.textMid,
                  height: 1.5,
                ),
              ),
            ),
            
            // Action buttons
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (int i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(actions[i], context),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(WintermmuteDialogAction action, BuildContext context) {
    final isPrimary = action.isPrimary;
    
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        action.onPressed();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isPrimary ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(4),
          color: isPrimary ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            action.label,
            style: WintermmuteStyles.bodyStyle.copyWith(
              color: isPrimary ? AppColors.primary : AppColors.textMid,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class WintermmuteDialogAction {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  WintermmuteDialogAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });
}
