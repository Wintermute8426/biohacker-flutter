import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../services/dose_schedule_service.dart';
import '../services/dose_logs_service.dart';
import '../screens/mark_missed_modal.dart';
import '../screens/add_symptoms_modal.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _weekStart;
  String? _selectedCycleId;
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    _weekStart = _getWeekStart(DateTime.now());
  }

  // Get Monday of week
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: weekday - 1));
  }

  void _goToPreviousWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
    });
  }

  void _goToNextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
    });
  }

  void _goToToday() {
    setState(() {
      _weekStart = _getWeekStart(DateTime.now());
    });
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
            icon: const Icon(Icons.today),
            onPressed: _goToToday,
            color: AppColors.primary,
          ),
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

          // Group doses by cycle for filter
          final cyclesInDoses = <String, String>{};
          for (final dose in doses) {
            if (!cyclesInDoses.containsKey(dose.cycleId)) {
              cyclesInDoses[dose.cycleId] = dose.peptideName;
            }
          }

          // Filter doses for selected week and cycle
          final weekDoses = doses.where((dose) {
            final doseDate = dose.date;
            final isInWeek = doseDate.isAfter(_weekStart.subtract(const Duration(days: 1))) &&
                doseDate.isBefore(_weekStart.add(const Duration(days: 7)));
            final matchesCycle =
                _selectedCycleId == null || dose.cycleId == _selectedCycleId;
            return isInWeek && matchesCycle;
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Week header with navigation
                _buildWeekHeader(),
                const SizedBox(height: 20),

                // Cycle filter
                _buildCycleFilter(cyclesInDoses),
                const SizedBox(height: 16),

                // Week grid (7 columns)
                _buildWeekGrid(weekDoses),
                const SizedBox(height: 16),

                // Status bar
                _buildStatusBar(weekDoses),
              ],
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: WintermmuteStyles.bodyStyle.copyWith(
              color: AppColors.error,
            ),
          ),
        ),
      ),
    );
  }

  // Week header with prev/next navigation
  Widget _buildWeekHeader() {
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final dateRange =
        '${DateFormat('MMM dd').format(_weekStart)} – ${DateFormat('MMM dd, yyyy').format(weekEnd)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _goToPreviousWeek,
              color: AppColors.primary,
            ),
            Text(
              dateRange,
              style: WintermmuteStyles.titleStyle.copyWith(fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _goToNextWeek,
              color: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }

  // Cycle filter dropdown
  Widget _buildCycleFilter(Map<String, String> cycles) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                _selectedCycleId == null ? 'All Cycles' : 'Selected',
                style: WintermmuteStyles.bodyStyle.copyWith(
                  color: _selectedCycleId == null
                      ? AppColors.primary
                      : AppColors.background,
                ),
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedCycleId = null;
                });
              },
              selected: _selectedCycleId == null,
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary,
            ),
          ),
          ...cycles.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  entry.value,
                  style: WintermmuteStyles.bodyStyle.copyWith(
                    color: _selectedCycleId == entry.key
                        ? AppColors.background
                        : AppColors.textMid,
                  ),
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedCycleId = selected ? entry.key : null;
                  });
                },
                selected: _selectedCycleId == entry.key,
                backgroundColor: AppColors.surface,
                selectedColor: AppColors.secondary,
              ),
            );
          }),
        ],
      ),
    );
  }

  // 7-column week grid
  Widget _buildWeekGrid(List<DoseInstance> weekDoses) {
    const daysOfWeek = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return Column(
      children: [
        // Day headers
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
          ),
          itemCount: 7,
          itemBuilder: (context, index) {
            return Center(
              child: Text(
                daysOfWeek[index],
                style: WintermmuteStyles.bodyStyle.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),

        // Date cells
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.2,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: 7,
          itemBuilder: (context, index) {
            final date = _weekStart.add(Duration(days: index));
            final dayDoses = weekDoses
                .where((d) =>
                    d.date.year == date.year &&
                    d.date.month == date.month &&
                    d.date.day == date.day)
                .toList();

            // Count by status
            final completed = dayDoses
                .where((d) => d.status == 'COMPLETED')
                .length;
            final scheduled = dayDoses
                .where((d) => d.status == 'SCHEDULED')
                .length;
            final missed = dayDoses
                .where((d) => d.status == 'MISSED')
                .length;

            // Determine cell color based on status
            Color cellColor = AppColors.surface;
            if (missed > 0) {
              cellColor = AppColors.error;
            } else if (scheduled > 0 && completed == 0) {
              cellColor = const Color(0xFF1E4620); // Dark green for pending
            } else if (completed > 0) {
              cellColor = const Color(0xFF0D2E1F); // Darker green for done
            }

            final isToday = date.year == DateTime.now().year &&
                date.month == DateTime.now().month &&
                date.day == DateTime.now().day;

            return GestureDetector(
              onTap: dayDoses.isNotEmpty
                  ? () => _showDayDetail(context, date, dayDoses)
                  : null,
              child: Material(
                color: cellColor,
                child: InkWell(
                  onTap: dayDoses.isNotEmpty
                      ? () => _showDayDetail(context, date, dayDoses)
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isToday ? AppColors.primary : AppColors.textMid,
                        width: isToday ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          date.day.toString(),
                          style: WintermmuteStyles.bodyStyle.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (dayDoses.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${dayDoses.length}',
                            style: WintermmuteStyles.smallStyle
                                .copyWith(color: AppColors.primary),
                          ),
                          if (dayDoses.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (completed > 0)
                                  const SizedBox(
                                    width: 4,
                                    height: 4,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Color(0xFF39FF14),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                if (scheduled > 0)
                                  const SizedBox(
                                    width: 4,
                                    height: 4,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Color(0xFF00FFFF),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Status bar with counts
  Widget _buildStatusBar(List<DoseInstance> weekDoses) {
    final completed =
        weekDoses.where((d) => d.status == 'COMPLETED').length;
    final scheduled =
        weekDoses.where((d) => d.status == 'SCHEDULED').length;
    final missed = weekDoses.where((d) => d.status == 'MISSED').length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatusChip('$completed', 'Logged', const Color(0xFF39FF14)),
        _buildStatusChip('$scheduled', 'Pending', const Color(0xFF00FFFF)),
        _buildStatusChip('$missed', 'Missed', AppColors.error),
      ],
    );
  }

  Widget _buildStatusChip(String count, String label, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: WintermmuteStyles.titleStyle.copyWith(
            color: color,
            fontSize: 20,
          ),
        ),
        Text(
          label,
          style: WintermmuteStyles.smallStyle.copyWith(
            color: AppColors.textMid,
          ),
        ),
      ],
    );
  }

  // Day detail bottom sheet
  void _showDayDetail(
    BuildContext context,
    DateTime date,
    List<DoseInstance> dayDoses,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              color: AppColors.surface,
              child: ListView(
                controller: scrollController,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.textMid,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          DateFormat('EEEE, MMM dd, yyyy').format(date),
                          style: WintermmuteStyles.titleStyle,
                        ),
                      ],
                    ),
                  ),
                  ...dayDoses.map((dose) {
                    return _buildDoseListItem(context, dose);
                  }),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDoseListItem(BuildContext context, DoseInstance dose) {
    final statusColor = dose.status == 'COMPLETED'
        ? const Color(0xFF39FF14)
        : dose.status == 'MISSED'
            ? AppColors.error
            : const Color(0xFF00FFFF);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: statusColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.background,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${dose.peptideName} - ${dose.doseAmount}mg',
                style: WintermmuteStyles.bodyStyle,
              ),
              const SizedBox(height: 4),
              Text(
                '${dose.time} • ${dose.route}',
                style: WintermmuteStyles.smallStyle
                    .copyWith(color: AppColors.textMid),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              border: Border.all(color: statusColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              dose.status,
              style: WintermmuteStyles.smallStyle.copyWith(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
