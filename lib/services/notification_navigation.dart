/// Singleton that holds pending navigation state from notification taps.
/// HomeScreen reads this on mount and app resume.
class NotificationNavigation {
  NotificationNavigation._();

  static String? pendingType;
  static Map<String, dynamic>? pendingData;

  /// Tab indices for HomeScreen
  static const int tabDashboard = 0;
  static const int tabCycles = 1;
  static const int tabLabs = 2;
  static const int tabReports = 3;
  static const int tabCalendar = 4;

  /// Returns the target tab index for a notification type, or null for non-tab destinations.
  static int? tabForType(String type) {
    switch (type) {
      case 'dose_reminder':
      case 'missed_dose':
        return tabCalendar;
      case 'milestone':
      case 'sideeffect':
        return tabCycles;
      case 'lab':
        return tabLabs;
      case 'hrv_checkin':
        return tabDashboard;
      case 'research_update':
        return null; // Push separate screen
      default:
        return tabDashboard;
    }
  }

  /// Returns true if this notification type should push a separate screen.
  static bool pushesScreen(String type) => type == 'research_update';

  /// Consume pending navigation state (returns and clears it).
  static ({String? type, Map<String, dynamic>? data}) consume() {
    final t = pendingType;
    final d = pendingData;
    pendingType = null;
    pendingData = null;
    return (type: t, data: d);
  }
}
