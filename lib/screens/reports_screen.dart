import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart' hide ScanlinesOverlay;
import '../services/reports_service.dart';
import '../widgets/common/scanlines_painter.dart';
import '../widgets/app_header.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/reports/dystopian_trend_chart.dart';
import '../widgets/reports/lab_result_card.dart';
import '../widgets/reports/cycle_timeline.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportsService _reportsService = ReportsService();

  int _selectedTabIndex = 0;
  bool _isLoading = true;

  // Data
  List<LabResultWithContext> _labsWithContext = [];
  List<CycleWindow> _cycles = [];
  List<AIInsight> _aiInsights = [];

  // Lab Results tab state
  int _expandedLabIndex = -1;

  // Trends tab state
  String _selectedCategory = 'HORMONES';
  Set<String> _selectedBiomarkers = {};

  // Reference ranges for chart shading
  static const Map<String, (double, double)> _referenceRanges = {
    'testosterone': (300.0, 900.0),
    'free_testosterone': (8.7, 25.0),
    'estradiol': (20.0, 40.0),
    'igf1': (100.0, 300.0),
    'hgh': (0.1, 5.0),
    'crp': (0.0, 3.0),
    'hdl': (40.0, 200.0),
    'ldl': (0.0, 130.0),
    'total_cholesterol': (0.0, 200.0),
    'triglycerides': (0.0, 150.0),
    'glucose': (70.0, 100.0),
    'insulin': (2.0, 12.0),
    'cortisol': (5.0, 20.0),
    'alt': (7.0, 56.0),
    'ast': (10.0, 40.0),
    'tsh': (0.4, 4.0),
    't3': (2.3, 4.2),
    't4': (4.5, 12.0),
    'prolactin': (4.0, 15.0),
    'psa': (0.0, 4.0),
  };

  final List<Color> _chartColorPalette = [
    AppColors.amber, // Amber
    AppColors.primary, // Cyan
    AppColors.secondary, // Magenta
    AppColors.accent, // Green
    Color(0xFFFFD740), // Yellow
    Color(0xFF00AAFF), // Blue
    Color(0xFFFF0088), // Pink
    Color(0xFFE040FB), // Purple
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _reportsService.getLabsWithCycleContext(),
        _reportsService.getCyclesForPeriod(
          DateTime.now().subtract(const Duration(days: 365)),
          DateTime.now(),
        ),
        _reportsService.generateAIInsights(),
      ]);

      if (mounted) {
        setState(() {
          _labsWithContext = results[0] as List<LabResultWithContext>;
          _cycles = results[1] as List<CycleWindow>;
          _aiInsights = results[2] as List<AIInsight>;
          _isLoading = false;

          // Auto-select first biomarker with data for trends
          _autoSelectBiomarkers();
        });
      }
    } catch (e) {
      print('Error loading reports data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _autoSelectBiomarkers() {
    // Find biomarkers that appear in 2+ labs
    final counts = <String, int>{};
    for (final lab in _labsWithContext) {
      for (final bc in lab.biomarkerChanges) {
        if (bc.currentValue != null) {
          counts[bc.name.toLowerCase()] = (counts[bc.name.toLowerCase()] ?? 0) + 1;
        }
      }
    }
    final available = counts.entries
        .where((e) => e.value >= 2)
        .map((e) => e.key)
        .toList();

    // Pick first one from hormones category if available
    for (final marker in available) {
      if (_getBiomarkerCategory(marker) == 'HORMONES') {
        _selectedBiomarkers = {marker};
        return;
      }
    }
    if (available.isNotEmpty) {
      _selectedBiomarkers = {available.first};
    }
  }

  Map<String, Color> _getBiomarkerColorMap() {
    final map = <String, Color>{};
    int i = 0;
    for (final marker in _selectedBiomarkers) {
      map[marker] = _chartColorPalette[i % _chartColorPalette.length];
      i++;
    }
    return map;
  }

  String _getBiomarkerCategory(String biomarkerName) {
    final name = biomarkerName.toLowerCase();
    if (name.contains('testosterone') || name.contains('estradiol') ||
        name.contains('e2') || name.contains('dht') || name.contains('cortisol') ||
        name.contains('igf') || name.contains('tsh') || name.contains('t3') ||
        name.contains('t4') || name.contains('prolactin')) {
      return 'HORMONES';
    }
    if (name.contains('glucose') || name.contains('insulin') ||
        name.contains('hba1c') || name.contains('crp')) {
      return 'METABOLIC';
    }
    if (name.contains('cholesterol') || name.contains('hdl') ||
        name.contains('ldl') || name.contains('triglyceride')) {
      return 'LIPIDS';
    }
    if (name.contains('calcium') || name.contains('magnesium') ||
        name.contains('zinc') || name.contains('iron')) {
      return 'MINERALS';
    }
    return 'OTHER';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          Column(
            children: [
              AppHeader(
                icon: Icons.assessment,
                iconColor: AppColors.primary,
                title: 'REPORTS',
              ),
              _buildTabSelector(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _buildTabContent(),
              ),
            ],
          ),
          const ScanlinesOverlay(opacity: 0.05),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    final tabs = ['LAB RESULTS', 'CYCLES', 'TRENDS', 'INSIGHTS'];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isActive = _selectedTabIndex == index;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedTabIndex = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.surface
                        : AppColors.primary.withOpacity(0.05),
                    border: Border.all(
                      color: isActive
                          ? AppColors.primary
                          : AppColors.borderDim,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? AppColors.primary : AppColors.textDim,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildLabResultsTab();
      case 1:
        return _buildCycleCorrelationTab();
      case 2:
        return _buildTrendsTab();
      case 3:
        return _buildInsightsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // ========== TAB 0: LAB RESULTS ==========
  Widget _buildLabResultsTab() {
    if (_labsWithContext.isEmpty) {
      return _buildOnboardingState(
        icon: Icons.science_outlined,
        title: 'NO LAB RESULTS YET',
        instructions: [
          'Upload your bloodwork PDF from the Labs tab',
          'We\'ll extract biomarkers automatically',
          'Track changes across multiple lab draws',
        ],
        actionLabel: 'GO TO LABS',
      );
    }

    // Sort by date descending
    final sortedLabs = List<LabResultWithContext>.from(_labsWithContext)
      ..sort((a, b) => b.labDate.compareTo(a.labDate));

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: _loadAllData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedLabs.length + 1, // +1 for summary header
        itemBuilder: (context, index) {
          if (index == 0) return _buildLabSummaryHeader(sortedLabs);
          final labIndex = index - 1;
          return LabResultCard(
            lab: sortedLabs[labIndex],
            isExpanded: _expandedLabIndex == labIndex,
            onTap: () {
              setState(() {
                _expandedLabIndex =
                    _expandedLabIndex == labIndex ? -1 : labIndex;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildLabSummaryHeader(List<LabResultWithContext> labs) {
    final totalLabs = labs.length;
    final latestDate = labs.isNotEmpty
        ? DateFormat('MMM d, yyyy').format(labs.first.labDate)
        : '--';

    // Count all out-of-range from latest lab
    final latestOutOfRange = labs.isNotEmpty
        ? labs.first.biomarkerChanges.where((b) => b.status != 'NORMAL').length
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          _buildStatColumn('TOTAL LABS', '$totalLabs', AppColors.primary),
          Container(
            width: 1,
            height: 30,
            color: AppColors.borderDim,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          _buildStatColumn('LATEST', latestDate, AppColors.textLight),
          Container(
            width: 1,
            height: 30,
            color: AppColors.borderDim,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          _buildStatColumn(
            'OUT OF RANGE',
            '$latestOutOfRange',
            latestOutOfRange > 0 ? AppColors.error : AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 8,
              color: AppColors.textDim,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ========== TAB 1: CYCLE CORRELATION ==========
  Widget _buildCycleCorrelationTab() {
    if (_cycles.isEmpty && _labsWithContext.isEmpty) {
      return _buildOnboardingState(
        icon: Icons.timeline,
        title: 'NO CYCLE DATA',
        instructions: [
          'Start a peptide cycle from the Cycles tab',
          'Upload bloodwork during your cycle',
          'See before/after comparisons here',
        ],
        actionLabel: 'GO TO CYCLES',
      );
    }

    return CycleTimeline(
      cycles: _cycles,
      labs: _labsWithContext,
    );
  }

  // ========== TAB 2: TRENDS ==========
  Widget _buildTrendsTab() {
    if (_labsWithContext.length < 2) {
      return _buildOnboardingState(
        icon: Icons.trending_up,
        title: 'NEED MORE DATA',
        instructions: [
          'Upload at least 2 lab results to see trends',
          'Each biomarker needs 2+ data points',
          'Get labs every 4-8 weeks for best tracking',
        ],
        actionLabel: 'UPLOAD LABS',
      );
    }

    // Get all available biomarkers with 2+ data points
    final availableBiomarkers = _getAvailableBiomarkers();

    if (availableBiomarkers.isEmpty) {
      return const EmptyState(
        icon: Icons.trending_up,
        title: 'NO TRENDING DATA',
        message: 'No biomarkers have enough data points (need 2+) to show trends',
      );
    }

    return Column(
      children: [
        _buildCategorySelector(availableBiomarkers),
        _buildBiomarkerSelector(availableBiomarkers),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: DystopianTrendChart(
              labResults: _labsWithContext,
              selectedBiomarkers: _selectedBiomarkers,
              biomarkerColors: _getBiomarkerColorMap(),
              referenceRanges: _referenceRanges,
            ),
          ),
        ),
      ],
    );
  }

  Map<String, List<String>> _getAvailableBiomarkers() {
    // Count data points per biomarker
    final counts = <String, int>{};
    for (final lab in _labsWithContext) {
      for (final bc in lab.biomarkerChanges) {
        if (bc.currentValue != null) {
          final key = bc.name.toLowerCase();
          counts[key] = (counts[key] ?? 0) + 1;
        }
      }
    }

    // Only keep biomarkers with 2+ data points, grouped by category
    final grouped = <String, List<String>>{};
    for (final entry in counts.entries) {
      if (entry.value >= 2) {
        final category = _getBiomarkerCategory(entry.key);
        grouped.putIfAbsent(category, () => []);
        grouped[category]!.add(entry.key);
      }
    }

    return grouped;
  }

  Widget _buildCategorySelector(Map<String, List<String>> availableBiomarkers) {
    final categories = availableBiomarkers.keys.toList()..sort();

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((category) {
            final isActive = _selectedCategory == category;
            final count = availableBiomarkers[category]?.length ?? 0;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedCategory = category),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.transparent,
                    border: Border.all(
                      color: isActive ? AppColors.primary : AppColors.borderDim,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$category ($count)',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive ? AppColors.primary : AppColors.textDim,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBiomarkerSelector(Map<String, List<String>> availableBiomarkers) {
    final markers = availableBiomarkers[_selectedCategory] ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: markers.map((marker) {
          final isSelected = _selectedBiomarkers.contains(marker);
          final colorIndex = markers.indexOf(marker);
          final color = _chartColorPalette[colorIndex % _chartColorPalette.length];

          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedBiomarkers.remove(marker);
                } else {
                  _selectedBiomarkers.add(marker);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
                border: Border.all(
                  color: color.withOpacity(isSelected ? 0.8 : 0.3),
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isSelected ? color : color.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    marker.toUpperCase().replaceAll('_', ' '),
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? color : AppColors.textMid,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ========== TAB 3: INSIGHTS ==========
  Widget _buildInsightsTab() {
    if (_labsWithContext.isEmpty) {
      return _buildOnboardingState(
        icon: Icons.psychology,
        title: 'NO DATA FOR INSIGHTS',
        instructions: [
          'Upload bloodwork to get personalized insights',
          'Track cycles to see correlations',
          'More data = better recommendations',
        ],
        actionLabel: 'GET STARTED',
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: _loadAllData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section 1: What changed during last cycle
          _buildLastCycleChanges(),
          const SizedBox(height: 16),

          // Section 2: Biomarkers needing attention
          _buildBiomarkersNeedingAttention(),
          const SizedBox(height: 16),

          // Section 3: Best responders
          _buildBestResponders(),
          const SizedBox(height: 16),

          // Section 4: AI insights
          if (_aiInsights.isNotEmpty) ...[
            _buildSectionHeader('AI ANALYSIS', Icons.psychology),
            const SizedBox(height: 8),
            ..._aiInsights.map((insight) => _buildInsightCard(insight)),
          ],
        ],
      ),
    );
  }

  Widget _buildLastCycleChanges() {
    // Find the most recent completed cycle
    final completedCycles = _cycles
        .where((c) => c.endDate.isBefore(DateTime.now()))
        .toList()
      ..sort((a, b) => b.endDate.compareTo(a.endDate));

    if (completedCycles.isEmpty) {
      return _buildInsightSection(
        'LAST CYCLE CHANGES',
        Icons.compare_arrows,
        AppColors.primary,
        [
          const Text(
            'No completed cycles yet. Finish a cycle to see biomarker changes.',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 11,
              color: AppColors.textMid,
            ),
          ),
        ],
      );
    }

    final lastCycle = completedCycles.first;

    // Find labs before and after this cycle
    final preWindow = lastCycle.startDate.subtract(const Duration(days: 30));
    final postWindow = lastCycle.endDate.add(const Duration(days: 14));

    final labsBefore = _labsWithContext
        .where((l) =>
            l.labDate.isAfter(preWindow) &&
            l.labDate.isBefore(lastCycle.startDate))
        .toList();
    final labsAfter = _labsWithContext
        .where((l) =>
            l.labDate.isAfter(lastCycle.startDate) &&
            l.labDate.isBefore(postWindow))
        .toList();

    if (labsBefore.isEmpty || labsAfter.isEmpty) {
      return _buildInsightSection(
        'LAST CYCLE: ${lastCycle.peptideName.toUpperCase()}',
        Icons.compare_arrows,
        _getPeptideColor(lastCycle.peptideName),
        [
          const Text(
            'Need labs before and after cycle to show changes. Upload bloodwork around your cycles.',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 11,
              color: AppColors.textMid,
            ),
          ),
        ],
      );
    }

    // Calculate changes
    final changes = <_InsightChange>[];
    final beforeLab = labsBefore.last;
    final afterLab = labsAfter.last;

    for (final afterMarker in afterLab.biomarkerChanges) {
      final beforeMarker = beforeLab.biomarkerChanges
          .where((b) => b.name == afterMarker.name)
          .firstOrNull;
      if (beforeMarker != null &&
          beforeMarker.currentValue != null &&
          afterMarker.currentValue != null &&
          beforeMarker.currentValue != 0) {
        final pct = ((afterMarker.currentValue! - beforeMarker.currentValue!) /
                beforeMarker.currentValue! *
                100);
        changes.add(_InsightChange(
          name: afterMarker.name,
          changePercent: pct,
          status: afterMarker.status,
        ));
      }
    }

    changes.sort((a, b) => b.changePercent.abs().compareTo(a.changePercent.abs()));

    return _buildInsightSection(
      'LAST CYCLE: ${lastCycle.peptideName.toUpperCase()}',
      Icons.compare_arrows,
      _getPeptideColor(lastCycle.peptideName),
      changes.take(5).map((c) {
        final isPositive = c.changePercent >= 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: isPositive ? AppColors.accent : AppColors.error,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  c.name,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    color: AppColors.textMid,
                  ),
                ),
              ),
              Text(
                '${isPositive ? '+' : ''}${c.changePercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? AppColors.accent : AppColors.error,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBiomarkersNeedingAttention() {
    if (_labsWithContext.isEmpty) return const SizedBox();

    // Get latest lab's out-of-range markers
    final latest = _labsWithContext
        .reduce((a, b) => a.labDate.isAfter(b.labDate) ? a : b);
    final outOfRange = latest.biomarkerChanges
        .where((b) => b.status != 'NORMAL' && b.currentValue != null)
        .toList();

    if (outOfRange.isEmpty) {
      return _buildInsightSection(
        'BIOMARKERS STATUS',
        Icons.check_circle_outline,
        AppColors.accent,
        [
          const Text(
            'All biomarkers within normal range. Keep it up.',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 11,
              color: AppColors.accent,
            ),
          ),
        ],
      );
    }

    return _buildInsightSection(
      'NEEDS ATTENTION (${outOfRange.length})',
      Icons.warning_amber,
      const Color(0xFFFFAA00),
      outOfRange.map((b) {
        final statusColor = b.status == 'HIGH' ? AppColors.error : const Color(0xFFFFAA00);
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  b.name,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    color: AppColors.textMid,
                  ),
                ),
              ),
              Text(
                '${b.currentValue!.toStringAsFixed(1)} ${b.unit ?? ''}',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  b.status,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBestResponders() {
    if (_labsWithContext.length < 2) return const SizedBox();

    // Sort labs chronologically
    final sorted = List<LabResultWithContext>.from(_labsWithContext)
      ..sort((a, b) => a.labDate.compareTo(b.labDate));

    final first = sorted.first;
    final last = sorted.last;

    // Calculate biggest improvements
    final improvements = <_InsightChange>[];
    for (final latestMarker in last.biomarkerChanges) {
      final earliestMarker = first.biomarkerChanges
          .where((b) => b.name == latestMarker.name)
          .firstOrNull;
      if (earliestMarker != null &&
          earliestMarker.currentValue != null &&
          latestMarker.currentValue != null &&
          earliestMarker.currentValue != 0) {
        final pct = ((latestMarker.currentValue! -
                    earliestMarker.currentValue!) /
                earliestMarker.currentValue! *
                100);
        // Only show positive improvements where status is NORMAL
        if (pct > 0 && latestMarker.status == 'NORMAL') {
          improvements.add(_InsightChange(
            name: latestMarker.name,
            changePercent: pct,
            status: latestMarker.status,
          ));
        }
      }
    }

    improvements.sort((a, b) => b.changePercent.compareTo(a.changePercent));

    if (improvements.isEmpty) return const SizedBox();

    return _buildInsightSection(
      'BEST RESPONDERS',
      Icons.emoji_events,
      AppColors.accent,
      improvements.take(5).map((imp) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              const Icon(
                Icons.trending_up,
                size: 12,
                color: AppColors.accent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  imp.name,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    color: AppColors.textMid,
                  ),
                ),
              ),
              Text(
                '+${imp.changePercent.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInsightSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(AIInsight insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                insight.icon,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  insight.title.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            insight.message,
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 10,
              color: AppColors.textMid,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ========== SHARED WIDGETS ==========

  Widget _buildOnboardingState({
    required IconData icon,
    required String title,
    required List<String> instructions,
    required String actionLabel,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColors.textDim),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            ...instructions.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.5),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 10,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12,
                          color: AppColors.textMid,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getPeptideColor(String peptideName) {
    final hash = peptideName.hashCode;
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      const Color(0xFFFFAA00),
      const Color(0xFF00AAFF),
      const Color(0xFFFF0088),
    ];
    return colors[hash.abs() % colors.length];
  }
}

class _InsightChange {
  final String name;
  final double changePercent;
  final String status;

  _InsightChange({
    required this.name,
    required this.changePercent,
    required this.status,
  });
}
