import 'package:supabase_flutter/supabase_flutter.dart';

class Cycle {
  final String id;
  final String userId;
  final String peptideName;
  final double dose; // in mg
  final String route; // SC, IM, IV, etc.
  final String frequency; // 1x weekly, 2x weekly, etc.
  final int durationWeeks;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;

  // Advanced dosing (optional)
  final Map<String, dynamic>? advancedSchedule;

  Cycle({
    required this.id,
    required this.userId,
    required this.peptideName,
    required this.dose,
    required this.route,
    required this.frequency,
    required this.durationWeeks,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    required this.createdAt,
    this.advancedSchedule,
  });

  // Convert to JSON for Supabase
  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'peptide_name': peptideName,
    'dose': dose,
    'route': route,
    'frequency': frequency,
    'duration_weeks': durationWeeks,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'advanced_schedule': advancedSchedule,
  };

  // Convert from JSON
  factory Cycle.fromJson(Map<String, dynamic> json) {
    return Cycle(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      peptideName: json['peptide_name'] as String,
      dose: (json['dose'] as num).toDouble(),
      route: json['route'] as String,
      frequency: json['frequency'] as String,
      durationWeeks: json['duration_weeks'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      advancedSchedule: json['advanced_schedule'] as Map<String, dynamic>?,
    );
  }
}

class CyclesDatabase {
  static const String tableName = 'cycles';
  final SupabaseClient supabase = Supabase.instance.client;

  // Save a new cycle
  Future<Cycle?> saveCycle({
    required String peptideName,
    required double dose,
    required String route,
    required String frequency,
    required int durationWeeks,
    required DateTime startDate,
    Map<String, dynamic>? advancedSchedule,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final endDate = startDate.add(Duration(days: durationWeeks * 7));
      final cycleData = {
        'user_id': user.id,
        'peptide_name': peptideName,
        'dose': dose,
        'route': route,
        'frequency': frequency,
        'duration_weeks': durationWeeks,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'advanced_schedule': advancedSchedule,
      };

      final response = await supabase
          .from(tableName)
          .insert(cycleData)
          .select()
          .single();

      return Cycle.fromJson(response);
    } catch (e) {
      print('Error saving cycle: $e');
      return null;
    }
  }

  // Get all cycles for current user
  Future<List<Cycle>> getUserCycles() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await supabase
          .from(tableName)
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final cycles = (response as List)
          .map((json) => Cycle.fromJson(json as Map<String, dynamic>))
          .toList();

      return cycles;
    } catch (e) {
      print('Error loading cycles: $e');
      return [];
    }
  }

  // Get active cycles only
  Future<List<Cycle>> getActiveCycles() async {
    try {
      final cycles = await getUserCycles();
      return cycles.where((c) => c.isActive).toList();
    } catch (e) {
      print('Error loading active cycles: $e');
      return [];
    }
  }

  // Update cycle
  Future<Cycle?> updateCycle({
    required String cycleId,
    String? peptideName,
    double? dose,
    String? route,
    String? frequency,
    int? durationWeeks,
    bool? isActive,
    DateTime? endDate,
    Map<String, dynamic>? advancedSchedule,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final updateData = <String, dynamic>{};
      if (peptideName != null) updateData['peptide_name'] = peptideName;
      if (dose != null) updateData['dose'] = dose;
      if (route != null) updateData['route'] = route;
      if (frequency != null) updateData['frequency'] = frequency;
      if (durationWeeks != null) updateData['duration_weeks'] = durationWeeks;
      if (isActive != null) updateData['is_active'] = isActive;
      if (endDate != null) updateData['end_date'] = endDate.toIso8601String();
      if (advancedSchedule != null) updateData['advanced_schedule'] = advancedSchedule;
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await supabase
          .from(tableName)
          .update(updateData)
          .eq('id', cycleId)
          .eq('user_id', user.id)
          .select()
          .single();

      return Cycle.fromJson(response);
    } catch (e) {
      print('Error updating cycle: $e');
      return null;
    }
  }

  // Delete cycle
  Future<bool> deleteCycle(String cycleId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await supabase
          .from(tableName)
          .delete()
          .eq('id', cycleId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      print('Error deleting cycle: $e');
      return false;
    }
  }
}
