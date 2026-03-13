import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../services/dashboard_insights_service.dart';

class InsightsScreen extends ConsumerWidget {
  final String cycleId; // Pass cycleId from cycles screen

  const InsightsScreen({Key? key, required this.cycleId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(dashboardSnapshotProvider(cycleId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'CYCLE INSIGHTS',
          style: WintermmuteStyles.titleStyle.copyWith(fontSize: 18),
        ),
        centerTitle: false,
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: snapshot.when(
        data: (data) {
          if (data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No insights yet',
                    style: WintermmuteStyles.headerStyle,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Complete doses to generate analytics',
                    style: WintermmuteStyles.bodyStyle.copyWith(
                      color: AppColors.textMid,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Adherence %
                _AdherenceCard(snapshot: data),
                const SizedBox(height: 20),

                // 2. Dose Timeline Heatmap
                _DoseTimelineCard(snapshot: data),
                const SizedBox(height: 20),

                // 3. Peptide Effectiveness
                _EffectivenessCard(snapshot: data),
                const SizedBox(height: 20),

                // 4. Side Effects Trend
                _SideEffectsCard(snapshot: data),
                const SizedBox(height: 20),

                // 5. Weight Change
                _WeightChangeCard(snapshot: data),
                const SizedBox(height: 20),

                // 6. Cost Analysis
                _CostAnalysisCard(snapshot: data),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error: $err', style: WintermmuteStyles.bodyStyle),
        ),
      ),
    );
  }
}

// 1. Adherence Card
class _AdherenceCard extends StatelessWidget {
  final DashboardSnapshot snapshot;

  const _AdherenceCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final adherence = snapshot.adherencePercent ?? 0.0;
    final barWidth = (adherence / 100) * 250;
    final barColor = adherence >= 80
        ? AppColors.accent // Green
        : adherence >= 60
            ? Color(0xFFFFA500) // Orange
            : Color(0xFFFF0040); // Red

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ADHERENCE THIS CYCLE',
            style: WintermmuteStyles.headerStyle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${adherence.toStringAsFixed(1)}%',
                      style: WintermmuteStyles.headerStyle.copyWith(
                        color: barColor,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.totalDosesLogged}/${snapshot.totalDosesScheduled} doses',
                      style: WintermmuteStyles.bodyStyle.copyWith(
                        color: AppColors.textMid,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Container(
                height: 60,
                width: barWidth.clamp(10, 250),
                decoration: BoxDecoration(
                  color: barColor.withOpacity(0.3),
                  border: Border.all(color: barColor),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 2. Dose Timeline Card (Simple heatmap preview)
class _DoseTimelineCard extends StatelessWidget {
  final DashboardSnapshot snapshot;

  const _DoseTimelineCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final loggedDates = snapshot.loggedDates;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DOSE TIMELINE',
            style: WintermmuteStyles.headerStyle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(14, (i) {
              final date = DateTime.now().subtract(Duration(days: 13 - i));
              final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              final isLogged = loggedDates.contains(dateStr);

              return Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isLogged ? AppColors.accent : AppColors.background,
                  border: Border.all(
                    color: isLogged ? AppColors.accent : AppColors.border,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isLogged
                    ? Center(
                        child: Text(
                          '✓',
                          style: TextStyle(color: AppColors.background, fontWeight: FontWeight.bold),
                        ),
                      )
                    : null,
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            '${loggedDates.length} days logged in last 14 days',
            style: WintermmuteStyles.tinyStyle.copyWith(color: AppColors.textMid),
          ),
        ],
      ),
    );
  }
}

// 3. Effectiveness Card
class _EffectivenessCard extends StatelessWidget {
  final DashboardSnapshot snapshot;

  const _EffectivenessCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final scores = snapshot.effectivenessScores ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PEPTIDE EFFECTIVENESS',
            style: WintermmuteStyles.headerStyle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 16),
          if (scores.isEmpty)
            Text(
              'Rate effectiveness on cycle completion',
              style: WintermmuteStyles.bodyStyle.copyWith(color: AppColors.textMid),
            )
          else
            Column(
              children: scores.entries.map((e) {
                final name = e.key;
                final score = (e.value as num).toDouble();
                final width = (score / 10) * 180;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name.toUpperCase(),
                          style: WintermmuteStyles.tinyStyle.copyWith(
                            color: AppColors.textMid,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          score.toStringAsFixed(1),
                          style: WintermmuteStyles.tinyStyle.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 6,
                      width: width.clamp(10, 180),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// 4. Side Effects Card
class _SideEffectsCard extends StatelessWidget {
  final DashboardSnapshot snapshot;

  const _SideEffectsCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final count = snapshot.sideEffectsCount;
    final avgSeverity = snapshot.sideEffectsAvgSeverity ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SIDE EFFECTS SUMMARY',
            style: WintermmuteStyles.headerStyle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    count.toString(),
                    style: WintermmuteStyles.headerStyle.copyWith(
                      color: AppColors.accent,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'logged',
                    style: WintermmuteStyles.tinyStyle.copyWith(color: AppColors.textMid),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    avgSeverity.toStringAsFixed(1),
                    style: WintermmuteStyles.headerStyle.copyWith(
                      color: avgSeverity > 5 ? Color(0xFFFF0040) : AppColors.textMid,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'avg severity',
                    style: WintermmuteStyles.tinyStyle.copyWith(color: AppColors.textMid),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 5. Weight Change Card
class _WeightChangeCard extends StatelessWidget {
  final DashboardSnapshot snapshot;

  const _WeightChangeCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final weightChange = snapshot.weightChangeLbs ?? 0.0;
    final bodyFatChange = snapshot.bodyFatChangePercent ?? 0.0;
    final isGain = weightChange > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BODY COMPOSITION',
            style: WintermmuteStyles.headerStyle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '${isGain ? '+' : ''}${weightChange.toStringAsFixed(1)} lbs',
                    style: WintermmuteStyles.headerStyle.copyWith(
                      color: isGain ? Color(0xFFFF0040) : AppColors.accent,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'weight change',
                    style: WintermmuteStyles.tinyStyle.copyWith(color: AppColors.textMid),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    '${bodyFatChange > 0 ? '+' : ''}${bodyFatChange.toStringAsFixed(1)}%',
                    style: WintermmuteStyles.headerStyle.copyWith(
                      color: bodyFatChange < 0 ? AppColors.accent : Color(0xFFFF0040),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'body fat %',
                    style: WintermmuteStyles.tinyStyle.copyWith(color: AppColors.textMid),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 6. Cost Analysis Card
class _CostAnalysisCard extends StatelessWidget {
  final DashboardSnapshot snapshot;

  const _CostAnalysisCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final total = snapshot.costTotal;
    final perDose = snapshot.costPerDose ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COST ANALYSIS',
            style: WintermmuteStyles.headerStyle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: WintermmuteStyles.headerStyle.copyWith(
                      color: AppColors.primary,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'total spent',
                    style: WintermmuteStyles.tinyStyle.copyWith(color: AppColors.textMid),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    '\$${perDose.toStringAsFixed(2)}',
                    style: WintermmuteStyles.headerStyle.copyWith(
                      color: AppColors.accent,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'per dose',
                    style: WintermmuteStyles.tinyStyle.copyWith(color: AppColors.textMid),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
