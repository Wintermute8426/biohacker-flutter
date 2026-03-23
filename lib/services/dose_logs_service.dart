import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_scheduler.dart';

class DoseLog {
  final String id;
  final String userId;
  final String cycleId;
  final String? scheduleId;
  final double doseAmount;
  final String route;
  final String? injectionSite;
  final DateTime loggedAt;
  final String? notes;
  final String status; // SCHEDULED, COMPLETED, MISSED
  final Map<String, dynamic>? symptoms;
  final DateTime createdAt;

  DoseLog({
    required this.id,
    required this.userId,
    required this.cycleId,
    this.scheduleId,
    required this.doseAmount,
    required this.route,
    this.injectionSite,
    required this.loggedAt,
    this.notes,
    required this.status,
    this.symptoms,
    required this.createdAt,
  });

  factory DoseLog.fromJson(Map<String, dynamic> json) {
    return DoseLog(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      cycleId: json['cycle_id'] ?? '',
      scheduleId: json['schedule_id'] as String?,
      doseAmount: (json['dose_amount'] as num?)?.toDouble() ?? 0,
      route: json['route'] ?? '',
      injectionSite: json['injection_site'],
      loggedAt: DateTime.parse(json['logged_at']),
      notes: json['notes'],
      status: json['status'] ?? 'SCHEDULED',
      symptoms: json['symptoms'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'cycle_id': cycleId,
      'schedule_id': scheduleId,
      'dose_amount': doseAmount,
      'route': route,
      'injection_site': injectionSite,
      'logged_at': loggedAt.toIso8601String(),
      'notes': notes,
      'status': status,
      'symptoms': symptoms,
    };
  }
}

class DoseLogsService {
  final SupabaseClient _supabase;

  DoseLogsService(this._supabase);

  // Auto-generate SCHEDULED dose logs from a dose schedule
  Future<List<DoseLog>> generateDosesFromSchedule({
    required String userId,
    required String cycleId,
    required String scheduleId,
    required String peptideName,
    required double doseAmount,
    required String route,
    required String scheduledTime,
    required List<int> daysOfWeek,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    try {
      if (kDebugMode) {
        print('[DoseLogsService] Generating doses from schedule for $peptideName');
      }

      final generatedDoses = <DoseLog>[];
      final end = endDate ?? startDate.add(const Duration(days: 365));

      // Generate dose_logs for each scheduled day
      for (DateTime date = startDate; date.isBefore(end); date = date.add(const Duration(days: 1))) {
        final dayOfWeek = date.weekday % 7; // 0 = Sunday

        if (daysOfWeek.contains(dayOfWeek)) {
          // Parse time (HH:MM format)
          final timeParts = scheduledTime.split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);

          final loggedAt = DateTime(date.year, date.month, date.day, hour, minute);

          // Create dose_logs entry with SCHEDULED status
          final data = {
            'user_id': userId,
            'cycle_id': cycleId,
            'dose_amount': doseAmount,
            'logged_at': loggedAt.toIso8601String(),
          };

          if (scheduleId.isNotEmpty) data['schedule_id'] = scheduleId;

          final response = await _supabase.from('dose_logs').insert(data).select().single();
          generatedDoses.add(DoseLog.fromJson(response as Map<String, dynamic>));
        }
      }

      if (kDebugMode) {
        print('[DoseLogsService] Generated ${generatedDoses.length} dose logs');
      }
      return generatedDoses;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[DoseLogsService] Failed to generate doses: $e');
        print('[DoseLogsService] Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  // Get all dose logs for cycle
  Future<List<DoseLog>> getCycleDoseLogs(String userId, String cycleId) async {
    try {
      final response = await _supabase
          .from('dose_logs')
          .select()
          .eq('user_id', userId)
          .eq('cycle_id', cycleId)
          .order('logged_at', ascending: false);

      return (response as List)
          .map((item) => DoseLog.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[DoseLogsService] Failed to fetch dose logs: $e');
        print('[DoseLogsService] Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  // Get dose logs for specific date
  Future<List<DoseLog>> getDoseLogsForDate(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final response = await _supabase
          .from('dose_logs')
          .select()
          .eq('user_id', userId)
          .gte('logged_at', startOfDay.toIso8601String())
          .lte('logged_at', endOfDay.toIso8601String())
          .order('logged_at', ascending: false);

      return (response as List)
          .map((item) => DoseLog.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[DoseLogsService] Failed to fetch dose logs for date: $e');
        print('[DoseLogsService] Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  // Mark dose as MISSED
  Future<bool> markAsMissed(String doseLogId) async {
    try {
      if (kDebugMode) {
        print('[DoseLogsService] markAsMissed() called for ID: $doseLogId');
      }

      // Validate input
      if (doseLogId.isEmpty) {
        if (kDebugMode) print('[DoseLogsService] ERROR: Empty doseLogId');
        return false;
      }

      // Check if dose log exists before update
      final existingRecords = await _supabase
          .from('dose_logs')
          .select()
          .eq('id', doseLogId);

      if (existingRecords.isEmpty) {
        if (kDebugMode) {
          print('[DoseLogsService] ERROR: Dose log $doseLogId not found');
        }
        return false;
      }

      if (kDebugMode) {
        final record = existingRecords.first;
        print('[DoseLogsService] Marking dose as MISSED: ${record['cycle_id']}, ${record['logged_at']}');
      }

      // Perform UPDATE
      await _supabase
          .from('dose_logs')
          .update({'status': 'MISSED'})
          .eq('id', doseLogId);

      if (kDebugMode) {
        print('[DoseLogsService] SUCCESS: Dose marked as MISSED');
      }

      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[DoseLogsService] ERROR in markAsMissed(): $e');
        print('[DoseLogsService] Stack trace: $stackTrace');
      }
      return false;
    }
  }

  // Mark dose as COMPLETED
  Future<bool> markAsCompleted(String doseLogId) async {
    try {
      final rows = await _supabase
          .from('dose_logs')
          .select('cycle_id, logged_at')
          .eq('id', doseLogId);

      await _supabase
          .from('dose_logs')
          .update({'status': 'COMPLETED'})
          .eq('id', doseLogId);

      // Cancel that day's dose reminder + missed dose alert
      if (rows.isNotEmpty) {
        final row = Map<String, dynamic>.from(rows.first as Map);
        final cycleId = row['cycle_id'] as String? ?? '';
        final loggedAt = DateTime.tryParse(row['logged_at'] as String? ?? '');
        if (cycleId.isNotEmpty && loggedAt != null) {
          await NotificationScheduler().onDoseLogged(cycleId, loggedAt);
        }
      }

      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[DoseLogsService] Failed to mark dose as completed: $e');
        print('[DoseLogsService] Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  // Add symptoms to dose
  Future<bool> addSymptoms(String doseLogId, Map<String, dynamic> symptoms) async {
    try {
      await _supabase
          .from('dose_logs')
          .update({'symptoms': symptoms})
          .eq('id', doseLogId);
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[DoseLogsService] Failed to add symptoms: $e');
        print('[DoseLogsService] Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  // Delete dose log
  Future<bool> deleteDoseLog(String logId) async {
    try {
      await _supabase.from('dose_logs').delete().eq('id', logId);
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[DoseLogsService] Failed to delete dose log: $e');
        print('[DoseLogsService] Stack trace: $stackTrace');
      }
      rethrow;
    }
  }
}

// Riverpod providers
final doseLogsServiceProvider = Provider((ref) {
  return DoseLogsService(Supabase.instance.client);
});

final currentUserIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

final cycleDoseLogsProvider =
    FutureProvider.family<List<DoseLog>, String>((ref, cycleId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final service = ref.watch(doseLogsServiceProvider);
  return service.getCycleDoseLogs(userId, cycleId);
});
