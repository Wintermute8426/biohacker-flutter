/// HIPAA compliance configuration
/// Adjust these values for testing vs production
class HipaaConfig {
  /// Session timeout duration
  /// Production: 30 minutes
  /// Testing: 2 minutes (set to const Duration(minutes: 2) for faster testing)
  static const Duration sessionTimeout = Duration(minutes: 30);
  
  /// Warning threshold before session expires
  /// Production: 28 minutes (2 minutes warning)
  /// Testing: 1.5 minutes (30 seconds warning)
  static const Duration warningThreshold = Duration(minutes: 28);
  
  /// Enable debug logging for session activity
  static const bool debugSessionTracking = false;
  
  /// HIPAA notice version (update this when privacy policy changes)
  static const String hipaaNoticeVersion = '1.0';
  static const String hipaaNoticeLastUpdated = '2026-03-26';
}
