import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../services/dashboard_analytics_service.dart';
import '../main.dart' show authProviderProvider;

class DashboardInsightsScreen extends ConsumerStatefulWidget {
  const DashboardInsightsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardInsightsScreen> createState() => _DashboardInsightsScreenState();
}

class _DashboardInsightsScreenState extends ConsumerState<DashboardInsightsScreen> {
  bool _isRefreshing = false;

  Future<void> _forceRefresh() async {
    setState(() => _isRefreshing = true);

    final userId = ref.read(authProviderProvider).user?.id;
    if (userId != null) {
      final service = ref.read(dashboardAnalyticsServiceProvider);
      await service.forceRefresh(userId);

      // Refresh provider
      ref.invalidate(dashboardDataProvider(userId));
    }

    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authProviderProvider).user?.id;

    if (userId == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Please log in to view insights',
            style: TextStyle(color: AppColors.textLight),
          ),
        ),
      );
    }

    final dashboardData = ref.watch(dashboardDataProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'DASHBOARD INSIGHTS',
          style: WintermmuteStyles.headerStyle.copyWith(fontSize: 16),
        ),
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              onPressed: _forceRefresh,
            ),
        ],
      ),
      body: dashboardData.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading dashboard',
                style: WintermmuteStyles.bodyStyle.copyWith(color: AppColors.error),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: WintermmuteStyles.tinyStyle.copyWith(color: AppColors.textMid),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        data: (data) {
          // Check for empty states
          if (data.compliance.dosesLogged == 0 &&
              data.topPeptide == null &&
              data.timeline.isEmpty) {
            return _buildEmptyState();
          }

          return _buildDashboardContent(data);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 80,
              color: AppColors.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'NO DATA YET',
              style: WintermmuteStyles.headerStyle.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Complete your first week to see insights',
              style: WintermmuteStyles.bodyStyle.copyWith(
                color: AppColors.textMid,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildEmptyStateAction('Create a cycle', Icons.add_circle_outline),
            const SizedBox(height: 12),
            _buildEmptyStateAction('Log your first dose', Icons.medication_outlined),
            const SizedBox(height: 12),
            _buildEmptyStateAction('Upload labs', Icons.science_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateAction(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: WintermmuteStyles.bodyStyle.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(DashboardData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Compliance Ring + Top Peptide
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildComplianceRing(data.compliance),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildTopPeptideCard(data.topPeptide),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 30-Day Timeline
          _buildSectionHeader('30-DAY DOSE TIMELINE'),
          const SizedBox(height: 12),
          _build30DayTimeline(data.timeline),
          const SizedBox(height: 24),

          // Side Effects Heatmap
          _buildSectionHeader('SIDE EFFECTS HEATMAP'),
          const SizedBox(height: 12),
          _buildSideEffectsHeatmap(data.sideEffectsHeatmap),
          const SizedBox(height: 24),

          // Lab Correlations
          _buildSectionHeader('LAB CORRELATIONS'),
          const SizedBox(height: 12),
          _buildLabCorrelations(data.labCorrelations),
          const SizedBox(height: 24),

          // Cost Efficiency
          if (data.costEfficiency != null) ...[
            _buildSectionHeader('COST EFFICIENCY'),
            const SizedBox(height: 12),
            _buildCostEfficiency(data.costEfficiency!),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: WintermmuteStyles.headerStyle.copyWith(
        fontSize: 14,
        color: AppColors.primary,
        letterSpacing: 1,
      ),
    );
  }

  // 1. COMPLIANCE RING
  Widget _buildComplianceRing(ComplianceData compliance) {
    final percentage = compliance.percentage;
    final color = _getComplianceColor(percentage);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _glowingCardDecoration(color),
      child: Column(
        children: [
          Text(
            'COMPLIANCE',
            style: WintermmuteStyles.smallStyle.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progress ring
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: percentage / 100,
                    strokeWidth: 12,
                    backgroundColor: AppColors.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                // Center text
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${percentage.toInt()}%',
                      style: WintermmuteStyles.titleStyle.copyWith(
                        fontSize: 48,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${compliance.dosesLogged}/${compliance.dosesScheduled} doses',
                      style: WintermmuteStyles.smallStyle.copyWith(
                        color: AppColors.textMid,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getComplianceColor(double percentage) {
    if (percentage >= 66) return AppColors.accent;
    if (percentage >= 33) return Colors.orange;
    return AppColors.error;
  }

  BoxDecoration _glowingCardDecoration(Color glowColor) {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: glowColor.withOpacity(0.3)),
      boxShadow: [
        BoxShadow(
          color: glowColor.withOpacity(0.1),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }

  // 2. TOP PEPTIDE CARD
  Widget _buildTopPeptideCard(TopPeptideData? topPeptide) {
    if (topPeptide == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            'NO DATA',
            style: WintermmuteStyles.smallStyle.copyWith(
              color: AppColors.textMid,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _glowingCardDecoration(AppColors.accent),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'TOP PEPTIDE',
            style: WintermmuteStyles.tinyStyle.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            topPeptide.peptideName,
            style: WintermmuteStyles.bodyStyle.copyWith(
              color: AppColors.textLight,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${topPeptide.rating.toStringAsFixed(1)}/10',
            style: WintermmuteStyles.headerStyle.copyWith(
              color: AppColors.accent,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Icon(
                index < (topPeptide.rating / 2).floor()
                    ? Icons.star
                    : Icons.star_border,
                color: AppColors.accent,
                size: 16,
              );
            }),
          ),
        ],
      ),
    );
  }

  // 3. 30-DAY TIMELINE
  Widget _build30DayTimeline(List<DoseTimelineDay> timeline) {
    if (timeline.isEmpty) {
      return _buildEmptyCard('No dose history');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Week labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                .map((day) => Text(
                      day,
                      style: WintermmuteStyles.tinyStyle.copyWith(
                        color: AppColors.textMid,
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          // Grid of days
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: timeline.length,
            itemBuilder: (context, index) {
              final day = timeline[index];
              return _buildTimelineDay(day);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineDay(DoseTimelineDay day) {
    final color = day.logged ? AppColors.accent : AppColors.surface;
    final borderColor = day.logged
        ? AppColors.accent.withOpacity(0.5)
        : AppColors.primary.withOpacity(0.2);

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(day.logged ? 0.3 : 1),
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: Text(
          '${day.date.day}',
          style: WintermmuteStyles.tinyStyle.copyWith(
            color: day.logged ? AppColors.accent : AppColors.textMid,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  // 4. SIDE EFFECTS HEATMAP
  Widget _buildSideEffectsHeatmap(Map<String, Map<int, int>> heatmap) {
    if (heatmap.isEmpty) {
      return _buildEmptyCard('No side effects logged');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const SizedBox(width: 100), // Peptide name space
              ...List.generate(5, (i) {
                return Expanded(
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: WintermmuteStyles.tinyStyle.copyWith(
                        color: AppColors.textMid,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.primary, height: 1),
          const SizedBox(height: 8),
          // Heatmap rows
          ...heatmap.entries.map((entry) {
            final peptide = entry.key;
            final severities = entry.value;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      peptide,
                      style: WintermmuteStyles.tinyStyle.copyWith(
                        color: AppColors.textLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ...List.generate(5, (i) {
                    final count = severities[i + 1] ?? 0;
                    final maxCount = severities.values.reduce(math.max);
                    final intensity = maxCount > 0 ? count / maxCount : 0.0;

                    return Expanded(
                      child: Container(
                        height: 30,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(intensity * 0.8),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Center(
                          child: Text(
                            count > 0 ? '$count' : '',
                            style: WintermmuteStyles.tinyStyle.copyWith(
                              color: AppColors.textLight,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // 5. LAB CORRELATIONS
  Widget _buildLabCorrelations(List<LabCorrelation> correlations) {
    if (correlations.isEmpty) {
      return _buildEmptyCard('Upload lab results to see correlations');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Which peptides moved your labs?',
            style: WintermmuteStyles.smallStyle.copyWith(
              color: AppColors.textMid,
            ),
          ),
          const SizedBox(height: 16),
          ...correlations.map((corr) {
            final color = corr.isImprovement ? AppColors.accent : AppColors.error;
            final arrow = corr.isImprovement ? '↑' : '↓';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      corr.biomarker,
                      style: WintermmuteStyles.bodyStyle.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                  Text(
                    '$arrow ${corr.changePercent.abs().toStringAsFixed(1)}%',
                    style: WintermmuteStyles.bodyStyle.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '(${corr.contributingPeptides.join(', ')})',
                      style: WintermmuteStyles.tinyStyle.copyWith(
                        color: AppColors.textMid,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // 6. COST EFFICIENCY
  Widget _buildCostEfficiency(CostEfficiencyData cost) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$/Month:',
                style: WintermmuteStyles.bodyStyle.copyWith(
                  color: AppColors.textMid,
                ),
              ),
              Text(
                '\$${cost.monthlyTotal.toStringAsFixed(2)}',
                style: WintermmuteStyles.headerStyle.copyWith(
                  color: AppColors.secondary,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cost per Dose Logged:',
                style: WintermmuteStyles.bodyStyle.copyWith(
                  color: AppColors.textMid,
                ),
              ),
              Text(
                '\$${cost.costPerDose.toStringAsFixed(2)}',
                style: WintermmuteStyles.bodyStyle.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          if (cost.bestValuePeptide != null) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.primary, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Best Value:',
                  style: WintermmuteStyles.smallStyle.copyWith(
                    color: AppColors.accent,
                  ),
                ),
                Text(
                  cost.bestValuePeptide!,
                  style: WintermmuteStyles.smallStyle.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          message,
          style: WintermmuteStyles.bodyStyle.copyWith(
            color: AppColors.textMid,
          ),
        ),
      ),
    );
  }
}
