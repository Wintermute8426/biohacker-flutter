import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/colors.dart';
import '../../services/reports_service.dart';

class LabResultCard extends StatelessWidget {
  final LabResultWithContext lab;
  final bool isExpanded;
  final VoidCallback onTap;

  const LabResultCard({
    Key? key,
    required this.lab,
    required this.isExpanded,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(
            color: AppColors.primary.withOpacity(isExpanded ? 0.8 : 0.3),
            width: isExpanded ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: isExpanded
                    ? const Border(
                        bottom: BorderSide(
                          color: Color(0xFF1A2540),
                          width: 1,
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  // Date
                  Text(
                    dateFormat.format(lab.labDate),
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Source
                  if (lab.labSource != null && lab.labSource != 'Lab Test')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        lab.labSource!,
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 9,
                          color: AppColors.textMid,
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Marker count
                  Text(
                    '${lab.markerCount} MARKERS',
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10,
                      color: AppColors.textDim,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status summary
                  _buildStatusSummary(),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textDim,
                    size: 18,
                  ),
                ],
              ),
            ),

            // Active cycles during this lab
            if (lab.activeCycles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Wrap(
                  spacing: 6,
                  children: lab.activeCycles.map((cycle) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getPeptideColor(cycle.peptideName)
                            .withOpacity(0.15),
                        border: Border.all(
                          color: _getPeptideColor(cycle.peptideName)
                              .withOpacity(0.5),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        cycle.peptideName.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: _getPeptideColor(cycle.peptideName),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Expanded: full biomarker list
            if (isExpanded) _buildBiomarkerList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSummary() {
    final high = lab.biomarkerChanges.where((b) => b.status == 'HIGH').length;
    final low = lab.biomarkerChanges.where((b) => b.status == 'LOW').length;

    if (high == 0 && low == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(3),
        ),
        child: const Text(
          'ALL NORMAL',
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (high > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.15),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              '$high HIGH',
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
          ),
        if (high > 0 && low > 0) const SizedBox(width: 4),
        if (low > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFAA00).withOpacity(0.15),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              '$low LOW',
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFAA00),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBiomarkerList() {
    final sorted = List<BiomarkerComparison>.from(lab.biomarkerChanges);
    // Show out-of-range first, then normal
    sorted.sort((a, b) {
      final aScore = a.status == 'HIGH' ? 0 : (a.status == 'LOW' ? 1 : 2);
      final bScore = b.status == 'HIGH' ? 0 : (b.status == 'LOW' ? 1 : 2);
      return aScore.compareTo(bScore);
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: sorted.map((biomarker) {
          return _buildBiomarkerRow(biomarker);
        }).toList(),
      ),
    );
  }

  Widget _buildBiomarkerRow(BiomarkerComparison biomarker) {
    final statusColor = _getStatusColor(biomarker.status);
    final hasChange = biomarker.changePercent != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        clipBehavior: Clip.hardEdge,
        children: [
          // Status indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          // Name
          Expanded(
            flex: 3,
            child: Text(
              biomarker.name,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              maxLines: 1,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                color: AppColors.textMid,
              ),
            ),
          ),
          // Value + unit
          Expanded(
            flex: 2,
            child: Text(
              biomarker.currentValue != null
                  ? '${biomarker.currentValue!.toStringAsFixed(1)} ${biomarker.unit ?? ''}'
                  : '--',
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 10),
          // Status label
          SizedBox(
            width: 54,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                biomarker.status,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Change percent
          SizedBox(
            width: 55,
            child: hasChange
                ? Text(
                    '${biomarker.changePercent! >= 0 ? '+' : ''}${biomarker.changePercent!.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10,
                      color: biomarker.changePercent! >= 0
                          ? AppColors.accent
                          : AppColors.error,
                    ),
                    textAlign: TextAlign.right,
                  )
                : const Text(
                    '--',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10,
                      color: AppColors.textDim,
                    ),
                    textAlign: TextAlign.right,
                  ),
          ),
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
