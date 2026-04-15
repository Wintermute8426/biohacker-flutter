import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';

/// Centralized user feedback utilities for consistent messaging across the app
class UserFeedback {
  /// Show success snackbar with green accent color
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.background),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: WintermmuteStyles.bodyStyle.copyWith(
                  color: AppColors.background,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.accent, // Green success color
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show error snackbar with red error color
  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: AppColors.textLight),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: WintermmuteStyles.bodyStyle.copyWith(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error, // Red error color
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show warning snackbar with orange color
  static void showWarning(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: AppColors.background),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: WintermmuteStyles.bodyStyle.copyWith(
                  color: AppColors.background,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFF6B00), // Orange warning color
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show info snackbar with cyan primary color
  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.background),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: WintermmuteStyles.bodyStyle.copyWith(
                  color: AppColors.background,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary, // Cyan info color
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show confirmation dialog for destructive actions
  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'CONFIRM',
    String cancelText = 'CANCEL',
    bool isDangerous = false,
  }) async {
    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDangerous ? AppColors.error : AppColors.primary,
            width: 2,
          ),
        ),
        title: Row(
          children: [
            Icon(
              isDangerous ? Icons.warning_amber : Icons.help_outline,
              color: isDangerous ? AppColors.error : AppColors.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                title,
                style: WintermmuteStyles.titleStyle.copyWith(
                  color: isDangerous ? AppColors.error : AppColors.primary,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: WintermmuteStyles.bodyStyle.copyWith(
            color: AppColors.textLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              cancelText,
              style: WintermmuteStyles.bodyStyle.copyWith(
                color: AppColors.textMid,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDangerous ? AppColors.error : AppColors.primary,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              confirmText,
              style: WintermmuteStyles.bodyStyle.copyWith(
                color: AppColors.background,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Convert technical error messages to user-friendly messages
  static String getFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    final rawError = error.toString();

    // Supabase/Postgrest errors — surface the real message, don't hide it
    // These show as: PostgrestException(message: ..., code: ..., details: ..., hint: ...)
    if (rawError.contains('PostgrestException') || rawError.contains('postgrest')) {
      // Extract the message field from the exception string if possible
      final msgMatch = RegExp(r'message:\s*([^,)]+)').firstMatch(rawError);
      final codeMatch = RegExp(r'code:\s*(\w+)').firstMatch(rawError);
      final code = codeMatch?.group(1) ?? '';
      final msg = msgMatch?.group(1)?.trim() ?? rawError;
      if (code == '42501' || errorString.contains('row-level security') || errorString.contains('rls')) {
        return 'Permission denied — please log out and log back in';
      }
      return 'Database error: $msg';
    }

    // Network errors
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('failed host lookup')) {
      return 'Network error - check your connection';
    }

    // Auth errors
    if (errorString.contains('invalid login credentials') ||
        errorString.contains('invalid email or password')) {
      return 'Invalid email or password';
    }
    if (errorString.contains('email not confirmed')) {
      return 'Please verify your email address';
    }
    if (errorString.contains('user already registered') ||
        errorString.contains('duplicate') ||
        errorString.contains('already exists')) {
      return 'Email already in use';
    }
    if (errorString.contains('weak password')) {
      return 'Password is too weak - use at least 8 characters';
    }
    if (errorString.contains('invalid email')) {
      return 'Invalid email address format';
    }
    if (errorString.contains('unauthorized') ||
        errorString.contains('not authenticated')) {
      return 'Please log in again';
    }

    // Validation errors
    if (errorString.contains('required') || errorString.contains('cannot be empty')) {
      return 'Please fill in all required fields';
    }
    if (errorString.contains('invalid format')) {
      return 'Invalid format - please check your input';
    }
    if (errorString.contains('out of range')) {
      return 'Value is out of acceptable range';
    }

    // Database errors
    if (errorString.contains('not found') || errorString.contains('does not exist')) {
      return 'Data not found - try refreshing';
    }
    if (errorString.contains('constraint') || errorString.contains('unique')) {
      return 'This entry already exists';
    }
    if (errorString.contains('foreign key')) {
      return 'Cannot complete - related data missing';
    }

    // Permission errors
    if (errorString.contains('permission') || errorString.contains('forbidden')) {
      return 'You don\'t have permission for this action';
    }

    // File/storage errors
    if (errorString.contains('storage') || errorString.contains('upload')) {
      return 'File upload failed - try again';
    }
    if (errorString.contains('file too large')) {
      return 'File is too large - max 10MB';
    }

    // Generic fallback
    if (errorString.contains('exception') || errorString.contains('error')) {
      return 'Something went wrong - please try again';
    }

    // If we can't identify the error, return a generic message
    return 'An unexpected error occurred';
  }

  /// Show loading indicator dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: AppColors.primary,
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message,
                  style: WintermmuteStyles.bodyStyle,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Dismiss loading dialog
  static void dismissLoadingDialog(BuildContext context) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
