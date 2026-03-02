import 'package:supabase_flutter/supabase_flutter.dart';

class DoseLog {
  final String? id;
  final String cycleId;
  final double doseAmount;
  final String doseUnit;
  final DateTime loggedAt;
  final String? route;
  final String? injectionSite;
  final String? notes;

  DoseLog({
    this.id,
    required this.cycleId,
    required this.doseAmount,
    this.doseUnit = 'mg',
    required this.loggedAt,
    this.route,
    this.injectionSite,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'cycle_id': cycleId,
    'dose_amount': doseAmount,
    'dose_unit': doseUnit,
    'logged_at': loggedAt.toIso8601String(),
    'route': route,
    'injection_site': injectionSite,
    'notes': notes,
  };

  factory DoseLog.fromJson(Map<String, dynamic> json) => DoseLog(
    id: json['id'],
    cycleId: json['cycle_id'],
    doseAmount: (json['dose_amount'] as num).toDouble(),
    doseUnit: json['dose_unit'] ?? 'mg',
    loggedAt: DateTime.parse(json['logged_at']),
    route: json['route'],
    injectionSite: json['injection_site'],
    notes: json['notes'],
  );
}

class SideEffect {
  final String? id;
  final String cycleId;
  final String symptom;
  final int severity;
  final String? notes;
  final DateTime loggedAt;

  SideEffect({
    this.id,
    required this.cycleId,
    required this.symptom,
    required this.severity,
    this.notes,
    required this.loggedAt,
  });

  Map<String, dynamic> toJson() => {
    'cycle_id': cycleId,
    'symptom': symptom,
    'severity': severity,
    'notes': notes,
    'logged_at': loggedAt.toIso8601String(),
  };

  factory SideEffect.fromJson(Map<String, dynamic> json) => SideEffect(
    id: json['id'],
    cycleId: json['cycle_id'],
    symptom: json['symptom'],
    severity: json['severity'],
    notes: json['notes'],
    loggedAt: DateTime.parse(json['logged_at']),
  );
}

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

  Map<String, dynamic> toJson() => {
    'weight_lbs': weightLbs,
    'body_fat_percent': bodyFatPercent,
    'logged_at': loggedAt.toIso8601String(),
    'notes': notes,
  };

  factory WeightLog.fromJson(Map<String, dynamic> json) => WeightLog(
    id: json['id'],
    weightLbs: (json['weight_lbs'] as num).toDouble(),
    bodyFatPercent: json['body_fat_percent'] != null ? (json['body_fat_percent'] as num).toDouble() : null,
    loggedAt: DateTime.parse(json['logged_at']),
    notes: json['notes'],
  );
}

class ProtocolTemplate {
  final String? id;
  final String name;
  final String? description;
  final String peptideName;
  final double dose;
  final String doseUnit;
  final String route;
  final String frequency;
  final int durationWeeks;
  final Map<String, dynamic>? advancedSchedule;
  final int usageCount;
  final bool isPublic;

  ProtocolTemplate({
    this.id,
    required this.name,
    this.description,
    required this.peptideName,
    required this.dose,
    this.doseUnit = 'mg',
    required this.route,
    required this.frequency,
    required this.durationWeeks,
    this.advancedSchedule,
    this.usageCount = 0,
    this.isPublic = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'peptide_name': peptideName,
    'dose': dose,
    'dose_unit': doseUnit,
    'route': route,
    'frequency': frequency,
    'duration_weeks': durationWeeks,
    'advanced_schedule': advancedSchedule,
    'usage_count': usageCount,
    'is_public': isPublic,
  };

  factory ProtocolTemplate.fromJson(Map<String, dynamic> json) => ProtocolTemplate(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    peptideName: json['peptide_name'],
    dose: (json['dose'] as num).toDouble(),
    doseUnit: json['dose_unit'] ?? 'mg',
    route: json['route'],
    frequency: json['frequency'],
    durationWeeks: json['duration_weeks'],
    advancedSchedule: json['advanced_schedule'],
    usageCount: json['usage_count'] ?? 0,
    isPublic: json['is_public'] ?? false,
  );
}

class PeptideInventory {
  final String? id;
  final String peptideName;
  final double vialSizeMg;
  final String vialSizeUnit;
  final int quantityVials;
  final double costPerVial;
  final DateTime purchasedDate;
  final DateTime? expiryDate;
  final String? notes;

  PeptideInventory({
    this.id,
    required this.peptideName,
    required this.vialSizeMg,
    this.vialSizeUnit = 'mg',
    required this.quantityVials,
    required this.costPerVial,
    required this.purchasedDate,
    this.expiryDate,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'peptide_name': peptideName,
    'vial_size_mg': vialSizeMg,
    'vial_size_unit': vialSizeUnit,
    'quantity_vials': quantityVials,
    'cost_per_vial': costPerVial,
    'purchased_date': purchasedDate.toIso8601String().split('T')[0],
    'expiry_date': expiryDate?.toIso8601String().split('T')[0],
    'notes': notes,
  };

  factory PeptideInventory.fromJson(Map<String, dynamic> json) => PeptideInventory(
    id: json['id'],
    peptideName: json['peptide_name'],
    vialSizeMg: (json['vial_size_mg'] as num).toDouble(),
    vialSizeUnit: json['vial_size_unit'] ?? 'mg',
    quantityVials: json['quantity_vials'],
    costPerVial: (json['cost_per_vial'] as num).toDouble(),
    purchasedDate: DateTime.parse(json['purchased_date']),
    expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date']) : null,
    notes: json['notes'],
  );
}

class CycleReview {
  final String? id;
  final String cycleId;
  final int effectivenessRating;
  final bool? wouldRepeat;
  final String? resultsSummary;
  final String? pros;
  final String? cons;

  CycleReview({
    this.id,
    required this.cycleId,
    required this.effectivenessRating,
    this.wouldRepeat,
    this.resultsSummary,
    this.pros,
    this.cons,
  });

  Map<String, dynamic> toJson() => {
    'cycle_id': cycleId,
    'effectiveness_rating': effectivenessRating,
    'would_repeat': wouldRepeat,
    'results_summary': resultsSummary,
    'pros': pros,
    'cons': cons,
  };

  factory CycleReview.fromJson(Map<String, dynamic> json) => CycleReview(
    id: json['id'],
    cycleId: json['cycle_id'],
    effectivenessRating: json['effectiveness_rating'],
    wouldRepeat: json['would_repeat'],
    resultsSummary: json['results_summary'],
    pros: json['pros'],
    cons: json['cons'],
  );
}

class HealthGoal {
  final String? id;
  final String cycleId;
  final String goalType;
  final double? targetValue;
  final String? targetUnit;
  final double? startValue;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;

  HealthGoal({
    this.id,
    required this.cycleId,
    required this.goalType,
    this.targetValue,
    this.targetUnit,
    this.startValue,
    required this.startDate,
    this.endDate,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'cycle_id': cycleId,
    'goal_type': goalType,
    'target_value': targetValue,
    'target_unit': targetUnit,
    'start_value': startValue,
    'start_date': startDate.toIso8601String().split('T')[0],
    'end_date': endDate?.toIso8601String().split('T')[0],
    'notes': notes,
  };

  factory HealthGoal.fromJson(Map<String, dynamic> json) => HealthGoal(
    id: json['id'],
    cycleId: json['cycle_id'],
    goalType: json['goal_type'],
    targetValue: json['target_value'] != null ? (json['target_value'] as num).toDouble() : null,
    targetUnit: json['target_unit'],
    startValue: json['start_value'] != null ? (json['start_value'] as num).toDouble() : null,
    startDate: DateTime.parse(json['start_date']),
    endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
    notes: json['notes'],
  );
}

class BiohackerDatabase {
  final SupabaseClient _supabase;

  BiohackerDatabase(this._supabase);

  // ===== DOSE LOGS =====
  Future<void> saveDoseLog(DoseLog log) async {
    try {
      await _supabase.from('dose_logs').insert(log.toJson());
    } catch (e) {
      print('Error saving dose log: $e');
      rethrow;
    }
  }

  Future<List<DoseLog>> getCycleDoselogs(String cycleId) async {
    try {
      final response = await _supabase
          .from('dose_logs')
          .select()
          .eq('cycle_id', cycleId)
          .order('logged_at', ascending: false);
      return (response as List).map((e) => DoseLog.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching dose logs: $e');
      return [];
    }
  }

  Future<void> deleteDoseLog(String doseLogId) async {
    try {
      await _supabase.from('dose_logs').delete().eq('id', doseLogId);
    } catch (e) {
      print('Error deleting dose log: $e');
      rethrow;
    }
  }

  // ===== SIDE EFFECTS =====
  Future<void> saveSideEffect(SideEffect effect) async {
    try {
      await _supabase.from('side_effects_log').insert(effect.toJson());
    } catch (e) {
      print('Error saving side effect: $e');
      rethrow;
    }
  }

  Future<List<SideEffect>> getCycleSideEffects(String cycleId) async {
    try {
      final response = await _supabase
          .from('side_effects_log')
          .select()
          .eq('cycle_id', cycleId)
          .order('logged_at', ascending: false);
      return (response as List).map((e) => SideEffect.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching side effects: $e');
      return [];
    }
  }

  Future<void> deleteSideEffect(String sideEffectId) async {
    try {
      await _supabase.from('side_effects_log').delete().eq('id', sideEffectId);
    } catch (e) {
      print('Error deleting side effect: $e');
      rethrow;
    }
  }

  // ===== WEIGHT LOGS =====
  Future<void> saveWeightLog(WeightLog log) async {
    try {
      await _supabase.from('weight_logs').insert(log.toJson());
    } catch (e) {
      print('Error saving weight log: $e');
      rethrow;
    }
  }

  Future<List<WeightLog>> getWeightLogs({int limit = 100}) async {
    try {
      final response = await _supabase
          .from('weight_logs')
          .select()
          .order('logged_at', ascending: false)
          .limit(limit);
      return (response as List).map((e) => WeightLog.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching weight logs: $e');
      return [];
    }
  }

  Future<void> deleteWeightLog(String weightLogId) async {
    try {
      await _supabase.from('weight_logs').delete().eq('id', weightLogId);
    } catch (e) {
      print('Error deleting weight log: $e');
      rethrow;
    }
  }

  // ===== PROTOCOL TEMPLATES =====
  Future<void> saveProtocolTemplate(ProtocolTemplate template) async {
    try {
      await _supabase.from('protocol_templates').insert(template.toJson());
    } catch (e) {
      print('Error saving protocol template: $e');
      rethrow;
    }
  }

  Future<List<ProtocolTemplate>> getUserProtocols() async {
    try {
      final response = await _supabase
          .from('protocol_templates')
          .select()
          .order('usage_count', ascending: false);
      return (response as List).map((e) => ProtocolTemplate.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching protocol templates: $e');
      return [];
    }
  }

  Future<void> deleteProtocolTemplate(String templateId) async {
    try {
      await _supabase.from('protocol_templates').delete().eq('id', templateId);
    } catch (e) {
      print('Error deleting protocol template: $e');
      rethrow;
    }
  }

  Future<void> incrementTemplateUsage(String templateId) async {
    try {
      final template = await _supabase
          .from('protocol_templates')
          .select('usage_count')
          .eq('id', templateId)
          .single();
      
      await _supabase
          .from('protocol_templates')
          .update({'usage_count': (template['usage_count'] ?? 0) + 1})
          .eq('id', templateId);
    } catch (e) {
      print('Error incrementing template usage: $e');
    }
  }

  // ===== PEPTIDE INVENTORY =====
  Future<void> saveInventory(PeptideInventory inventory) async {
    try {
      await _supabase.from('peptide_inventory').insert(inventory.toJson());
    } catch (e) {
      print('Error saving inventory: $e');
      rethrow;
    }
  }

  Future<List<PeptideInventory>> getInventory() async {
    try {
      final response = await _supabase
          .from('peptide_inventory')
          .select()
          .order('expiry_date', ascending: true);
      return (response as List).map((e) => PeptideInventory.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching inventory: $e');
      return [];
    }
  }

  Future<void> updateInventory(String inventoryId, int newQuantity) async {
    try {
      await _supabase
          .from('peptide_inventory')
          .update({'quantity_vials': newQuantity})
          .eq('id', inventoryId);
    } catch (e) {
      print('Error updating inventory: $e');
      rethrow;
    }
  }

  Future<void> deleteInventory(String inventoryId) async {
    try {
      await _supabase.from('peptide_inventory').delete().eq('id', inventoryId);
    } catch (e) {
      print('Error deleting inventory: $e');
      rethrow;
    }
  }

  // ===== CYCLE REVIEWS =====
  Future<void> saveCycleReview(CycleReview review) async {
    try {
      await _supabase.from('cycle_reviews').insert(review.toJson());
    } catch (e) {
      print('Error saving cycle review: $e');
      rethrow;
    }
  }

  Future<CycleReview?> getCycleReview(String cycleId) async {
    try {
      final response = await _supabase
          .from('cycle_reviews')
          .select()
          .eq('cycle_id', cycleId)
          .maybeSingle();
      return response != null ? CycleReview.fromJson(response) : null;
    } catch (e) {
      print('Error fetching cycle review: $e');
      return null;
    }
  }

  // ===== HEALTH GOALS =====
  Future<void> saveHealthGoal(HealthGoal goal) async {
    try {
      await _supabase.from('health_goals').insert(goal.toJson());
    } catch (e) {
      print('Error saving health goal: $e');
      rethrow;
    }
  }

  Future<List<HealthGoal>> getCycleGoals(String cycleId) async {
    try {
      final response = await _supabase
          .from('health_goals')
          .select()
          .eq('cycle_id', cycleId);
      return (response as List).map((e) => HealthGoal.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching health goals: $e');
      return [];
    }
  }

  Future<void> deleteHealthGoal(String goalId) async {
    try {
      await _supabase.from('health_goals').delete().eq('id', goalId);
    } catch (e) {
      print('Error deleting health goal: $e');
      rethrow;
    }
  }
}
