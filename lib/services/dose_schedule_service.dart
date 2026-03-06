import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  DoseInstance({
    required this.date,
    required this.time,
    required this.peptideName,
    required this.doseAmount,
    required this.route,
    required this.scheduleId,
    required this.cycleId,
    this.isLogged,
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
      print('Error fetching dose schedules: $e');
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
      print('[DEBUG SERVICE] Creating schedule for $peptideName');
      print('[DEBUG SERVICE] User: $userId, Cycle: $cycleId');
      print('[DEBUG SERVICE] Dose: ${doseAmount}mg, Route: $route, Time: $scheduledTime');
      print('[DEBUG SERVICE] Days: $daysOfWeek, Start: ${startDate.toString()}');
      
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
      
      print('[DEBUG SERVICE] Insert data: $data');
      
      final response = await _supabase
          .from('dose_schedules')
          .insert(data)
          .select()
          .single();

      print('[DEBUG SERVICE] Insert successful, response: $response');
      return DoseSchedule.fromJson(response);
    } catch (e, stackTrace) {
      final errorMsg = 'Supabase Error: ${e.toString()}';
      print('[ERROR SERVICE] Error creating dose schedule: $errorMsg');
      print('[ERROR SERVICE] Exception type: ${e.runtimeType}');
      print('[ERROR SERVICE] Stack trace: $stackTrace');
      
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

      for (final schedule in schedules) {
        // Skip if schedule hasn't started yet
        if (schedule.startDate.isAfter(now)) continue;

        // Generate dose instances for next 30 days
        for (int i = 0; i < daysAhead; i++) {
          final date = DateTime(now.year, now.month, now.day).add(Duration(days: i));

          // Skip if past end date
          if (schedule.endDate != null && date.isAfter(schedule.endDate!)) continue;

          // Check if this day should have a dose (0=Sunday, 1=Monday, etc.)
          final dayOfWeek = date.weekday; // 1=Monday, 7=Sunday
          final adjustedDayOfWeek = dayOfWeek == 7 ? 0 : dayOfWeek; // Convert to 0=Sunday

          if (schedule.daysOfWeek.contains(adjustedDayOfWeek)) {
            instances.add(DoseInstance(
              date: date,
              time: schedule.scheduledTime,
              peptideName: schedule.peptideName,
              doseAmount: schedule.doseAmount,
              route: schedule.route,
              scheduleId: schedule.id,
              cycleId: schedule.cycleId,
              isLogged: null, // TODO: Check dose_logs table
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
      print('Error getting upcoming doses: $e');
      return [];
    }
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
      print('Error updating dose schedule: $e');
      return null;
    }
  }

  // Skip single dose (by updating dose_logs with skip flag)
  Future<bool> skipDose(String scheduleId, DateTime date) async {
    try {
      // For now, just log it with a skip flag
      // In the future, add a dose_skips table
      print('Skipped dose for $scheduleId on $date');
      return true;
    } catch (e) {
      print('Error skipping dose: $e');
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

final currentUserIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
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
