import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dose_logs_service.dart' show currentUserIdProvider;

// Models
class DoseSchedule {
  final String id;
  final String userId;
  final String cycleId;
  final String peptideName;
  final double doseAmount;
  final String route; // IM, SC, IV
  final String scheduledTime; // HH:MM format
  final List<int> daysOfWeek; // [1,3,5] for Mon/Wed/Fri
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? notes;

  DoseSchedule({
    required this.id,
    required this.userId,
    required this.cycleId,
    required this.peptideName,
    required this.doseAmount,
    required this.route,
    required this.scheduledTime,
    required this.daysOfWeek,
    required this.startDate,
    this.endDate,
    required this.isActive,
    this.notes,
  });

  factory DoseSchedule.fromJson(Map<String, dynamic> json) {
    return DoseSchedule(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      cycleId: json['cycle_id'] ?? '',
      peptideName: json['peptide_name'] ?? '',
      doseAmount: (json['dose_amount'] as num?)?.toDouble() ?? 0,
      route: json['route'] ?? 'IM',
      scheduledTime: json['scheduled_time'] ?? '08:00',
      daysOfWeek: List<int>.from(json['days_of_week'] ?? []),
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isActive: json['is_active'] ?? true,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'cycle_id': cycleId,
      'peptide_name': peptideName,
      'dose_amount': doseAmount,
      'route': route,
      'scheduled_time': scheduledTime,
      'days_of_week': daysOfWeek,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'is_active': isActive,
      'notes': notes,
    };
  }
}

class DoseInstance {
  final DateTime date;
  final String time;
  final String peptideName;
  final double doseAmount;
  final String route;
  final String scheduleId;
  final String cycleId;
  final bool? isLogged;
  final String doseLogId;
  final String status; // SCHEDULED, COMPLETED, MISSED

  DoseInstance({
    required this.date,
    required this.time,
    required this.peptideName,
    required this.doseAmount,
    required this.route,
    required this.scheduleId,
    required this.cycleId,
    this.isLogged,
    required this.doseLogId,
    required this.status,
  });
}

// Service
class DoseScheduleService {
  final SupabaseClient _supabase;

  DoseScheduleService(this._supabase);

  // Get all dose schedules for user
  Future<List<DoseSchedule>> getDoseSchedules(String userId) async {
    try {
      final response = await _supabase
          .from('dose_schedules')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true);

      return (response as List)
          .map((item) => DoseSchedule.fromJson(item))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('[DoseScheduleService] Error fetching dose schedules: $e');
      }
      return [];
    }
  }

  // Create dose schedule from cycle
  Future<DoseSchedule?> createDoseSchedule({
    required String userId,
    required String cycleId,
    required String peptideName,
    required double doseAmount,
    required String route,
    required String scheduledTime, // HH:MM
    required List<int> daysOfWeek, // [1,3,5]
    required DateTime startDate,
    DateTime? endDate,
    String? notes,
  }) async {
    try {
      if (kDebugMode) {
        print('[DoseScheduleService] Creating schedule for $peptideName');
      }

      final data = {
        'user_id': userId,
        'cycle_id': cycleId,
        'peptide_name': peptideName,
        'dose_amount': doseAmount,
        'route': route,
        'scheduled_time': scheduledTime,
        'days_of_week': daysOfWeek,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate?.toIso8601String().split('T')[0],
        'is_active': true,
        'notes': notes,
      };

      final response = await _supabase
          .from('dose_schedules')
          .insert(data)
          .select()
          .single();

      if (kDebugMode) {
        print('[DoseScheduleService] Schedule created successfully');
      }
      return DoseSchedule.fromJson(response);
    } catch (e, stackTrace) {
      final errorMsg = 'Supabase Error: ${e.toString()}';
      if (kDebugMode) {
        print('[DoseScheduleService] Error creating dose schedule: $errorMsg');
      }
      if (kDebugMode) {
        print('[DoseScheduleService] Exception type: ${e.runtimeType}');
        if (kDebugMode) {
          print('[DoseScheduleService] Stack trace: $stackTrace');
        }
      }

      // Throw the error so caller can see it
      throw Exception(errorMsg);
    }
  }

  // Get dose instances for next 30 days
  Future<List<DoseInstance>> getUpcomingDoses(
    String userId, {
    int daysAhead = 30,
  }) async {
    try {
      final schedules = await getDoseSchedules(userId);
      final instances = <DoseInstance>[];
      final now = DateTime.now();

      // Fetch all dose_logs for the past 30 days AND next 30 days (to show missed doses)
      final startDate = now.subtract(Duration(days: 30));
      final endDate = now.add(Duration(days: daysAhead));

      final doseLogs = await _supabase
          .from('dose_logs')
          .select()
          .eq('user_id', userId)
          .gte('logged_at', startDate.toIso8601String())
          .lte('logged_at', endDate.toIso8601String());

      // Create a map of dose_logs by cycle_id + logged_at date for quick lookup
      final doseLogMap = <String, Map<String, dynamic>>{};

      for (final log in doseLogs as List) {
        final cycleId = log['cycle_id'] as String? ?? '';
        final loggedAt = DateTime.parse(log['logged_at'] as String);
        final logDateKey = '${cycleId}_${loggedAt.year}-${loggedAt.month.toString().padLeft(2, '0')}-${loggedAt.day.toString().padLeft(2, '0')}';
        doseLogMap[logDateKey] = log as Map<String, dynamic>;
      }

      for (final schedule in schedules) {
        // Generate dose instances for past 30 days + next 30 days (60 days total)
        // Start from 30 days ago to capture missed doses
        for (int i = -30; i < daysAhead; i++) {
          final date = DateTime(now.year, now.month, now.day).add(Duration(days: i));

          // Skip if before schedule start date
          if (date.isBefore(schedule.startDate)) continue;

          // Skip if past end date
          if (schedule.endDate != null && date.isAfter(schedule.endDate!)) continue;

          // Check if this day should have a dose (0=Sunday, 1=Monday, etc.)
          final dayOfWeek = date.weekday; // 1=Monday, 7=Sunday
          final adjustedDayOfWeek = dayOfWeek == 7 ? 0 : dayOfWeek; // Convert to 0=Sunday

          if (schedule.daysOfWeek.contains(adjustedDayOfWeek)) {
            // Look up dose_log for this cycle + date (use cycleId not scheduleId)
            final logDateKey = '${schedule.cycleId}_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            final doseLog = doseLogMap[logDateKey];

            final doseLogId = doseLog?['id'] as String? ?? '';
            final status = doseLog?['status'] as String? ?? 'SCHEDULED';

            // Use dose_log's dose_amount if available (varies by phase), otherwise use schedule default
            final doseAmount = (doseLog?['dose_amount'] as num?)?.toDouble() ?? schedule.doseAmount;

            instances.add(DoseInstance(
              date: date,
              time: schedule.scheduledTime,
              peptideName: schedule.peptideName,
              doseAmount: doseAmount,
              route: schedule.route,
              scheduleId: schedule.id,
              cycleId: schedule.cycleId,
              isLogged: status != 'SCHEDULED',
              doseLogId: doseLogId,
              status: status,
            ));
          }
        }
      }

      // Sort by date + time
      instances.sort((a, b) {
        final aDateTime = DateTime(a.date.year, a.date.month, a.date.day);
        final bDateTime = DateTime(b.date.year, b.date.month, b.date.day);
        if (aDateTime != bDateTime) return aDateTime.compareTo(bDateTime);
        return a.time.compareTo(b.time);
      });

      return instances;
    } catch (e) {
      if (kDebugMode) {
        print('[DoseScheduleService] Error getting upcoming doses: $e');
      }
      return [];
    }
  }

  // ===== BUILD #280: OPTIMIZED WEEK-BASED QUERIES =====
  
  // Get doses for a specific week (7-day range)
  // Much faster than getUpcomingDoses for single week view
  Future<List<DoseInstance>> getWeekDoses(
    String userId, {
    DateTime? weekStart,
    String? cycleId,
  }) async {
    try {
      final start = weekStart ?? _getWeekStart(DateTime.now());
      final end = start.add(const Duration(days: 7));

      // Fetch dose_logs for the week (indexed query, should be <100ms)
      var query = _supabase
          .from('dose_logs')
          .select()
          .eq('user_id', userId)
          .gte('logged_at', start.toIso8601String())
          .lt('logged_at', end.toIso8601String());

      if (cycleId != null && cycleId.isNotEmpty) {
        query = query.eq('cycle_id', cycleId);
      }

      final doseLogs = await query.order('logged_at', ascending: true);

      // Build map for quick lookup
      final doseLogMap = <String, Map<String, dynamic>>{};
      for (final log in doseLogs as List) {
        final cycleIdKey = log['cycle_id'] as String? ?? '';
        final loggedAt = DateTime.parse(log['logged_at'] as String);
        final logDateKey = '${cycleIdKey}_${loggedAt.year}-${loggedAt.month.toString().padLeft(2, '0')}-${loggedAt.day.toString().padLeft(2, '0')}';
        doseLogMap[logDateKey] = log as Map<String, dynamic>;
      }

      // Get all schedules for user (needed for frequency info)
      final schedules = await getDoseSchedules(userId);
      final instances = <DoseInstance>[];

      // Generate instances for each schedule, day, and frequency
      for (final schedule in schedules) {
        if (cycleId != null && schedule.cycleId != cycleId) continue;
        if (schedule.endDate != null && start.isAfter(schedule.endDate!)) continue;

        for (int i = 0; i < 7; i++) {
          final date = start.add(Duration(days: i));

          // Check if this day matches frequency
          final dayOfWeek = date.weekday;
          final adjustedDayOfWeek = dayOfWeek == 7 ? 0 : dayOfWeek;

          if (schedule.daysOfWeek.contains(adjustedDayOfWeek)) {
            // Look up the actual dose from dose_logs
            final logDateKey = '${schedule.cycleId}_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            final doseLog = doseLogMap[logDateKey];

            final doseLogId = doseLog?['id'] as String? ?? '';
            final status = doseLog?['status'] as String? ?? 'SCHEDULED';
            final doseAmount = (doseLog?['dose_amount'] as num?)?.toDouble() ?? schedule.doseAmount;

            instances.add(DoseInstance(
              date: date,
              time: schedule.scheduledTime,
              peptideName: schedule.peptideName,
              doseAmount: doseAmount,
              route: schedule.route,
              scheduleId: schedule.id,
              cycleId: schedule.cycleId,
              isLogged: status != 'SCHEDULED',
              doseLogId: doseLogId,
              status: status,
            ));
          }
        }
      }

      // Sort by date + time
      instances.sort((a, b) {
        final aDateTime = DateTime(a.date.year, a.date.month, a.date.day);
        final bDateTime = DateTime(b.date.year, b.date.month, b.date.day);
        if (aDateTime != bDateTime) return aDateTime.compareTo(bDateTime);
        return a.time.compareTo(b.time);
      });

      return instances;
    } catch (e) {
      if (kDebugMode) {
        print('[DoseScheduleService] Error getting week doses: $e');
      }
      return [];
    }
  }

  // Helper: Get Monday of week
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: weekday - 1));
  }

  // Update dose schedule
  Future<DoseSchedule?> updateDoseSchedule(
    String scheduleId, {
    String? scheduledTime,
    List<int>? daysOfWeek,
    bool? isActive,
    String? notes,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (scheduledTime != null) updates['scheduled_time'] = scheduledTime;
      if (daysOfWeek != null) updates['days_of_week'] = daysOfWeek;
      if (isActive != null) updates['is_active'] = isActive;
      if (notes != null) updates['notes'] = notes;

      final response = await _supabase
          .from('dose_schedules')
          .update(updates)
          .eq('id', scheduleId)
          .select()
          .single();

      return DoseSchedule.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('[DoseScheduleService] Error updating dose schedule: $e');
      }
      return null;
    }
  }

  // Skip single dose (by updating dose_logs with skip flag)
  Future<bool> skipDose(String scheduleId, DateTime date) async {
    try {
      // For now, just log it with a skip flag
      // In the future, add a dose_skips table
      if (kDebugMode) {
        print('[DoseScheduleService] Skipped dose for $scheduleId on $date');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[DoseScheduleService] Error skipping dose: $e');
      }
      return false;
    }
  }
}

// Riverpod Providers
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final doseScheduleServiceProvider = Provider<DoseScheduleService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return DoseScheduleService(supabase);
});

final upcomingDosesProvider = FutureProvider<List<DoseInstance>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final service = ref.watch(doseScheduleServiceProvider);
  return service.getUpcomingDoses(userId, daysAhead: 30);
});

final doseSchedulesProvider = FutureProvider<List<DoseSchedule>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final service = ref.watch(doseScheduleServiceProvider);
  return service.getDoseSchedules(userId);
});
