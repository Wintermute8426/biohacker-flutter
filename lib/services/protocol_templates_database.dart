import 'package:supabase_flutter/supabase_flutter.dart';

class ProtocolTemplate {
  final String? id;
  final String name;
  final String? description;
  final String peptideName;
  final double dose;
  final String route;
  final String frequency;
  final int durationWeeks;
  final int usageCount;
  final bool isPublic;

  ProtocolTemplate({
    this.id,
    required this.name,
    this.description,
    required this.peptideName,
    required this.dose,
    required this.route,
    required this.frequency,
    required this.durationWeeks,
    this.usageCount = 0,
    this.isPublic = false,
  });

  factory ProtocolTemplate.fromJson(Map<String, dynamic> json) => ProtocolTemplate(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    peptideName: json['peptide_name'],
    dose: (json['dose'] as num).toDouble(),
    route: json['route'],
    frequency: json['frequency'],
    durationWeeks: json['duration_weeks'],
    usageCount: json['usage_count'] ?? 0,
    isPublic: json['is_public'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'peptide_name': peptideName,
    'dose': dose,
    'route': route,
    'frequency': frequency,
    'duration_weeks': durationWeeks,
    'usage_count': usageCount,
    'is_public': isPublic,
  };
}

class ProtocolTemplatesDatabase {
  final supabase = Supabase.instance.client;
  final String tableName = 'protocol_templates';

  // Save protocol template
  Future<ProtocolTemplate?> saveProtocol({
    required String name,
    String? description,
    required String peptideName,
    required double dose,
    required String route,
    required String frequency,
    required int durationWeeks,
    bool isPublic = false,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final data = {
        'user_id': user.id,
        'name': name,
        'description': description,
        'peptide_name': peptideName,
        'dose': dose,
        'route': route,
        'frequency': frequency,
        'duration_weeks': durationWeeks,
        'usage_count': 0,
        'is_public': isPublic,
      };

      final response = await supabase
          .from(tableName)
          .insert(data)
          .select()
          .single();

      return ProtocolTemplate.fromJson(response);
    } catch (e) {
      print('Error saving protocol template: $e');
      rethrow;
    }
  }

  // Get user's protocols
  Future<List<ProtocolTemplate>> getUserProtocols() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await supabase
          .from(tableName)
          .select()
          .eq('user_id', user.id)
          .order('usage_count', ascending: false);

      return (response as List).map((e) => ProtocolTemplate.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching protocols: $e');
      return [];
    }
  }

  // Increment usage count
  Future<void> incrementUsage(String templateId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final template = await supabase
          .from(tableName)
          .select('usage_count')
          .eq('id', templateId)
          .eq('user_id', user.id)
          .single();

      await supabase
          .from(tableName)
          .update({'usage_count': (template['usage_count'] ?? 0) + 1})
          .eq('id', templateId)
          .eq('user_id', user.id);
    } catch (e) {
      print('Error incrementing usage: $e');
    }
  }

  // Delete protocol template
  Future<bool> deleteProtocol(String templateId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await supabase
          .from(tableName)
          .delete()
          .eq('id', templateId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      print('Error deleting protocol: $e');
      return false;
    }
  }
}
