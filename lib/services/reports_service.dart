import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/cycle_review.dart';

class DoseTimelineData {
  final String peptideName;
  final List<DosePoint> points;
  final int colorIndex;

  DoseTimelineData({
    required this.peptideName,
    required this.points,
    required this.colorIndex,
  });
}

class DosePoint {
  final DateTime date;
  final double amount;
  final String? route;

  DosePoint({
    required this.date,
    required this.amount,
    this.route,
  });
}

class SideEffectHeatmapData {
  final DateTime date;
  final int maxSeverity;
  final List<String> symptoms;

  SideEffectHeatmapData({
    required this.date,
    required this.maxSeverity,
    required this.symptoms,
  });
}

class WeightPoint {
  final DateTime date;
  final double weight;
  final String? cycleId;
  final String? cycleName;

  WeightPoint({
    required this.date,
    required this.weight,
    this.cycleId,
    this.cycleName,
  });
}

class CycleLabCorrelation {
  final String labId;
  final DateTime labDate;
  final Map<String, dynamic> biomarkers;
  final List<CycleWindow> cycles;
  final List<DosePoint> doses;
  final List<WeightPoint> weights;

  CycleLabCorrelation({
    required this.labId,
    required this.labDate,
    required this.biomarkers,
    required this.cycles,
    required this.doses,
    required this.weights,
  });
}

class CycleWindow {
  final String cycleId;
  final String peptideName;
  final DateTime startDate;
  final DateTime endDate;
  final double dose;

  CycleWindow({
    required this.cycleId,
    required this.peptideName,
    required this.startDate,
    required this.endDate,
    required this.dose,
  });
}

class CycleEffectiveness {
  final String cycleId;
  final String cycleName;
  final DateTime startDate;
  final DateTime endDate;
  final int rating;
  final String? notes;

  CycleEffectiveness({
    required this.cycleId,
    required this.cycleName,
    required this.startDate,
    required this.endDate,
    required this.rating,
    this.notes,
  });
}

class AIInsight {
  final String title;
  final String message;
  final String icon;

  AIInsight({
    required this.title,
    required this.message,
    required this.icon,
  });
}

class ReportsService {
  final SupabaseClient supabase = Supabase.instance.client;

  // A. Dose Timeline - Get dose data grouped by peptide (last 90 days)
  Future<List<DoseTimelineData>> getDoseTimeline() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));

      // Get all dose logs from last 90 days with cycle info
      final response = await supabase
          .from('dose_logs')
          .select('*, cycles!inner(peptide_name)')
          .eq('user_id', user.id)
          .gte('logged_at', cutoffDate.toIso8601String())
          .order('logged_at');

      final logs = response as List;

      // Group by peptide
      final Map<String, List<DosePoint>> peptideGroups = {};
      
      for (var log in logs) {
        final peptideName = log['cycles']['peptide_name'] as String;
        if (!peptideGroups.containsKey(peptideName)) {
          peptideGroups[peptideName] = [];
        }

        peptideGroups[peptideName]!.add(DosePoint(
          date: DateTime.parse(log['logged_at']),
          amount: (log['dose_amount'] as num).toDouble(),
          route: log['route'],
        ));
      }

      // Convert to timeline data with color indices
      int colorIndex = 0;
      return peptideGroups.entries.map((entry) {
        return DoseTimelineData(
          peptideName: entry.key,
          points: entry.value,
          colorIndex: colorIndex++,
        );
      }).toList();
    } catch (e) {
      print('Error fetching dose timeline: $e');
      return [];
    }
  }

  // B. Side Effects Heatmap - Get max severity per day
  Future<List<SideEffectHeatmapData>> getSideEffectsHeatmap(
      DateTime startDate, DateTime endDate) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await supabase
          .from('side_effects_log')
          .select()
          .eq('user_id', user.id)
          .gte('logged_at', startDate.toIso8601String())
          .lte('logged_at', endDate.toIso8601String())
          .order('logged_at');

      final effects = response as List;

      // Group by date
      final Map<String, List<Map<String, dynamic>>> dateGroups = {};
      
      for (var effect in effects) {
        final date = DateTime.parse(effect['logged_at'])
            .toIso8601String()
            .split('T')[0];
        if (!dateGroups.containsKey(date)) {
          dateGroups[date] = [];
        }
        dateGroups[date]!.add(effect);
      }

      // Calculate max severity and symptoms per day
      return dateGroups.entries.map((entry) {
        final dayEffects = entry.value;
        final maxSeverity = dayEffects
            .map((e) => e['severity'] as int)
            .reduce((a, b) => a > b ? a : b);
        final symptoms = dayEffects
            .map((e) => e['symptom'] as String)
            .toList();

        return SideEffectHeatmapData(
          date: DateTime.parse(entry.key),
          maxSeverity: maxSeverity,
          symptoms: symptoms,
        );
      }).toList();
    } catch (e) {
      print('Error fetching side effects heatmap: $e');
      return [];
    }
  }

  // C. Weight Trends - Get weight history with cycle overlays (last 6 months)
  Future<List<WeightPoint>> getWeightTrends() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final cutoffDate = DateTime.now().subtract(const Duration(days: 180));

      final response = await supabase
          .from('weight_logs')
          .select()
          .eq('user_id', user.id)
          .gte('logged_at', cutoffDate.toIso8601String())
          .order('logged_at');

      final logs = response as List;

      // Get active cycles during this period to associate weight with cycles
      final cyclesResponse = await supabase
          .from('cycles')
          .select()
          .eq('user_id', user.id)
          .gte('end_date', cutoffDate.toIso8601String());

      final cycles = cyclesResponse as List;

      return logs.map((log) {
        final logDate = DateTime.parse(log['logged_at']);
        
        // Find if weight was logged during a cycle
        String? cycleId;
        String? cycleName;
        for (var cycle in cycles) {
          final startDate = DateTime.parse(cycle['start_date']);
          final endDate = DateTime.parse(cycle['end_date']);
          if (logDate.isAfter(startDate) && logDate.isBefore(endDate)) {
            cycleId = cycle['id'];
            cycleName = cycle['peptide_name'];
            break;
          }
        }

        return WeightPoint(
          date: logDate,
          weight: (log['weight_lbs'] as num).toDouble(),
          cycleId: cycleId,
          cycleName: cycleName,
        );
      }).toList();
    } catch (e) {
      print('Error fetching weight trends: $e');
      return [];
    }
  }

  // Get cycles for weight chart overlay
  Future<List<CycleWindow>> getCyclesForPeriod(
      DateTime startDate, DateTime endDate) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await supabase
          .from('cycles')
          .select()
          .eq('user_id', user.id)
          .gte('end_date', startDate.toIso8601String())
          .lte('start_date', endDate.toIso8601String());

      final cycles = response as List;

      return cycles.map((cycle) {
        return CycleWindow(
          cycleId: cycle['id'],
          peptideName: cycle['peptide_name'],
          startDate: DateTime.parse(cycle['start_date']),
          endDate: DateTime.parse(cycle['end_date']),
          dose: (cycle['dose'] as num).toDouble(),
        );
      }).toList();
    } catch (e) {
      print('Error fetching cycles: $e');
      return [];
    }
  }

  // D. Cycle-Lab Correlation - Get lab results with 90-day context
  Future<List<CycleLabCorrelation>> getCycleLabCorrelation() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get all lab results
      final labsResponse = await supabase
          .from('labs_results')
          .select()
          .eq('user_id', user.id)
          .order('upload_date', ascending: false);

      final labs = labsResponse as List;
      final List<CycleLabCorrelation> correlations = [];

      for (var lab in labs) {
        final labDate = DateTime.parse(lab['upload_date']);
        final windowStart = labDate.subtract(const Duration(days: 90));

        // Get cycles in 90-day window
        final cyclesResponse = await supabase
            .from('cycles')
            .select()
            .eq('user_id', user.id)
            .gte('end_date', windowStart.toIso8601String())
            .lte('start_date', labDate.toIso8601String());

        final cycles = (cyclesResponse as List).map((c) => CycleWindow(
          cycleId: c['id'],
          peptideName: c['peptide_name'],
          startDate: DateTime.parse(c['start_date']),
          endDate: DateTime.parse(c['end_date']),
          dose: (c['dose'] as num).toDouble(),
        )).toList();

        // Get doses in 90-day window
        final dosesResponse = await supabase
            .from('dose_logs')
            .select('*, cycles!inner(peptide_name)')
            .eq('user_id', user.id)
            .gte('logged_at', windowStart.toIso8601String())
            .lte('logged_at', labDate.toIso8601String())
            .order('logged_at');

        final doses = (dosesResponse as List).map((d) => DosePoint(
          date: DateTime.parse(d['logged_at']),
          amount: (d['dose_amount'] as num).toDouble(),
          route: d['route'],
        )).toList();

        // Get weights in 90-day window
        final weightsResponse = await supabase
            .from('weight_logs')
            .select()
            .eq('user_id', user.id)
            .gte('logged_at', windowStart.toIso8601String())
            .lte('logged_at', labDate.toIso8601String())
            .order('logged_at');

        final weights = (weightsResponse as List).map((w) => WeightPoint(
          date: DateTime.parse(w['logged_at']),
          weight: (w['weight_lbs'] as num).toDouble(),
        )).toList();

        correlations.add(CycleLabCorrelation(
          labId: lab['id'],
          labDate: labDate,
          biomarkers: lab['extracted_data'] ?? {},
          cycles: cycles,
          doses: doses,
          weights: weights,
        ));
      }

      return correlations;
    } catch (e) {
      print('Error fetching cycle-lab correlation: $e');
      return [];
    }
  }

  // E. Effectiveness Ratings - Get cycle reviews
  Future<List<CycleEffectiveness>> getCycleEffectiveness() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await supabase
          .from('cycle_reviews')
          .select('*, cycles!inner(*)')
          .eq('user_id', user.id)
          .order('cycles(start_date)', ascending: false);

      final reviews = response as List;

      return reviews.map((review) {
        final cycle = review['cycles'];
        return CycleEffectiveness(
          cycleId: cycle['id'],
          cycleName: cycle['peptide_name'],
          startDate: DateTime.parse(cycle['start_date']),
          endDate: DateTime.parse(cycle['end_date']),
          rating: review['effectiveness_rating'] as int,
          notes: review['notes'],
        );
      }).toList();
    } catch (e) {
      print('Error fetching cycle effectiveness: $e');
      return [];
    }
  }

  // Save or update cycle review
  Future<CycleReview?> saveCycleReview({
    required String cycleId,
    required int effectivenessRating,
    String? notes,
    String? existingReviewId,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      if (existingReviewId != null) {
        // Update existing review
        final response = await supabase
            .from('cycle_reviews')
            .update({
              'effectiveness_rating': effectivenessRating,
              'notes': notes,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingReviewId)
            .eq('user_id', user.id)
            .select()
            .single();

        return CycleReview.fromJson(response);
      } else {
        // Create new review
        final response = await supabase
            .from('cycle_reviews')
            .insert({
              'user_id': user.id,
              'cycle_id': cycleId,
              'effectiveness_rating': effectivenessRating,
              'notes': notes,
            })
            .select()
            .single();

        return CycleReview.fromJson(response);
      }
    } catch (e) {
      print('Error saving cycle review: $e');
      return null;
    }
  }

  // F. AI Insights - Generate insights using Claude API
  Future<List<AIInsight>> generateAIInsights() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Gather aggregate data
      final insights = <AIInsight>[];

      // 1. Most consistent peptide
      final doseLogs = await supabase
          .from('dose_logs')
          .select('*, cycles!inner(peptide_name)')
          .eq('user_id', user.id)
          .gte('logged_at', DateTime.now().subtract(const Duration(days: 180)).toIso8601String());

      final logs = doseLogs as List;
      if (logs.isNotEmpty) {
        final peptideCounts = <String, int>{};
        for (var log in logs) {
          final peptide = log['cycles']['peptide_name'] as String;
          peptideCounts[peptide] = (peptideCounts[peptide] ?? 0) + 1;
        }

        final mostConsistent = peptideCounts.entries.reduce((a, b) => 
          a.value > b.value ? a : b);

        insights.add(AIInsight(
          title: 'Most Consistent',
          message: 'You\'ve been most consistent with ${mostConsistent.key} (${mostConsistent.value} doses logged)',
          icon: '🎯',
        ));
      }

      // 2. Weight change during best cycle
      final weightLogs = await supabase
          .from('weight_logs')
          .select()
          .eq('user_id', user.id)
          .order('logged_at');

      final weights = weightLogs as List;
      if (weights.length >= 2) {
        final firstWeight = (weights.first['weight_lbs'] as num).toDouble();
        final lastWeight = (weights.last['weight_lbs'] as num).toDouble();
        final change = lastWeight - firstWeight;

        insights.add(AIInsight(
          title: 'Weight Trend',
          message: change >= 0 
              ? 'Weight increased by ${change.abs().toStringAsFixed(1)} lbs'
              : 'Weight decreased by ${change.abs().toStringAsFixed(1)} lbs',
          icon: change >= 0 ? '📈' : '📉',
        ));
      }

      // 3. Most common side effect
      final sideEffects = await supabase
          .from('side_effects_log')
          .select()
          .eq('user_id', user.id);

      final effects = sideEffects as List;
      if (effects.isNotEmpty) {
        final symptomCounts = <String, int>{};
        for (var effect in effects) {
          final symptom = effect['symptom'] as String;
          symptomCounts[symptom] = (symptomCounts[symptom] ?? 0) + 1;
        }

        final mostCommon = symptomCounts.entries.reduce((a, b) => 
          a.value > b.value ? a : b);

        insights.add(AIInsight(
          title: 'Side Effects',
          message: 'Most common: ${mostCommon.key} (${mostCommon.value} occurrences)',
          icon: '⚠️',
        ));
      }

      // 4. Lab improvement
      final labResults = await supabase
          .from('labs_results')
          .select()
          .eq('user_id', user.id)
          .order('upload_date', ascending: false)
          .limit(2);

      final labs = labResults as List;
      if (labs.length >= 2) {
        final recent = labs[0]['extracted_data'];
        final previous = labs[1]['extracted_data'];

        if (recent['testosterone'] != null && previous['testosterone'] != null) {
          final recentT = _extractValue(recent['testosterone']);
          final previousT = _extractValue(previous['testosterone']);
          
          if (recentT != null && previousT != null && previousT > 0) {
            final change = ((recentT - previousT) / previousT * 100);
            
            insights.add(AIInsight(
              title: 'Testosterone',
              message: change >= 0
                  ? 'Improved by ${change.toStringAsFixed(1)}% since last lab'
                  : 'Decreased by ${change.abs().toStringAsFixed(1)}% since last lab',
              icon: change >= 0 ? '💪' : '📊',
            ));
          }
        }
      }

      // 5. Recommendation
      insights.add(AIInsight(
        title: 'Recommendation',
        message: 'Keep logging consistently to unlock deeper insights and personalized recommendations',
        icon: '💡',
      ));

      return insights;
    } catch (e) {
      print('Error generating AI insights: $e');
      return [];
    }
  }

  double? _extractValue(dynamic data) {
    if (data is Map) {
      return (data['value'] as num?)?.toDouble();
    }
    return (data as num?)?.toDouble();
  }
}
