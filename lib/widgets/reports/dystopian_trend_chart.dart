import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../theme/colors.dart';
import '../../services/reports_service.dart';

class DystopianTrendChart extends StatefulWidget {
  final List<LabResultWithContext> labResults;
  final Set<String> selectedBiomarkers;
  final Map<String, Color> biomarkerColors;
  final Map<String, (double, double)> referenceRanges;

  const DystopianTrendChart({
    Key? key,
    required this.labResults,
    required this.selectedBiomarkers,
    required this.biomarkerColors,
    this.referenceRanges = const {},
  }) : super(key: key);

  @override
  State<DystopianTrendChart> createState() => _DystopianTrendChartState();
}

class _DystopianTrendChartState extends State<DystopianTrendChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedBiomarkers.isEmpty) {
      return _buildEmptyState('SELECT BIOMARKERS', 'Choose markers to track');
    }

    final chartData = _generateChartData();
    if (chartData.isEmpty) {
      return _buildEmptyState(
        'INSUFFICIENT DATA',
        'Need 2+ labs with matching biomarkers to show trends',
      );
    }

    // Sort lab results chronologically for chart display
    final sortedLabs = List<LabResultWithContext>.from(widget.labResults)
      ..sort((a, b) => a.labDate.compareTo(b.labDate));

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: [
            // Legend
            _buildLegend(),
            const SizedBox(height: 8),
            // Chart
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                child: Stack(
                  children: [
                    // Scanlines
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ScanlinesPainter(),
                      ),
                    ),
                    // Chart
                    LineChart(
                      LineChartData(
                        minY: _getMinY(),
                        maxY: _getMaxY(),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _getInterval(),
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: const Color(0xFF1A1A1A),
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
                                final index = value.toInt();
                                if (index < 0 || index >= sortedLabs.length) {
                                  return const SizedBox();
                                }
                                final date = sortedLabs[index].labDate;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    DateFormat('M/d').format(date),
                                    style: const TextStyle(
                                      fontFamily: 'JetBrains Mono',
                                      fontSize: 9,
                                      color: AppColors.textDim,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 45,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 9,
                                    color: AppColors.textDim,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        rangeAnnotations: _buildReferenceRanges(),
                        lineBarsData: chartData,
                        lineTouchData: LineTouchData(
                          enabled: true,
                          touchTooltipData: LineTouchTooltipData(
                            tooltipBgColor: Colors.black.withOpacity(0.9),
                            tooltipBorder: BorderSide(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                            getTooltipItems: (spots) {
                              return spots.map((spot) {
                                final markerName = _getMarkerForBarIndex(
                                    spot.barIndex, chartData);
                                final color = widget.biomarkerColors[markerName] ??
                                    AppColors.primary;
                                return LineTooltipItem(
                                  '${markerName?.toUpperCase() ?? ''}\n${spot.y.toStringAsFixed(1)}',
                                  TextStyle(
                                    color: color,
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegend() {
    final chartData = _generateChartData();
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: widget.selectedBiomarkers.map((marker) {
        final color = widget.biomarkerColors[marker] ?? AppColors.primary;
        final hasData = chartData.any((line) {
          final lineMarker = _markerNames[chartData.indexOf(line)];
          return lineMarker == marker;
        });
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 3,
              color: hasData ? color : color.withOpacity(0.3),
            ),
            const SizedBox(width: 4),
            Text(
              marker.toUpperCase(),
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 9,
                color: hasData ? color : AppColors.textDim,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  final List<String> _markerNames = [];

  List<LineChartBarData> _generateChartData() {
    final lines = <LineChartBarData>[];
    _markerNames.clear();

    // Sort labs chronologically
    final sortedLabs = List<LabResultWithContext>.from(widget.labResults)
      ..sort((a, b) => a.labDate.compareTo(b.labDate));

    for (final marker in widget.selectedBiomarkers) {
      final color = widget.biomarkerColors[marker] ?? AppColors.primary;
      final spots = <FlSpot>[];

      for (int i = 0; i < sortedLabs.length; i++) {
        final lwc = sortedLabs[i];
        final comparison = lwc.biomarkerChanges.where(
          (bc) => bc.name.toLowerCase() == marker.toLowerCase(),
        ).firstOrNull;

        if (comparison?.currentValue != null) {
          spots.add(FlSpot(i.toDouble(), comparison!.currentValue!));
        }
      }

      // Only include biomarkers with 2+ data points
      if (spots.length >= 2) {
        _markerNames.add(marker);
        lines.add(
          LineChartBarData(
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
              color: color.withOpacity(0.08),
            ),
            dashArray: _animation.value < 1.0 ? [5, 5] : null,
          ),
        );
      }
    }

    return lines;
  }

  RangeAnnotations _buildReferenceRanges() {
    final annotations = <HorizontalRangeAnnotation>[];

    // Show reference range for single selected biomarker
    if (widget.selectedBiomarkers.length == 1) {
      final marker = widget.selectedBiomarkers.first;
      final range = widget.referenceRanges[marker.toLowerCase()];
      if (range != null) {
        annotations.add(
          HorizontalRangeAnnotation(
            y1: range.$1,
            y2: range.$2,
            color: AppColors.accent.withOpacity(0.06),
          ),
        );
      }
    }

    return RangeAnnotations(horizontalRangeAnnotations: annotations);
  }

  String? _getMarkerForBarIndex(int barIndex, List<LineChartBarData> data) {
    if (barIndex < _markerNames.length) return _markerNames[barIndex];
    return null;
  }

  double _getMinY() {
    double min = double.infinity;
    final sortedLabs = List<LabResultWithContext>.from(widget.labResults)
      ..sort((a, b) => a.labDate.compareTo(b.labDate));

    for (final marker in widget.selectedBiomarkers) {
      for (final lwc in sortedLabs) {
        final comparison = lwc.biomarkerChanges
            .where((bc) => bc.name.toLowerCase() == marker.toLowerCase())
            .firstOrNull;
        if (comparison?.currentValue != null &&
            comparison!.currentValue! < min) {
          min = comparison.currentValue!;
        }
      }
      // Also consider reference range min
      final range = widget.referenceRanges[marker.toLowerCase()];
      if (range != null && range.$1 < min) min = range.$1;
    }

    if (min == double.infinity) return 0;
    return (min * 0.8).floorToDouble(); // 20% padding below
  }

  double _getMaxY() {
    double max = double.negativeInfinity;
    final sortedLabs = List<LabResultWithContext>.from(widget.labResults)
      ..sort((a, b) => a.labDate.compareTo(b.labDate));

    for (final marker in widget.selectedBiomarkers) {
      for (final lwc in sortedLabs) {
        final comparison = lwc.biomarkerChanges
            .where((bc) => bc.name.toLowerCase() == marker.toLowerCase())
            .firstOrNull;
        if (comparison?.currentValue != null &&
            comparison!.currentValue! > max) {
          max = comparison.currentValue!;
        }
      }
      // Also consider reference range max
      final range = widget.referenceRanges[marker.toLowerCase()];
      if (range != null && range.$2 > max) max = range.$2;
    }

    if (max == double.negativeInfinity) return 100;
    return (max * 1.2).ceilToDouble(); // 20% padding above
  }

  double _getInterval() {
    final range = _getMaxY() - _getMinY();
    if (range <= 10) return 2;
    if (range <= 50) return 10;
    if (range <= 200) return 25;
    if (range <= 500) return 50;
    return 100;
  }

  Widget _buildEmptyState(String title, String message) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFFFF9800).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: AppColors.textDim,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                color: AppColors.textMid,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 10,
                color: AppColors.textDim,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.03)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
