import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      print('[DEBUG SERVICE] Generating doses from schedule for $peptideName');
      
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
          
          print('[DEBUG SERVICE] Generated dose for ${date.toIso8601String()}');
        }
      }
      
      print('[DEBUG SERVICE] Generated ${generatedDoses.length} dose logs');
      return generatedDoses;
    } catch (e) {
      print('[ERROR SERVICE] Failed to generate doses: $e');
      return [];
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
    } catch (e) {
      print('[ERROR] Failed to fetch dose logs: $e');
      return [];
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
    } catch (e) {
      print('[ERROR] Failed to fetch dose logs for date: $e');
      return [];
    }
  }

  // Mark dose as MISSED
  Future<bool> markAsMissed(String doseLogId) async {
    try {
      print('[DoseLogsService] 🔵🔵🔵 === START markAsMissed() ===');
      print('[DoseLogsService] 🔵 Input doseLogId: $doseLogId');
      print('[DoseLogsService] 🔵 doseLogId type: ${doseLogId.runtimeType}');
      print('[DoseLogsService] 🔵 doseLogId length: ${doseLogId.length}');
      print('[DoseLogsService] 🔵 doseLogId isEmpty: ${doseLogId.isEmpty}');

      // Step 1: Check current user
      final currentUser = _supabase.auth.currentUser;
      print('[DoseLogsService] 👤 Current user ID: ${currentUser?.id}');
      print('[DoseLogsService] 👤 Current user email: ${currentUser?.email}');

      // Step 2: Check if dose log exists BEFORE update
      print('[DoseLogsService] 🔍 Querying dose_logs table to verify entry exists...');
      final existingRecords = await _supabase
          .from('dose_logs')
          .select()
          .eq('id', doseLogId);

      print('[DoseLogsService] 🔍 Query result: $existingRecords');
      print('[DoseLogsService] 🔍 Records found: ${existingRecords.length}');

      if (existingRecords.isEmpty) {
        print('[DoseLogsService] ❌ FATAL: No dose_log entry exists with ID: $doseLogId');
        print('[DoseLogsService] ❌ Cannot update non-existent record!');
        return false;
      }

      final existingRecord = existingRecords.first;
      print('[DoseLogsService] 📋 Existing record details:');
      print('[DoseLogsService] 📋   id: ${existingRecord['id']}');
      print('[DoseLogsService] 📋   user_id: ${existingRecord['user_id']}');
      print('[DoseLogsService] 📋   cycle_id: ${existingRecord['cycle_id']}');
      print('[DoseLogsService] 📋   status: ${existingRecord['status']}');
      print('[DoseLogsService] 📋   logged_at: ${existingRecord['logged_at']}');
      print('[DoseLogsService] 📋   dose_amount: ${existingRecord['dose_amount']}');

      // Step 3: Check if current user owns this record
      if (existingRecord['user_id'] != currentUser?.id) {
        print('[DoseLogsService] ⚠️ WARNING: User mismatch!');
        print('[DoseLogsService] ⚠️ Record user_id: ${existingRecord['user_id']}');
        print('[DoseLogsService] ⚠️ Current user_id: ${currentUser?.id}');
        print('[DoseLogsService] ⚠️ This may trigger RLS policy rejection!');
      }

      // Step 4: Attempt UPDATE
      print('[DoseLogsService] 💾 Executing UPDATE query...');
      print('[DoseLogsService] 💾 UPDATE dose_logs SET status = MISSED WHERE id = $doseLogId');

      await _supabase
          .from('dose_logs')
          .update({'status': 'MISSED'})
          .eq('id', doseLogId);

      print('[DoseLogsService] ✅ UPDATE query executed without throwing exception');
      print('[DoseLogsService] ✅✅✅ SUCCESS: Dose marked as MISSED!');
      print('[DoseLogsService] ✅ UPDATE succeeded (no exception thrown)');
      print('[DoseLogsService] ✅ Note: Empty response [] is SUCCESS for UPDATE queries');
      print('[DoseLogsService] 🔵🔵🔵 === END markAsMissed() ===');

      return true;
    } catch (e, stackTrace) {
      print('[DoseLogsService] ❌❌❌ EXCEPTION THROWN in markAsMissed()');
      print('[DoseLogsService] ❌ Error type: ${e.runtimeType}');
      print('[DoseLogsService] ❌ Error message: $e');
      print('[DoseLogsService] ❌ Full stack trace:');
      print('[DoseLogsService] ❌ $stackTrace');
      return false;
    }
  }

  // Mark dose as COMPLETED
  Future<bool> markAsCompleted(String doseLogId) async {
    try {
      await _supabase
          .from('dose_logs')
          .update({'status': 'COMPLETED'})
          .eq('id', doseLogId);
      return true;
    } catch (e) {
      print('[ERROR] Failed to mark dose as completed: $e');
      return false;
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
    } catch (e) {
      print('[ERROR] Failed to add symptoms: $e');
      return false;
    }
  }

  // Delete dose log
  Future<bool> deleteDoseLog(String logId) async {
    try {
      await _supabase.from('dose_logs').delete().eq('id', logId);
      return true;
    } catch (e) {
      print('[ERROR] Failed to delete dose log: $e');
      return false;
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
