import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../services/dose_schedule_service.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _currentDate;
  int _viewDays = 14; // Show next 14 days

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final upcomingDoses = ref.watch(upcomingDosesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'DOSE CALENDAR',
          style: WintermmuteStyles.titleStyle.copyWith(fontSize: 18),
        ),
        centerTitle: false,
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(upcomingDosesProvider),
            color: AppColors.primary,
          ),
        ],
      ),
      body: upcomingDoses.when(
        data: (doses) {
          if (doses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No doses scheduled',
                    style: WintermmuteStyles.headerStyle,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Create a cycle to start scheduling doses',
                    style: WintermmuteStyles.bodyStyle.copyWith(
                      color: AppColors.textMid,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Next 14 days summary
                _buildUpcomingSummary(doses),
                const SizedBox(height: 24),

                // Timeline of doses
                Text(
                  'UPCOMING DOSES',
                  style: WintermmuteStyles.headerStyle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 16),
                _buildDoseTimeline(doses),
              ],
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error loading doses: $err',
            style: WintermmuteStyles.bodyStyle,
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingSummary(List<DoseInstance> doses) {
    // Group doses by date for next 7 days
    final nextWeek = <DateTime, List<DoseInstance>>{};
    final now = DateTime.now();

    for (final dose in doses) {
      final nextWeekDate = DateTime(dose.date.year, dose.date.month, dose.date.day);
      if (nextWeekDate.isBefore(now.add(const Duration(days: 7)))) {
        if (!nextWeek.containsKey(nextWeekDate)) {
          nextWeek[nextWeekDate] = [];
        }
        nextWeek[nextWeekDate]!.add(dose);
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEXT 7 DAYS',
            style: WintermmuteStyles.bodyStyle.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: nextWeek.entries.map((entry) {
              final date = entry.key;
              final dayDoses = entry.value;
              final dayName = DateFormat('EEE').format(date);
              final dayNum = date.day;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(
                    color: _isToday(date)
                        ? AppColors.accent
                        : AppColors.primary.withOpacity(0.2),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Text(
                      '$dayName $dayNum',
                      style: WintermmuteStyles.smallStyle.copyWith(
                        color: _isToday(date) ? AppColors.accent : AppColors.textMid,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dayDoses.length}',
                      style: WintermmuteStyles.bodyStyle.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDoseTimeline(List<DoseInstance> doses) {
    final groupedByDate = <DateTime, List<DoseInstance>>{};

    for (final dose in doses) {
      final date = DateTime(dose.date.year, dose.date.month, dose.date.day);
      if (!groupedByDate.containsKey(date)) {
        groupedByDate[date] = [];
      }
      groupedByDate[date]!.add(dose);
    }

    final sortedDates = groupedByDate.keys.toList()..sort();

    return Column(
      children: sortedDates.map((date) {
        final dayDoses = groupedByDate[date]!;
        final isToday = _isToday(date);
        final dateStr = DateFormat('EEE, MMM dd, yyyy').format(date);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  if (isToday)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      margin: const EdgeInsets.only(right: 8),
                    ),
                  Text(
                    dateStr,
                    style: WintermmuteStyles.bodyStyle.copyWith(
                      color: isToday ? AppColors.accent : AppColors.textMid,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

            // Doses for this date
            ...dayDoses.map((dose) => _buildDoseCard(dose)),
            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDoseCard(DoseInstance dose) {
    return GestureDetector(
      onTap: () => _showDoseDetails(dose),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(
            color: _getPeptideColor(dose.peptideName).withOpacity(0.4),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            // Time
            SizedBox(
              width: 60,
              child: Text(
                dose.time,
                style: WintermmuteStyles.bodyStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),

            // Peptide info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dose.peptideName,
                    style: WintermmuteStyles.bodyStyle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${dose.doseAmount.toStringAsFixed(1)}mg ${dose.route}',
                    style: WintermmuteStyles.smallStyle.copyWith(
                      color: AppColors.textMid,
                    ),
                  ),
                ],
              ),
            ),

            // Status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(
                  color: dose.isLogged == true
                      ? AppColors.accent
                      : AppColors.textDim,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                dose.isLogged == true ? '✓ LOGGED' : 'PENDING',
                style: WintermmuteStyles.tinyStyle.copyWith(
                  color: dose.isLogged == true
                      ? AppColors.accent
                      : AppColors.textDim,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDoseDetails(DoseInstance dose) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dose.peptideName,
              style: WintermmuteStyles.headerStyle,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailItem('Time', dose.time),
                _buildDetailItem('Dose', '${dose.doseAmount}mg'),
                _buildDetailItem('Route', dose.route),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      'CLOSE',
                      style: WintermmuteStyles.bodyStyle.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Log dose
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Dose logged (coming in Phase 10C)'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: Text(
                      'LOG DOSE',
                      style: WintermmuteStyles.bodyStyle.copyWith(
                        color: AppColors.background,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: WintermmuteStyles.tinyStyle.copyWith(
            color: AppColors.textMid,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: WintermmuteStyles.bodyStyle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Color _getPeptideColor(String peptideName) {
    final hash = peptideName.hashCode;
    const colors = [
      AppColors.primary,
      AppColors.accent,
      Color(0xFFFF00FF),
      Color(0xFFFF6600),
    ];
    return colors[hash.abs() % colors.length];
  }
}
