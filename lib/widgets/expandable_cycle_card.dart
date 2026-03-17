import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../services/cycles_database.dart';
import 'dose_display.dart';

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

    final protocolId = 'PROT-${widget.cycle.startDate.millisecondsSinceEpoch.toString().substring(7)}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: WintermmuteStyles.cardDecoration, // Matte background
      child: GestureDetector(
        onTap: _toggleExpand,
        child: Stack(
          children: [
            // Top-left: PROTOCOL ID badge
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Color(0xFFFF9800).withOpacity(0.15),
                  border: Border.all(color: Color(0xFFFF9800).withOpacity(0.7), width: 1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.science, color: Color(0xFFFF9800).withOpacity(0.8), size: 10),
                    SizedBox(width: 4),
                    Text(
                      protocolId,
                      style: TextStyle(
                        color: Color(0xFFFF9800).withOpacity(0.85),
                        fontSize: 8,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Top-right: ROGUE-2 callsign
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFFFF9800).withOpacity(0.8), width: 1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flash_on, color: Color(0xFFFF9800).withOpacity(0.8), size: 10),
                    SizedBox(width: 3),
                    Text(
                      'ROGUE-2',
                      style: TextStyle(
                        color: Color(0xFFFF9800).withOpacity(0.9),
                        fontSize: 8,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Padding(
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),  // More top padding for badges
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Peptide name, status badge, and dose on right
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side: Peptide name + status
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Peptide name
                          Text(
                            widget.cycle.peptideName.toUpperCase(),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: widget.cycle.isActive
                                  ? AppColors.accent.withOpacity(0.15)
                                  : AppColors.textDim.withOpacity(0.15),
                              border: Border.all(
                                color: widget.cycle.isActive
                                    ? AppColors.accent.withOpacity(0.2)
                                    : AppColors.textDim.withOpacity(0.2),
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
                    ),
                    const SizedBox(width: 16),
                    // Right side: DoseDisplay widget
                    DoseDisplay(
                      doseMg: widget.cycle.dose,
                      peptideName: widget.cycle.peptideName,
                      color: AppColors.primary,
                      showLabel: true,
                      showSyringe: true,
                      mgStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontFamily: 'monospace',
                      ),
                      mlStyle: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMid,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Route and Frequency info chips
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        label: 'ROUTE',
                        value: _getFullRouteName(widget.cycle.route),
                        icon: Icons.medical_services,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        label: 'FREQ',
                        value: widget.cycle.frequency,
                        icon: Icons.calendar_today,
                      ),
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
                                  side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
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
                              side: BorderSide(color: AppColors.error.withOpacity(0.2)),
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
          ],  // Close Stack children
        ),  // Close Stack
      ),  // Close GestureDetector
    );  // Close Container
  }

  Widget _buildInfoChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: AppColors.primary.withOpacity(0.6)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.textDim,
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
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
                color: AppColors.primary.withOpacity(0.15),
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
