import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// A reusable full-screen modal overlay with consistent styling.
///
/// Uses a dark backdrop (0.7 opacity) and an almost-opaque surface (0.95 opacity)
/// for readability while maintaining a slight overlay effect.
class FullScreenModal extends StatelessWidget {
  final Widget child;
  final String? title;
  final VoidCallback? onClose;

  const FullScreenModal({
    super.key,
    required this.child,
    this.title,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height - 32,
            maxWidth: MediaQuery.of(context).size.width - 32,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF000000),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppColors.amber.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null)
                _buildHeader(context),
              Flexible(
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(
          bottom: BorderSide(color: AppColors.amber.withOpacity(0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 14, color: AppColors.amber.withOpacity(0.6)),
          const SizedBox(width: 8),
          Icon(Icons.science, color: AppColors.amber, size: 13),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '> ${title!.toUpperCase()}',
              style: const TextStyle(
                color: AppColors.amber,
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            color: AppColors.textMid,
            onPressed: onClose ?? () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// Helper method to show a full-screen modal
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    VoidCallback? onClose,
  }) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => FullScreenModal(
          title: title,
          onClose: onClose,
          child: child,
        ),
      ),
    );
  }
}
