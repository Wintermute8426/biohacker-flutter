import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../services/dose_schedule_service.dart';
import '../services/dose_logs_service.dart';
import '../services/labs_database.dart';
import '../widgets/side_effects_modal.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> with WidgetsBindingObserver {
  late DateTime _weekStart;
  late DateTime _monthStart;
  String? _selectedCycleId;
  String? _selectedDate;
  bool _showMonthView = false; // Toggle between week and month views
  int _buildCounter = 0; // Debug: Track rebuilds

  @override
  void initState() {
    super.initState();
    _weekStart = _getWeekStart(DateTime.now());
    _monthStart = _getMonthStart(DateTime.now());
    WidgetsBinding.instance.addObserver(this);
    print('[Calendar] SYNC FIX: initState called, lifecycle observer added for missed dose sync');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // SYNC FIX: Aggressively refresh when app resumes
    if (state == AppLifecycleState.resumed) {
      print('[Calendar] SYNC FIX: App resumed, forcing immediate refresh');
      ref.refresh(upcomingDosesProvider);
      ref.refresh(doseSchedulesProvider);
    }
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

  @override
  Widget build(BuildContext context) {
    _buildCounter++;
    debugPrint('🔴 [Calendar] BUILD START: Build #$_buildCounter called');
    // ISSUE 1 FIX: Aggressively watch the provider and log when it changes
    final upcomingDoses = ref.watch(upcomingDosesProvider);
    debugPrint('🔴 [Calendar] ISSUE 1 DEBUG: Build #$_buildCounter called. Provider state: ${upcomingDoses.runtimeType}');

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
          // View toggle button - switches between week and month view
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.accent.withOpacity(0.5),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(_showMonthView ? Icons.view_week : Icons.calendar_month),
              onPressed: () {
                print('[Calendar] ISSUE 2 FIX: Toggle button pressed. Current: $_showMonthView');
                setState(() {
                  _showMonthView = !_showMonthView;
                  print('[Calendar] ISSUE 2 FIX: New value: $_showMonthView');
                });
                // Show feedback that view changed
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _showMonthView ? 'Switched to Month View' : 'Switched to Week View',
                      style: WintermmuteStyles.bodyStyle,
                    ),
                    backgroundColor: AppColors.accent,
                    duration: const Duration(milliseconds: 800),
                  ),
                );
                print('[Calendar] ISSUE 2 FIX: setState complete, SnackBar shown');
              },
              color: AppColors.accent,
              tooltip: _showMonthView ? 'Switch to Week View' : 'Switch to Month View',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: _goToToday,
            color: AppColors.primary,
          ),
          // SYNC FIX: Aggressive refresh button with immediate provider refetch
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.primary.withOpacity(0.5),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                print('[Calendar] SYNC FIX: Manual refresh triggered');
                ref.refresh(upcomingDosesProvider);
                ref.refresh(doseSchedulesProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Calendar refreshed',
                      style: WintermmuteStyles.bodyStyle,
                    ),
                    backgroundColor: AppColors.primary,
                    duration: const Duration(milliseconds: 800),
                  ),
                );
              },
              color: AppColors.primary,
              tooltip: 'Refresh calendar',
            ),
          ),
        ],
      ),
      body: upcomingDoses.when(
        data: (doses) {
          // ISSUE 1 FIX: Log dose data to verify missed status is reflected
          print('[Calendar] ISSUE 1 DEBUG: Got ${doses.length} doses from provider');
          final missedCount = doses.where((d) => d.status == 'MISSED').length;
          print('[Calendar] ISSUE 1 DEBUG: Found $missedCount missed doses');

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
                // ISSUE 2 DEBUG: Log current view mode
                Builder(builder: (context) {
                  print('[Calendar] ISSUE 2 DEBUG: Rendering view. _showMonthView = $_showMonthView');
                  return const SizedBox.shrink();
                }),

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
                Builder(builder: (context) {
                  print('[Calendar] ISSUE 2 DEBUG: Building grid. _showMonthView = $_showMonthView');
                  return _showMonthView
                      ? _buildMonthGrid(displayDoses, labDates)
                      : _buildWeekGrid(displayDoses, labDates);
                }),
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
    // NEW MODEL: Assume all past scheduled doses are taken unless explicitly marked as MISSED
    final pastDoses = doses.where((d) => d.date.isBefore(DateTime.now())).toList();
    final pastMissed = pastDoses.where((d) => d.status == 'MISSED').length;
    final pastTotal = pastDoses.length;
    final pastTaken = pastTotal - pastMissed; // Everything except explicitly missed
    final pastComplianceRate = pastTotal > 0 ? (pastTaken / pastTotal * 100).toStringAsFixed(1) : '100.0';

    // For display: count logged doses (COMPLETED status)
    final logged = doses.where((d) => d.status == 'COMPLETED').length;
    final total = doses.length;

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
                '($pastTaken/$pastTotal assumed taken)',
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
                '$logged',
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
                '$pastMissed',
                style: WintermmuteStyles.statValueStyle.copyWith(
                  fontSize: 20,
                  color: AppColors.error,
                ),
              ),
              Text(
                'Missed',
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
            debugPrint('🔴 [WEEK CELL] Building cell for date: ${date.year}-${date.month}-${date.day}');

            final dayDoses = weekDoses
                .where((d) =>
                    d.date.year == date.year &&
                    d.date.month == date.month &&
                    d.date.day == date.day)
                .toList();

            debugPrint('🔴 [WEEK CELL] Query result for ${date.year}-${date.month}-${date.day}: ${dayDoses.length} doses found');
            for (final d in dayDoses) {
              debugPrint('🔴   - Dose: ${d.peptideName} ${d.doseAmount}mg, status=${d.status}, logId=${d.doseLogId}');
            }

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

            // ISSUE 1 DEBUG: Log every day that has doses
            if (dayDoses.isNotEmpty) {
              print('[ISSUE1 DEBUG] WEEK VIEW - Date ${date.year}-${date.month}-${date.day}: ${dayDoses.length} doses');
              for (final d in dayDoses) {
                print('[ISSUE1 DEBUG]   - ${d.peptideName} ${d.doseAmount}mg');
                print('[ISSUE1 DEBUG]     status: ${d.status}');
                print('[ISSUE1 DEBUG]     doseLogId: ${d.doseLogId}');
                print('[ISSUE1 DEBUG]     cycleId: ${d.cycleId}');
                print('[ISSUE1 DEBUG]     date: ${d.date}');
              }
              print('[ISSUE1 DEBUG]   Status counts: completed=$completed, scheduled=$scheduled, missed=$missed');
            }

            final isToday = date.year == DateTime.now().year &&
                date.month == DateTime.now().month &&
                date.day == DateTime.now().day;
            final isPast = date.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
            final isFuture = date.isAfter(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));

            // NEW MODEL: Determine cell color based on new logic
            Color cellColor = AppColors.surface;
            debugPrint('🔴 [WEEK CELL] Cell color logic for ${date.year}-${date.month}-${date.day}:');
            debugPrint('🔴   missed=$missed, completed=$completed, scheduled=$scheduled');
            debugPrint('🔴   isPast=$isPast, isFuture=$isFuture, isToday=$isToday');
            if (missed > 0) {
              // Bright red for explicitly missed doses
              cellColor = AppColors.error.withOpacity(0.5);
              debugPrint('🔴   → Cell color: RED (missed=$missed doses)');
            } else if (isPast && dayDoses.isNotEmpty) {
              // Green for past scheduled doses (assumed taken unless missed)
              cellColor = const Color(0xFF0D2E1F);
              debugPrint('🔴   → Cell color: GREEN (past assumed taken)');
            } else if (isFuture && dayDoses.isNotEmpty) {
              // Cyan for future scheduled doses
              cellColor = const Color(0xFF1E4620);
              debugPrint('🔴   → Cell color: CYAN (future scheduled)');
            } else if (isToday && dayDoses.isNotEmpty) {
              // Cyan for today's scheduled doses
              cellColor = const Color(0xFF1E4620);
              debugPrint('🔴   → Cell color: CYAN (today scheduled)');
            } else {
              debugPrint('🔴   → Cell color: DEFAULT (no doses or no match)');
            }

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
                                  const Padding(
                                    padding: EdgeInsets.only(left: 2),
                                    child: SizedBox(
                                      width: 4,
                                      height: 4,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Color(0xFF00FFFF),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (missed > 0)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 2),
                                    child: SizedBox(
                                      width: 4,
                                      height: 4,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Color(0xFFFF0000),
                                          shape: BoxShape.circle,
                                        ),
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
    const daysOfWeek = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    final daysInMonth = _getDaysInMonth(_monthStart);
    final firstDayOfWeek = _monthStart.weekday; // 1=Monday, 7=Sunday

    // Calculate padding days for alignment (convert to Sunday-based: 1=Mon->1, 7=Sun->0)
    final paddingDays = firstDayOfWeek == 7 ? 0 : firstDayOfWeek;
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
            debugPrint('🔴 [MONTH CELL] Building cell for date: ${date.year}-${date.month}-${date.day}');

            final dayDoses = monthDoses
                .where((d) =>
                    d.date.year == date.year &&
                    d.date.month == date.month &&
                    d.date.day == date.day)
                .toList();

            debugPrint('🔴 [MONTH CELL] Query result for ${date.year}-${date.month}-${date.day}: ${dayDoses.length} doses found');
            for (final d in dayDoses) {
              debugPrint('🔴   - Dose: ${d.peptideName} ${d.doseAmount}mg, status=${d.status}, logId=${d.doseLogId}');
            }

            // Count by status
            final completed = dayDoses.where((d) => d.status == 'COMPLETED').length;
            final scheduled = dayDoses.where((d) => d.status == 'SCHEDULED').length;
            final missed = dayDoses.where((d) => d.status == 'MISSED').length;

            // ISSUE 1 DEBUG: Log every day that has doses
            if (dayDoses.isNotEmpty) {
              print('[ISSUE1 DEBUG] MONTH VIEW - Date ${date.year}-${date.month}-${date.day}: ${dayDoses.length} doses');
              for (final d in dayDoses) {
                print('[ISSUE1 DEBUG]   - ${d.peptideName} ${d.doseAmount}mg');
                print('[ISSUE1 DEBUG]     status: ${d.status}');
                print('[ISSUE1 DEBUG]     doseLogId: ${d.doseLogId}');
                print('[ISSUE1 DEBUG]     cycleId: ${d.cycleId}');
                print('[ISSUE1 DEBUG]     date: ${d.date}');
              }
              print('[ISSUE1 DEBUG]   Status counts: completed=$completed, scheduled=$scheduled, missed=$missed');
            }

            final isToday = date.year == DateTime.now().year &&
                date.month == DateTime.now().month &&
                date.day == DateTime.now().day;
            final isPast = date.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
            final isFuture = date.isAfter(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));

            // NEW MODEL: Determine cell color based on new logic
            Color cellColor = AppColors.surface;
            debugPrint('🔴 [MONTH CELL] Cell color logic for ${date.year}-${date.month}-${date.day}:');
            debugPrint('🔴   missed=$missed, completed=$completed, scheduled=$scheduled');
            debugPrint('🔴   isPast=$isPast, isFuture=$isFuture, isToday=$isToday');
            if (missed > 0) {
              // Bright red for explicitly missed doses - more visible in month view
              cellColor = AppColors.error.withOpacity(0.4);
              debugPrint('🔴   → Cell color: RED (missed=$missed doses)');
            } else if (isPast && dayDoses.isNotEmpty) {
              // Green for past scheduled doses (assumed taken unless missed)
              cellColor = const Color(0xFF0D2E1F);
              debugPrint('🔴   → Cell color: GREEN (past assumed taken)');
            } else if (isFuture && dayDoses.isNotEmpty) {
              // Cyan for future scheduled doses
              cellColor = const Color(0xFF1E4620);
              debugPrint('🔴   → Cell color: CYAN (future scheduled)');
            } else if (isToday && dayDoses.isNotEmpty) {
              // Cyan for today's scheduled doses
              cellColor = const Color(0xFF1E4620);
              debugPrint('🔴   → Cell color: CYAN (today scheduled)');
            } else {
              debugPrint('🔴   → Cell color: DEFAULT (no doses or no match)');
            }

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
                          if (missed > 0)
                            const Padding(
                              padding: EdgeInsets.only(left: 1),
                              child: SizedBox(
                                width: 3,
                                height: 3,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFF0000),
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final logged = weekDoses.where((d) => d.status == 'COMPLETED').length;
    final pastScheduled = weekDoses.where((d) =>
        d.status == 'SCHEDULED' && d.date.isBefore(today)).length;
    final futureScheduled = weekDoses.where((d) =>
        d.status == 'SCHEDULED' && (d.date.isAfter(today) || d.date.isAtSameMomentAs(today))).length;
    final missed = weekDoses.where((d) => d.status == 'MISSED').length;

    // NEW MODEL: Show "Assumed Taken" for past scheduled doses
    final assumedTaken = pastScheduled + logged;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatusChip('$assumedTaken', 'Assumed Taken', const Color(0xFF39FF14)),
        _buildStatusChip('$futureScheduled', 'Upcoming', const Color(0xFF00FFFF)),
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
    // NEW MODEL: Assume all past doses are taken unless explicitly marked as missed
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isPast = dose.date.isBefore(today);

    final statusColor = dose.status == 'COMPLETED'
        ? const Color(0xFF39FF14)
        : dose.status == 'MISSED'
            ? AppColors.error
            : isPast
                ? const Color(0xFF39FF14) // Past scheduled = assumed taken (green)
                : const Color(0xFF00FFFF); // Future scheduled = upcoming (cyan)

    final displayStatus = dose.status == 'SCHEDULED' && isPast
        ? 'ASSUMED TAKEN'
        : dose.status;

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
                  displayStatus,
                  style: WintermmuteStyles.smallStyle.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          if (dose.status == 'SCHEDULED') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _markAsMissed(context, dose),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'MARK AS MISSED',
                      style: WintermmuteStyles.bodyStyle.copyWith(
                        color: AppColors.background,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showSideEffectsModal(context, dose),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'LOG SIDE EFFECTS',
                      style: WintermmuteStyles.bodyStyle.copyWith(
                        color: AppColors.background,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Mark dose as missed
  Future<void> _markAsMissed(BuildContext context, DoseInstance dose) async {
    try {
      final service = ref.read(doseLogsServiceProvider);
      final userId = ref.read(currentUserIdProvider);

      if (userId == null) {
        print('Error: No user ID found');
        return;
      }

      String doseLogId = dose.doseLogId;

      // If no dose_log exists yet, create one first
      if (doseLogId.isEmpty) {
        print('[DEBUG] Creating new dose_log entry for missed dose');
        final supabase = Supabase.instance.client;

        // Parse time to create proper DateTime
        final timeParts = dose.time.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final loggedAt = DateTime(
          dose.date.year,
          dose.date.month,
          dose.date.day,
          hour,
          minute
        );

        final response = await supabase
            .from('dose_logs')
            .insert({
              'user_id': userId,
              'cycle_id': dose.cycleId,
              'schedule_id': dose.scheduleId,
              'dose_amount': dose.doseAmount,
              'route': dose.route,
              'logged_at': loggedAt.toIso8601String(),
              'status': 'MISSED',
            })
            .select()
            .single();

        doseLogId = response['id'] as String;
        print('[DEBUG] Created dose_log with ID: $doseLogId');
      } else {
        // Update existing dose_log
        await service.markAsMissed(doseLogId);
      }

      if (context.mounted) {
        // Close the day detail sheet
        Navigator.pop(context);
        // CRITICAL FIX: Use ref.refresh instead of invalidate for immediate sync
        // ref.invalidate only marks for rebuild, ref.refresh forces immediate refetch
        ref.refresh(upcomingDosesProvider);
        ref.refresh(doseSchedulesProvider);
        print('[Calendar] SYNC FIX: Forced immediate provider refresh after marking missed');
        // Show feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Dose marked as missed',
              style: WintermmuteStyles.bodyStyle,
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      print('Error marking dose as missed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error marking dose as missed: $e',
              style: WintermmuteStyles.bodyStyle,
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Show side effects modal
  void _showSideEffectsModal(BuildContext context, DoseInstance dose) {
    // Import the SideEffectsModal widget
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (context) {
        return SideEffectsModal(
          dose: dose,
          onSaved: () {
            // Close the day detail sheet
            Navigator.pop(context);
            // SYNC FIX: Use ref.refresh for immediate calendar sync
            ref.refresh(upcomingDosesProvider);
            ref.refresh(doseSchedulesProvider);
            print('[Calendar] SYNC FIX: Side effects saved, providers refreshed');
          },
        );
      },
    );
  }
}
