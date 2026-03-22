import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../services/dashboard_insights_service.dart';
import '../widgets/city_background.dart';
import '../widgets/cyberpunk_rain.dart';

// Shared section card builder - profile page aesthetic
Widget _buildInsightSection({
  required String title,
  required IconData icon,
  required Color accentColor,
  required Widget child,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF0A0A0A).withOpacity(0.85),
      border: Border.all(color: accentColor.withOpacity(0.25), width: 1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 3, height: 14, color: accentColor),
            const SizedBox(width: 8),
            Icon(icon, color: accentColor, size: 14),
            const SizedBox(width: 8),
            Text(
              '> $title',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: accentColor,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}

class InsightsScreen extends ConsumerWidget {
  final String cycleId;

  const InsightsScreen({Key? key, required this.cycleId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(dashboardSnapshotProvider(cycleId));

    return SafeArea(
      child: Stack(
        children: [
          const Positioned.fill(
            child: CityBackground(enabled: true, animateLights: true, opacity: 0.3),
          ),
          const Positioned.fill(
            child: CyberpunkRain(enabled: true, particleCount: 40, opacity: 0.25),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: const Color(0xFF000000),
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.primary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: Row(
                children: [
                  Container(width: 3, height: 18, color: AppColors.secondary),
                  const SizedBox(width: 10),
                  Text(
                    '> CYCLE INSIGHTS',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: AppColors.secondary.withOpacity(0.3),
                ),
              ),
            ),
            body: Stack(
              children: [
                snapshot.when(
                  data: (data) {
                    if (data == null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.analytics_outlined, color: AppColors.textDim, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              '[ NO INTEL AVAILABLE ]',
                              style: TextStyle(
                                color: AppColors.textDim,
                                fontFamily: 'monospace',
                                fontSize: 12,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Complete doses to generate analytics',
                              style: TextStyle(
                                color: AppColors.textDim.withOpacity(0.6),
                                fontFamily: 'monospace',
                                fontSize: 10,
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
                          _AdherenceCard(snapshot: data),
                          const SizedBox(height: 12),
                          _DoseTimelineCard(snapshot: data),
                          const SizedBox(height: 12),
                          _EffectivenessCard(snapshot: data),
                          const SizedBox(height: 12),
                          _SideEffectsCard(snapshot: data),
                          const SizedBox(height: 12),
                          _WeightChangeCard(snapshot: data),
                          const SizedBox(height: 12),
                          _CostAnalysisCard(snapshot: data),
                          const SizedBox(height: 12),
                        ],
                      ),
                    );
                  },
                  loading: () => Center(
                    child: CircularProgressIndicator(color: AppColors.secondary),
                  ),
                  error: (err, stack) => Center(
                    child: Text(
                      'Error: $err',
                      style: TextStyle(color: AppColors.error, fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ),
                // Scanlines overlay
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _ScanlinesPainter()),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final barColor = adherence >= 80
        ? AppColors.accent
        : adherence >= 60
            ? const Color(0xFFFFA500)
            : AppColors.error;

    return _buildInsightSection(
      title: 'ADHERENCE THIS CYCLE',
      icon: Icons.track_changes,
      accentColor: AppColors.primary,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${adherence.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: barColor,
                    fontSize: 32,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${snapshot.totalDosesLogged}/${snapshot.totalDosesScheduled} doses',
                  style: TextStyle(
                    color: AppColors.textMid,
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Bar visualization
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                height: 48,
                width: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF000000),
                  border: Border.all(color: barColor.withOpacity(0.3), width: 1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: (adherence / 100).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColor.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 2. Dose Timeline Card
class _DoseTimelineCard extends StatelessWidget {
  final DashboardSnapshot snapshot;

  const _DoseTimelineCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final loggedDates = snapshot.loggedDates;

    return _buildInsightSection(
      title: 'DOSE TIMELINE',
      icon: Icons.grid_on,
      accentColor: AppColors.amber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(14, (i) {
              final date = DateTime.now().subtract(Duration(days: 13 - i));
              final dateStr =
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              final isLogged = loggedDates.contains(dateStr);

              return Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isLogged
                      ? AppColors.amber.withOpacity(0.4)
                      : const Color(0xFF000000),
                  border: Border.all(
                    color: isLogged
                        ? AppColors.amber.withOpacity(0.7)
                        : AppColors.amber.withOpacity(0.15),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: isLogged
                    ? Center(
                        child: Text(
                          '✓',
                          style: TextStyle(
                            color: AppColors.amber,
                            fontFamily: 'monospace',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            '${loggedDates.length}/14 days logged',
            style: TextStyle(
              color: AppColors.amber.withOpacity(0.6),
              fontFamily: 'monospace',
              fontSize: 10,
              letterSpacing: 1,
            ),
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

    return _buildInsightSection(
      title: 'PEPTIDE EFFECTIVENESS',
      icon: Icons.science,
      accentColor: AppColors.secondary,
      child: scores.isEmpty
          ? Text(
              '[ RATE EFFECTIVENESS ON CYCLE COMPLETION ]',
              style: TextStyle(
                color: AppColors.textDim,
                fontFamily: 'monospace',
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            )
          : Column(
              children: scores.entries.map((e) {
                final name = e.key;
                final score = (e.value as num).toDouble();
                final widthFactor = (score / 10).clamp(0.0, 1.0);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            name.toUpperCase(),
                            style: TextStyle(
                              color: AppColors.textMid,
                              fontFamily: 'monospace',
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            score.toStringAsFixed(1),
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: widthFactor,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
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

    return _buildInsightSection(
      title: 'SIDE EFFECTS SUMMARY',
      icon: Icons.warning_amber,
      accentColor: AppColors.error,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 28,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'LOGGED',
                style: TextStyle(
                  color: AppColors.textDim,
                  fontFamily: 'monospace',
                  fontSize: 9,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          Container(width: 1, height: 40, color: AppColors.error.withOpacity(0.3)),
          Column(
            children: [
              Text(
                avgSeverity.toStringAsFixed(1),
                style: TextStyle(
                  color: avgSeverity > 5 ? AppColors.error : AppColors.textMid,
                  fontSize: 28,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'AVG SEVERITY',
                style: TextStyle(
                  color: AppColors.textDim,
                  fontFamily: 'monospace',
                  fontSize: 9,
                  letterSpacing: 1,
                ),
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

    return _buildInsightSection(
      title: 'BODY COMPOSITION',
      icon: Icons.monitor_weight,
      accentColor: AppColors.accent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                '${isGain ? '+' : ''}${weightChange.toStringAsFixed(1)}',
                style: TextStyle(
                  color: isGain ? AppColors.error : AppColors.accent,
                  fontSize: 24,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'LBS CHANGE',
                style: TextStyle(
                  color: AppColors.textDim,
                  fontFamily: 'monospace',
                  fontSize: 9,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          Container(width: 1, height: 40, color: AppColors.accent.withOpacity(0.3)),
          Column(
            children: [
              Text(
                '${bodyFatChange > 0 ? '+' : ''}${bodyFatChange.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: bodyFatChange < 0 ? AppColors.accent : AppColors.error,
                  fontSize: 24,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'BODY FAT %',
                style: TextStyle(
                  color: AppColors.textDim,
                  fontFamily: 'monospace',
                  fontSize: 9,
                  letterSpacing: 1,
                ),
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

    return _buildInsightSection(
      title: 'COST ANALYSIS',
      icon: Icons.attach_money,
      accentColor: AppColors.primary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'TOTAL SPENT',
                style: TextStyle(
                  color: AppColors.textDim,
                  fontFamily: 'monospace',
                  fontSize: 9,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          Container(width: 1, height: 40, color: AppColors.primary.withOpacity(0.3)),
          Column(
            children: [
              Text(
                '\$${perDose.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 24,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'PER DOSE',
                style: TextStyle(
                  color: AppColors.textDim,
                  fontFamily: 'monospace',
                  fontSize: 9,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.04)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
