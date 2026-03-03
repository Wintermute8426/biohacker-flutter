class CycleReview {
  final String id;
  final String cycleId;
  final String userId;
  final int effectivenessRating; // 1-10
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  CycleReview({
    required this.id,
    required this.cycleId,
    required this.userId,
    required this.effectivenessRating,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CycleReview.fromJson(Map<String, dynamic> json) {
    return CycleReview(
      id: json['id'] ?? '',
      cycleId: json['cycle_id'] ?? '',
      userId: json['user_id'] ?? '',
      effectivenessRating: json['effectiveness_rating'] ?? 5,
      notes: json['notes'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cycle_id': cycleId,
      'user_id': userId,
      'effectiveness_rating': effectivenessRating,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CycleReview copyWith({
    String? id,
    String? cycleId,
    String? userId,
    int? effectivenessRating,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CycleReview(
      id: id ?? this.id,
      cycleId: cycleId ?? this.cycleId,
      userId: userId ?? this.userId,
      effectivenessRating: effectivenessRating ?? this.effectivenessRating,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
