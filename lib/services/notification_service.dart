import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Core notification service — init, permissions, schedule, cancel.
/// Singleton. Call [initialize] once at app startup.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ─── Channel IDs ────────────────────────────────────────────────────────────
  static const String _doseChannel = 'biohacker_doses';
  static const String _labChannel = 'biohacker_labs';
  static const String _milestonesChannel = 'biohacker_milestones';
  static const String _updatesChannel = 'biohacker_updates';

  // ─── Initialize ─────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundTap,
    );

    await _createAndroidChannels();
    _initialized = true;

    if (kDebugMode) print('[NotificationService] Initialized');
  }

  Future<void> _createAndroidChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    final vibrate = Int64List.fromList([0, 500, 200, 500]);

    await android.createNotificationChannel(AndroidNotificationChannel(
      _doseChannel,
      'Dose Reminders',
      description: 'Dose scheduling and missed dose alerts',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: vibrate,
    ));

    await android.createNotificationChannel(const AndroidNotificationChannel(
      _labChannel,
      'Lab Reminders',
      description: 'Bloodwork and diagnostic window reminders',
      importance: Importance.defaultImportance,
    ));

    await android.createNotificationChannel(const AndroidNotificationChannel(
      _milestonesChannel,
      'Cycle Milestones',
      description: 'Protocol start, midpoint, and completion events',
      importance: Importance.defaultImportance,
    ));

    await android.createNotificationChannel(const AndroidNotificationChannel(
      _updatesChannel,
      'Research Updates',
      description: 'New peptide intelligence and study updates',
      importance: Importance.low,
    ));
  }

  // ─── Permissions ─────────────────────────────────────────────────────────────

  Future<bool> requestPermissions() async {
    bool granted = false;

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      granted = await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      granted = await android.requestNotificationsPermission() ?? false;
      // Request exact alarm permission (Android 12+)
      await android.requestExactAlarmsPermission();
    }

    if (kDebugMode) print('[NotificationService] Permissions granted: $granted');
    return granted;
  }

  // ─── Tap Handlers ────────────────────────────────────────────────────────────

  static void _onTap(NotificationResponse res) {
    if (kDebugMode) print('[NotificationService] Tapped: ${res.payload}');
    // TODO: push to relevant screen via global navigator key
  }

  @pragma('vm:entry-point')
  static void _onBackgroundTap(NotificationResponse res) {
    if (kDebugMode) {
      print('[NotificationService] Background tap: ${res.payload}');
    }
  }

  // ─── ID Generation ───────────────────────────────────────────────────────────

  /// Deterministic notification ID from any string key (always positive).
  int _id(String key) => key.hashCode.abs() % 2147483647;

  // ─── Schedule: Dose Reminder ─────────────────────────────────────────────────

  /// Schedule a dose reminder at [doseTime]. Automatically schedules a missed
  /// dose alert 2 hours later if [scheduleMissedAlert] is true.
  Future<void> scheduleDoseReminder({
    required String cycleId,
    required String peptideName,
    required double doseAmountMg,
    required String route,
    required DateTime doseTime,
    bool scheduleMissedAlert = true,
  }) async {
    if (!_initialized) await initialize();

    final now = DateTime.now();
    if (doseTime.isBefore(now)) return;

    final dateKey = doseTime.toIso8601String().substring(0, 10);
    final doseStr = doseAmountMg < 1.0
        ? '${(doseAmountMg * 1000).toStringAsFixed(0)}mcg'
        : '${doseAmountMg.toStringAsFixed(1)}mg';
    final timeStr =
        '${doseTime.hour.toString().padLeft(2, '0')}:${doseTime.minute.toString().padLeft(2, '0')}';

    await _plugin.zonedSchedule(
      _id('dose_${cycleId}_$dateKey'),
      '⚗️ PROTOCOL ACTIVE',
      '$peptideName • $doseStr $route • $timeStr',
      tz.TZDateTime.from(doseTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _doseChannel,
          'Dose Reminders',
          channelDescription: 'Dose scheduling reminders',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(
            'Protocol Active\n$peptideName $doseStr $route\nScheduled: $timeStr\nTap to log your dose.',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          badgeNumber: 1,
          sound: 'default',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'dose_reminder:$cycleId:${doseTime.toIso8601String()}',
    );

    if (scheduleMissedAlert) {
      final alertTime = doseTime.add(const Duration(hours: 2));
      if (alertTime.isAfter(now)) {
        await _plugin.zonedSchedule(
          _id('missed_${cycleId}_$dateKey'),
          '⚠️ PROTOCOL BREACH',
          '$peptideName dose missed • Log now?',
          tz.TZDateTime.from(alertTime, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              _doseChannel,
              'Dose Reminders',
              channelDescription: 'Missed dose alerts',
              importance: Importance.max,
              priority: Priority.max,
              color: const Color(0xFFFF0040),
            ),
            iOS: const DarwinNotificationDetails(
              badgeNumber: 1,
              sound: 'default',
              interruptionLevel: InterruptionLevel.timeSensitive,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'missed_dose:$cycleId:${doseTime.toIso8601String()}',
        );
      }
    }
  }

  // ─── Schedule: Cycle Milestone ───────────────────────────────────────────────

  /// milestoneType: 'start' | 'mid' | 'pre_end' | 'end'
  Future<void> scheduleCycleMilestone({
    required String cycleId,
    required String milestoneType,
    required String peptideName,
    required int durationDays,
    required DateTime scheduledTime,
  }) async {
    if (!_initialized) await initialize();
    if (scheduledTime.isBefore(DateTime.now())) return;

    String title;
    String body;

    switch (milestoneType) {
      case 'start':
        title = '⚗️ PROTOCOL INITIATED';
        body = '$peptideName Cycle • ${durationDays}d protocol online';
        break;
      case 'mid':
        title = '📊 PROTOCOL MIDPOINT';
        body =
            '$peptideName • Day ${durationDays ~/ 2} • Consider bloodwork assessment';
        break;
      case 'pre_end':
        title = '⏱️ PROTOCOL ENDING';
        body = '$peptideName • 3 days remaining in cycle';
        break;
      case 'end':
        title = '✅ PROTOCOL COMPLETE';
        body = '$peptideName ${durationDays}d cycle finished • Log results?';
        break;
      default:
        return;
    }

    await _plugin.zonedSchedule(
      _id('milestone_${milestoneType}_$cycleId'),
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _milestonesChannel,
          'Cycle Milestones',
          channelDescription: 'Protocol milestone notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(sound: 'default'),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'milestone:$milestoneType:$cycleId',
    );
  }

  // ─── Schedule: Lab Reminder ──────────────────────────────────────────────────

  /// reminderType: 'bloodwork_due' | 'baseline_required'
  Future<void> scheduleLabReminder({
    required String userId,
    required String reminderType,
    required DateTime scheduledTime,
  }) async {
    if (!_initialized) await initialize();
    if (scheduledTime.isBefore(DateTime.now())) return;

    final monthKey = scheduledTime.toIso8601String().substring(0, 7);
    final isBaseline = reminderType == 'baseline_required';

    await _plugin.zonedSchedule(
      _id('lab_${reminderType}_$monthKey'),
      isBaseline ? '🔬 BASELINE REQUIRED' : '🔬 DIAGNOSTIC WINDOW',
      isBaseline
          ? 'Upload labs before starting your next cycle'
          : 'Bloodwork due this cycle • Schedule your diagnostic',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _labChannel,
          'Lab Reminders',
          channelDescription: 'Bloodwork and diagnostic reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(sound: 'default'),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'lab:$reminderType:$userId',
    );
  }

  // ─── Schedule: Side Effect Check-In ─────────────────────────────────────────

  Future<void> scheduleSideEffectCheckIn({
    required String cycleId,
    required String peptideName,
    required int weekNumber,
    required DateTime scheduledTime,
  }) async {
    if (!_initialized) await initialize();
    if (scheduledTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      _id('sideeffect_${cycleId}_week$weekNumber'),
      '🩺 PROTOCOL STATUS CHECK',
      '$peptideName • Week $weekNumber • Any adverse effects this week?',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _milestonesChannel,
          'Cycle Milestones',
          channelDescription: 'Weekly status check-ins',
          importance: Importance.low,
          priority: Priority.low,
        ),
        iOS: DarwinNotificationDetails(sound: 'default'),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'sideeffect:$cycleId:$weekNumber',
    );
  }

  // ─── Immediate: Test ─────────────────────────────────────────────────────────

  Future<void> showTestNotification() async {
    if (!_initialized) await initialize();

    await _plugin.show(
      0,
      '⚗️ SYSTEM TEST',
      'Biohacker notification system operational • All channels nominal',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _doseChannel,
          'Dose Reminders',
          channelDescription: 'Test notification',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(sound: 'default'),
      ),
      payload: 'test',
    );
  }

  // ─── Cancel ──────────────────────────────────────────────────────────────────

  /// Cancel the dose reminder AND missed dose alert for [cycleId] on [date].
  Future<void> cancelDoseReminder(String cycleId, DateTime date) async {
    final key = date.toIso8601String().substring(0, 10);
    await _plugin.cancel(_id('dose_${cycleId}_$key'));
    await _plugin.cancel(_id('missed_${cycleId}_$key'));
  }

  /// Cancel all milestone notifications for a cycle.
  Future<void> cancelCycleMilestones(String cycleId) async {
    for (final t in ['start', 'mid', 'pre_end', 'end']) {
      await _plugin.cancel(_id('milestone_${t}_$cycleId'));
    }
  }

  /// Cancel all weekly side-effect check-ins for a cycle.
  Future<void> cancelCycleSideEffectCheckIns(
      String cycleId, int totalWeeks) async {
    for (int w = 1; w <= totalWeeks; w++) {
      await _plugin.cancel(_id('sideeffect_${cycleId}_week$w'));
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
