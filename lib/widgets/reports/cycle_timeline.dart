import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/colors.dart';
import '../../services/reports_service.dart';

class CycleTimeline extends StatelessWidget {
  final List<CycleWindow> cycles;
  final List<LabResultWithContext> labs;

  const CycleTimeline({
    Key? key,
    required this.cycles,
    required this.labs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (cycles.isEmpty) {
      return _buildEmptyState();
    }

    // Sort cycles by start date descending
    final sortedCycles = List<CycleWindow>.from(cycles)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedCycles.length,
      itemBuilder: (context, index) {
        final cycle = sortedCycles[index];
        return _buildCycleSection(cycle, index);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timeline, size: 48, color: AppColors.textDim),
          const SizedBox(height: 16),
          const Text(
            'NO CYCLES TRACKED',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a peptide cycle to see correlations\nwith your lab results here',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 11,
              color: AppColors.textMid,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCycleSection(CycleWindow cycle, int index) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final isActive = cycle.endDate.isAfter(DateTime.now());
    final duration = cycle.endDate.difference(cycle.startDate).inDays;
    final color = _getPeptideColor(cycle.peptideName);

    // Find labs taken during this cycle (between start and end + 14 days grace)
    final gracePeriod = cycle.endDate.add(const Duration(days: 14));
    final labsDuringCycle = labs.where((lab) {
      return lab.labDate.isAfter(cycle.startDate) &&
          lab.labDate.isBefore(gracePeriod);
    }).toList();

    // Find labs before cycle (30 days before start)
    final preWindow = cycle.startDate.subtract(const Duration(days: 30));
    final labsBeforeCycle = labs.where((lab) {
      return lab.labDate.isAfter(preWindow) &&
          lab.labDate.isBefore(cycle.startDate);
    }).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cycle header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(
                color: isActive ? AppColors.accent : color.withOpacity(0.5),
                width: isActive ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.accent : color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cycle.peptideName.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${cycle.dose} mg',
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11,
                        color: AppColors.textMid,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (isActive ? AppColors.accent : const Color(0xFFFFAA00))
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        isActive ? 'ACTIVE' : 'COMPLETED',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? AppColors.accent
                              : const Color(0xFFFFAA00),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppColors.textMid.withOpacity(0.8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${dateFormat.format(cycle.startDate)} - ${dateFormat.format(cycle.endDate)}',
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 10,
                        color: AppColors.textMid,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$duration days',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),

                // Visual timeline bar
                const SizedBox(height: 12),
                _buildTimelineBar(cycle, labsDuringCycle, labsBeforeCycle, color),
              ],
            ),
          ),

          // Labs during this cycle
          if (labsDuringCycle.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildLabsSection(
              'LABS DURING CYCLE',
              labsDuringCycle,
              color,
              cycle,
            ),
          ],

          // Before/after comparison
          if (labsBeforeCycle.isNotEmpty && labsDuringCycle.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildBeforeAfterComparison(
              labsBeforeCycle.last,
              labsDuringCycle.last,
              cycle,
              color,
            ),
          ],

          // No labs warning
          if (labsDuringCycle.isEmpty && labsBeforeCycle.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(
                    color: const Color(0xFFFFAA00).withOpacity(0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Color(0xFFFFAA00),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'No labs uploaded during this cycle. Upload bloodwork to see how this peptide affected your biomarkers.',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          color: AppColors.textMid,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineBar(
    CycleWindow cycle,
    List<LabResultWithContext> labsDuring,
    List<LabResultWithContext> labsBefore,
    Color color,
  ) {
    final totalDays = cycle.endDate.difference(cycle.startDate).inDays;
    if (totalDays <= 0) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline bar
        Container(
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: color.withOpacity(0.4),
              width: 2,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Progress fill
                  Container(
                    width: _getCycleProgress(cycle) * constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Lab markers
                  ...labsDuring.map((lab) {
                    final daysIn =
                        lab.labDate.difference(cycle.startDate).inDays;
                    final position = (daysIn / totalDays).clamp(0.0, 1.0);
                    return Positioned(
                      left: position * constraints.maxWidth - 6,
                      top: 1,
                      child: Container(
                        width: 12,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.8),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.6),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.science,
                          size: 10,
                          color: Colors.black,
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        // Legend
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color.withOpacity(0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Cycle duration',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 9,
                color: AppColors.textMid.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Lab taken',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 9,
                color: AppColors.textMid.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _getCycleProgress(CycleWindow cycle) {
    final now = DateTime.now();
    if (now.isAfter(cycle.endDate)) return 1.0;
    if (now.isBefore(cycle.startDate)) return 0.0;
    final total = cycle.endDate.difference(cycle.startDate).inDays;
    final elapsed = now.difference(cycle.startDate).inDays;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  Widget _buildLabsSection(
    String title,
    List<LabResultWithContext> labsList,
    Color color,
    CycleWindow cycle,
  ) {
    final dateFormat = DateFormat('MMM d');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...labsList.map((lab) {
            final daysIntoCycle =
                lab.labDate.difference(cycle.startDate).inDays;
            final outOfRange = lab.biomarkerChanges
                .where((b) => b.status != 'NORMAL')
                .length;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text(
                    dateFormat.format(lab.labDate),
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Day $daysIntoCycle',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 9,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${lab.markerCount} markers',
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 9,
                      color: AppColors.textDim,
                    ),
                  ),
                  const Spacer(),
                  if (outOfRange > 0)
                    Text(
                      '$outOfRange out of range',
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 9,
                        color: Color(0xFFFFAA00),
                      ),
                    )
                  else
                    const Text(
                      'All normal',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 9,
                        color: AppColors.accent,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBeforeAfterComparison(
    LabResultWithContext before,
    LabResultWithContext after,
    CycleWindow cycle,
    Color color,
  ) {
    // Find biomarkers present in both labs
    final commonMarkers = <_BeforeAfterMarker>[];

    for (final afterMarker in after.biomarkerChanges) {
      final beforeMarker = before.biomarkerChanges
          .where((b) => b.name == afterMarker.name)
          .firstOrNull;
      if (beforeMarker != null &&
          beforeMarker.currentValue != null &&
          afterMarker.currentValue != null) {
        final change = afterMarker.currentValue! - beforeMarker.currentValue!;
        final changePercent = beforeMarker.currentValue! != 0
            ? (change / beforeMarker.currentValue! * 100)
            : 0.0;
        commonMarkers.add(_BeforeAfterMarker(
          name: afterMarker.name,
          beforeValue: beforeMarker.currentValue!,
          afterValue: afterMarker.currentValue!,
          unit: afterMarker.unit ?? '',
          changePercent: changePercent,
          afterStatus: afterMarker.status,
        ));
      }
    }

    if (commonMarkers.isEmpty) return const SizedBox();

    // Sort by absolute change percentage
    commonMarkers.sort((a, b) =>
        b.changePercent.abs().compareTo(a.changePercent.abs()));

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                'BEFORE / AFTER ${cycle.peptideName.toUpperCase()}',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Header row
          const Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'MARKER',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 8,
                    color: AppColors.textDim,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'BEFORE',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 8,
                    color: AppColors.textDim,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'AFTER',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 8,
                    color: AppColors.textDim,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(
                width: 55,
                child: Text(
                  'CHANGE',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 8,
                    color: AppColors.textDim,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(color: Color(0xFF1A2540), height: 1),
          const SizedBox(height: 4),
          ...commonMarkers.take(8).map((m) {
            final changeColor = m.changePercent >= 0
                ? AppColors.accent
                : AppColors.error;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      m.name,
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 10,
                        color: AppColors.textMid,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      m.beforeValue.toStringAsFixed(1),
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 10,
                        color: AppColors.textDim,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      m.afterValue.toStringAsFixed(1),
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(m.afterStatus),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  SizedBox(
                    width: 55,
                    child: Text(
                      '${m.changePercent >= 0 ? '+' : ''}${m.changePercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: changeColor,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'HIGH':
        return AppColors.error;
      case 'LOW':
        return const Color(0xFFFFAA00);
      default:
        return AppColors.accent;
    }
  }

  Color _getPeptideColor(String peptideName) {
    final hash = peptideName.hashCode;
    final colors = [
      const Color(0xFF00FFFF),
      const Color(0xFFFF00FF),
      const Color(0xFF39FF14),
      const Color(0xFFFFAA00),
      const Color(0xFF00AAFF),
      const Color(0xFFFF0088),
    ];
    return colors[hash.abs() % colors.length];
  }
}

class _BeforeAfterMarker {
  final String name;
  final double beforeValue;
  final double afterValue;
  final String unit;
  final double changePercent;
  final String afterStatus;

  _BeforeAfterMarker({
    required this.name,
    required this.beforeValue,
    required this.afterValue,
    required this.unit,
    required this.changePercent,
    required this.afterStatus,
  });
}
