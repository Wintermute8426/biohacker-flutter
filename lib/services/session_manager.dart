import 'dart:async';
import 'package:flutter/material.dart';
import 'secure_storage_service.dart';
import '../config/hipaa_config.dart';

/// HIPAA-compliant session timeout manager
/// Automatically logs out users after 30 minutes of inactivity
/// Shows warning dialog at 28 minutes
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final SecureStorageService _secureStorage = SecureStorageService();
  
  // Session timeout duration (configurable via HipaaConfig)
  static Duration get _sessionTimeout => HipaaConfig.sessionTimeout;
  
  // Warning threshold (configurable via HipaaConfig)
  static Duration get _warningThreshold => HipaaConfig.warningThreshold;
  
  Timer? _sessionTimer;
  Timer? _warningTimer;
  bool _isActive = false;
  DateTime? _lastActivity;
  VoidCallback? _onSessionExpired;
  BuildContext? _context;

  /// Initialize session manager with logout callback
  void initialize({
    required VoidCallback onSessionExpired,
    BuildContext? context,
  }) {
    _onSessionExpired = onSessionExpired;
    _context = context;
    _isActive = true;
    resetActivity();
  }

  /// Record user activity (tap, scroll, navigation)
  void resetActivity() {
    if (!_isActive) return;

    _lastActivity = DateTime.now();
    _secureStorage.setLastActivityTimestamp(_lastActivity!.millisecondsSinceEpoch);

    // Cancel existing timers
    _sessionTimer?.cancel();
    _warningTimer?.cancel();

    // Start warning timer (28 minutes)
    _warningTimer = Timer(_warningThreshold, _showWarningDialog);

    // Start session timeout timer (30 minutes)
    _sessionTimer = Timer(_sessionTimeout, _handleSessionTimeout);
  }

  /// Show warning dialog at 28 minutes
  void _showWarningDialog() {
    if (_context == null || !_isActive) return;

    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Session Expiring',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Your session will expire in 2 minutes due to inactivity. Any interaction will extend your session.',
          style: TextStyle(color: Color(0xFFAAAAAA)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              resetActivity(); // Extend session
            },
            child: const Text(
              'Continue Session',
              style: TextStyle(color: Color(0xFF00FFD1)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleSessionTimeout(); // Logout now
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Color(0xFFFF4444)),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle session timeout - logout user
  void _handleSessionTimeout() {
    if (!_isActive) return;

    _sessionTimer?.cancel();
    _warningTimer?.cancel();
    _isActive = false;

    // Clear secure storage
    _secureStorage.clearAll();

    // Call logout callback
    _onSessionExpired?.call();
  }

  /// Stop session tracking (on logout)
  void dispose() {
    _sessionTimer?.cancel();
    _warningTimer?.cancel();
    _isActive = false;
    _lastActivity = null;
    _context = null;
    _secureStorage.clearLastActivityTimestamp();
  }

  /// Check if session is still active
  bool get isActive => _isActive;

  /// Get time remaining before timeout
  Duration? get timeRemaining {
    if (_lastActivity == null || !_isActive) return null;
    final elapsed = DateTime.now().difference(_lastActivity!);
    final remaining = _sessionTimeout - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
