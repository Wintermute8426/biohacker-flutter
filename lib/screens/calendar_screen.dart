import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../services/dose_schedule_service.dart';
import '../services/dose_logs_service.dart';
import '../services/labs_database.dart';
import '../screens/mark_missed_modal.dart';
import '../screens/add_symptoms_modal.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _weekStart;
  late DateTime _monthStart;
  String? _selectedCycleId;
  String? _selectedDate;
  bool _showMonthView = false; // Toggle between week and month views

  @override
  void initState() {
    super.initState();
    _weekStart = _getWeekStart(DateTime.now());
    _monthStart = _getMonthStart(DateTime.now());
  }

  // Get Monday of week
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: weekday - 1));
  }

  // Get first day of month
  DateTime _getMonthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // Get days in month
  int _getDaysInMonth(DateTime date) {
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
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
      _monthStart = _getMonthStart(DateTime.now());
    });
  }

  void _goToPreviousMonth() {
    setState(() {
      _monthStart = DateTime(_monthStart.year, _monthStart.month - 1, 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _monthStart = DateTime(_monthStart.year, _monthStart.month + 1, 1);
    });
  }

  void _toggleViewMode() {
    setState(() {
      _showMonthView = !_showMonthView;
    });
  }

  @override
  Widget build(BuildContext context) {
    final upcomingDoses = ref.watch(upcomingDosesProvider);
    final userId = ref.watch(currentUserIdProvider);

    // Fetch lab results for bloodwork integration
    final labsData = userId != null
        ? ref.watch(userLabResultsProvider(userId))
        : const AsyncValue.data([]);

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
            icon: Icon(_showMonthView ? Icons.view_week : Icons.calendar_month),
            onPressed: _toggleViewMode,
            color: AppColors.accent,
            tooltip: _showMonthView ? 'Week View' : 'Month View',
          ),
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

          // Filter doses for selected week/month and cycle
          final displayDoses = doses.where((dose) {
            final doseDate = dose.date;
            bool isInRange;

            if (_showMonthView) {
              // Month view: show all doses in the month
              final monthEnd = DateTime(_monthStart.year, _monthStart.month + 1, 0);
              isInRange = doseDate.isAfter(_monthStart.subtract(const Duration(days: 1))) &&
                  doseDate.isBefore(monthEnd.add(const Duration(days: 1)));
            } else {
              // Week view: show only current week
              isInRange = doseDate.isAfter(_weekStart.subtract(const Duration(days: 1))) &&
                  doseDate.isBefore(_weekStart.add(const Duration(days: 7)));
            }

            final matchesCycle =
                _selectedCycleId == null || dose.cycleId == _selectedCycleId;
            return isInRange && matchesCycle;
          }).toList();

          // Extract lab dates for bloodwork integration
          final labDates = <DateTime>[];
          labsData.whenData((labs) {
            for (final lab in labs) {
              labDates.add(lab.uploadDate);
            }
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // View header with navigation
                _showMonthView
                    ? _buildMonthHeader()
                    : _buildWeekHeader(),
                const SizedBox(height: 20),

                // Compliance tracker
                _buildComplianceTracker(displayDoses),
                const SizedBox(height: 16),

                // Cycle filter
                _buildCycleFilter(cyclesInDoses),
                const SizedBox(height: 16),

                // Calendar grid
                _showMonthView
                    ? _buildMonthGrid(displayDoses, labDates)
                    : _buildWeekGrid(displayDoses, labDates),
                const SizedBox(height: 16),

                // Status bar
                _buildStatusBar(displayDoses),
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

  // Month header with prev/next navigation
  Widget _buildMonthHeader() {
    final monthName = DateFormat('MMMM yyyy').format(_monthStart);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _goToPreviousMonth,
              color: AppColors.primary,
            ),
            Text(
              monthName,
              style: WintermmuteStyles.titleStyle.copyWith(fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _goToNextMonth,
              color: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }

  // Compliance tracker widget
  Widget _buildComplianceTracker(List<DoseInstance> doses) {
    final completed = doses.where((d) => d.status == 'COMPLETED').length;
    final total = doses.length;
    final complianceRate = total > 0 ? (completed / total * 100).toStringAsFixed(1) : '0.0';

    final pastDoses = doses.where((d) => d.date.isBefore(DateTime.now())).toList();
    final pastCompleted = pastDoses.where((d) => d.status == 'COMPLETED').length;
    final pastTotal = pastDoses.length;
    final pastComplianceRate = pastTotal > 0 ? (pastCompleted / pastTotal * 100).toStringAsFixed(1) : '0.0';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.surface,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                '$pastComplianceRate%',
                style: WintermmuteStyles.statValueAccentStyle.copyWith(fontSize: 20),
              ),
              Text(
                'Compliance',
                style: WintermmuteStyles.smallStyle.copyWith(color: AppColors.textMid),
              ),
              Text(
                '($pastCompleted/$pastTotal logged)',
                style: WintermmuteStyles.smallStyle.copyWith(
                  color: AppColors.textDim,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.border,
          ),
          Column(
            children: [
              Text(
                '$completed',
                style: WintermmuteStyles.statValueStyle.copyWith(fontSize: 20),
              ),
              Text(
                'Logged',
                style: WintermmuteStyles.smallStyle.copyWith(color: AppColors.textMid),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.border,
          ),
          Column(
            children: [
              Text(
                '${total - completed}',
                style: WintermmuteStyles.statValueStyle.copyWith(
                  fontSize: 20,
                  color: AppColors.textMid,
                ),
              ),
              Text(
                'Pending',
                style: WintermmuteStyles.smallStyle.copyWith(color: AppColors.textMid),
              ),
            ],
          ),
        ],
      ),
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
  Widget _buildWeekGrid(List<DoseInstance> weekDoses, List<DateTime> labDates) {
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

            // Check if this date has a lab result
            final hasLab = labDates.any((labDate) =>
                labDate.year == date.year &&
                labDate.month == date.month &&
                labDate.day == date.day);

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
                          if (dayDoses.isNotEmpty || hasLab)
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
                                if (hasLab)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 2),
                                    child: Icon(
                                      Icons.science,
                                      size: 8,
                                      color: Color(0xFFFF00FF),
                                    ),
                                  ),
                              ],
                            ),
                        ] else if (hasLab) ...[
                          const SizedBox(height: 4),
                          const Icon(
                            Icons.science,
                            size: 12,
                            color: Color(0xFFFF00FF),
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

  // Month grid (shows full 30 days)
  Widget _buildMonthGrid(List<DoseInstance> monthDoses, List<DateTime> labDates) {
    const daysOfWeek = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final daysInMonth = _getDaysInMonth(_monthStart);
    final firstDayOfWeek = _monthStart.weekday; // 1=Monday, 7=Sunday

    // Calculate padding days for alignment
    final paddingDays = firstDayOfWeek - 1;
    final totalCells = paddingDays + daysInMonth;
    final rows = (totalCells / 7).ceil();

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
                  fontSize: 11,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 4),

        // Date cells with padding
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: rows * 7,
          itemBuilder: (context, index) {
            // Skip padding cells
            if (index < paddingDays || index >= paddingDays + daysInMonth) {
              return Container();
            }

            final dayNumber = index - paddingDays + 1;
            final date = DateTime(_monthStart.year, _monthStart.month, dayNumber);
            final dayDoses = monthDoses
                .where((d) =>
                    d.date.year == date.year &&
                    d.date.month == date.month &&
                    d.date.day == date.day)
                .toList();

            // Count by status
            final completed = dayDoses.where((d) => d.status == 'COMPLETED').length;
            final scheduled = dayDoses.where((d) => d.status == 'SCHEDULED').length;
            final missed = dayDoses.where((d) => d.status == 'MISSED').length;

            // Determine cell color
            Color cellColor = AppColors.surface;
            if (missed > 0) {
              cellColor = AppColors.error.withOpacity(0.2);
            } else if (scheduled > 0 && completed == 0) {
              cellColor = const Color(0xFF1E4620);
            } else if (completed > 0) {
              cellColor = const Color(0xFF0D2E1F);
            }

            final isToday = date.year == DateTime.now().year &&
                date.month == DateTime.now().month &&
                date.day == DateTime.now().day;

            final hasLab = labDates.any((labDate) =>
                labDate.year == date.year &&
                labDate.month == date.month &&
                labDate.day == date.day);

            return GestureDetector(
              onTap: dayDoses.isNotEmpty
                  ? () => _showDayDetail(context, date, dayDoses)
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  color: cellColor,
                  border: Border.all(
                    color: isToday ? AppColors.primary : AppColors.border,
                    width: isToday ? 2 : 0.5,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayNumber.toString(),
                      style: WintermmuteStyles.bodyStyle.copyWith(
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        fontSize: 11,
                      ),
                    ),
                    if (dayDoses.isNotEmpty || hasLab) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (completed > 0)
                            const SizedBox(
                              width: 3,
                              height: 3,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0xFF39FF14),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          if (scheduled > 0)
                            const Padding(
                              padding: EdgeInsets.only(left: 1),
                              child: SizedBox(
                                width: 3,
                                height: 3,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF00FFFF),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          if (hasLab)
                            const Padding(
                              padding: EdgeInsets.only(left: 1),
                              child: Icon(
                                Icons.science,
                                size: 6,
                                color: Color(0xFFFF00FF),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
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
          if (dose.status == 'SCHEDULED') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showQuickLogModal(context, dose),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'MARK AS TAKEN',
                  style: WintermmuteStyles.bodyStyle.copyWith(
                    color: AppColors.background,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Quick-log modal with injection site picker
  void _showQuickLogModal(BuildContext context, DoseInstance dose) {
    String? selectedSite;
    final injectionSites = [
      'Left Abdomen',
      'Right Abdomen',
      'Left Thigh',
      'Right Thigh',
      'Left Deltoid',
      'Right Deltoid',
      'Left Glute',
      'Right Glute',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log Dose',
                      style: WintermmuteStyles.titleStyle,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${dose.peptideName} - ${dose.doseAmount}mg',
                      style: WintermmuteStyles.bodyStyle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${dose.time} • ${dose.route}',
                      style: WintermmuteStyles.smallStyle
                          .copyWith(color: AppColors.textMid),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Injection Site (Optional)',
                      style: WintermmuteStyles.bodyStyle.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedSite,
                      decoration: InputDecoration(
                        hintText: 'Select injection site',
                        hintStyle: WintermmuteStyles.bodyStyle
                            .copyWith(color: AppColors.textDim),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                      dropdownColor: AppColors.surface,
                      style: WintermmuteStyles.bodyStyle,
                      items: injectionSites.map((site) {
                        return DropdownMenuItem(
                          value: site,
                          child: Text(site),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSite = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              'CANCEL',
                              style: WintermmuteStyles.bodyStyle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await _logDose(dose, selectedSite);
                              if (context.mounted) {
                                Navigator.pop(context);
                                // Close the day detail sheet too
                                Navigator.pop(context);
                                // Refresh the calendar
                                ref.refresh(upcomingDosesProvider);
                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Dose logged successfully!',
                                      style: WintermmuteStyles.bodyStyle,
                                    ),
                                    backgroundColor: AppColors.accent,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.background,
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
          },
        );
      },
    );
  }

  // Log dose to database
  Future<void> _logDose(DoseInstance dose, String? injectionSite) async {
    try {
      final service = ref.read(doseLogsServiceProvider);

      // Update the dose_log status to COMPLETED
      if (dose.doseLogId.isNotEmpty) {
        await service.markAsCompleted(dose.doseLogId);

        // If injection site is provided, update it too
        if (injectionSite != null) {
          await Supabase.instance.client
              .from('dose_logs')
              .update({'injection_site': injectionSite})
              .eq('id', dose.doseLogId);
        }
      }
    } catch (e) {
      print('Error logging dose: $e');
    }
  }
}
