import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DoseLog {
  final String id;
  final String userId;
  final String cycleId;
  final String? scheduleId;
  final String peptideName;
  final double doseAmount;
  final String route;
  final String? injectionSite;
  final DateTime loggedAt;
  final String? notes;
  final DateTime createdAt;

  DoseLog({
    required this.id,
    required this.userId,
    required this.cycleId,
    this.scheduleId,
    required this.peptideName,
    required this.doseAmount,
    required this.route,
    this.injectionSite,
    required this.loggedAt,
    this.notes,
    required this.createdAt,
  });

  factory DoseLog.fromJson(Map<String, dynamic> json) {
    return DoseLog(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      cycleId: json['cycle_id'] ?? '',
      scheduleId: json['schedule_id'],
      peptideName: json['peptide_name'] ?? '',
      doseAmount: (json['dose_amount'] as num?)?.toDouble() ?? 0,
      route: json['route'] ?? '',
      injectionSite: json['injection_site'],
      loggedAt: DateTime.parse(json['logged_at']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'cycle_id': cycleId,
      'schedule_id': scheduleId,
      'peptide_name': peptideName,
      'dose_amount': doseAmount,
      'route': route,
      'injection_site': injectionSite,
      'logged_at': loggedAt.toIso8601String(),
      'notes': notes,
    };
  }
}

class DoseLogsService {
  final SupabaseClient _supabase;

  DoseLogsService(this._supabase);

  // Create dose log
  Future<DoseLog?> logDose({
    required String userId,
    required String cycleId,
    String? scheduleId,
    required String peptideName,
    required double doseAmount,
    required String route,
    String? injectionSite,
    required DateTime loggedAt,
    String? notes,
  }) async {
    try {
      print('[DEBUG] Logging dose: $peptideName, ${doseAmount}mg');

      // Match the actual dose_logs schema
      final data = {
        'cycle_id': cycleId,
        'dosis_id': scheduleId ?? '', // Use schedule_id as dosis_id
        'dose_amount': doseAmount,
        'logged_at': loggedAt.toIso8601String(),
      };
      
      // Add optional fields
      if (notes != null && notes.isNotEmpty) data['notes'] = notes;
      
      print('[DEBUG SERVICE] Inserting to dose_logs with data: $data');
      final response = await _supabase.from('dose_logs').insert(data).select().single();

      print('[DEBUG] Dose logged successfully');
      return DoseLog.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('[ERROR] Failed to log dose: $e');
      throw Exception('Failed to log dose: $e');
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

final cycleDoseLogsProvider =
    FutureProvider.family<List<DoseLog>, String>((ref, cycleId) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];

  final service = ref.watch(doseLogsServiceProvider);
  return service.getCycleDoseLogs(userId, cycleId);
});
