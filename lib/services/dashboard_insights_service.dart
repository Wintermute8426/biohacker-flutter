import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class DashboardSnapshot {
  final String id;
  final String userId;
  final String cycleId;
  final double? adherencePercent;
  final int totalDosesLogged;
  final int totalDosesScheduled;
  final int sideEffectsCount;
  final double? sideEffectsAvgSeverity;
  final double? weightChangeLbs;
  final double? bodyFatChangePercent;
  final double costTotal;
  final double? costPerDose;
  final Map<String, dynamic>? effectivenessScores;
  final List<String> loggedDates;
  final DateTime createdAt;

  DashboardSnapshot({
    required this.id,
    required this.userId,
    required this.cycleId,
    this.adherencePercent,
    required this.totalDosesLogged,
    required this.totalDosesScheduled,
    required this.sideEffectsCount,
    this.sideEffectsAvgSeverity,
    this.weightChangeLbs,
    this.bodyFatChangePercent,
    required this.costTotal,
    this.costPerDose,
    this.effectivenessScores,
    required this.loggedDates,
    required this.createdAt,
  });

  factory DashboardSnapshot.fromJson(Map<String, dynamic> json) {
    return DashboardSnapshot(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      cycleId: json['cycle_id'] ?? '',
      adherencePercent: (json['adherence_percent'] as num?)?.toDouble(),
      totalDosesLogged: json['total_doses_logged'] ?? 0,
      totalDosesScheduled: json['total_doses_scheduled'] ?? 0,
      sideEffectsCount: json['side_effects_count'] ?? 0,
      sideEffectsAvgSeverity: (json['side_effects_avg_severity'] as num?)?.toDouble(),
      weightChangeLbs: (json['weight_change_lbs'] as num?)?.toDouble(),
      bodyFatChangePercent: (json['body_fat_change_percent'] as num?)?.toDouble(),
      costTotal: (json['cost_total'] as num?)?.toDouble() ?? 0,
      costPerDose: (json['cost_per_dose'] as num?)?.toDouble(),
      effectivenessScores: json['effectiveness_scores'] as Map<String, dynamic>?,
      loggedDates: List<String>.from(json['logged_dates'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class DashboardInsightsService {
  final SupabaseClient _supabase;

  DashboardInsightsService(this._supabase);

  // Get latest snapshot for cycle
  Future<DashboardSnapshot?> getLatestSnapshot(String userId, String cycleId) async {
    try {
      final response = await _supabase
          .from('dashboard_snapshots')
          .select()
          .eq('user_id', userId)
          .eq('cycle_id', cycleId)
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      return DashboardSnapshot.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('[ERROR] Failed to fetch snapshot: $e');
      }
      return null;
    }
  }

  // Get all snapshots for user (for historical view)
  Future<List<DashboardSnapshot>> getAllSnapshots(String userId) async {
    try {
      final response = await _supabase
          .from('dashboard_snapshots')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => DashboardSnapshot.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('[ERROR] Failed to fetch snapshots: $e');
      }
      return [];
    }
  }

  // Create or update snapshot
  Future<DashboardSnapshot?> upsertSnapshot({
    required String userId,
    required String cycleId,
    double? adherencePercent,
    int? totalDosesLogged,
    int? totalDosesScheduled,
    int? sideEffectsCount,
    double? sideEffectsAvgSeverity,
    double? weightChangeLbs,
    double? bodyFatChangePercent,
    double? costTotal,
    double? costPerDose,
    Map<String, dynamic>? effectivenessScores,
    List<String>? loggedDates,
  }) async {
    try {
      final data = {
        'user_id': userId,
        'cycle_id': cycleId,
        if (adherencePercent != null) 'adherence_percent': adherencePercent,
        if (totalDosesLogged != null) 'total_doses_logged': totalDosesLogged,
        if (totalDosesScheduled != null) 'total_doses_scheduled': totalDosesScheduled,
        if (sideEffectsCount != null) 'side_effects_count': sideEffectsCount,
        if (sideEffectsAvgSeverity != null) 'side_effects_avg_severity': sideEffectsAvgSeverity,
        if (weightChangeLbs != null) 'weight_change_lbs': weightChangeLbs,
        if (bodyFatChangePercent != null) 'body_fat_change_percent': bodyFatChangePercent,
        if (costTotal != null) 'cost_total': costTotal,
        if (costPerDose != null) 'cost_per_dose': costPerDose,
        if (effectivenessScores != null) 'effectiveness_scores': effectivenessScores,
        if (loggedDates != null) 'logged_dates': loggedDates,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('dashboard_snapshots')
          .upsert(data, onConflict: 'cycle_id')
          .select()
          .single();

      return DashboardSnapshot.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('[ERROR] Failed to upsert snapshot: $e');
      }
      return null;
    }
  }
}

// Riverpod providers
final dashboardInsightsServiceProvider = Provider((ref) {
  return DashboardInsightsService(Supabase.instance.client);
});

final currentUserIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

final dashboardSnapshotProvider = FutureProvider.family<DashboardSnapshot?, String>((ref, cycleId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final service = ref.watch(dashboardInsightsServiceProvider);
  return service.getLatestSnapshot(userId, cycleId);
});

final allDashboardSnapshotsProvider = FutureProvider<List<DashboardSnapshot>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final service = ref.watch(dashboardInsightsServiceProvider);
  return service.getAllSnapshots(userId);
});
