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
import '../widgets/cyberpunk_rain.dart';
import '../widgets/city_background.dart';
import '../widgets/app_header.dart';
import '../widgets/full_screen_modal.dart';
import '../widgets/dose_display.dart';
import '../widgets/common/scanlines_painter.dart' as common;

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
  bool _showMonthView = true; // Default to month/30-day view
  int _buildCounter = 0; // Debug: Track rebuilds

  // Reconstitution data (TODO: move to database)
  // Maps peptide name to reconstitution info: [totalMg, totalML]
  final Map<String, List<double>> _reconstitutionData = {
    'BPC-157': [5.0, 2.0],
    'TB-500': [5.0, 2.0],
    'GHK-Cu': [50.0, 2.0],
    'Semaglutide': [5.0, 2.0],
    'Tirzepatide': [10.0, 2.0],
    'CJC-1295': [2.0, 2.0],
    'Ipamorelin': [5.0, 2.0],
    'MOTS-c': [10.0, 2.0],
    'Thymosin Alpha-1': [5.0, 2.0],
    'PT-141': [10.0, 2.0],
  };

  // Calculate mL draw amount
  double calculateMLDraw(String peptideName, double doseMg) {
    final reconInfo = _reconstitutionData[peptideName];
    if (reconInfo == null) {
      return (doseMg / 5.0) * 2.0; // Default: 5mg/2mL
    }
    final totalMg = reconInfo[0];
    final totalML = reconInfo[1];
    final concentration = totalMg / totalML; // mg/mL
    return doseMg / concentration;
  }

  // Get consistent color per peptide (same as dashboard)
  Color getPeptideColor(String peptideName) {
    final hash = peptideName.hashCode;
    final colors = [
      const Color(0xFF00FFFF), // Cyan
      const Color(0xFF00FF00), // Green
      const Color(0xFFFF9800), // Amber
      const Color(0xFFFF00FF), // Magenta
      const Color(0xFFFFFF00), // Yellow
      const Color(0xFF00FF99), // Mint
    ];
    return colors[hash.abs() % colors.length];
  }

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

    return SafeArea(
      child: Stack(
        children: [
          // City background layer
          const Positioned.fill(
            child: CityBackground(
              enabled: true,
              animateLights: true,
              opacity: 0.3,
            ),
          ),
          // Rain effect layer
          const Positioned.fill(
            child: CyberpunkRain(
              enabled: true,
              particleCount: 40,
              opacity: 0.25,
            ),
          ),
          // Main scaffold content
          Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                // Header using reusable widget with view toggle
                AppHeader(
                  icon: Icons.calendar_month,
                  iconColor: WintermmuteStyles.colorCyan,
                  title: 'DOSE CALENDAR',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // CRT-styled view toggle button
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(
                            color: const Color(0xFF00FFFF),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00FFFF).withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _showMonthView = !_showMonthView;
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          child: Text(
                            _showMonthView ? 'MONTH' : 'WEEK',
                            style: WintermmuteStyles.bodyStyle.copyWith(
                              color: const Color(0xFF00FFFF),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      upcomingDoses.when(
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
                  return _showMonthView
                      ? _buildMonthGrid(displayDoses, labDates)
                      : _buildWeekGrid(displayDoses, labDates);
                }),
                const SizedBox(height: 16),

                // Status bar - only show for week view
                if (!_showMonthView)
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
                      // Scanlines overlay - use const for performance
                      const Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _ScanlinesPainter(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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

  // Compliance tracker widget - dystopian cyberpunk style
  Widget _buildComplianceTracker(List<DoseInstance> doses) {
    // NEW MODEL: Assume all past scheduled doses are taken unless explicitly marked as MISSED
    final pastDoses = doses.where((d) => d.date.isBefore(DateTime.now())).toList();
    final pastMissed = pastDoses.where((d) => d.status == 'MISSED').length;
    final pastTotal = pastDoses.length;
    final pastTaken = pastTotal - pastMissed;
    final pastComplianceRate = pastTotal > 0 ? (pastTaken / pastTotal * 100).toStringAsFixed(1) : '100.0';

    // For display: count logged doses (COMPLETED status)
    final logged = doses.where((d) => d.status == 'COMPLETED').length;
    final upcoming = doses.where((d) => d.date.isAfter(DateTime.now())).length;

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 20),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF00FFFF).withOpacity(0.6),
              width: 2,
            ),
            borderRadius: BorderRadius.zero,
            color: AppColors.background,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00FFFF).withOpacity(0.15),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Compliance rate
          Column(
            children: [
              Text(
                '$pastComplianceRate%',
                style: WintermmuteStyles.statValueAccentStyle.copyWith(
                  fontSize: 22,
                  color: const Color(0xFF00FFFF),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'COMPLIANCE',
                style: WintermmuteStyles.smallStyle.copyWith(
                  color: const Color(0xFF00FFFF).withOpacity(0.7),
                  fontSize: 9,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '($pastTaken/$pastTotal)',
                style: WintermmuteStyles.smallStyle.copyWith(
                  color: AppColors.textDim,
                  fontSize: 8,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          // Vertical divider
          Container(
            width: 1,
            height: 50,
            color: const Color(0xFF00FFFF).withOpacity(0.3),
          ),
          // Upcoming doses
          Column(
            children: [
              Text(
                '$upcoming',
                style: WintermmuteStyles.statValueStyle.copyWith(
                  fontSize: 22,
                  color: const Color(0xFF00FFFF),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'UPCOMING',
                style: WintermmuteStyles.smallStyle.copyWith(
                  color: const Color(0xFF00FFFF).withOpacity(0.7),
                  fontSize: 9,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Vertical divider
          Container(
            width: 1,
            height: 50,
            color: const Color(0xFF00FFFF).withOpacity(0.3),
          ),
          // Missed doses
          Column(
            children: [
              Text(
                '$pastMissed',
                style: WintermmuteStyles.statValueStyle.copyWith(
                  fontSize: 22,
                  color: const Color(0xFFFF0040),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'MISSED',
                style: WintermmuteStyles.smallStyle.copyWith(
                  color: const Color(0xFFFF0040).withOpacity(0.7),
                  fontSize: 9,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
        ),
        // Top enhancement badge
        Positioned(
          top: -12,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(color: const Color(0xFF00FFFF), width: 1),
            ),
            child: Text(
              'SYSTEM STATUS',
              style: WintermmuteStyles.smallStyle.copyWith(
                color: const Color(0xFF00FFFF),
                fontSize: 7,
                letterSpacing: 1.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // Bottom enhancement badge
        Positioned(
          bottom: -12,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(color: const Color(0xFF00FFFF), width: 1),
            ),
            child: Text(
              'PROTOCOL ACTIVE',
              style: WintermmuteStyles.smallStyle.copyWith(
                color: const Color(0xFF00FFFF),
                fontSize: 7,
                letterSpacing: 1.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCycleId = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedCycleId == null
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _selectedCycleId == null
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.3),
                    width: _selectedCycleId == null ? 2 : 1,
                  ),
                ),
                child: Text(
                  'ALL CYCLES',
                  style: TextStyle(
                    color: _selectedCycleId == null
                        ? Colors.black
                        : AppColors.primary,
                    fontSize: 13,
                    fontWeight: _selectedCycleId == null
                        ? FontWeight.bold
                        : FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          ...cycles.entries.map((entry) {
            final isSelected = _selectedCycleId == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCycleId = isSelected ? null : entry.key;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.secondary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.secondary
                          : AppColors.primary.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    entry.value.toUpperCase(),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.black
                          : AppColors.primary,
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // 7-column week grid - CRT styled
  Widget _buildWeekGrid(List<DoseInstance> weekDoses, List<DateTime> labDates) {
    const daysOfWeek = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return Column(
      children: [
        // Day headers - CRT styled with cyan text
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
          ),
          itemCount: 7,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          itemBuilder: (context, index) {
            return Center(
              child: Text(
                daysOfWeek[index],
                style: WintermmuteStyles.bodyStyle.copyWith(
                  color: const Color(0xFF00FFFF),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Date cells - optimize with keys and performance flags
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
          addAutomaticKeepAlives: false, // Optimize: Reduce memory overhead
          addRepaintBoundaries: true, // Keep repaint boundaries for interactive cells
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
              cellColor = AppColors.error.withOpacity(0.15);
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
                      color: AppColors.background,
                      border: Border.all(
                        color: isToday ? const Color(0xFF00FFFF) : AppColors.textMid.withOpacity(0.4),
                        width: isToday ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.zero,
                      boxShadow: isToday ? [
                        BoxShadow(
                          color: const Color(0xFF00FFFF).withOpacity(0.2),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ] : null,
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
                          // Dose count badge - simple text
                          Text(
                            '${dayDoses.length}×',
                            style: WintermmuteStyles.smallStyle.copyWith(
                              color: const Color(0xFF00FFFF),
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Status indicator row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (completed > 0)
                                const Icon(Icons.check_circle, size: 8, color: Color(0xFF39FF14)),
                              if (scheduled > 0)
                                const Icon(Icons.schedule, size: 8, color: Color(0xFF00FFFF)),
                              if (missed > 0)
                                const Icon(Icons.cancel, size: 8, color: Color(0xFFFF0040)),
                            ],
                          ),
                        ],
                        if (hasLab && dayDoses.isEmpty)
                          const Icon(Icons.science, size: 10, color: Color(0xFFFF00FF)),
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
        // Day headers - CRT styled
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
          ),
          itemCount: 7,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          itemBuilder: (context, index) {
            return Center(
              child: Text(
                daysOfWeek[index],
                style: WintermmuteStyles.bodyStyle.copyWith(
                  color: const Color(0xFF00FFFF),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),

        // Date cells with padding - optimize with performance flags
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
          addAutomaticKeepAlives: false, // Optimize: Reduce memory overhead
          addRepaintBoundaries: true, // Keep repaint boundaries for interactive cells
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
              cellColor = AppColors.error.withOpacity(0.15);
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
                  color: AppColors.background,
                  border: Border.all(
                    color: isToday ? const Color(0xFF00FFFF) : AppColors.border.withOpacity(0.3),
                    width: isToday ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.zero,
                  boxShadow: isToday ? [
                    BoxShadow(
                      color: const Color(0xFF00FFFF).withOpacity(0.15),
                      blurRadius: 3,
                      spreadRadius: 1,
                    ),
                  ] : null,
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
                      const SizedBox(height: 3),
                      // Dose count indicator - compact month view style
                      if (dayDoses.isNotEmpty)
                        Text(
                          '${dayDoses.length}×',
                          style: WintermmuteStyles.smallStyle.copyWith(
                            color: const Color(0xFF00FFFF),
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (completed > 0)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 0.5),
                              child: Icon(
                                Icons.check_circle,
                                size: 5,
                                color: Color(0xFF39FF14),
                              ),
                            ),
                          if (scheduled > 0)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 0.5),
                              child: Icon(
                                Icons.schedule,
                                size: 5,
                                color: Color(0xFF00FFFF),
                              ),
                            ),
                          if (missed > 0)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 0.5),
                              child: Icon(
                                Icons.cancel,
                                size: 5,
                                color: Color(0xFFFF0040),
                              ),
                            ),
                          if (hasLab)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 0.5),
                              child: Icon(
                                Icons.science,
                                size: 5,
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

  // Day detail modal with CRT resistance aesthetic
  void _showDayDetail(
    BuildContext context,
    DateTime date,
    List<DoseInstance> dayDoses,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
        ),
        child: Stack(
          children: [
            // Cyberpunk background effects
            Positioned.fill(
              child: CityBackground(enabled: true, opacity: 0.15),
            ),
            Positioned.fill(
              child: CyberpunkRain(enabled: true, opacity: 0.1),
            ),
            // Main content
            Column(
          children: [
            // CRT-styled header with cyan theme
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF00FFFF).withOpacity(0.6),
                    width: 2,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FFFF).withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: DOSE DETAIL badge (left) + close button (right)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: const Color(0xFF00FFFF).withOpacity(0.8), size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'DAILY DOSES',
                            style: TextStyle(
                              color: const Color(0xFF00FFFF).withOpacity(0.8),
                              fontSize: 9,
                              fontFamily: 'monospace',
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: const Color(0xFF00FFFF).withOpacity(0.9)),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Date below
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE').format(date).toUpperCase(),
                        style: TextStyle(
                          color: const Color(0xFF00FFFF).withOpacity(0.7),
                          fontSize: 10,
                          fontFamily: 'monospace',
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(date).toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF00FFFF),
                          fontSize: 16,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Dose list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: dayDoses.map((dose) => _buildDoseCard(context, dose)).toList(),
              ),
            ),
            ],
          ),
          ],
        ),
      ),
    );
  }

  // CRT-styled dose card matching calendar aesthetic
  Widget _buildDoseCard(BuildContext context, DoseInstance dose) {
    // Determine status for coloring
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isPast = dose.date.isBefore(today);

    final peptideColor = getPeptideColor(dose.peptideName);

    final isCompleted = dose.status == 'COMPLETED';
    final isMissed = dose.status == 'MISSED';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: const Color(0xFF00FFFF).withOpacity(0.8),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FFFF).withOpacity(0.25),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle scanlines
          Positioned.fill(
            child: CustomPaint(
              painter: common.ScanlinesPainter(
                opacity: 0.05,
                spacing: 3.0,
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: peptide name, time, route, dose display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dose.peptideName.toUpperCase(),
                          style: TextStyle(
                            color: const Color(0xFF00FFFF),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: peptideColor.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dose.time,
                              style: TextStyle(
                                color: peptideColor.withOpacity(0.7),
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.medical_services,
                              size: 12,
                              color: peptideColor.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dose.route.toUpperCase(),
                              style: TextStyle(
                                color: peptideColor.withOpacity(0.7),
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // DoseDisplay widget on right
                  DoseDisplay(
                    doseMg: dose.doseAmount,
                    peptideName: dose.peptideName,
                    color: peptideColor,
                    showLabel: false,
                    showSyringe: true,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Status badge
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: peptideColor.withOpacity(0.6),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 12,
                        color: peptideColor.withOpacity(0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ADMINISTERED',
                        style: TextStyle(
                          color: peptideColor.withOpacity(0.8),
                          fontSize: 9,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isMissed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFFF0040).withOpacity(0.6),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cancel,
                        size: 12,
                        color: const Color(0xFFFF0040).withOpacity(0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'MISSED',
                        style: TextStyle(
                          color: const Color(0xFFFF0040).withOpacity(0.8),
                          fontSize: 9,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isPast)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF00FF00).withOpacity(0.6),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check,
                        size: 12,
                        color: const Color(0xFF00FF00).withOpacity(0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ASSUMED TAKEN',
                        style: TextStyle(
                          color: const Color(0xFF00FF00).withOpacity(0.8),
                          fontSize: 9,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: peptideColor.withOpacity(0.6),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: peptideColor.withOpacity(0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'SCHEDULED',
                        style: TextStyle(
                          color: peptideColor.withOpacity(0.8),
                          fontSize: 9,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              // Action buttons (only for scheduled doses)
              if (dose.status == 'SCHEDULED') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildCRTButton(
                        label: 'MARK MISSED',
                        icon: Icons.cancel_outlined,
                        color: const Color(0xFFFF0040),
                        onPressed: () => _markAsMissed(context, dose),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCRTButton(
                        label: 'LOG EFFECTS',
                        icon: Icons.note_add_outlined,
                        color: peptideColor,
                        onPressed: () => _showSideEffectsModal(context, dose),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // CRT-styled action button
  Widget _buildCRTButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: color.withOpacity(0.6), width: 2),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color.withOpacity(0.8), size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.85),
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
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

class _ScanlinesPainter extends CustomPainter {
  const _ScanlinesPainter();

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
