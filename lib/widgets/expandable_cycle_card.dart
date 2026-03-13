import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../services/cycles_database.dart';

/// Expandable cycle card with inline expansion (Wintermute dashboard style)
/// Removes navigation buttons, expands inline to show edit/complete/delete actions
class ExpandableCycleCard extends StatefulWidget {
  final Cycle cycle;
  final Future<Map<String, dynamic>> Function(String) loadCycleSummary;
  final VoidCallback onEdit;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const ExpandableCycleCard({
    Key? key,
    required this.cycle,
    required this.loadCycleSummary,
    required this.onEdit,
    required this.onComplete,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<ExpandableCycleCard> createState() => _ExpandableCycleCardState();
}

class _ExpandableCycleCardState extends State<ExpandableCycleCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  String _getFullRouteName(String route) {
    // Convert abbreviations to full names
    final routeMap = {
      'SC': 'Subcutaneous',
      'IM': 'Intramuscular',
      'Oral': 'Oral',
      'IV': 'Intravenous',
      'SC (subcutaneous)': 'Subcutaneous',
      'IM (intramuscular)': 'Intramuscular',
    };
    return routeMap[route] ?? route;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final endDate = widget.cycle.startDate.add(
      Duration(days: widget.cycle.durationWeeks * 7),
    );
    final daysRemaining = endDate.difference(now).inDays;
    final progress = widget.cycle.durationWeeks > 0
        ? (now.difference(widget.cycle.startDate).inDays /
                (widget.cycle.durationWeeks * 7))
            .clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: WintermmuteStyles.cardDecoration, // Matte background
      child: GestureDetector(
        onTap: _toggleExpand,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.cycle.peptideName.toUpperCase(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.cycle.isActive
                                ? AppColors.accent.withOpacity(0.15)
                                : AppColors.textDim.withOpacity(0.15),
                            border: Border.all(
                              color: widget.cycle.isActive
                                  ? AppColors.accent.withOpacity(0.3)
                                  : AppColors.textDim.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            widget.cycle.isActive ? 'ACTIVE' : 'COMPLETE',
                            style: TextStyle(
                              color: widget.cycle.isActive
                                  ? AppColors.accent
                                  : AppColors.textDim,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Dose, Route (full name), Frequency Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildStatColumn('DOSE', '${widget.cycle.dose} mg', AppColors.primary),
                    ),
                    Expanded(
                      child: _buildStatColumn(
                        'ROUTE',
                        _getFullRouteName(widget.cycle.route),
                        AppColors.textLight,
                      ),
                    ),
                    Expanded(
                      child: _buildStatColumn('FREQ', widget.cycle.frequency, AppColors.textLight),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Duration & Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.cycle.durationWeeks} WEEKS',
                      style: TextStyle(
                        color: AppColors.textMid,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      daysRemaining > 0 ? '$daysRemaining DAYS LEFT' : 'COMPLETED',
                      style: TextStyle(
                        color: daysRemaining > 0 ? AppColors.accent : AppColors.textDim,
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: AppColors.border.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      daysRemaining > 0 ? AppColors.primary : AppColors.textDim,
                    ),
                  ),
                ),

                // Expanded section
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  axisAlignment: -1.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Divider with decoration
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppColors.primary.withOpacity(0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Summary info
                      FutureBuilder<Map<String, dynamic>>(
                        future: widget.loadCycleSummary(widget.cycle.id),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          }

                          final data = snapshot.data!;
                          final totalDoses = data['totalDoses'] as int? ?? 0;
                          final lastDose = data['lastDose'] as String?;
                          final missedDoses = data['missedDoses'] as List<String>? ?? [];
                          final recentSideEffects = data['recentSideEffects'] as List<String>? ?? [];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tracking stats
                              if (totalDoses > 0) ...[
                                _buildSectionHeader('TRACKING'),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$totalDoses DOSES LOGGED',
                                      style: TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    if (lastDose != null)
                                      Text(
                                        'LAST: $lastDose',
                                        style: TextStyle(
                                          color: AppColors.textMid,
                                          fontSize: 10,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Missed doses
                              if (missedDoses.isNotEmpty) ...[
                                _buildSectionHeader('MISSED (${missedDoses.length})'),
                                const SizedBox(height: 6),
                                ...missedDoses.take(3).map((missed) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          Icon(Icons.close, color: AppColors.error, size: 12),
                                          const SizedBox(width: 4),
                                          Text(
                                            missed,
                                            style: TextStyle(
                                              color: AppColors.textMid,
                                              fontSize: 11,
                                              fontFamily: 'monospace',
                                              decoration: TextDecoration.lineThrough,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                const SizedBox(height: 12),
                              ],

                              // Side effects
                              if (recentSideEffects.isNotEmpty) ...[
                                _buildSectionHeader('SYMPTOMS (${recentSideEffects.length})'),
                                const SizedBox(height: 6),
                                ...recentSideEffects.take(3).map((effect) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '• $effect',
                                        style: TextStyle(
                                          color: AppColors.textMid,
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    )),
                                const SizedBox(height: 12),
                              ],
                            ],
                          );
                        },
                      ),

                      // Action buttons (expanded view only)
                      if (widget.cycle.isActive) ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: widget.onEdit,
                                icon: Icon(Icons.edit, size: 14, color: AppColors.primary),
                                label: Text(
                                  'EDIT',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: widget.onComplete,
                                icon: Icon(Icons.check_circle, size: 14, color: AppColors.background),
                                label: Text(
                                  'COMPLETE',
                                  style: TextStyle(
                                    color: AppColors.background,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: widget.onDelete,
                            icon: Icon(Icons.delete, size: 14, color: AppColors.error),
                            label: Text(
                              'DELETE CYCLE',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Tap hint
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Center(
                    child: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textDim,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textDim,
            fontSize: 10,
            fontFamily: 'monospace',
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
