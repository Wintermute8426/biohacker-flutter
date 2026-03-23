import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';
import 'cycles_database.dart';
import 'dose_schedule_service.dart';

/// User's notification preferences (loaded from notification_preferences table).
class NotificationPrefs {
  final bool doseRemindersEnabled;
  final String doseReminderTime; // HH:MM
  final bool cycleMilestonesEnabled;
  final bool sideEffectsEnabled;
  final bool researchUpdatesEnabled;
  final String labReminderFrequency; // 'never' | 'monthly' | 'every_3_months' | 'every_6_months'

  const NotificationPrefs({
    this.doseRemindersEnabled = true,
    this.doseReminderTime = '08:00',
    this.cycleMilestonesEnabled = true,
    this.sideEffectsEnabled = true,
    this.researchUpdatesEnabled = true,
    this.labReminderFrequency = 'every_3_months',
  });

  factory NotificationPrefs.fromJson(Map<String, dynamic> json) {
    return NotificationPrefs(
      doseRemindersEnabled: json['dose_reminders_enabled'] as bool? ?? true,
      doseReminderTime: json['dose_reminder_time'] as String? ?? '08:00',
      cycleMilestonesEnabled:
          json['cycle_milestones_enabled'] as bool? ?? true,
      sideEffectsEnabled: json['side_effects_enabled'] as bool? ?? true,
      researchUpdatesEnabled:
          json['research_updates_enabled'] as bool? ?? true,
      labReminderFrequency:
          json['lab_reminder_frequency'] as String? ?? 'every_3_months',
    );
  }

  Map<String, dynamic> toJson() => {
        'dose_reminders_enabled': doseRemindersEnabled,
        'dose_reminder_time': doseReminderTime,
        'cycle_milestones_enabled': cycleMilestonesEnabled,
        'side_effects_enabled': sideEffectsEnabled,
        'research_updates_enabled': researchUpdatesEnabled,
        'lab_reminder_frequency': labReminderFrequency,
      };

  /// How many days between lab reminders.
  int get labIntervalDays {
    switch (labReminderFrequency) {
      case 'monthly':
        return 30;
      case 'every_3_months':
        return 90;
      case 'every_6_months':
        return 180;
      default:
        return 0;
    }
  }
}

/// High-level scheduler. Reads active cycles + dose schedules from Supabase,
/// then schedules all local notifications via [NotificationService].
///
/// Call [rescheduleAll] on app start and whenever preferences change.
/// Call [onDoseLogged] immediately after a dose is marked COMPLETED.
/// Call [cancelCycleNotifications] when a cycle is deleted or ended.
class NotificationScheduler {
  static final NotificationScheduler _instance =
      NotificationScheduler._internal();
  factory NotificationScheduler() => _instance;
  NotificationScheduler._internal();

  final NotificationService _svc = NotificationService();
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── Load prefs from DB ──────────────────────────────────────────────────────

  Future<NotificationPrefs> loadPrefs(String userId) async {
    try {
      final row = await _supabase
          .from('notification_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) return const NotificationPrefs();
      return NotificationPrefs.fromJson(Map<String, dynamic>.from(row as Map));
    } catch (e) {
      if (kDebugMode) print('[NotificationScheduler] loadPrefs error: $e');
      return const NotificationPrefs();
    }
  }

  Future<void> savePrefs(String userId, NotificationPrefs prefs) async {
    try {
      final existing = await _supabase
          .from('notification_preferences')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existing == null) {
        await _supabase.from('notification_preferences').insert({
          'user_id': userId,
          ...prefs.toJson(),
        });
      } else {
        await _supabase
            .from('notification_preferences')
            .update(prefs.toJson())
            .eq('user_id', userId);
      }
    } catch (e) {
      if (kDebugMode) print('[NotificationScheduler] savePrefs error: $e');
    }
  }

  // ─── Parse reminder time ─────────────────────────────────────────────────────

  /// Returns a DateTime for [timeStr] (HH:MM) on the given [date].
  DateTime _timeOnDate(String timeStr, DateTime date) {
    final parts = timeStr.split(':');
    final h = int.tryParse(parts[0]) ?? 8;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return DateTime(date.year, date.month, date.day, h, m);
  }

  // ─── Reschedule all ──────────────────────────────────────────────────────────

  /// Cancel everything and reschedule from scratch for all active cycles.
  /// Call on app start, after login, and after changing preferences.
  Future<void> rescheduleAll() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final prefs = await loadPrefs(userId);
      await _svc.cancelAll();

      final cyclesDb = CyclesDatabase();
      final scheduleService = DoseScheduleService(_supabase);

      final cycles = await cyclesDb.getActiveCycles();
      if (kDebugMode) {
        print(
            '[NotificationScheduler] Scheduling notifications for ${cycles.length} active cycles');
      }

      for (final cycle in cycles) {
        await _scheduleCycle(
          cycle: cycle,
          prefs: prefs,
          scheduleService: scheduleService,
        );
      }

      // Lab reminders
      if (prefs.labReminderFrequency != 'never' && prefs.labIntervalDays > 0) {
        await _scheduleLabReminders(userId: userId, prefs: prefs);
      }

      if (kDebugMode) print('[NotificationScheduler] Reschedule complete');
    } catch (e) {
      if (kDebugMode) print('[NotificationScheduler] rescheduleAll error: $e');
    }
  }

  // ─── Schedule one cycle ──────────────────────────────────────────────────────

  Future<void> _scheduleCycle({
    required Cycle cycle,
    required NotificationPrefs prefs,
    required DoseScheduleService scheduleService,
  }) async {
    // Dose reminders — schedule next 14 days
    if (prefs.doseRemindersEnabled) {
      final schedules = await scheduleService.getDoseSchedules(cycle.userId);
      final cycleSchedules =
          schedules.where((s) => s.cycleId == cycle.id && s.isActive).toList();

      final now = DateTime.now();
      final window = now.add(const Duration(days: 14));

      for (final schedule in cycleSchedules) {
        for (DateTime d = now;
            d.isBefore(window) && d.isBefore(cycle.endDate);
            d = d.add(const Duration(days: 1))) {
          final dow = d.weekday % 7; // 0=Sun … 6=Sat
          if (!schedule.daysOfWeek.contains(dow)) continue;

          final timeParts = schedule.scheduledTime.split(':');
          final doseTime = DateTime(d.year, d.month, d.day,
              int.parse(timeParts[0]), int.parse(timeParts[1]));

          await _svc.scheduleDoseReminder(
            cycleId: cycle.id,
            peptideName: cycle.peptideName,
            doseAmountMg: cycle.dose,
            route: cycle.route,
            doseTime: doseTime,
          );
        }
      }
    }

    // Milestones
    if (prefs.cycleMilestonesEnabled) {
      final totalDays = cycle.durationWeeks * 7;
      final reminderTime = prefs.doseReminderTime;

      // Start (fire at 09:00 on start day)
      await _svc.scheduleCycleMilestone(
        cycleId: cycle.id,
        milestoneType: 'start',
        peptideName: cycle.peptideName,
        durationDays: totalDays,
        scheduledTime: _timeOnDate(reminderTime, cycle.startDate),
      );

      // Mid-cycle
      final midDate = cycle.startDate.add(Duration(days: totalDays ~/ 2));
      await _svc.scheduleCycleMilestone(
        cycleId: cycle.id,
        milestoneType: 'mid',
        peptideName: cycle.peptideName,
        durationDays: totalDays,
        scheduledTime: _timeOnDate(reminderTime, midDate),
      );

      // Pre-end (3 days before)
      final preEndDate =
          cycle.endDate.subtract(const Duration(days: 3));
      await _svc.scheduleCycleMilestone(
        cycleId: cycle.id,
        milestoneType: 'pre_end',
        peptideName: cycle.peptideName,
        durationDays: totalDays,
        scheduledTime: _timeOnDate(reminderTime, preEndDate),
      );

      // End
      await _svc.scheduleCycleMilestone(
        cycleId: cycle.id,
        milestoneType: 'end',
        peptideName: cycle.peptideName,
        durationDays: totalDays,
        scheduledTime: _timeOnDate(reminderTime, cycle.endDate),
      );
    }

    // Weekly side-effect check-ins (Sundays at 18:00)
    if (prefs.sideEffectsEnabled) {
      final now = DateTime.now();
      for (int week = 1; week <= cycle.durationWeeks; week++) {
        final checkDate =
            cycle.startDate.add(Duration(days: week * 7));
        if (checkDate.isBefore(now)) continue;

        final checkTime =
            DateTime(checkDate.year, checkDate.month, checkDate.day, 18, 0);

        await _svc.scheduleSideEffectCheckIn(
          cycleId: cycle.id,
          peptideName: cycle.peptideName,
          weekNumber: week,
          scheduledTime: checkTime,
        );
      }
    }
  }

  // ─── Lab reminders ───────────────────────────────────────────────────────────

  Future<void> _scheduleLabReminders({
    required String userId,
    required NotificationPrefs prefs,
  }) async {
    final intervalDays = prefs.labIntervalDays;
    if (intervalDays <= 0) return;

    // Schedule the next 2 lab reminders
    final now = DateTime.now();
    for (int i = 1; i <= 2; i++) {
      final reminderDate = now.add(Duration(days: intervalDays * i));
      final reminderTime =
          DateTime(reminderDate.year, reminderDate.month, reminderDate.day, 9, 0);

      await _svc.scheduleLabReminder(
        userId: userId,
        reminderType: 'bloodwork_due',
        scheduledTime: reminderTime,
      );
    }
  }

  // ─── Event hooks ─────────────────────────────────────────────────────────────

  /// Call after a dose is marked COMPLETED to cancel that day's reminders.
  Future<void> onDoseLogged(String cycleId, DateTime doseDate) async {
    await _svc.cancelDoseReminder(cycleId, doseDate);
    if (kDebugMode) {
      print('[NotificationScheduler] Cancelled reminders for $cycleId on $doseDate');
    }
  }

  /// Call when a cycle is deleted or manually ended.
  Future<void> cancelCycleNotifications(Cycle cycle) async {
    await _svc.cancelCycleMilestones(cycle.id);
    await _svc.cancelCycleSideEffectCheckIns(cycle.id, cycle.durationWeeks);
    // Individual dose reminders are cancelled via onDoseLogged or on reschedule
    if (kDebugMode) {
      print('[NotificationScheduler] Cancelled all notifications for cycle ${cycle.id}');
    }
  }

  /// Call after a new cycle is created — schedules that cycle immediately.
  Future<void> onCycleCreated(Cycle cycle) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final prefs = await loadPrefs(userId);
    final scheduleService = DoseScheduleService(_supabase);

    await _scheduleCycle(
      cycle: cycle,
      prefs: prefs,
      scheduleService: scheduleService,
    );
  }
}
