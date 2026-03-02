import 'package:supabase_flutter/supabase_flutter.dart';

class SideEffect {
  final String id;
  final String userId;
  final String cycleId;
  final String symptom;
  final int severity; // 1-10
  final String? notes;
  final DateTime loggedAt;
  final DateTime createdAt;

  SideEffect({
    required this.id,
    required this.userId,
    required this.cycleId,
    required this.symptom,
    required this.severity,
    this.notes,
    required this.loggedAt,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'cycle_id': cycleId,
    'symptom': symptom,
    'severity': severity,
    'notes': notes,
    'logged_at': loggedAt.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  factory SideEffect.fromJson(Map<String, dynamic> json) {
    return SideEffect(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      cycleId: json['cycle_id'] as String,
      symptom: json['symptom'] as String,
      severity: json['severity'] as int,
      notes: json['notes'] as String?,
      loggedAt: DateTime.parse(json['logged_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class SideEffectsDatabase {
  static const String tableName = 'side_effects_log';
  final SupabaseClient supabase = Supabase.instance.client;

  static const List<String> SYMPTOM_OPTIONS = [
    'Fatigue',
    'Acne',
    'Headache',
    'Nausea',
    'Insomnia',
    'Joint pain',
    'Muscle soreness',
    'Mood changes',
    'Anxiety',
    'Brain fog',
    'Appetite change',
    'Water retention',
    'Irritability',
    'Other',
  ];

  // Log a side effect
  Future<SideEffect?> logSideEffect({
    required String cycleId,
    required String symptom,
    required int severity,
    required DateTime loggedAt,
    String? notes,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final data = {
        'user_id': user.id,
        'cycle_id': cycleId,
        'symptom': symptom,
        'severity': severity,
        'logged_at': loggedAt.toIso8601String(),
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await supabase
          .from(tableName)
          .insert(data)
          .select()
          .single();

      return SideEffect.fromJson(response);
    } catch (e) {
      print('Error logging side effect: $e');
      return null;
    }
  }

  // Get side effects for a cycle
  Future<List<SideEffect>> getCycleSideEffects(String cycleId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await supabase
          .from(tableName)
          .select()
          .eq('user_id', user.id)
          .eq('cycle_id', cycleId)
          .order('logged_at', ascending: false);

      final sideEffects = (response as List)
          .map((json) => SideEffect.fromJson(json as Map<String, dynamic>))
          .toList();

      return sideEffects;
    } catch (e) {
      print('Error loading side effects: $e');
      return [];
    }
  }

  // Get all side effects for user
  Future<List<SideEffect>> getAllSideEffects() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await supabase
          .from(tableName)
          .select()
          .eq('user_id', user.id)
          .order('logged_at', ascending: false);

      final sideEffects = (response as List)
          .map((json) => SideEffect.fromJson(json as Map<String, dynamic>))
          .toList();

      return sideEffects;
    } catch (e) {
      print('Error loading side effects: $e');
      return [];
    }
  }

  // Delete side effect
  Future<bool> deleteSideEffect(String sideEffectId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await supabase
          .from(tableName)
          .delete()
          .eq('id', sideEffectId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      print('Error deleting side effect: $e');
      return false;
    }
  }
}
