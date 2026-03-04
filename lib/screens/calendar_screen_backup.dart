import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../services/calendar_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CalendarService _calendarService = CalendarService();
  
  DateTime _selectedMonth = DateTime.now();
  Map<DateTime, CalendarEvent> _events = {};
  bool _isLoading = true;
  
  // Filters
  bool _showCycles = true;
  bool _showProtocols = true;
  bool _showLabs = true;
  bool _showWeight = true;

  @override
  void initState() {
    super.initState();
    _loadMonthEvents();
  }

  Future<void> _loadMonthEvents() async {
    setState(() => _isLoading = true);

    try {
      final events = await _calendarService.getMonthEvents(
        _selectedMonth.year,
        _selectedMonth.month,
      );

      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading calendar events: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load calendar: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _loadMonthEvents();
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
    _loadMonthEvents();
  }

  void _goToToday() {
    setState(() {
      _selectedMonth = DateTime.now();
    });
    _loadMonthEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'CALENDAR',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            color: AppColors.primary,
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: _goToToday,
            color: AppColors.primary,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadMonthEvents,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildMonthHeader(),
                  const SizedBox(height: 16),
                  _buildCalendarGrid(),
                  const SizedBox(height: 16),
                  _buildLegend(),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousMonth,
            color: AppColors.primary,
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedMonth),
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextMonth,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startWeekday = firstDay.weekday % 7; // 0 = Sunday

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Weekday headers
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                  .map((d) => SizedBox(
                        width: 40,
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMid,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          // Days grid
          ...List.generate((daysInMonth + startWeekday + 6) ~/ 7, (week) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (weekday) {
                  final dayNumber = week * 7 + weekday - startWeekday + 1;
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const SizedBox(width: 50, height: 70);
                  }

                  final date = DateTime(_selectedMonth.year, _selectedMonth.month, dayNumber);
                  final event = _events[date];
                  final isToday = _isToday(date);

                  return GestureDetector(
                    onTap: () => _showDayDetails(date, event),
                    child: Container(
                      width: 50,
                      height: 70,
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: isToday ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                        border: Border.all(
                          color: isToday ? AppColors.primary : AppColors.border,
                          width: isToday ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Day number
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              '$dayNumber',
                              style: TextStyle(
                                color: isToday ? AppColors.primary : AppColors.textLight,
                                fontSize: 12,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          // Event indicators
                          if (event != null && event.hasEvents)
                            Expanded(
                              child: _buildEventIndicators(event),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildEventIndicators(CalendarEvent event) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Cycle indicator (horizontal bar)
        if (_showCycles && event.cycles.isNotEmpty)
          Container(
            height: 3,
            width: 40,
            decoration: BoxDecoration(
              color: _getCycleColor(event.cycles.first.peptideName),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(height: 2),
        // Protocol badge
        if (_showProtocols && event.protocols.isNotEmpty)
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
        const SizedBox(height: 2),
        // Lab marker (red dot)
        if (_showLabs && event.labs.isNotEmpty)
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
        const SizedBox(height: 2),
        // Weight indicator
        if (_showWeight && event.weight != null)
          Icon(
            Icons.scale,
            size: 8,
            color: AppColors.textMid,
          ),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LEGEND',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildLegendItem(
            'Horizontal Bar',
            'Active cycle',
            Container(
              width: 30,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          _buildLegendItem(
            'Green Dot',
            'Protocol active',
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          _buildLegendItem(
            'Red Dot',
            'Lab result',
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
          _buildLegendItem(
            'Scale Icon',
            'Weight logged',
            Icon(
              Icons.scale,
              size: 12,
              color: AppColors.textMid,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, String description, Widget indicator) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 40, child: indicator),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                Text(description, style: TextStyle(color: AppColors.textDim, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDayDetails(DateTime date, CalendarEvent? event) {
    if (event == null || !event.hasEvents) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(date),
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            
            // Active Cycles
            if (event.cycles.isNotEmpty) ...[
              _buildDetailSection('ACTIVE CYCLES'),
              ...event.cycles.map((cycle) => _buildCycleItem(cycle)),
              const SizedBox(height: 16),
            ],

            // Protocols
            if (event.protocols.isNotEmpty) ...[
              _buildDetailSection('PROTOCOLS'),
              ...event.protocols.map((protocol) => _buildProtocolItem(protocol)),
              const SizedBox(height: 16),
            ],

            // Doses Logged
            if (event.doses.isNotEmpty) ...[
              _buildDetailSection('DOSES LOGGED'),
              ...event.doses.map((dose) => _buildDoseItem(dose)),
              const SizedBox(height: 16),
            ],

            // Weight
            if (event.weight != null) ...[
              _buildDetailSection('WEIGHT'),
              _buildWeightItem(event.weight!),
              const SizedBox(height: 16),
            ],

            // Labs
            if (event.labs.isNotEmpty) ...[
              _buildDetailSection('LAB RESULTS'),
              ...event.labs.map((lab) => _buildLabItem(lab)),
              const SizedBox(height: 16),
            ],

            // Side Effects
            if (event.sideEffects.isNotEmpty) ...[
              _buildDetailSection('SIDE EFFECTS'),
              ...event.sideEffects.map((effect) => _buildSideEffectItem(effect)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildCycleItem(CycleEvent cycle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: _getCycleColor(cycle.peptideName),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cycle.peptideName,
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${cycle.dose}mg ${cycle.route}',
                  style: TextStyle(color: AppColors.textMid, fontSize: 12),
                ),
                Text(
                  '${DateFormat('M/d').format(cycle.startDate)} - ${DateFormat('M/d').format(cycle.endDate)}',
                  style: TextStyle(color: AppColors.textDim, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolItem(ProtocolEvent protocol) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.bookmark, color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  protocol.name,
                  style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
                ),
                Text(
                  protocol.category,
                  style: TextStyle(color: AppColors.textMid, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoseItem(DoseEvent dose) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.medication, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dose.peptideName,
                  style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${dose.amount}mg ${dose.route ?? ""}',
                  style: TextStyle(color: AppColors.textMid, fontSize: 12),
                ),
                Text(
                  DateFormat('h:mm a').format(dose.loggedAt),
                  style: TextStyle(color: AppColors.textDim, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightItem(WeightEvent weight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.scale, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${weight.weightLbs.toStringAsFixed(1)} lbs',
                  style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
                ),
                if (weight.bodyFatPercent != null)
                  Text(
                    'Body Fat: ${weight.bodyFatPercent!.toStringAsFixed(1)}%',
                    style: TextStyle(color: AppColors.textMid, fontSize: 12),
                  ),
                if (weight.notes != null)
                  Text(
                    weight.notes!,
                    style: TextStyle(color: AppColors.textDim, fontSize: 10),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabItem(LabEvent lab) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.science, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Lab Report Uploaded',
              style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideEffectItem(SideEffectEvent effect) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  effect.symptom,
                  style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Severity: ${effect.severity}/10',
                  style: TextStyle(color: AppColors.textMid, fontSize: 12),
                ),
                if (effect.notes != null)
                  Text(
                    effect.notes!,
                    style: TextStyle(color: AppColors.textDim, fontSize: 10),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'FILTER EVENTS',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterCheckbox('Show Cycles', _showCycles, (value) {
              setState(() => _showCycles = value);
              Navigator.pop(context);
            }),
            _buildFilterCheckbox('Show Protocols', _showProtocols, (value) {
              setState(() => _showProtocols = value);
              Navigator.pop(context);
            }),
            _buildFilterCheckbox('Show Labs', _showLabs, (value) {
              setState(() => _showLabs = value);
              Navigator.pop(context);
            }),
            _buildFilterCheckbox('Show Weight', _showWeight, (value) {
              setState(() => _showWeight = value);
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCheckbox(String label, bool value, Function(bool) onChanged) {
    return CheckboxListTile(
      title: Text(label, style: TextStyle(color: AppColors.textLight)),
      value: value,
      onChanged: (newValue) => onChanged(newValue ?? value),
      activeColor: AppColors.primary,
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Color _getCycleColor(String peptideName) {
    final colors = [
      AppColors.primary,
      AppColors.accent,
      Colors.purple,
      Colors.orange,
      Colors.blue,
      Colors.pink,
    ];
    return colors[peptideName.hashCode % colors.length];
  }
}
