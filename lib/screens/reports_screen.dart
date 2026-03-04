import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../theme/colors.dart';
import '../services/reports_service.dart';
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

  DateTime _heatmapMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      // Gather data for Claude analysis
      final analysisData = {
        'weight_trends': _weightTrends.map((w) => {
          'date': w.date.toIso8601String(),
          'weight': w.weight,
        }).toList(),
        'effectiveness_ratings': _effectiveness.map((e) => {
          'cycle': e.cycleName,
          'rating': e.rating,
          'notes': e.notes,
        }).toList(),
        'side_effects': _sideEffectsHeatmap.map((s) => {
          'date': s.date.toIso8601String(),
          'severity': s.maxSeverity,
          'symptoms': s.symptoms,
        }).toList(),
        'lab_correlations': _labCorrelations.take(2).map((l) => {
          'date': l.labDate.toIso8601String(),
          'biomarkers': l.biomarkers,
          'cycles': l.cycles.map((c) => c.peptideName).toList(),
        }).toList(),
      };

      final prompt = '''Analyze this peptide protocol data and provide 3-5 key insights:

Weight Trends: ${_weightTrends.length} data points over ${(_weightTrends.isNotEmpty ? _weightTrends.last.date.difference(_weightTrends.first.date).inDays : 0)} days
Latest Lab Results: ${_labCorrelations.isNotEmpty ? _labCorrelations.first.biomarkers.toString() : 'None'}
Best Performing Cycles: ${_effectiveness.where((e) => e.rating >= 8).map((e) => e.cycleName).join(', ')}
Side Effects: ${_sideEffectsHeatmap.length} logged events

Provide insights on:
1. Weight consistency and trends
2. Hormonal optimization patterns
3. Side effect patterns and severity
4. Actionable recommendations for next cycles

Format as JSON array of objects with "title" (emoji + text), "message" (insight), "icon" (single emoji) fields.''';

      // Call Claude API (using Anthropic's Claude)
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': 'sk-ant-api03-YOUR_API_KEY_HERE', // TODO: Move to env
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-5-sonnet-20241022',
          'max_tokens': 1024,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'];
        
        // Parse JSON from Claude's response
        final insights = jsonDecode(content) as List;
        
        setState(() {
          _aiInsights = insights.map((i) => AIInsight(
            title: i['title'],
            message: i['message'],
            icon: i['icon'],
          )).toList();
          _isGeneratingAI = false;
        });
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating Claude insights: $e');
      setState(() => _isGeneratingAI = false);
      _showError('Failed to generate AI insights. Using fallback.');
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'REPORTS',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
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
      body: _isLoading
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
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Cycle-Lab Correlation
                RefreshIndicator(
                  onRefresh: _loadAllData,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSectionHeader('🧪 CYCLE-LAB CORRELATION', '90-Day Context'),
                      const SizedBox(height: 12),
                      _buildLabCorrelations(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                // Tab 2: Effectiveness & Side Effects
                RefreshIndicator(
                  onRefresh: _loadAllData,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSectionHeader('⭐ EFFECTIVENESS RATINGS', 'By Cycle'),
                      const SizedBox(height: 12),
                      _buildEffectivenessRatings(),
                      const SizedBox(height: 32),
                      _buildSectionHeader('🔥 SIDE EFFECTS HEATMAP', 'Monthly View'),
                      const SizedBox(height: 12),
                      _buildSideEffectsHeatmap(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                // Tab 3: Lab Trends (Weight)
                RefreshIndicator(
                  onRefresh: _loadAllData,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSectionHeader('⚖️ WEIGHT TRENDS', 'Last 6 Months'),
                      const SizedBox(height: 12),
                      _buildWeightTrends(),
                      const SizedBox(height: 32),
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
                      _buildSectionHeader('💡 AI INSIGHTS', 'Claude Analysis'),
                      const SizedBox(height: 12),
                      _buildAIInsights(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                // Tab 5: Cycle Timeline (Dose Timeline)
                RefreshIndicator(
                  onRefresh: _loadAllData,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSectionHeader('📊 DOSE TIMELINE', 'Last 90 Days'),
                      const SizedBox(height: 12),
                      _buildDoseTimeline(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                // Tab 6: Body Composition
                Center(
                  child: Text(
                    'BODY COMPOSITION - Coming Soon',
                    style: TextStyle(color: AppColors.textMid, fontSize: 16, letterSpacing: 1),
                  ),
                ),
                // Tab 7: Cycle Comparison
                Center(
                  child: Text(
                    'CYCLE COMPARISON - Coming Soon',
                    style: TextStyle(color: AppColors.textMid, fontSize: 16, letterSpacing: 1),
                  ),
                ),
              ],
            ),
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
                    color: AppColors.border,
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
                            style: TextStyle(color: AppColors.textDim, fontSize: 10),
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
                          style: TextStyle(color: AppColors.textDim, fontSize: 10),
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
                      color: color.withOpacity(0.1),
                    ),
                  );
                }).toList(),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final timeline = _doseTimeline[spot.barIndex];
                        return LineTooltipItem(
                          '${timeline.peptideName}\n${spot.y.toStringAsFixed(1)}mg',
                          TextStyle(color: _getChartColor(spot.barIndex), fontSize: 12),
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
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
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.border,
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
                      style: TextStyle(color: AppColors.textDim, fontSize: 10),
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
                    style: TextStyle(color: AppColors.textDim, fontSize: 10),
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
                color: AppColors.accent.withOpacity(0.1),
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
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  if (spot.barIndex == 1) return null; // Skip trend line
                  final point = _weightTrends[spot.x.toInt()];
                  return LineTooltipItem(
                    '${point.weight.toStringAsFixed(1)} lbs\n${DateFormat('MMM d').format(point.date)}',
                    TextStyle(color: AppColors.accent, fontSize: 12),
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
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final cycle = _effectiveness[groupIndex];
                return BarTooltipItem(
                  '${cycle.cycleName}\nRating: ${cycle.rating}/10',
                  TextStyle(color: AppColors.accent),
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
                      style: TextStyle(color: AppColors.textDim, fontSize: 10),
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
                    style: TextStyle(color: AppColors.textDim, fontSize: 10),
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
              color: AppColors.border,
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
                    color: AppColors.border.withOpacity(0.2),
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
}
