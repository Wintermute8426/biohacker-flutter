import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../theme/colors.dart';
import '../services/reports_service.dart';
import '../widgets/common/scanlines_painter.dart';
import '../widgets/app_header.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/reports/dystopian_trend_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportsService _reportsService = ReportsService();

  int _selectedTabIndex = 0;
  bool _isLoading = true;
  bool _isGeneratingAI = false;

  // Data
  List<CycleLabCorrelation> _labCorrelations = [];
  List<CycleWindow> _cycles = [];
  List<CycleComparison> _cycleComparisons = [];
  List<LabResultWithContext> _labsWithContext = [];
  List<AIInsight> _aiInsights = [];

  // Tab 2: Trends state
  String _selectedCategory = 'HORMONES';
  Set<String> _selectedBiomarkers = {'testosterone', 'dht'};
  
  final Map<String, Color> _biomarkerColors = {
    'testosterone': const Color(0xFFFF9800), // Amber
    'dht': const Color(0xFF00FFFF),          // Cyan
    'estradiol': const Color(0xFFFF00FF),    // Magenta
    'vitamin_d': const Color(0xFFFFD740),    // Yellow
    'b12': const Color(0xFF39FF14),          // Green
  };
  
  final Map<String, IconData> _biomarkerIcons = {
    'testosterone': Icons.trending_up,
    'dht': Icons.science,
    'estradiol': Icons.favorite,
    'vitamin_d': Icons.wb_sunny,
    'b12': Icons.flash_on,
  };

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _reportsService.getCycleLabCorrelation(),
        _reportsService.getCyclesForPeriod(
          DateTime.now().subtract(const Duration(days: 365)),
          DateTime.now(),
        ),
        _reportsService.getCycleComparisons(),
        _reportsService.getLabsWithCycleContext(),
        _reportsService.generateAIInsights(),
      ]);

      if (mounted) {
        setState(() {
          _labCorrelations = results[0] as List<CycleLabCorrelation>;
          _cycles = results[1] as List<CycleWindow>;
          _cycleComparisons = results[2] as List<CycleComparison>;
          _labsWithContext = results[3] as List<LabResultWithContext>;
          _aiInsights = results[4] as List<AIInsight>;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading reports data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _regenerateAIInsights() async {
    setState(() => _isGeneratingAI = true);
    try {
      final insights = await _reportsService.generateAIInsights();
      if (mounted) {
        setState(() {
          _aiInsights = insights;
          _isGeneratingAI = false;
        });
      }
    } catch (e) {
      print('Error generating AI insights: $e');
      if (mounted) {
        setState(() => _isGeneratingAI = false);
      }
    }
  }

  Color getPeptideColor(String peptideName) {
    final hash = peptideName.hashCode;
    final colors = [
      const Color(0xFF00FFFF), // Cyan
      const Color(0xFFFF00FF), // Magenta
      const Color(0xFF39FF14), // Neon Green
      const Color(0xFFFFAA00), // Amber
      const Color(0xFF00AAFF), // Blue
      const Color(0xFFFF0088), // Pink
    ];
    return colors[hash.abs() % colors.length];
  }

  Color getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'HORMONES':
        return const Color(0xFFFF00FF); // Magenta
      case 'METABOLIC':
        return const Color(0xFF39FF14); // Neon Green
      case 'LIPIDS':
        return const Color(0xFFFFAA00); // Amber
      case 'MINERALS':
        return const Color(0xFF00AAFF); // Blue
      default:
        return const Color(0xFF00FFFF); // Cyan
    }
  }

  String getBiomarkerCategory(String biomarkerName) {
    final name = biomarkerName.toLowerCase();

    // Hormones
    if (name.contains('testosterone') || name.contains('estradiol') ||
        name.contains('e2') || name.contains('dht') || name.contains('cortisol') ||
        name.contains('igf') || name.contains('tsh') || name.contains('t3') ||
        name.contains('t4') || name.contains('prolactin')) {
      return 'HORMONES';
    }

    // Metabolic
    if (name.contains('glucose') || name.contains('insulin') ||
        name.contains('hba1c') || name.contains('crp')) {
      return 'METABOLIC';
    }

    // Lipids
    if (name.contains('cholesterol') || name.contains('hdl') ||
        name.contains('ldl') || name.contains('triglyceride')) {
      return 'LIPIDS';
    }

    // Minerals
    if (name.contains('calcium') || name.contains('magnesium') ||
        name.contains('zinc') || name.contains('iron')) {
      return 'MINERALS';
    }

    return 'OTHER';
  }

  List<String> getTop3Biomarkers(Map<String, dynamic> biomarkers) {
    // Priority biomarkers to show
    final priority = ['testosterone', 'free_testosterone', 'estradiol', 'e2',
                      'dht', 'igf1', 'glucose', 'hdl', 'ldl'];

    final available = biomarkers.keys.toList();
    final result = <String>[];

    for (final p in priority) {
      final match = available.firstWhere(
        (key) => key.toLowerCase().contains(p),
        orElse: () => '',
      );
      if (match.isNotEmpty && !result.contains(match)) {
        result.add(match);
        if (result.length >= 3) break;
      }
    }

    // Fill remaining with any available
    while (result.length < 3 && result.length < available.length) {
      for (final key in available) {
        if (!result.contains(key)) {
          result.add(key);
          break;
        }
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          Column(
            children: [
              AppHeader(
                icon: Icons.assessment,
                iconColor: const Color(0xFF00FFFF),
                title: 'REPORTS',
              ),
              _buildTabSelector(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00FFFF),
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
    final tabs = [
      'LAB>PEPTIDE',
      'TRENDS',
      'HISTORY',
      'PERFORMANCE',
      'INSIGHTS',
    ];

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
              child: _buildTabButton(
                label: tabs[index],
                isActive: isActive,
                onTap: () => setState(() => _selectedTabIndex = index),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF0A0A0A)
              : const Color(0xFF00FFFF).withOpacity(0.1), // Faint cyan for inactive
          border: Border.all(
            color: isActive ? const Color(0xFF00FFFF) : const Color(0xFF1A2540),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF00FFFF).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Courier New',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? const Color(0xFF00FFFF) : const Color(0xFF606060),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildLabPeptideTab();
      case 1:
        return _buildTrendsTab();
      case 2:
        return _buildHistoryTab();
      case 3:
        return _buildPerformanceTab();
      case 4:
        return _buildInsightsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // TAB 1: LAB > PEPTIDE CORRELATION
  Widget _buildLabPeptideTab() {
    if (_labCorrelations.isEmpty) {
      return const EmptyState(
        icon: Icons.science_outlined,
        title: 'NO LAB DATA',
        message: 'Lab results will appear here once uploaded',
      );
    }

    // Sort by lab date descending
    final sortedLabs = List<CycleLabCorrelation>.from(_labCorrelations)
      ..sort((a, b) => b.labDate.compareTo(a.labDate));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedLabs.length,
      itemBuilder: (context, index) {
        final lab = sortedLabs[index];
        return _buildLabCorrelationCard(lab);
      },
    );
  }

  Widget _buildLabCorrelationCard(CycleLabCorrelation lab) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final top3Markers = getTop3Biomarkers(lab.biomarkers);

    // Calculate which cycles were active in 30 days before lab
    final windowStart = lab.labDate.subtract(const Duration(days: 30));
    final activeCycles = lab.cycles.where((cycle) {
      return cycle.endDate.isAfter(windowStart) &&
             cycle.startDate.isBefore(lab.labDate);
    }).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border.all(color: const Color(0xFF00FFFF), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: LAB - [Date]
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF00FFFF), width: 1),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'LAB - ${dateFormat.format(lab.labDate)}',
                  style: const TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00FFFF),
                  ),
                ),
              ],
            ),
          ),

          // Subheader: Key biomarkers
          if (top3Markers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                top3Markers.map((m) => m.toUpperCase().replaceAll('_', ' ')).join(' • '),
                style: const TextStyle(
                  fontFamily: 'Courier New',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFAA00), // Amber
                ),
              ),
            ),

          // Section: ACTIVE CYCLES
          if (activeCycles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ACTIVE CYCLES',
                    style: TextStyle(
                      fontFamily: 'Courier New',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF39FF14), // Green
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...activeCycles.map((cycle) {
                    final daysBefore = lab.labDate.difference(cycle.endDate).inDays;
                    final daysBeforeStart = lab.labDate.difference(cycle.startDate).inDays;
                    final timeRange = daysBefore < 0
                        ? 'Active during lab'
                        : '($daysBeforeStart days before - $daysBefore days before)';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cycle.peptideName.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Courier New',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFFFFF),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: getPeptideColor(cycle.peptideName)
                                      .withOpacity(0.2),
                                  border: Border.all(
                                    color: getPeptideColor(cycle.peptideName),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  timeRange,
                                  style: TextStyle(
                                    fontFamily: 'Courier New',
                                    fontSize: 9,
                                    color: getPeptideColor(cycle.peptideName),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

          // Section: RESULTS (Top 3 biomarkers with changes)
          if (top3Markers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RESULTS',
                    style: TextStyle(
                      fontFamily: 'Courier New',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00FFFF), // Cyan
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...top3Markers.map((marker) {
                    final value = lab.biomarkers[marker];
                    final displayName = marker.toUpperCase().replaceAll('_', ' ');

                    // For now, just show current value
                    // TODO: Add before/after comparison when previous lab data is available
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontFamily: 'Courier New',
                                fontSize: 11,
                                color: Color(0xFFA0A0A0),
                              ),
                            ),
                          ),
                          Text(
                            '$value',
                            style: const TextStyle(
                              fontFamily: 'Courier New',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00FFFF),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // TAB 2: LAB TRENDS
  Widget _buildTrendsTab() {
    if (_labsWithContext.isEmpty) {
      return const EmptyState(
        icon: Icons.trending_up,
        title: 'NO TREND DATA',
        message: 'Need at least 2 lab results to show trends',
      );
    }

    return Column(
      children: [
        _buildCategorySelector(),
        _buildBiomarkerCheckboxes(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DystopianTrendChart(
              labResults: _labsWithContext,
              selectedBiomarkers: _selectedBiomarkers,
              biomarkerColors: _biomarkerColors,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    final categories = ['HORMONES', 'METABOLIC', 'LIPIDS', 'MINERALS'];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((category) {
            final isActive = _selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedCategory = category),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF00FFFF).withOpacity(0.1)
                        : Colors.transparent,
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF00FFFF)
                          : const Color(0xFF1A2540),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontFamily: 'Courier New',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? const Color(0xFF00FFFF)
                          : const Color(0xFF606060),
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

  Widget _buildBiomarkerCheckboxes() {
    final biomarkers = _getBiomarkersForCategory(_selectedCategory);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: biomarkers.map((marker) {
          final isSelected = _selectedBiomarkers.contains(marker);
          final color = _biomarkerColors[marker] ?? const Color(0xFF00FFFF);
          final icon = _biomarkerIcons[marker] ?? Icons.analytics;
          
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
                border: Border.all(
                  color: color.withOpacity(isSelected ? 0.8 : 0.4),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: color.withOpacity(isSelected ? 1.0 : 0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    marker.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: color.withOpacity(isSelected ? 1.0 : 0.7),
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

  List<String> _getBiomarkersForCategory(String category) {
    switch (category) {
      case 'HORMONES':
        return ['testosterone', 'dht', 'e2', 'cortisol', 'igf1'];
      case 'METABOLIC':
        return ['glucose', 'hba1c', 'insulin'];
      case 'LIPIDS':
        return ['total_chol', 'ldl', 'hdl', 'triglycerides'];
      case 'MINERALS':
        return ['calcium', 'magnesium', 'zinc', 'iron'];
      default:
        return [];
    }
  }

  Widget _buildTrendsChart() {
    if (_selectedBiomarkers.isEmpty) {
      return const Center(
        child: Text(
          'SELECT AT LEAST ONE BIOMARKER',
          style: TextStyle(
            fontFamily: 'Courier New',
            fontSize: 12,
            color: Color(0xFF606060),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          border: Border.all(color: const Color(0xFF00FFFF), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: 1,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: const Color(0xFF1A2540),
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: const Color(0xFF1A2540),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: 10,
                        color: Color(0xFF606060),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toStringAsFixed(0),
                      style: const TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: 10,
                        color: Color(0xFF606060),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: const Color(0xFF00FFFF), width: 1),
            ),
            minX: 0,
            maxX: 10,
            minY: 0,
            maxY: 100,
            lineBarsData: _selectedBiomarkers.map((marker) {
              final color = _biomarkerColors[marker] ?? const Color(0xFF00FFFF);
              
              // Generate real data from lab results
              final spots = <FlSpot>[];
              // Extract biomarker values from comparisons
              for (int i = 0; i < _labsWithContext.length; i++) {
                final lwc = _labsWithContext[i];
                // Check biomarker changes for this marker
                final markerChange = lwc.biomarkerChanges.where(
                  (bc) => bc.name.toLowerCase() == marker.toLowerCase(),
                ).firstOrNull;
                
                if (markerChange?.currentValue != null) {
                  spots.add(FlSpot(i.toDouble(), markerChange!.currentValue!));
                }
              }
              
              // Default to flat line if no data
              if (spots.isEmpty) {
                spots.add(FlSpot(0, 0));
              }
              
              return LineChartBarData(
                spots: spots,
                isCurved: true,
                color: color,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: color,
                      strokeWidth: 2,
                      strokeColor: Colors.black,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: color.withOpacity(0.1),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // TAB 3: CYCLE HISTORY
  Widget _buildHistoryTab() {
    if (_cycles.isEmpty) {
      return const EmptyState(
        icon: Icons.history,
        title: 'NO CYCLE HISTORY',
        message: 'Start tracking cycles to see history',
      );
    }

    // Sort by start date descending
    final sortedCycles = List<CycleWindow>.from(_cycles)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedCycles.length,
      itemBuilder: (context, index) {
        final cycle = sortedCycles[index];
        return _buildCycleHistoryCard(cycle);
      },
    );
  }

  Widget _buildCycleHistoryCard(CycleWindow cycle) {
    final dateFormat = DateFormat('MMM d');
    final isActive = cycle.endDate.isAfter(DateTime.now());
    final duration = cycle.endDate.difference(cycle.startDate).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border.all(
          color: isActive ? const Color(0xFF39FF14) : const Color(0xFF00FFFF),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Status dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF39FF14) // Green for active
                        : const Color(0xFFFFAA00), // Amber for completed
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: getPeptideColor(cycle.peptideName).withOpacity(0.2),
                    border: Border.all(
                      color: getPeptideColor(cycle.peptideName),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    cycle.peptideName.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Courier New',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: getPeptideColor(cycle.peptideName),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF39FF14).withOpacity(0.2)
                        : const Color(0xFFFFAA00).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : 'COMPLETED',
                    style: TextStyle(
                      fontFamily: 'Courier New',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? const Color(0xFF39FF14)
                          : const Color(0xFFFFAA00),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: Color(0xFF606060),
                ),
                const SizedBox(width: 4),
                Text(
                  '${dateFormat.format(cycle.startDate)} - ${dateFormat.format(cycle.endDate)}',
                  style: const TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 11,
                    color: Color(0xFFA0A0A0),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$duration DAYS',
                  style: const TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00FFFF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.medical_services,
                  size: 12,
                  color: Color(0xFF606060),
                ),
                const SizedBox(width: 4),
                Text(
                  'DOSE: ${cycle.dose} MG',
                  style: const TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 11,
                    color: Color(0xFFA0A0A0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // TAB 4: PROTOCOL PERFORMANCE
  Widget _buildPerformanceTab() {
    if (_cycleComparisons.isEmpty) {
      return const EmptyState(
        icon: Icons.assessment,
        title: 'NO PERFORMANCE DATA',
        message: 'Complete cycles and upload labs to see performance',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cycleComparisons.length,
      itemBuilder: (context, index) {
        final cycle = _cycleComparisons[index];
        return _buildPerformanceCard(cycle);
      },
    );
  }

  Widget _buildPerformanceCard(CycleComparison cycle) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final duration = cycle.endDate.difference(cycle.startDate).inDays;
    final isEffective = cycle.rating >= 4;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border.all(color: const Color(0xFF00FFFF), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF00FFFF), width: 1),
              ),
            ),
            child: Row(
              children: [
                Text(
                  cycle.cycleName.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00FFFF),
                  ),
                ),
                const Spacer(),
                Text(
                  '$duration DAYS',
                  style: const TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 12,
                    color: Color(0xFFA0A0A0),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'DOSES LOGGED:',
                      style: TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: 11,
                        color: Color(0xFF606060),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${cycle.dosesLogged}',
                      style: const TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'AVG WEIGHT:',
                      style: TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: 11,
                        color: Color(0xFF606060),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${cycle.avgWeight.toStringAsFixed(1)} KG',
                      style: const TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'SIDE EFFECTS:',
                      style: TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: 11,
                        color: Color(0xFF606060),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${cycle.sideEffects}',
                      style: TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: cycle.sideEffects > 5
                            ? const Color(0xFFFF0040)
                            : const Color(0xFF39FF14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isEffective
                        ? const Color(0xFF39FF14).withOpacity(0.1)
                        : const Color(0xFFFFAA00).withOpacity(0.1),
                    border: Border.all(
                      color: isEffective
                          ? const Color(0xFF39FF14)
                          : const Color(0xFFFFAA00),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isEffective ? Icons.check_circle : Icons.warning,
                        size: 16,
                        color: isEffective
                            ? const Color(0xFF39FF14)
                            : const Color(0xFFFFAA00),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isEffective ? 'EFFECTIVE' : 'NEEDS ADJUSTMENT',
                        style: TextStyle(
                          fontFamily: 'Courier New',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isEffective
                              ? const Color(0xFF39FF14)
                              : const Color(0xFFFFAA00),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'RATING: ${cycle.rating}/5',
                        style: const TextStyle(
                          fontFamily: 'Courier New',
                          fontSize: 11,
                          color: Color(0xFFA0A0A0),
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

  // TAB 5: AI INSIGHTS
  Widget _buildInsightsTab() {
    return Column(
      children: [
        // Header with brain icon
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.psychology,
                color: Color(0xFF00FFFF),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'AI INSIGHTS',
                style: TextStyle(
                  fontFamily: 'Courier New',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00FFFF),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: _isGeneratingAI ? null : _regenerateAIInsights,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                border: Border.all(color: const Color(0xFF00FFFF), width: 1),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FFFF).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isGeneratingAI)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Color(0xFF00FFFF),
                        strokeWidth: 2,
                      ),
                    )
                  else
                    const Icon(
                      Icons.refresh,
                      color: Color(0xFF00FFFF),
                      size: 16,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    _isGeneratingAI
                        ? 'GENERATING...'
                        : 'REFRESH AI INSIGHTS',
                    style: const TextStyle(
                      fontFamily: 'Courier New',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00FFFF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _aiInsights.isEmpty
              ? const EmptyState(
                  icon: Icons.lightbulb_outline,
                  title: 'NO INSIGHTS YET',
                  message: 'Generate AI insights to get personalized recommendations',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _aiInsights.length,
                  itemBuilder: (context, index) {
                    final insight = _aiInsights[index];
                    return _buildInsightCard(insight);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(AIInsight insight) {
    IconData icon;
    switch (insight.icon) {
      case 'warning':
        icon = Icons.warning;
        break;
      case 'check':
        icon = Icons.check_circle;
        break;
      case 'info':
        icon = Icons.info;
        break;
      case 'lightbulb':
        icon = Icons.lightbulb;
        break;
      default:
        icon = Icons.insights;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border.all(color: const Color(0xFF00FFFF), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: const Color(0xFF00FFFF), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insight.title.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Courier New',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00FFFF),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  insight.message,
                  style: const TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 11,
                    color: Color(0xFFA0A0A0),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ScanlinesPainter(opacity: 0.03),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
