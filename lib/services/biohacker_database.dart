// Data models for Biohacker app
// Service methods will be added incrementally

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
