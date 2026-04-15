import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class WeightLog {
  final String? id;
  final double weightLbs;
  final double? bodyFatPercent;
  final DateTime loggedAt;
  final String? notes;

  WeightLog({
    this.id,
    required this.weightLbs,
    this.bodyFatPercent,
    required this.loggedAt,
    this.notes,
  });

  factory WeightLog.fromJson(Map<String, dynamic> json) => WeightLog(
    id: json['id'],
    weightLbs: (json['weight_lbs'] as num).toDouble(),
    bodyFatPercent: json['body_fat_percent'] != null ? (json['body_fat_percent'] as num).toDouble() : null,
    loggedAt: DateTime.parse(json['logged_at']),
    notes: json['notes'],
  );

  Map<String, dynamic> toJson() => {
    'weight_lbs': weightLbs,
    'body_fat_percent': bodyFatPercent,
    'logged_at': loggedAt.toIso8601String(),
    'notes': notes,
  };
}

class WeightLogsDatabase {
  final supabase = Supabase.instance.client;
  final String tableName = 'weight_logs';

  // Save weight log
  Future<WeightLog?> saveWeightLog({
    required double weightLbs,
    double? bodyFatPercent,
    required DateTime loggedAt,
    String? notes,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        print('DEBUG: Saving weight log - User: ${user.id}, Weight: $weightLbs');
      }

      final data = {
        'user_id': user.id,
        'weight_lbs': weightLbs,
        'body_fat_percent': bodyFatPercent,
        'logged_at': loggedAt.toIso8601String().split('T')[0], // Date only
        'notes': notes,
      };

      if (kDebugMode) {
        print('DEBUG: Data being inserted: $data');
      }

      final response = await supabase
          .from(tableName)
          .insert(data)
          .select()
          .single();

      if (kDebugMode) {
        print('DEBUG: Weight log saved successfully: $response');
      }
      return WeightLog.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('ERROR saving weight log: $e');
      }
      rethrow; // Re-throw so caller can see the error
    }
  }

  // Get weight logs (most recent first)
  Future<List<WeightLog>> getWeightLogs({int limit = 100}) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await supabase
          .from(tableName)
          .select()
          .eq('user_id', user.id)
          .order('logged_at', ascending: false)
          .limit(limit);

      return (response as List).map((e) => WeightLog.fromJson(e)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching weight logs: $e');
      }
      return [];
    }
  }

  // Delete weight log
  Future<bool> deleteWeightLog(String logId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await supabase
          .from(tableName)
          .delete()
          .eq('id', logId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting weight log: $e');
      }
      return false;
    }
  }

  // Get weight trend (last N entries)
  Future<List<WeightLog>> getWeightTrend({int days = 30}) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final response = await supabase
          .from(tableName)
          .select()
          .eq('user_id', user.id)
          .gte('logged_at', cutoffDate.toIso8601String())
          .order('logged_at', ascending: false);

      return (response as List).map((e) => WeightLog.fromJson(e)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching weight trend: $e');
      }
      return [];
    }
  }
}
