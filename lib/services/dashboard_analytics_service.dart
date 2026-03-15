import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

// Dashboard data models
class DashboardData {
  final ComplianceData compliance;
  final TopPeptideData? topPeptide;
  final List<DoseTimelineDay> timeline;
  final Map<String, Map<int, int>> sideEffectsHeatmap;
  final List<LabCorrelation> labCorrelations;
  final CostEfficiencyData? costEfficiency;
  final DateTime generatedAt;

  DashboardData({
    required this.compliance,
    this.topPeptide,
    required this.timeline,
    required this.sideEffectsHeatmap,
    required this.labCorrelations,
    this.costEfficiency,
    required this.generatedAt,
  });
}

class ComplianceData {
  final int dosesLogged;
  final int dosesScheduled;
  final double percentage;

  ComplianceData({
    required this.dosesLogged,
    required this.dosesScheduled,
    required this.percentage,
  });
}

class TopPeptideData {
  final String peptideName;
  final double rating;
  final int cyclesUsed;

  TopPeptideData({
    required this.peptideName,
    required this.rating,
    required this.cyclesUsed,
  });
}

class DoseTimelineDay {
  final DateTime date;
  final bool logged;
  final List<String> peptides;

  DoseTimelineDay({
    required this.date,
    required this.logged,
    required this.peptides,
  });
}

class LabCorrelation {
  final String biomarker;
  final double changePercent;
  final List<String> contributingPeptides;
  final bool isImprovement;

  LabCorrelation({
    required this.biomarker,
    required this.changePercent,
    required this.contributingPeptides,
    required this.isImprovement,
  });
}

class CostEfficiencyData {
  final double monthlyTotal;
  final double costPerDose;
  final String? bestValuePeptide;
  final String? leastCostEffectivePeptide;

  CostEfficiencyData({
    required this.monthlyTotal,
    required this.costPerDose,
    this.bestValuePeptide,
    this.leastCostEffectivePeptide,
  });
}

class DashboardAnalyticsService {
  final SupabaseClient _supabase;

  DashboardAnalyticsService(this._supabase);

  /// Get or generate dashboard data (with 24h caching)
  Future<DashboardData> getDashboardData(String userId) async {
    try {
      // Check for cached snapshot (not expired)
      final cached = await _getCachedSnapshot(userId);
      if (cached != null) {
        if (kDebugMode) {
          print('[DashboardAnalyticsService] Using cached data');
        }
        return cached;
      }

      // Generate fresh data
      if (kDebugMode) {
        print('[DashboardAnalyticsService] Generating fresh data');
      }
      final data = await _generateDashboardData(userId);

      // Cache it
      await _cacheSnapshot(userId, data);

      return data;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[DashboardAnalyticsService] Error: $e');
        print('[DashboardAnalyticsService] Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Check if cached snapshot exists and is not expired
  Future<DashboardData?> _getCachedSnapshot(String userId) async {
    try {
      final response = await _supabase
          .from('dashboard_snapshots')
          .select()
          .eq('user_id', userId)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      return _parseCachedSnapshot(response);
    } catch (e) {
      if (kDebugMode) {
        print('[DashboardAnalyticsService] Cache lookup failed: $e');
      }
      return null;
    }
  }

  /// Parse cached snapshot from database
  DashboardData _parseCachedSnapshot(Map<String, dynamic> json) {
    final loggedDates = List<String>.from(json['logged_dates'] ?? []);
    final sideEffectsData = Map<String, dynamic>.from(json['side_effects_data'] ?? {});
    final labCorrelationsData = List<dynamic>.from(json['lab_correlations'] ?? []);

    return DashboardData(
      compliance: ComplianceData(
        dosesLogged: json['total_doses_logged'] ?? 0,
        dosesScheduled: json['total_doses_scheduled'] ?? 0,
        percentage: (json['compliance_rate'] as num?)?.toDouble() ?? 0.0,
      ),
      topPeptide: json['top_peptide'] != null
          ? TopPeptideData(
              peptideName: json['top_peptide'],
              rating: (json['top_peptide_rating'] as num?)?.toDouble() ?? 0.0,
              cyclesUsed: 1,
            )
          : null,
      timeline: _buildTimelineFromDates(loggedDates),
      sideEffectsHeatmap: _parseSideEffectsHeatmap(sideEffectsData),
      labCorrelations: labCorrelationsData
          .map((item) => LabCorrelation(
                biomarker: item['biomarker'] ?? '',
                changePercent: (item['change'] as num?)?.toDouble() ?? 0.0,
                contributingPeptides: List<String>.from(item['peptides'] ?? []),
                isImprovement: ((item['change'] as num?)?.toDouble() ?? 0.0) > 0,
              ))
          .toList(),
      costEfficiency: json['monthly_cost'] != null
          ? CostEfficiencyData(
              monthlyTotal: (json['monthly_cost'] as num?)?.toDouble() ?? 0.0,
              costPerDose: (json['cost_per_dose'] as num?)?.toDouble() ?? 0.0,
              bestValuePeptide: json['best_value_peptide'],
              leastCostEffectivePeptide: json['least_cost_effective_peptide'],
            )
          : null,
      generatedAt: DateTime.parse(json['created_at']),
    );
  }

  /// Generate fresh dashboard data from database
  Future<DashboardData> _generateDashboardData(String userId) async {
    // Run all queries in parallel
    final results = await Future.wait([
      _calculateCompliance(userId),
      _findTopPeptide(userId),
      _build30DayTimeline(userId),
      _buildSideEffectsHeatmap(userId),
      _calculateLabCorrelations(userId),
      _calculateCostEfficiency(userId),
    ]);

    return DashboardData(
      compliance: results[0] as ComplianceData,
      topPeptide: results[1] as TopPeptideData?,
      timeline: results[2] as List<DoseTimelineDay>,
      sideEffectsHeatmap: results[3] as Map<String, Map<int, int>>,
      labCorrelations: results[4] as List<LabCorrelation>,
      costEfficiency: results[5] as CostEfficiencyData?,
      generatedAt: DateTime.now(),
    );
  }

  /// 1. Calculate compliance rate
  Future<ComplianceData> _calculateCompliance(String userId) async {
    try {
      // Get all dose logs in last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final logsResponse = await _supabase
          .from('dose_logs')
          .select('id')
          .eq('user_id', userId)
          .gte('logged_at', thirtyDaysAgo.toIso8601String());

      final dosesLogged = (logsResponse as List).length;

      // Get scheduled doses (estimate from active cycles)
      final cyclesResponse = await _supabase
          .from('cycles')
          .select('frequency, start_date, end_date')
          .eq('user_id', userId)
          .eq('is_active', true);

      int scheduledDoses = 0;
      for (final cycle in cyclesResponse as List) {
        final freq = cycle['frequency'] as String;
        scheduledDoses += _estimateScheduledDoses(freq, thirtyDaysAgo);
      }

      if (scheduledDoses == 0) scheduledDoses = 1; // Avoid division by zero

      final percentage = (dosesLogged / scheduledDoses * 100).clamp(0, 100).toDouble();

      return ComplianceData(
        dosesLogged: dosesLogged,
        dosesScheduled: scheduledDoses,
        percentage: percentage,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[DashboardAnalyticsService] Compliance calculation failed: $e');
      }
      return ComplianceData(dosesLogged: 0, dosesScheduled: 0, percentage: 0);
    }
  }

  /// Estimate scheduled doses based on frequency
  int _estimateScheduledDoses(String frequency, DateTime since) {
    final daysElapsed = DateTime.now().difference(since).inDays;

    if (frequency.contains('daily')) return daysElapsed;
    if (frequency.contains('2x weekly')) return (daysElapsed / 3.5).floor();
    if (frequency.contains('3x weekly')) return (daysElapsed / 2.33).floor();
    if (frequency.contains('weekly')) return (daysElapsed / 7).floor();
    if (frequency.contains('every 3 days')) return (daysElapsed / 3).floor();

    return daysElapsed; // Default: daily
  }

  /// 2. Find top-performing peptide
  Future<TopPeptideData?> _findTopPeptide(String userId) async {
    try {
      // Get all active cycles with dose counts
      final cyclesResponse = await _supabase
          .from('cycles')
          .select('id, peptide_name')
          .eq('user_id', userId)
          .eq('is_active', true);

      if ((cyclesResponse as List).isEmpty) return null;

      // Count logs per peptide
      final peptideScores = <String, int>{};
      for (final cycle in cyclesResponse) {
        final peptideName = cycle['peptide_name'] as String;
        final logsResponse = await _supabase
            .from('dose_logs')
            .select('id')
            .eq('cycle_id', cycle['id'])
            .limit(100);

        final logCount = (logsResponse as List).length;
        peptideScores[peptideName] = (peptideScores[peptideName] ?? 0) + logCount;
      }

      if (peptideScores.isEmpty) return null;

      // Find peptide with most logs (proxy for effectiveness)
      final topPeptide = peptideScores.entries.reduce((a, b) => a.value > b.value ? a : b);

      // Calculate rating (normalize to 10)
      final maxLogs = peptideScores.values.reduce(max);
      final rating = (topPeptide.value / maxLogs * 10).clamp(0, 10).toDouble();

      return TopPeptideData(
        peptideName: topPeptide.key,
        rating: rating,
        cyclesUsed: 1,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[DashboardAnalyticsService] Top peptide calculation failed: $e');
      }
      return null;
    }
  }

  /// 3. Build 30-day dose timeline
  Future<List<DoseTimelineDay>> _build30DayTimeline(String userId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      // Get all logs in last 30 days
      final logsResponse = await _supabase
          .from('dose_logs')
          .select('logged_at, cycle_id')
          .eq('user_id', userId)
          .gte('logged_at', thirtyDaysAgo.toIso8601String());

      // Get cycle names
      final cycleIds = (logsResponse as List).map((log) => log['cycle_id']).toSet();
      final cyclesMap = <String, String>{};

      if (cycleIds.isNotEmpty) {
        final cyclesResponse = await _supabase
            .from('cycles')
            .select('id, peptide_name')
            .inFilter('id', cycleIds.toList());

        for (final cycle in cyclesResponse as List) {
          cyclesMap[cycle['id']] = cycle['peptide_name'];
        }
      }

      // Build timeline
      final timeline = <DoseTimelineDay>[];
      final loggedDatesMap = <String, List<String>>{};

      for (final log in logsResponse) {
        final date = DateTime.parse(log['logged_at']);
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final peptide = cyclesMap[log['cycle_id']] ?? 'Unknown';

        if (!loggedDatesMap.containsKey(dateKey)) {
          loggedDatesMap[dateKey] = [];
        }
        if (!loggedDatesMap[dateKey]!.contains(peptide)) {
          loggedDatesMap[dateKey]!.add(peptide);
        }
      }

      // Generate all 30 days
      for (int i = 29; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        timeline.add(DoseTimelineDay(
          date: date,
          logged: loggedDatesMap.containsKey(dateKey),
          peptides: loggedDatesMap[dateKey] ?? [],
        ));
      }

      return timeline;
    } catch (e) {
      if (kDebugMode) {
        print('[DashboardAnalyticsService] Timeline build failed: $e');
      }
      return [];
    }
  }

  /// 4. Build side effects heatmap
  Future<Map<String, Map<int, int>>> _buildSideEffectsHeatmap(String userId) async {
    try {
      // Get all side effects
      final effectsResponse = await _supabase
          .from('side_effects_log')
          .select('cycle_id, severity')
          .eq('user_id', userId);

      if ((effectsResponse as List).isEmpty) return {};

      // Get cycle names
      final cycleIds = effectsResponse.map((e) => e['cycle_id']).toSet();
      final cyclesMap = <String, String>{};

      if (cycleIds.isNotEmpty) {
        final cyclesResponse = await _supabase
            .from('cycles')
            .select('id, peptide_name')
            .inFilter('id', cycleIds.toList());

        for (final cycle in cyclesResponse as List) {
          cyclesMap[cycle['id']] = cycle['peptide_name'];
        }
      }

      // Build heatmap: {peptide_name: {severity: count}}
      final heatmap = <String, Map<int, int>>{};

      for (final effect in effectsResponse) {
        final peptide = cyclesMap[effect['cycle_id']] ?? 'Unknown';
        final severity = (effect['severity'] as int).clamp(1, 5);

        if (!heatmap.containsKey(peptide)) {
          heatmap[peptide] = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
        }
        heatmap[peptide]![severity] = (heatmap[peptide]![severity] ?? 0) + 1;
      }

      return heatmap;
    } catch (e) {
      if (kDebugMode) {
        print('[DashboardAnalyticsService] Side effects heatmap failed: $e');
      }
      return {};
    }
  }

  /// 5. Calculate lab correlations
  Future<List<LabCorrelation>> _calculateLabCorrelations(String userId) async {
    try {
      // Get all lab results
      final labsResponse = await _supabase
          .from('labs_results')
          .select('biomarkers, upload_date, cycle_id')
          .eq('user_id', userId)
          .order('upload_date', ascending: false)
          .limit(10);

      if ((labsResponse as List).length < 2) return [];

      // Compare latest vs baseline
      final latest = labsResponse[0];
      final baseline = labsResponse[labsResponse.length - 1];

      final latestBiomarkers = Map<String, dynamic>.from(latest['biomarkers'] ?? {});
      final baselineBiomarkers = Map<String, dynamic>.from(baseline['biomarkers'] ?? {});

      final correlations = <LabCorrelation>[];

      // Get active peptides during this period
      final activePeptides = await _getActivePeptidesBetweenDates(
        userId,
        DateTime.parse(baseline['upload_date']),
        DateTime.parse(latest['upload_date']),
      );

      // Calculate changes for each biomarker
      for (final biomarker in latestBiomarkers.keys) {
        if (baselineBiomarkers.containsKey(biomarker)) {
          final latestValue = (latestBiomarkers[biomarker] as num?)?.toDouble();
          final baselineValue = (baselineBiomarkers[biomarker] as num?)?.toDouble();

          if (latestValue != null && baselineValue != null && baselineValue > 0) {
            final changePercent = ((latestValue - baselineValue) / baselineValue * 100);

            if (changePercent.abs() > 5) { // Only show significant changes
              correlations.add(LabCorrelation(
                biomarker: biomarker,
                changePercent: changePercent,
                contributingPeptides: activePeptides,
                isImprovement: changePercent > 0,
              ));
            }
          }
        }
      }

      // Sort by absolute change (most significant first)
      correlations.sort((a, b) => b.changePercent.abs().compareTo(a.changePercent.abs()));

      return correlations.take(3).toList();
    } catch (e) {
      if (kDebugMode) {
        print('[DashboardAnalyticsService] Lab correlations failed: $e');
      }
      return [];
    }
  }

  /// Get active peptides between two dates
  Future<List<String>> _getActivePeptidesBetweenDates(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase
          .from('cycles')
          .select('peptide_name')
          .eq('user_id', userId)
          .lte('start_date', endDate.toIso8601String())
          .gte('end_date', startDate.toIso8601String());

      return (response as List)
          .map((cycle) => cycle['peptide_name'] as String)
          .toSet()
          .toList();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[DashboardAnalyticsService] Failed to get active peptides: $e');
        print('[DashboardAnalyticsService] Stack trace: $stackTrace');
      }
      return [];
    }
  }

  /// 6. Calculate cost efficiency
  Future<CostEfficiencyData?> _calculateCostEfficiency(String userId) async {
    try {
      // Get cycle expenses (if table exists)
      final expensesResponse = await _supabase
          .from('cycle_expenses')
          .select('amount, cycle_id')
          .eq('user_id', userId);

      if ((expensesResponse as List).isEmpty) return null;

      double totalCost = 0;
      for (final expense in expensesResponse) {
        totalCost += (expense['amount'] as num?)?.toDouble() ?? 0;
      }

      // Get total logged doses
      final logsResponse = await _supabase
          .from('dose_logs')
          .select('id')
          .eq('user_id', userId);

      final totalDoses = (logsResponse as List).length;
      final costPerDose = totalDoses > 0 ? (totalCost / totalDoses).toDouble() : 0.0;

      // Monthly cost (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final monthlyExpensesResponse = await _supabase
          .from('cycle_expenses')
          .select('amount')
          .eq('user_id', userId)
          .gte('created_at', thirtyDaysAgo.toIso8601String());

      double monthlyTotal = 0;
      for (final expense in monthlyExpensesResponse as List) {
        monthlyTotal += (expense['amount'] as num?)?.toDouble() ?? 0;
      }

      return CostEfficiencyData(
        monthlyTotal: monthlyTotal,
        costPerDose: costPerDose,
        bestValuePeptide: null, // TODO: Calculate from cost per mg
        leastCostEffectivePeptide: null,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[DashboardAnalyticsService] Cost efficiency calculation failed: $e');
      }
      return null;
    }
  }

  /// Cache snapshot to database
  Future<void> _cacheSnapshot(String userId, DashboardData data) async {
    try {
      final loggedDates = data.timeline
          .where((day) => day.logged)
          .map((day) => '${day.date.year}-${day.date.month.toString().padLeft(2, '0')}-${day.date.day.toString().padLeft(2, '0')}')
          .toList();

      final sideEffectsData = <String, dynamic>{};
      data.sideEffectsHeatmap.forEach((peptide, severities) {
        sideEffectsData[peptide] = severities.map((k, v) => MapEntry('severity_$k', v));
      });

      final labCorrelationsData = data.labCorrelations.map((corr) => {
        'biomarker': corr.biomarker,
        'change': corr.changePercent,
        'peptides': corr.contributingPeptides,
      }).toList();

      await _supabase.from('dashboard_snapshots').insert({
        'user_id': userId,
        'compliance_rate': data.compliance.percentage,
        'total_doses_logged': data.compliance.dosesLogged,
        'total_doses_scheduled': data.compliance.dosesScheduled,
        'top_peptide': data.topPeptide?.peptideName,
        'top_peptide_rating': data.topPeptide?.rating,
        'side_effects_data': sideEffectsData,
        'lab_correlations': labCorrelationsData,
        'cost_per_dose': data.costEfficiency?.costPerDose,
        'monthly_cost': data.costEfficiency?.monthlyTotal,
        'best_value_peptide': data.costEfficiency?.bestValuePeptide,
        'least_cost_effective_peptide': data.costEfficiency?.leastCostEffectivePeptide,
        'logged_dates': loggedDates,
        'created_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('[DashboardAnalyticsService] Failed to cache snapshot: $e');
      }
    }
  }

  /// Parse side effects heatmap from JSONB
  Map<String, Map<int, int>> _parseSideEffectsHeatmap(Map<String, dynamic> data) {
    final heatmap = <String, Map<int, int>>{};

    data.forEach((peptide, severities) {
      final severityMap = <int, int>{};
      if (severities is Map) {
        severities.forEach((key, value) {
          if (key.toString().startsWith('severity_')) {
            final severity = int.tryParse(key.toString().replaceFirst('severity_', ''));
            if (severity != null) {
              severityMap[severity] = (value as num?)?.toInt() ?? 0;
            }
          }
        });
      }
      heatmap[peptide] = severityMap;
    });

    return heatmap;
  }

  /// Build timeline from logged dates
  List<DoseTimelineDay> _buildTimelineFromDates(List<String> loggedDates) {
    final timeline = <DoseTimelineDay>[];

    for (int i = 29; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      timeline.add(DoseTimelineDay(
        date: date,
        logged: loggedDates.contains(dateKey),
        peptides: [],
      ));
    }

    return timeline;
  }

  /// Force refresh (clear cache)
  Future<DashboardData> forceRefresh(String userId) async {
    try {
      // Delete old snapshots
      await _supabase
          .from('dashboard_snapshots')
          .delete()
          .eq('user_id', userId);

      return getDashboardData(userId);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[DashboardAnalyticsService] Force refresh failed: $e');
        print('[DashboardAnalyticsService] Stack trace: $stackTrace');
      }
      rethrow;
    }
  }
}

// Riverpod providers
final dashboardAnalyticsServiceProvider = Provider<DashboardAnalyticsService>((ref) {
  return DashboardAnalyticsService(Supabase.instance.client);
});

final dashboardDataProvider = FutureProvider.family<DashboardData, String>((ref, userId) async {
  final service = ref.watch(dashboardAnalyticsServiceProvider);
  return service.getDashboardData(userId);
});
