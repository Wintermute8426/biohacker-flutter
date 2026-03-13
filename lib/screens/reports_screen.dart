import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../theme/colors.dart';
import '../services/reports_service.dart';
import '../theme/wintermute_styles.dart';
import '../theme/wintermute_background.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with TickerProviderStateMixin {
  final ReportsService _reportsService = ReportsService();
  late TabController _tabController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isLoading = true;
  bool _isGeneratingAI = false;

  // Data for each section
  List<DoseTimelineData> _doseTimeline = [];
  List<SideEffectHeatmapData> _sideEffectsHeatmap = [];
  List<WeightPoint> _weightTrends = [];
  List<CycleWindow> _cycleBands = [];
  List<CycleLabCorrelation> _labCorrelations = [];
  List<CycleEffectiveness> _effectiveness = [];
  List<AIInsight> _aiInsights = [];
  List<CycleComparison> _cycleComparisons = [];
  List<LabResultWithContext> _labsWithContext = [];

  DateTime _heatmapMonth = DateTime.now();
  
  // Tab 3: Selected biomarkers for Lab Trends chart
  Set<String> _selectedMarkers = {'testosterone', 'igf1'};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    
    // Initialize pulse animation controller
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      // Load all data concurrently
      final results = await Future.wait([
        _reportsService.getDoseTimeline(),
        _reportsService.getSideEffectsHeatmap(
          DateTime(_heatmapMonth.year, _heatmapMonth.month, 1),
          DateTime(_heatmapMonth.year, _heatmapMonth.month + 1, 0),
        ),
        _reportsService.getWeightTrends(),
        _reportsService.getCyclesForPeriod(
          DateTime.now().subtract(const Duration(days: 180)),
          DateTime.now(),
        ),
        _reportsService.getCycleLabCorrelation(),
        _reportsService.getCycleEffectiveness(),
        _reportsService.generateAIInsights(),
        _reportsService.getCycleComparisons(),
        _reportsService.getLabsWithCycleContext(),
      ]);

      if (mounted) {
        setState(() {
          _doseTimeline = results[0] as List<DoseTimelineData>;
          _sideEffectsHeatmap = results[1] as List<SideEffectHeatmapData>;
          _weightTrends = results[2] as List<WeightPoint>;
          _cycleBands = results[3] as List<CycleWindow>;
          _labCorrelations = results[4] as List<CycleLabCorrelation>;
          _effectiveness = results[5] as List<CycleEffectiveness>;
          _aiInsights = results[6] as List<AIInsight>;
          _cycleComparisons = results[7] as List<CycleComparison>;
          _labsWithContext = results[8] as List<LabResultWithContext>;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading reports data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load reports: $e');
      }
    }
  }

  Future<void> _generateClaudeInsights() async {
    setState(() => _isGeneratingAI = true);

    try {
      // Build comprehensive data summary for Claude
      final dataForAnalysis = '''
PEPTIDE PROTOCOL DATA FOR ANALYSIS:

Weight Tracking:
${_weightTrends.isNotEmpty ? _weightTrends.map((w) => '- ${DateFormat('MMM d').format(w.date)}: ${w.weight.toStringAsFixed(1)} lbs').join('\n') : 'No weight data'}

Cycles Completed:
${_cycleComparisons.isNotEmpty ? _cycleComparisons.map((c) => '- ${c.cycleName}: ${c.dosesLogged} doses over ${c.endDate.difference(c.startDate).inDays} days (Rating: ${c.rating}/10)').join('\n') : 'No cycle data'}

Latest Lab Results:
${_labsWithContext.isNotEmpty ? _labsWithContext.first.biomarkerChanges.take(10).map((b) => '- ${b.name}: ${b.currentValue?.toStringAsFixed(1) ?? 'N/A'} ${b.unit ?? ''} (vs previous: ${b.previousValue?.toStringAsFixed(1) ?? 'N/A'}, change: ${b.changePercent?.toStringAsFixed(1) ?? 'N/A'}%)').join('\n') : 'No lab data'}

Side Effects Logged: ${_sideEffectsHeatmap.length} events
''';

      print('DEBUG: Sending insights request to dashboard backend');

      // Call Wintermute Dashboard backend (production proxy)
      final response = await http.post(
        Uri.parse('http://100.71.64.116:9000/api/insights'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'analysisData': dataForAnalysis,
        }),
      );

      print('DEBUG: Backend response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final insightsData = data['insights'] as List;
        
        print('DEBUG: Received ${insightsData.length} insights from backend');

        if (mounted) {
          setState(() {
            _aiInsights = insightsData.map((i) => AIInsight(
              title: i['title'] as String,
              message: i['message'] as String,
              icon: i['icon'] as String,
            )).toList();
            _isGeneratingAI = false;
          });
        }
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMsg = errorBody['message'] ?? 'Unknown error';
        print('DEBUG: Backend error: $errorMsg');
        throw Exception('Backend error: $errorMsg');
      }
    } catch (e) {
      print('Error generating insights: $e');
      if (mounted) {
        setState(() => _isGeneratingAI = false);
        _showError('Failed to generate insights: $e');
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

  @override
  Widget build(BuildContext context) {
    return WintermmuteBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'REPORTS',
          style: WintermmuteStyles.titleStyle,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
            color: AppColors.primary,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMid,
          labelStyle: WintermmuteStyles.tabLabelStyle,
          unselectedLabelStyle: WintermmuteStyles.tabLabelStyle.copyWith(
            color: AppColors.textMid,
          ),
          tabs: const [
            Tab(text: '1'),
            Tab(text: '2'),
            Tab(text: '3'),
            Tab(text: '4'),
            Tab(text: '5'),
            Tab(text: '6'),
            Tab(text: '7'),
          ],
        ),
      ),
      body: ScanlinesOverlay(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'ANALYZING DATA...',
                      style: TextStyle(color: AppColors.textMid, letterSpacing: 2),
                    ),
                  ],
                ),
              )
            : AnimatedOpacity(
                opacity: _isLoading ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: TabBarView(
                controller: _tabController,
                children: [
                // Tab 1: Cycle-Lab Correlation (New Layout)
                RefreshIndicator(
                  onRefresh: _loadAllData,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildCycleLabCorrelationV2(),
                    ],
                  ),
                ),
                // Tab 2: Cycle Comparison (Peptide Summary Table)
                RefreshIndicator(
                  onRefresh: _loadAllData,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildCycleComparisonV2(),
                    ],
                  ),
                ),
                // Tab 3: Lab Trends (Biomarker chart with selectors)
                RefreshIndicator(
                  onRefresh: _loadAllData,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildLabTrendsV2(),
                    ],
                  ),
                ),
                // Tab 4: AI Insights
                RefreshIndicator(
                  onRefresh: _loadAllData,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildAIInsightsV2(),
                    ],
                  ),
                ),
                // Tab 5: Cycle Timeline (Gantt chart)
                RefreshIndicator(
                  onRefresh: _loadAllData,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildCycleTimelineV2(),
                    ],
                  ),
                ),
                // Tab 6: Body Composition
                RefreshIndicator(
                  onRefresh: _loadAllData,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSectionHeader('💪 BODY COMPOSITION', 'Weight + Body Fat %'),
                      const SizedBox(height: 12),
                      _buildBodyComposition(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                // Tab 7: Effectiveness Summary
                RefreshIndicator(
                  onRefresh: _loadAllData,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildEffectivenessSummary(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Tab 1: Cycle-Lab Correlation (V2 - New Layout)
  Widget _buildCycleLabCorrelationV2() {
    if (_labsWithContext.isEmpty) {
      return _buildEmptyState('No lab results available');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildSectionHeader('🧪 CYCLE-LAB CORRELATION', 'Visualize peptide impact on biomarkers'),
        const SizedBox(height: 24),
        // Lab results
        ..._labsWithContext.map((labContext) => _buildLabResultCard(labContext)).toList(),
      ],
    );
  }

  Widget _buildLabResultCard(LabResultWithContext labContext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            // Lab date
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(16),
              decoration: WintermmuteStyles.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('M/dd/yyyy').format(labContext.labDate),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${labContext.labSource ?? 'Unknown Lab'} + ${labContext.markerCount} markers',
                    style: TextStyle(color: AppColors.textMid, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Active cycles during prior 3 months
            if (labContext.activeCycles.isNotEmpty) ...[
              Text(
                'ACTIVE CYCLES (3 MONTHS PRIOR)',
                style: TextStyle(
                  color: AppColors.textMid,
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: WintermmuteStyles.cardDecoration,
                child: Column(
                  children: labContext.activeCycles.map((cycle) {
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cycle.peptideName,
                                style: TextStyle(color: AppColors.primary, fontSize: 12),
                              ),
                              Text(
                                '${DateFormat('MMM d').format(cycle.startDate)} - ${DateFormat('MMM d').format(cycle.endDate)}',
                                style: TextStyle(color: AppColors.textMid, fontSize: 10),
                              ),
                            ],
                          ),
                          Text(
                            '${cycle.dose.toStringAsFixed(0)}mg',
                            style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            if (labContext.activeCycles.isEmpty) ...[
              Text(
                'ACTIVE CYCLES (3 MONTHS PRIOR)',
                style: TextStyle(
                  color: AppColors.textMid,
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: WintermmuteStyles.cardDecoration,
                child: Text(
                  'No active cycles during this period',
                  style: TextStyle(color: AppColors.textMid, fontSize: 12),
                ),
              ),
            ],

            // Key changes section
            if (labContext.biomarkerChanges.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'KEY CHANGES VS PREVIOUS LAB',
                style: TextStyle(
                  color: AppColors.textMid,
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Show first 3 biomarkers
              ...labContext.biomarkerChanges
                  .where((b) => b.previousValue != null)
                  .take(3)
                  .map((biomarker) => _buildBiomarkerCard(biomarker))
                  .toList(),
              // Show "More" section if there are more than 3
              if (labContext.biomarkerChanges.where((b) => b.previousValue != null).length > 3) ...[
                const SizedBox(height: 12),
                _buildExpandableBiomarkerSection(
                  labContext.biomarkerChanges
                      .where((b) => b.previousValue != null)
                      .skip(3)
                      .toList(),
                ),
              ],
            ],
        const SizedBox(height: 16),
        Container(
          height: 1,
          color: AppColors.border,
          margin: const EdgeInsets.symmetric(vertical: 16),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'HIGH':
        return AppColors.error;
      case 'LOW':
        return AppColors.secondary;
      default:
        return AppColors.accent;
    }
  }

  Widget _buildBiomarkerCard(BiomarkerComparison biomarker) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: WintermmuteStyles.customCardDecoration(
        borderColor: _getStatusColor(biomarker.status),
        borderRadius: 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                biomarker.name,
                style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Text(
                    '${biomarker.currentValue?.toStringAsFixed(1) ?? 'N/A'} ${biomarker.unit ?? ''}',
                    style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  if (biomarker.changePercent != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: biomarker.changePercent! >= 0
                            ? AppColors.accent.withOpacity(0.2)
                            : AppColors.error.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        '${biomarker.changePercent! >= 0 ? '+' : ''}${biomarker.changePercent?.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: biomarker.changePercent! >= 0 ? AppColors.accent : AppColors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Previous: ${biomarker.previousValue?.toStringAsFixed(1) ?? 'N/A'}',
            style: TextStyle(color: AppColors.textMid, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableBiomarkerSection(List<BiomarkerComparison> biomarkers) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
          ),
          child: ExpansionTile(
            title: Text(
              'MORE BIOMARKERS (+${biomarkers.length})',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            childrenPadding: EdgeInsets.zero,
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: AppColors.surface.withOpacity(0.5),
            collapsedBackgroundColor: AppColors.surface.withOpacity(0.5),
            iconColor: AppColors.primary,
            collapsedIconColor: AppColors.primary,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: biomarkers
                      .map((biomarker) => Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    biomarker.name,
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Previous: ${biomarker.previousValue?.toStringAsFixed(1) ?? 'N/A'}',
                                    style: TextStyle(color: AppColors.textMid, fontSize: 9),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${biomarker.currentValue?.toStringAsFixed(1) ?? 'N/A'} ${biomarker.unit ?? ''}',
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (biomarker.changePercent != null)
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: biomarker.changePercent! >= 0
                                          ? AppColors.accent.withOpacity(0.2)
                                          : AppColors.error.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Text(
                                      '${biomarker.changePercent! >= 0 ? '+' : ''}${biomarker.changePercent?.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color: biomarker.changePercent! >= 0 ? AppColors.accent : AppColors.error,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (biomarker != biomarkers.last)
                        Divider(
                          color: AppColors.border,
                          height: 1,
                          indent: 12,
                          endIndent: 12,
                        ),
                    ],
                  ))
                  .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: AppColors.textMid,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // A. Dose Timeline Chart
  Widget _buildDoseTimeline() {
    if (_doseTimeline.isEmpty) {
      return _buildEmptyState('No dose data available');
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: WintermmuteStyles.cardDecoration,
      child: Column(
        children: [
          // Legend
          Wrap(
            spacing: 12,
            children: _doseTimeline.asMap().entries.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getChartColor(entry.key),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    entry.value.peptideName,
                    style: TextStyle(color: AppColors.textMid, fontSize: 10),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: const Color(0xFF606060).withOpacity(0.2),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 15 != 0) return const SizedBox.shrink();
                        final date = DateTime.now().subtract(Duration(days: 90 - value.toInt()));
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('M/d').format(date),
                            style: const TextStyle(
                              color: Color(0xFF606060),
                              fontSize: 10,
                              fontFamily: 'JetBrains Mono',
                            ),
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
                          '${value.toInt()}mg',
                          style: const TextStyle(
                            color: Color(0xFF606060),
                            fontSize: 10,
                            fontFamily: 'JetBrains Mono',
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: _doseTimeline.asMap().entries.map((entry) {
                  final color = _getChartColor(entry.key);
                  return LineChartBarData(
                    spots: entry.value.points.map((point) {
                      final daysDiff = DateTime.now().difference(point.date).inDays;
                      return FlSpot(90 - daysDiff.toDouble(), point.amount);
                    }).toList(),
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: color,
                          strokeWidth: 2,
                          strokeColor: AppColors.background,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.12),
                    ),
                  );
                }).toList(),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: AppColors.surface,
                    tooltipBorder: BorderSide(color: AppColors.primary, width: 1),
                    tooltipRoundedRadius: 4,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final timeline = _doseTimeline[spot.barIndex];
                        return LineTooltipItem(
                          '${timeline.peptideName}\n${spot.y.toStringAsFixed(1)}mg',
                          const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontFamily: 'JetBrains Mono',
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // B. Side Effects Heatmap (Calendar Grid)
  Widget _buildSideEffectsHeatmap() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: WintermmuteStyles.cardDecoration,
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _heatmapMonth = DateTime(_heatmapMonth.year, _heatmapMonth.month - 1);
                  });
                  _loadSideEffectsForMonth();
                },
                color: AppColors.primary,
              ),
              Text(
                DateFormat('MMMM yyyy').format(_heatmapMonth),
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _heatmapMonth = DateTime(_heatmapMonth.year, _heatmapMonth.month + 1);
                  });
                  _loadSideEffectsForMonth();
                },
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Calendar grid
          _buildHeatmapGrid(),
          const SizedBox(height: 16),
          // Legend
          _buildHeatmapLegend(),
        ],
      ),
    );
  }

  Widget _buildHeatmapGrid() {
    final firstDay = DateTime(_heatmapMonth.year, _heatmapMonth.month, 1);
    final lastDay = DateTime(_heatmapMonth.year, _heatmapMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startWeekday = firstDay.weekday % 7; // 0 = Sunday

    return Column(
      children: [
        // Weekday headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((d) => Text(d, style: TextStyle(color: AppColors.textMid, fontSize: 12)))
              .toList(),
        ),
        const SizedBox(height: 8),
        // Days grid
        ...List.generate((daysInMonth + startWeekday + 6) ~/ 7, (week) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (weekday) {
                final dayNumber = week * 7 + weekday - startWeekday + 1;
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const SizedBox(width: 40, height: 40);
                }

                final date = DateTime(_heatmapMonth.year, _heatmapMonth.month, dayNumber);
                final data = _sideEffectsHeatmap.firstWhere(
                  (d) => d.date.day == dayNumber,
                  orElse: () => SideEffectHeatmapData(date: date, maxSeverity: 0, symptoms: []),
                );

                return GestureDetector(
                  onTap: () => _showSideEffectDetails(data),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getSeverityColor(data.maxSeverity),
                      border: Border.all(
                        color: data.maxSeverity > 0 
                            ? AppColors.error.withOpacity(0.5)
                            : AppColors.border,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: data.maxSeverity > 5 ? [
                        BoxShadow(
                          color: AppColors.error.withOpacity(0.3),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ] : null,
                    ),
                    child: Center(
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          color: data.maxSeverity > 0 ? Colors.white : AppColors.textDim,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHeatmapLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Low (1-3)', _getSeverityColor(2)),
        const SizedBox(width: 8),
        _buildLegendItem('Med (4-6)', _getSeverityColor(5)),
        const SizedBox(width: 8),
        _buildLegendItem('High (7-10)', _getSeverityColor(8)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: AppColors.textMid, fontSize: 10)),
      ],
    );
  }

  void _showSideEffectDetails(SideEffectHeatmapData data) {
    if (data.symptoms.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SIDE EFFECTS - ${DateFormat('MMM d, yyyy').format(data.date)}',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Max Severity: ${data.maxSeverity}/10',
              style: TextStyle(color: AppColors.textLight),
            ),
            const SizedBox(height: 8),
            ...data.symptoms.map((symptom) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('• $symptom', style: TextStyle(color: AppColors.textMid)),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSideEffectsForMonth() async {
    final startDate = DateTime(_heatmapMonth.year, _heatmapMonth.month, 1);
    final endDate = DateTime(_heatmapMonth.year, _heatmapMonth.month + 1, 0);
    final data = await _reportsService.getSideEffectsHeatmap(startDate, endDate);
    if (mounted) {
      setState(() => _sideEffectsHeatmap = data);
    }
  }

  Color _getSeverityColor(int severity) {
    if (severity == 0) return AppColors.surface;
    if (severity <= 3) return AppColors.accent.withOpacity(0.3);
    if (severity <= 6) return Colors.orange.withOpacity(0.5);
    if (severity <= 8) return AppColors.error.withOpacity(0.6);
    return AppColors.error.withOpacity(0.8);
  }

  // C. Weight Trends Chart (ENHANCED with dual axis + trend line)
  Widget _buildWeightTrends() {
    if (_weightTrends.isEmpty) {
      return _buildEmptyState('No weight data available');
    }

    // Calculate trend line (linear regression)
    final trendData = _calculateTrendLine(_weightTrends);

    return Container(
      height: 350,
      padding: const EdgeInsets.all(16),
      decoration: WintermmuteStyles.cardDecoration.copyWith(
        boxShadow: null,
        color: AppColors.surface.withOpacity(0.15),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: const Color(0xFF606060).withOpacity(0.2),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 30,
                getTitlesWidget: (value, meta) {
                  if (_weightTrends.isEmpty) return const SizedBox.shrink();
                  final index = value.toInt();
                  if (index < 0 || index >= _weightTrends.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('M/d').format(_weightTrends[index].date),
                      style: const TextStyle(
                        color: Color(0xFF606060),
                        fontSize: 10,
                        fontFamily: 'JetBrains Mono',
                      ),
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
                    '${value.toInt()}lbs',
                    style: const TextStyle(
                      color: Color(0xFF606060),
                      fontSize: 10,
                      fontFamily: 'JetBrains Mono',
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            // Weight line
            LineChartBarData(
              spots: _weightTrends.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.weight);
              }).toList(),
              isCurved: true,
              color: AppColors.accent,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.accent,
                    strokeWidth: 2,
                    strokeColor: AppColors.background,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.accent.withOpacity(0.12),
              ),
            ),
            // Trend line
            LineChartBarData(
              spots: trendData,
              isCurved: false,
              color: AppColors.primary.withOpacity(0.6),
              barWidth: 2,
              dotData: FlDotData(show: false),
              dashArray: [5, 5],
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: AppColors.surface,
              tooltipBorder: BorderSide(color: AppColors.primary, width: 1),
              tooltipRoundedRadius: 4,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  if (spot.barIndex == 1) return null; // Skip trend line
                  final point = _weightTrends[spot.x.toInt()];
                  return LineTooltipItem(
                    '${point.weight.toStringAsFixed(1)} lbs\n${DateFormat('MMM d').format(point.date)}',
                    const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontFamily: 'JetBrains Mono',
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _calculateTrendLine(List<WeightPoint> weights) {
    if (weights.length < 2) return [];

    // Linear regression: y = mx + b
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    int n = weights.length;

    for (int i = 0; i < n; i++) {
      double x = i.toDouble();
      double y = weights[i].weight;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    double m = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    double b = (sumY - m * sumX) / n;

    return List.generate(n, (i) => FlSpot(i.toDouble(), m * i + b));
  }

  // D. Cycle-Lab Correlations
  Widget _buildLabCorrelations() {
    if (_labCorrelations.isEmpty) {
      return _buildEmptyState('No lab results available');
    }

    return Column(
      children: _labCorrelations.map((correlation) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.science, color: AppColors.secondary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Lab Report - ${DateFormat('MMM d, yyyy').format(correlation.labDate)}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Biomarkers
              _buildBiomarker('Testosterone', correlation.biomarkers['testosterone']),
              _buildBiomarker('Cortisol', correlation.biomarkers['cortisol']),
              _buildBiomarker('Glucose', correlation.biomarkers['glucose']),
              const SizedBox(height: 12),
              Text(
                '90-Day Context:',
                style: TextStyle(color: AppColors.textMid, fontSize: 12),
              ),
              const SizedBox(height: 8),
              ...correlation.cycles.map((cycle) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '• ${cycle.peptideName} (${cycle.dose}mg) - ${DateFormat('M/d').format(cycle.startDate)} to ${DateFormat('M/d').format(cycle.endDate)}',
                      style: TextStyle(color: AppColors.textMid, fontSize: 12),
                    ),
                  )),
              if (correlation.cycles.isEmpty)
                Text('No cycles during this period', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBiomarker(String name, dynamic value) {
    if (value == null) return const SizedBox.shrink();

    String displayValue = '';
    if (value is Map) {
      displayValue = value['value']?.toString() ?? 'N/A';
    } else {
      displayValue = value.toString();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: TextStyle(color: AppColors.textLight)),
          Text(displayValue, style: TextStyle(color: AppColors.accent)),
        ],
      ),
    );
  }

  // E. Effectiveness Ratings
  Widget _buildEffectivenessRatings() {
    if (_effectiveness.isEmpty) {
      return _buildEmptyState('No cycle ratings yet');
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 10,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: AppColors.surface,
              tooltipBorder: BorderSide(color: AppColors.primary, width: 1),
              tooltipRoundedRadius: 4,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final cycle = _effectiveness[groupIndex];
                return BarTooltipItem(
                  '${cycle.cycleName}\nRating: ${cycle.rating}/10',
                  const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontFamily: 'JetBrains Mono',
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= _effectiveness.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _effectiveness[index].cycleName.substring(0, 
                        _effectiveness[index].cycleName.length > 8 ? 8 : _effectiveness[index].cycleName.length),
                      style: const TextStyle(
                        color: Color(0xFF606060),
                        fontSize: 10,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Color(0xFF606060),
                      fontSize: 10,
                      fontFamily: 'JetBrains Mono',
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: const Color(0xFF606060).withOpacity(0.2),
              strokeWidth: 1,
            ),
          ),
          barGroups: _effectiveness.asMap().entries.map((entry) {
            final rating = entry.value.rating;
            final color = _getRatingColor(rating);
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: rating.toDouble(),
                  color: color,
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 10,
                    color: const Color(0xFF606060).withOpacity(0.2),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getRatingColor(int rating) {
    if (rating <= 3) return AppColors.error;
    if (rating <= 6) return Colors.orange;
    if (rating <= 8) return Colors.yellow;
    return AppColors.accent;
  }

  // F. AI Insights (with Claude integration)
  Widget _buildAIInsights() {
    return Column(
      children: [
        if (_aiInsights.isEmpty)
          _buildEmptyState('No insights yet - keep logging data!'),
        ..._aiInsights.map((insight) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.title,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        insight.message,
                        style: TextStyle(color: AppColors.textMid),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        // AI Refresh Button
        ElevatedButton.icon(
          onPressed: _isGeneratingAI ? null : _generateClaudeInsights,
          icon: _isGeneratingAI
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : Icon(Icons.auto_awesome, color: AppColors.primary),
          label: Text(
            _isGeneratingAI ? 'GENERATING...' : 'REFRESH AI INSIGHTS',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surface,
            side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  // Tab 2: Cycle Comparison V2 - Peptide summary table with stats
  Widget _buildCycleComparisonV2() {
    if (_cycleComparisons.isEmpty) {
      return _buildEmptyState('No cycle data available');
    }

    // Group cycles by peptide to get aggregate stats
    final peptideStats = <String, List<CycleComparison>>{};
    for (var cycle in _cycleComparisons) {
      if (!peptideStats.containsKey(cycle.cycleName)) {
        peptideStats[cycle.cycleName] = [];
      }
      peptideStats[cycle.cycleName]!.add(cycle);
    }

    // Calculate peptide-level metrics
    final peptideMetrics = peptideStats.entries.map((entry) {
      final peptideName = entry.key;
      final cycles = entry.value;
      final totalCycles = cycles.length;
      final completedCycles = cycles.where((c) => c.rating > 0).length;
      final adherencePercent = totalCycles > 0 ? (completedCycles / totalCycles * 100) : 0;
      final avgDuration = totalCycles > 0
          ? cycles.map((c) => c.endDate.difference(c.startDate).inDays).reduce((a, b) => a + b) / totalCycles
          : 0;
      final totalDoses = cycles.fold<int>(0, (sum, c) => sum + c.dosesLogged);
      final avgRating = totalCycles > 0
          ? cycles.map((c) => c.rating).reduce((a, b) => a + b) / totalCycles
          : 0;

      return {
        'peptide': peptideName,
        'totalCycles': totalCycles,
        'completedCycles': completedCycles,
        'adherence': adherencePercent,
        'avgDuration': avgDuration,
        'totalDoses': totalDoses,
        'avgRating': avgRating,
      };
    }).toList();

    // Sort by adherence descending
    peptideMetrics.sort((a, b) => (b['adherence'] as double).compareTo(a['adherence'] as double));

    // Get top stats
    final bestAdherence = peptideMetrics.isNotEmpty ? peptideMetrics.first : null;
    final mostUsed = peptideMetrics.isNotEmpty
        ? peptideMetrics.reduce((a, b) => (a['totalCycles'] as int) > (b['totalCycles'] as int) ? a : b)
        : null;
    final longestProtocol = peptideMetrics.isNotEmpty
        ? peptideMetrics.reduce((a, b) => (a['avgDuration'] as double) > (b['avgDuration'] as double) ? a : b)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildSectionHeader('📊 CYCLE COMPARISON', 'Peptide performance summary'),
        const SizedBox(height: 20),

        // Top 3 stat cards
        if (bestAdherence != null) ...[
          Row(
            children: [
              Expanded(
                child: _buildStatCardLarge(
                  '✅ BEST ADHERENCE',
                  bestAdherence['peptide'] as String,
                  '${(bestAdherence['adherence'] as double).toStringAsFixed(0)}%',
                  AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCardLarge(
                  '🔥 MOST USED',
                  mostUsed!['peptide'] as String,
                  '${mostUsed['totalCycles']} cycles',
                  AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatCardLarge(
            '⏱️ LONGEST PROTOCOL',
            longestProtocol!['peptide'] as String,
            '${(longestProtocol['avgDuration'] as double).toStringAsFixed(0)} days avg',
            AppColors.secondary,
          ),
          const SizedBox(height: 24),
        ],

        // Table header
        Text(
          'PEPTIDE COMPARISON',
          style: TextStyle(
            color: AppColors.textMid,
            fontSize: 11,
            letterSpacing: 1,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Table
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              // Header row
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text('PEPTIDE', style: _tableHeaderStyle()),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text('CYCLES', style: _tableHeaderStyle(), textAlign: TextAlign.center),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text('✓', style: _tableHeaderStyle(), textAlign: TextAlign.center),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('ADHR', style: _tableHeaderStyle(), textAlign: TextAlign.right),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('DAYS', style: _tableHeaderStyle(), textAlign: TextAlign.right),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('DOSES', style: _tableHeaderStyle(), textAlign: TextAlign.right),
                    ),
                  ],
                ),
              ),
              // Data rows
              ...peptideMetrics.asMap().entries.map((entry) {
                final metric = entry.value;
                final isHighlight = entry.key < 3; // Highlight first 3
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isHighlight ? AppColors.surface.withOpacity(0.7) : AppColors.surface,
                    border: Border(bottom: BorderSide(color: AppColors.border.withOpacity(0.3))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          metric['peptide'] as String,
                          style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${metric['totalCycles']}',
                          style: TextStyle(color: AppColors.textLight, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${metric['completedCycles']}',
                          style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${(metric['adherence'] as double).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: (metric['adherence'] as double) >= 80 ? AppColors.accent : AppColors.textMid,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${(metric['avgDuration'] as double).toStringAsFixed(0)}',
                          style: TextStyle(color: AppColors.textMid, fontSize: 10),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${metric['totalDoses']}',
                          style: TextStyle(color: AppColors.accent, fontSize: 10),
                          textAlign: TextAlign.right,
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
    );
  }

  TextStyle _tableHeaderStyle() {
    return WintermmuteStyles.tinyStyle.copyWith(
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    );
  }

  Widget _buildStatCardLarge(String label, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: WintermmuteStyles.customCardDecoration(
        borderColor: color,
        borderRadius: 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: WintermmuteStyles.tinyStyle.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: WintermmuteStyles.bodyStyle.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          _buildPulsingStatValue(value, AppColors.accent),
        ],
      ),
    );
  }

  // Tab 3: Lab Trends V2 - Biomarker line chart with selectors
  Widget _buildLabTrendsV2() {
    if (_labsWithContext.isEmpty) {
      return _buildEmptyState('No lab data available');
    }

    // Get all unique biomarkers across all labs
    final allMarkers = <String>{};
    for (var lab in _labsWithContext) {
      for (var biomarker in lab.biomarkerChanges) {
        allMarkers.add(biomarker.name.toLowerCase().replaceAll(' ', '_'));
      }
    }

    // Build data points for selected markers
    final chartData = <String, List<FlSpot>>{};
    final latestValues = <String, double>{};
    final baselineValues = <String, double>{};

    for (var marker in _selectedMarkers) {
      chartData[marker] = [];
    }

    // Sort labs by date (oldest first for chart)
    final sortedLabs = List<LabResultWithContext>.from(_labsWithContext)
      ..sort((a, b) => a.labDate.compareTo(b.labDate));

    for (int i = 0; i < sortedLabs.length; i++) {
      final lab = sortedLabs[i];
      for (var biomarker in lab.biomarkerChanges) {
        final markerKey = biomarker.name.toLowerCase().replaceAll(' ', '_');
        if (_selectedMarkers.contains(markerKey) && biomarker.currentValue != null) {
          chartData[markerKey]?.add(FlSpot(i.toDouble(), biomarker.currentValue!));
          
          // Track latest and baseline values
          latestValues[markerKey] = biomarker.currentValue!;
          if (!baselineValues.containsKey(markerKey)) {
            baselineValues[markerKey] = biomarker.currentValue!;
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildSectionHeader('📈 LAB TRENDS', 'Biomarker changes over time'),
        const SizedBox(height: 20),

        // Marker selectors
        Text(
          'SELECT MARKERS TO DISPLAY',
          style: TextStyle(
            color: AppColors.textMid,
            fontSize: 11,
            letterSpacing: 1,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildMarkerChip('testosterone', 'Testosterone'),
            _buildMarkerChip('igf1', 'IGF-1'),
            _buildMarkerChip('crp', 'CRP'),
            _buildMarkerChip('hdl', 'HDL'),
            _buildMarkerChip('glucose', 'Glucose'),
            _buildMarkerChip('cortisol', 'Cortisol'),
            _buildMarkerChip('free_testosterone', 'Free T'),
            _buildMarkerChip('estradiol', 'Estradiol'),
          ],
        ),
        const SizedBox(height: 24),

        // Chart
        if (_selectedMarkers.isNotEmpty && chartData.values.any((v) => v.isNotEmpty)) ...[
          Text(
            'MARKER TRENDS OVER TIME',
            style: TextStyle(
              color: AppColors.textMid,
              fontSize: 11,
              letterSpacing: 1,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: const Color(0xFF606060).withOpacity(0.2),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedLabs.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MMM').format(sortedLabs[index].labDate),
                              style: const TextStyle(
                                color: Color(0xFF606060),
                                fontSize: 10,
                                fontFamily: 'JetBrains Mono',
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Color(0xFF606060),
                            fontSize: 10,
                            fontFamily: 'JetBrains Mono',
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: chartData.entries.where((e) => e.value.isNotEmpty).map((entry) {
                  final colorIndex = _selectedMarkers.toList().indexOf(entry.key);
                  final color = _getChartColor(colorIndex);
                  return LineChartBarData(
                    spots: entry.value,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: color,
                          strokeWidth: 2,
                          strokeColor: AppColors.background,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.12),
                    ),
                  );
                }).toList(),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: AppColors.surface,
                    tooltipBorder: BorderSide(color: AppColors.primary, width: 1),
                    tooltipRoundedRadius: 4,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final markerKey = _selectedMarkers.toList()[spot.barIndex];
                        return LineTooltipItem(
                          '${_beautifyMarkerName(markerKey)}\n${spot.y.toStringAsFixed(1)}',
                          const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontFamily: 'JetBrains Mono',
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Wrap(
            spacing: 16,
            children: _selectedMarkers.map((marker) {
              final colorIndex = _selectedMarkers.toList().indexOf(marker);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 3,
                    color: _getChartColor(colorIndex),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _beautifyMarkerName(marker),
                    style: TextStyle(color: AppColors.textMid, fontSize: 10),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Summary stat cards
          ...latestValues.entries.map((entry) {
            final marker = entry.key;
            final current = entry.value;
            final baseline = baselineValues[marker];
            final changePercent = baseline != null && baseline != 0
                ? ((current - baseline) / baseline * 100)
                : null;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _beautifyMarkerName(marker),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${current.toStringAsFixed(1)} ${_getUnitForMarker(marker)}',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (changePercent != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: changePercent >= 0
                            ? AppColors.accent.withOpacity(0.2)
                            : AppColors.error.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}% vs baseline',
                        style: TextStyle(
                          color: changePercent >= 0 ? AppColors.accent : AppColors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ] else ...[
          _buildEmptyState('Select markers to view trends'),
        ],
      ],
    );
  }

  Widget _buildMarkerChip(String key, String label) {
    final isSelected = _selectedMarkers.contains(key);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedMarkers.remove(key);
          } else {
            _selectedMarkers.add(key);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textMid,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _beautifyMarkerName(String key) {
    final names = {
      'testosterone': 'Testosterone',
      'free_testosterone': 'Free T',
      'estradiol': 'Estradiol',
      'igf1': 'IGF-1',
      'hgh': 'HGH',
      'crp': 'CRP',
      'hdl': 'HDL',
      'ldl': 'LDL',
      'glucose': 'Glucose',
      'cortisol': 'Cortisol',
    };
    return names[key] ?? key;
  }

  String _getUnitForMarker(String key) {
    final units = {
      'testosterone': 'ng/dL',
      'free_testosterone': 'pg/mL',
      'estradiol': 'pg/mL',
      'igf1': 'ng/mL',
      'hgh': 'ng/mL',
      'crp': 'mg/L',
      'hdl': 'mg/dL',
      'ldl': 'mg/dL',
      'glucose': 'mg/dL',
      'cortisol': 'µg/dL',
    };
    return units[key] ?? '';
  }

  // Tab 4: AI Insights V2 - Brain icon + Generate button
  Widget _buildAIInsightsV2() {
    if (_aiInsights.isNotEmpty) {
      // Display generated insights with brain icon
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brain icon at top
          Center(
            child: Text(
              '🧠',
              style: TextStyle(fontSize: 48, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('💡 AI INSIGHTS', 'Personalized analysis'),
          const SizedBox(height: 20),
          ..._aiInsights.asMap().entries.map((entry) {
            final insight = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        insight.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          insight.title,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    insight.message,
                    style: TextStyle(
                      color: AppColors.textMid,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: _isGeneratingAI ? null : () {
                setState(() => _aiInsights = []);
              },
              child: Text(
                'GENERATE NEW INSIGHTS',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Brain icon
          Text(
            '🧠',
            style: TextStyle(fontSize: 64, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          // Title
          Text(
            'AI-Powered Insights',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Analyze your cycles and lab data to identify patterns, correlations, and optimize your protocol.',
              style: TextStyle(
                color: AppColors.textMid,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          // Generate button
          GestureDetector(
            onTap: _isGeneratingAI ? null : _generateClaudeInsights,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isGeneratingAI ? AppColors.textMid : AppColors.primary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isGeneratingAI) ...[
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    _isGeneratingAI ? 'GENERATING...' : '✨ GENERATE INSIGHTS',
                    style: TextStyle(
                      color: _isGeneratingAI ? AppColors.textMid : AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Tab 5: Cycle Timeline V2 - Gantt chart showing all cycles
  Widget _buildCycleTimelineV2() {
    if (_cycleComparisons.isEmpty) {
      return _buildEmptyState('No cycle data available');
    }

    // Sort cycles by start date (oldest first)
    final sortedCycles = List<CycleComparison>.from(_cycleComparisons)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    // Find date range
    final allDates = <DateTime>[];
    for (var cycle in sortedCycles) {
      allDates.add(cycle.startDate);
      allDates.add(cycle.endDate);
    }
    final minDate = allDates.reduce((a, b) => a.isBefore(b) ? a : b);
    final maxDate = allDates.reduce((a, b) => a.isAfter(b) ? a : b);
    final totalDays = maxDate.difference(minDate).inDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildSectionHeader('📊 CYCLE TIMELINE', 'Visual timeline of all cycles'),
        const SizedBox(height: 20),

        // Status legend
        Text(
          'STATUS LEGEND',
          style: TextStyle(
            color: AppColors.textMid,
            fontSize: 11,
            letterSpacing: 1,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatusBadge('Active', AppColors.primary),
            const SizedBox(width: 16),
            _buildStatusBadge('Paused', Colors.orange),
            const SizedBox(width: 16),
            _buildStatusBadge('Completed', AppColors.accent),
          ],
        ),
        const SizedBox(height: 24),

        // Timeline
        ...sortedCycles.map((cycle) {
          final startOffset = cycle.startDate.difference(minDate).inDays;
          final duration = cycle.endDate.difference(cycle.startDate).inDays;
          final percentStart = (startOffset / totalDays * 100).clamp(0, 100);
          final percentWidth = (duration / totalDays * 100).clamp(0, 100);

          // Determine status
          final now = DateTime.now();
          String status = 'Completed';
          Color statusColor = AppColors.accent;
          if (now.isBefore(cycle.endDate) && now.isAfter(cycle.startDate)) {
            status = 'Active';
            statusColor = AppColors.primary;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cycle.cycleName,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${DateFormat('MMM d').format(cycle.startDate)} - ${DateFormat('MMM d').format(cycle.endDate)}',
                      style: TextStyle(color: AppColors.textMid, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Bar
                Stack(
                  children: [
                    // Background timeline
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Positioned cycle bar
                    Positioned(
                      left: percentStart.isNaN ? 0 : percentStart as double,
                      child: Container(
                        width: percentWidth.isNaN ? 0 : percentWidth as double,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withOpacity(0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${duration} days • $status',
                  style: TextStyle(
                    color: AppColors.textMid,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        }).toList(),

        // Date labels at bottom
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMM yyyy').format(minDate),
              style: TextStyle(color: AppColors.textMid, fontSize: 10),
            ),
            Text(
              DateFormat('MMM yyyy').format(maxDate),
              style: TextStyle(color: AppColors.textMid, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMid,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // Tab 7: Effectiveness Summary - Overall protocol performance
  Widget _buildEffectivenessSummary() {
    if (_effectiveness.isEmpty && _cycleComparisons.isEmpty) {
      return _buildEmptyState('No effectiveness data available');
    }

    // Calculate overall metrics
    double avgRating = 0;
    int totalCycles = _cycleComparisons.length;
    int highPerformance = 0; // Cycles with rating >= 8
    
    if (_cycleComparisons.isNotEmpty) {
      avgRating = _cycleComparisons.fold(0, (sum, c) => sum + c.rating) / _cycleComparisons.length;
      highPerformance = _cycleComparisons.where((c) => c.rating >= 8).length;
    }

    // Sort cycles by rating (highest first)
    final sortedCycles = List<CycleComparison>.from(_cycleComparisons)
      ..sort((a, b) => b.rating.compareTo(a.rating));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildSectionHeader('⭐ EFFECTIVENESS SUMMARY', 'Protocol performance analysis'),
        const SizedBox(height: 20),

        // Overall metrics cards
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'AVG RATING',
                '${avgRating.toStringAsFixed(1)}/10',
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'HIGH PERF',
                '$highPerformance / $totalCycles',
                AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          'TOTAL CYCLES',
          totalCycles.toString(),
          AppColors.secondary,
        ),
        const SizedBox(height: 24),

        // Detailed breakdown
        Text(
          'CYCLE RATINGS BREAKDOWN',
          style: TextStyle(
            color: AppColors.textMid,
            fontSize: 11,
            letterSpacing: 1,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Rating distribution
        ..._buildRatingDistribution(),

        const SizedBox(height: 24),

        // Top performers
        if (sortedCycles.isNotEmpty) ...[
          Text(
            'TOP PERFORMERS',
            style: TextStyle(
              color: AppColors.textMid,
              fontSize: 11,
              letterSpacing: 1,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...sortedCycles.take(5).map((cycle) {
            final ratingColor = cycle.rating >= 8
                ? AppColors.accent
                : cycle.rating >= 6
                    ? Colors.orange
                    : AppColors.error;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: ratingColor.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        cycle.cycleName,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: ratingColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${cycle.rating}/10',
                          style: TextStyle(
                            color: ratingColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${DateFormat('MMM d').format(cycle.startDate)} - ${DateFormat('MMM d').format(cycle.endDate)}',
                        style: TextStyle(color: AppColors.textMid, fontSize: 11),
                      ),
                      Text(
                        '${cycle.dosesLogged} doses',
                        style: TextStyle(color: AppColors.accent, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],

        const SizedBox(height: 24),

        // Recommendations
        Container(
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
                '💡 RECOMMENDATIONS',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              ..._buildRecommendations(sortedCycles, avgRating),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: WintermmuteStyles.customCardDecoration(
        borderColor: color,
        borderRadius: 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMid,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          _buildPulsingStatValue(value, color),
        ],
      ),
    );
  }

  List<Widget> _buildRatingDistribution() {
    // Count cycles by rating range
    final excellent = _cycleComparisons.where((c) => c.rating >= 9).length;
    final great = _cycleComparisons.where((c) => c.rating >= 7 && c.rating < 9).length;
    final good = _cycleComparisons.where((c) => c.rating >= 5 && c.rating < 7).length;
    final fair = _cycleComparisons.where((c) => c.rating < 5).length;

    return [
      _buildRatingBar('Excellent (9-10)', excellent, AppColors.accent),
      _buildRatingBar('Great (7-8)', great, Colors.orange),
      _buildRatingBar('Good (5-6)', good, AppColors.primary),
      _buildRatingBar('Fair (<5)', fair, AppColors.error),
    ];
  }

  Widget _buildRatingBar(String label, int count, Color color) {
    final total = _cycleComparisons.length;
    final percentage = total > 0 ? (count / total * 100) : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(color: AppColors.textMid, fontSize: 11),
              ),
              Text(
                '$count (${percentage.toStringAsFixed(0)}%)',
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              widthFactor: percentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRecommendations(List<CycleComparison> sorted, double avgRating) {
    final recommendations = <Widget>[];

    if (sorted.isEmpty) {
      recommendations.add(
        Text(
          'Start tracking cycle effectiveness ratings to see personalized recommendations.',
          style: TextStyle(color: AppColors.textMid, fontSize: 11, height: 1.6),
        ),
      );
      return recommendations;
    }

    // Recommendation 1: Best protocol
    if (sorted.isNotEmpty && sorted.first.rating >= 7) {
      recommendations.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '✅ Repeat ${sorted.first.cycleName}: Highest rated protocol (${sorted.first.rating}/10)',
            style: TextStyle(color: AppColors.accent, fontSize: 11, height: 1.6),
          ),
        ),
      );
    }

    // Recommendation 2: Consistency
    if (avgRating >= 7) {
      recommendations.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '💪 Excellent consistency: Maintain current dosing strategy',
            style: TextStyle(color: AppColors.accent, fontSize: 11, height: 1.6),
          ),
        ),
      );
    } else if (avgRating >= 5) {
      recommendations.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '📋 Good progress: Focus on top performers and adjust other protocols',
            style: TextStyle(color: Colors.orange, fontSize: 11, height: 1.6),
          ),
        ),
      );
    }

    // Recommendation 3: Low performers
    final lowPerformers = sorted.where((c) => c.rating < 5).toList();
    if (lowPerformers.isNotEmpty) {
      recommendations.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '⚠️ Consider discontinuing or adjusting: ${lowPerformers.take(2).map((c) => c.cycleName).join(", ")}',
            style: TextStyle(color: AppColors.error, fontSize: 11, height: 1.6),
          ),
        ),
      );
    }

    // Recommendation 4: Next steps
    recommendations.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          '🚀 Schedule labs in 3 months to measure cumulative impact of best protocols',
          style: TextStyle(color: AppColors.primary, fontSize: 11, height: 1.6),
        ),
      ),
    );

    return recommendations;
  }

  // Tab 6: Body Composition - Dual-axis weight + body fat chart
  Widget _buildBodyComposition() {
    if (_weightTrends.isEmpty) {
      return _buildEmptyState('No weight data available');
    }

    final hasBodyFat = _weightTrends.any((w) => w.bodyFatPercent != null);
    
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: WintermmuteStyles.cardDecoration,
      child: Column(
        children: [
          // Legend
          Wrap(
            spacing: 20,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Weight (lbs)',
                    style: TextStyle(color: AppColors.textMid, fontSize: 10),
                  ),
                ],
              ),
              if (hasBodyFat)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Body Fat %',
                      style: TextStyle(color: AppColors.textMid, fontSize: 10),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: const Color(0xFF606060).withOpacity(0.2),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 30 != 0) return const SizedBox.shrink();
                        final index = value.toInt();
                        if (index >= 0 && index < _weightTrends.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('M/d').format(_weightTrends[index].date),
                              style: const TextStyle(
                                color: Color(0xFF606060),
                                fontSize: 10,
                                fontFamily: 'JetBrains Mono',
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(
                            color: Color(0xFF606060),
                            fontSize: 10,
                            fontFamily: 'JetBrains Mono',
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Weight line
                  LineChartBarData(
                    spots: _weightTrends.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.weight);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.12),
                    ),
                  ),
                  // Body fat line (if available)
                  if (hasBodyFat)
                    LineChartBarData(
                      spots: _weightTrends
                          .asMap()
                          .entries
                          .where((entry) => entry.value.bodyFatPercent != null)
                          .map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.bodyFatPercent! * 10);
                      }).toList(),
                      isCurved: true,
                      color: AppColors.accent,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.accent.withOpacity(0.12),
                      ),
                    ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: AppColors.surface,
                    tooltipBorder: BorderSide(color: AppColors.primary, width: 1),
                    tooltipRoundedRadius: 4,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index >= 0 && index < _weightTrends.length) {
                          final point = _weightTrends[index];
                          if (spot.barIndex == 0) {
                            return LineTooltipItem(
                              '${point.weight.toStringAsFixed(1)} lbs',
                              const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontFamily: 'JetBrains Mono',
                              ),
                            );
                          } else if (point.bodyFatPercent != null) {
                            return LineTooltipItem(
                              '${point.bodyFatPercent!.toStringAsFixed(1)}% BF',
                              const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontFamily: 'JetBrains Mono',
                              ),
                            );
                          }
                        }
                        return null;
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tab 7: Cycle Comparison - Side-by-side summary cards
  Widget _buildCycleComparison() {
    if (_cycleComparisons.isEmpty) {
      return _buildEmptyState('No cycle data available');
    }

    return Column(
      children: _cycleComparisons.map((cycle) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cycle name + dates
              Text(
                cycle.cycleName,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${DateFormat('MMM d').format(cycle.startDate)} - ${DateFormat('MMM d').format(cycle.endDate)}',
                style: TextStyle(color: AppColors.textMid, fontSize: 12),
              ),
              const SizedBox(height: 16),
              // Stats grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _buildStatCard('⭐ RATING', '${cycle.rating}/10', 
                    cycle.rating >= 7 ? AppColors.accent : cycle.rating >= 5 ? Colors.orange : AppColors.error),
                  _buildStatCard('💉 DOSES', '${cycle.dosesLogged}', AppColors.primary),
                  _buildStatCard('⚖️ AVG WEIGHT', '${cycle.avgWeight.toStringAsFixed(1)} lbs', AppColors.secondary),
                  _buildStatCard('⚠️ SIDE FX', '${cycle.sideEffects}', AppColors.error),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Helper: Stat card for cycle comparison
  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textMid, fontSize: 10, letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: AppColors.textMid),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Color _getChartColor(int index) {
    final colors = [
      AppColors.primary,      // Cyan
      AppColors.accent,       // Green
      Colors.orange,
      AppColors.secondary,    // Magenta
      Colors.purple,
      Colors.blue,
    ];
    return colors[index % colors.length];
  }

  // Pulse animation wrapper for stat values
  Widget _buildPulsingStatValue(String value, Color color) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(_pulseAnimation.value),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'JetBrains Mono',
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
