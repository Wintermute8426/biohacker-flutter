import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class DoseLog {
  final String id;
  final String userId;
  final String cycleId;
  final double doseAmount;
  final DateTime loggedAt;
  final String? route;
  final String? location;
  final String? notes;
  final DateTime createdAt;

  DoseLog({
    required this.id,
    required this.userId,
    required this.cycleId,
    required this.doseAmount,
    required this.loggedAt,
    this.route,
    this.location,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'cycle_id': cycleId,
    'dose_amount': doseAmount,
    'logged_at': loggedAt.toIso8601String(),
    'route': route,
    'location': location,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
  };

  factory DoseLog.fromJson(Map<String, dynamic> json) {
    return DoseLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      cycleId: json['cycle_id'] as String,
      doseAmount: (json['dose_amount'] as num).toDouble(),
      loggedAt: DateTime.parse(json['logged_at'] as String),
      route: json['route'] as String?,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class DoseLogsDatabase {
  static const String tableName = 'dose_logs';
  final SupabaseClient supabase = Supabase.instance.client;

  // Log a dose
  Future<DoseLog?> logDose({
    required String cycleId,
    required double doseAmount,
    required DateTime loggedAt,
    String? route,
    String? location,
    String? notes,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final doseData = {
        'user_id': user.id,
        'cycle_id': cycleId,
        'dose_amount': doseAmount,
        'logged_at': loggedAt.toIso8601String(),
        'route': route,
        'location': location,
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await supabase
          .from(tableName)
          .insert(doseData)
          .select()
          .single();

      return DoseLog.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error logging dose: $e');
      }
      return null;
    }
  }

  // Get dose logs for a cycle
  Future<List<DoseLog>> getCycleDoseLogs(String cycleId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await supabase
          .from(tableName)
          .select()
          .eq('user_id', user.id)
          .eq('cycle_id', cycleId)
          .order('logged_at', ascending: false);

      final logs = (response as List)
          .map((json) => DoseLog.fromJson(json as Map<String, dynamic>))
          .toList();

      return logs;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading dose logs: $e');
      }
      return [];
    }
  }

  // Get all dose logs for user
  Future<List<DoseLog>> getAllDoseLogs() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await supabase
          .from(tableName)
          .select()
          .eq('user_id', user.id)
          .order('logged_at', ascending: false);

      final logs = (response as List)
          .map((json) => DoseLog.fromJson(json as Map<String, dynamic>))
          .toList();

      return logs;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading dose logs: $e');
      }
      return [];
    }
  }

  // Delete dose log
  Future<bool> deleteDoseLog(String doseLogId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await supabase
          .from(tableName)
          .delete()
          .eq('id', doseLogId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting dose log: $e');
      }
      return false;
    }
  }
}
