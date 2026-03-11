import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../services/cycles_database.dart';
import '../services/dose_logs_database.dart';
import '../services/dose_logs_service.dart';
import '../services/dose_schedule_service.dart';
import '../services/weight_logs_database.dart';
import '../widgets/side_effects_modal.dart';
import '../widgets/weight_log_modal.dart';
import 'labs_screen.dart';
import '../main.dart' show authProviderProvider;

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final cycleDb = CyclesDatabase();
  final doseDb = DoseLogsDatabase();

  List<DoseInstance> _todaysDoses = [];
  List<Cycle> _activeCycles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final userId = ref.read(authProviderProvider).user?.id;
      if (userId == null) return;

      final doseService = ref.read(doseScheduleServiceProvider);

      // Get today's doses
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final allDoses = await doseService.getUpcomingDoses(userId, daysAhead: 1);
      _todaysDoses = allDoses.where((dose) {
        final doseDate = DateTime(dose.date.year, dose.date.month, dose.date.day);
        return doseDate.isAtSameMomentAs(today);
      }).toList();

      // Get active cycles
      _activeCycles = await cycleDb.getActiveCycles();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('[Dashboard] Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markDoseMissed(DoseInstance dose) async {
    try {
      final userId = ref.read(authProviderProvider).user?.id;
      if (userId == null) return;

      // Mark the dose as MISSED using DoseLogsService
      final doseLogsService = ref.read(doseLogsServiceProvider);
      await doseLogsService.markAsMissed(dose.doseLogId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Dose marked as missed',
              style: WintermmuteStyles.bodyStyle,
            ),
            backgroundColor: const Color(0xFFFF6B00), // Orange warning color
            duration: const Duration(seconds: 2),
          ),
        );
        _loadData();
      }
    } catch (e) {
      print('[Dashboard] Error marking dose as missed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error marking dose',
              style: WintermmuteStyles.bodyStyle,
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _openResearchLink() async {
    final url = Uri.parse('https://peptides.org');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('[Dashboard] Error opening research link: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open research link',
              style: WintermmuteStyles.bodyStyle,
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showSideEffectsModal(DoseInstance dose) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SideEffectsModal(
        dose: dose,
        onSaved: _loadData,
      ),
    );
  }

  void _showWeightLogModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => WeightLogModal(
        onSaved: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Weight logged successfully',
                  style: WintermmuteStyles.bodyStyle,
                ),
                backgroundColor: AppColors.accent,
              ),
            );
          }
        },
      ),
    );
  }

  double _calculateCycleProgress(Cycle cycle) {
    final now = DateTime.now();
    final totalDays = cycle.endDate.difference(cycle.startDate).inDays;
    final currentDay = now.difference(cycle.startDate).inDays + 1;

    if (currentDay <= 0) return 0.0;
    if (currentDay >= totalDays) return 1.0;

    return currentDay / totalDays;
  }

  int _getCurrentDay(Cycle cycle) {
    final now = DateTime.now();
    return now.difference(cycle.startDate).inDays + 1;
  }

  int _getTotalDays(Cycle cycle) {
    return cycle.endDate.difference(cycle.startDate).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Text(
                          'DAILY ACTIONS',
                          style: WintermmuteStyles.headerStyle.copyWith(
                            fontSize: 18,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // TODAY'S DOSES SECTION
                        _buildTodaysDosesSection(),
                        const SizedBox(height: 32),

                        // CYCLE PROGRESS SECTION
                        _buildCycleProgressSection(),
                        const SizedBox(height: 32),

                        // QUICK ACTIONS SECTION
                        _buildQuickActionsSection(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
          // Scanlines overlay
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ScanlinesPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysDosesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.medication_outlined,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'TODAY\'S DOSES',
              style: WintermmuteStyles.bodyStyle.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_todaysDoses.isEmpty) _buildNoDosesToday() else _buildDosesList(),
      ],
    );
  }

  Widget _buildNoDosesToday() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.accent.withOpacity(0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withOpacity(0.05),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.accent,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'All doses complete!',
            style: WintermmuteStyles.titleStyle.copyWith(
              color: AppColors.accent,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No doses scheduled for today',
            style: WintermmuteStyles.bodyStyle.copyWith(
              color: AppColors.textMid,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDosesList() {
    return Column(
      children: _todaysDoses.map((dose) => _buildDoseCard(dose)).toList(),
    );
  }

  Widget _buildDoseCard(DoseInstance dose) {
    final isCompleted = dose.status == 'COMPLETED';
    final isMissed = dose.status == 'MISSED';
    final maxDose = 10.0; // Max expected dose for progress bar scaling
    final fillPercent = (dose.doseAmount / maxDose).clamp(0.0, 1.0);

    // Find the corresponding cycle for progress info
    final cycle = _activeCycles.firstWhere(
      (c) => c.id == dose.cycleId,
      orElse: () => _activeCycles.isNotEmpty ? _activeCycles.first : null as Cycle,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isCompleted
              ? AppColors.accent.withOpacity(0.5)
              : isMissed
                  ? const Color(0xFFFF6B00).withOpacity(0.5)
                  : AppColors.primary.withOpacity(0.5),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.surface,
        boxShadow: isCompleted
            ? [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  dose.peptideName.toUpperCase(),
                  style: WintermmuteStyles.titleStyle.copyWith(
                    color: AppColors.primary,
                    fontSize: 18,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.accent.withOpacity(0.2)
                      : AppColors.secondary.withOpacity(0.2),
                  border: Border.all(
                    color: isCompleted ? AppColors.accent : AppColors.secondary,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  dose.time,
                  style: WintermmuteStyles.bodyStyle.copyWith(
                    color: isCompleted ? AppColors.accent : AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Syringe visual indicator
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.vaccines_outlined,
                    color: AppColors.textMid,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'DOSE AMOUNT',
                    style: WintermmuteStyles.smallStyle.copyWith(
                      color: AppColors.textMid,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: fillPercent,
                    child: Container(
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.accent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: 24,
                    alignment: Alignment.center,
                    child: Text(
                      '${dose.doseAmount}mg',
                      style: WintermmuteStyles.bodyStyle.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        shadows: [
                          Shadow(
                            color: AppColors.background,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cycle progress bar
          if (cycle != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: AppColors.textMid,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'CYCLE PROGRESS',
                      style: WintermmuteStyles.smallStyle.copyWith(
                        color: AppColors.textMid,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: _calculateCycleProgress(cycle).clamp(0.0, 1.0),
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF00FFFF), // Cyan
                              const Color(0xFF00FF41), // Neon green
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00FFFF).withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      height: 20,
                      alignment: Alignment.center,
                      child: Text(
                        'Day ${_getCurrentDay(cycle)} of ${_getTotalDays(cycle)} (${(_calculateCycleProgress(cycle) * 100).toInt()}%)',
                        style: WintermmuteStyles.bodyStyle.copyWith(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          shadows: [
                            Shadow(
                              color: AppColors.background,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Route and site info
          Row(
            children: [
              _buildInfoChip(Icons.route, dose.route),
              const SizedBox(width: 8),
              _buildInfoChip(Icons.location_on_outlined, 'Rotate site'),
            ],
          ),

          if (!isCompleted && !isMissed) ...[
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _markDoseMissed(dose),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: Text(
                      'MARK MISSED',
                      style: WintermmuteStyles.bodyStyle.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B00), // Orange warning color
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showSideEffectsModal(dose),
                    icon: const Icon(Icons.warning_amber_outlined, size: 18),
                    label: Text(
                      'LOG EFFECTS',
                      style: WintermmuteStyles.bodyStyle.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: BorderSide(color: AppColors.secondary, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'COMPLETED',
                  style: WintermmuteStyles.bodyStyle.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMid),
          const SizedBox(width: 6),
          Text(
            label,
            style: WintermmuteStyles.smallStyle.copyWith(
              color: AppColors.textMid,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.trending_up,
              color: AppColors.secondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'CYCLE PROGRESS',
              style: WintermmuteStyles.bodyStyle.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_activeCycles.isEmpty)
          _buildNoCyclesState()
        else
          Column(
            children: _activeCycles.map((cycle) => _buildCycleProgressCard(cycle)).toList(),
          ),
      ],
    );
  }

  Widget _buildNoCyclesState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.surface,
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_circle_outline,
            color: AppColors.primary,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No active cycles',
            style: WintermmuteStyles.titleStyle.copyWith(
              color: AppColors.primary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first cycle to get started',
            style: WintermmuteStyles.bodyStyle.copyWith(
              color: AppColors.textMid,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCycleProgressCard(Cycle cycle) {
    final progress = _calculateCycleProgress(cycle);
    final currentDay = _getCurrentDay(cycle);
    final totalDays = _getTotalDays(cycle);
    final isOnTrack = progress <= 1.0;
    final progressColor = isOnTrack ? AppColors.accent : AppColors.secondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: progressColor.withOpacity(0.5),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cycle name
          Text(
            cycle.peptideName.toUpperCase(),
            style: WintermmuteStyles.titleStyle.copyWith(
              color: AppColors.primary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${cycle.dose}mg • ${cycle.frequency} • ${cycle.route}',
            style: WintermmuteStyles.smallStyle.copyWith(
              color: AppColors.textMid,
            ),
          ),
          const SizedBox(height: 12),

          // Progress bar
          Stack(
            children: [
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: progressColor.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: 20,
                alignment: Alignment.center,
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: WintermmuteStyles.bodyStyle.copyWith(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    shadows: [
                      Shadow(
                        color: AppColors.background,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Day count
          Text(
            'Day $currentDay of $totalDays',
            style: WintermmuteStyles.bodyStyle.copyWith(
              color: progressColor,
              fontWeight: FontWeight.bold,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.flash_on,
              color: AppColors.accent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'QUICK ACTIONS',
              style: WintermmuteStyles.bodyStyle.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.scale_outlined,
                label: 'LOG WEIGHT',
                color: AppColors.accent,
                onTap: _showWeightLogModal,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.science_outlined,
                label: 'VIEW LABS',
                color: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LabsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.biotech,
                label: '🔬 RESEARCH',
                color: AppColors.secondary,
                onTap: _openResearchLink,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: WintermmuteStyles.bodyStyle.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.07)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
