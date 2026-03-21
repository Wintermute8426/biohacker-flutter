import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/colors.dart';
import '../../services/reports_service.dart';

class DystopianTrendChart extends StatefulWidget {
  final List<LabResultWithContext> labResults;
  final Set<String> selectedBiomarkers;
  final Map<String, Color> biomarkerColors;

  const DystopianTrendChart({
    Key? key,
    required this.labResults,
    required this.selectedBiomarkers,
    required this.biomarkerColors,
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
      return _buildEmptyState();
    }

    final chartData = _generateChartData();
    if (chartData.isEmpty) {
      return _buildNoDataState();
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: const Color(0xFF00FFFF).withOpacity(0.3),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
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
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
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
                          if (index < 0 || index >= widget.labResults.length) {
                            return const SizedBox();
                          }
                          final date = widget.labResults[index].labDate;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${date.month}/${date.day}',
                              style: TextStyle(
                                fontFamily: 'monospace',
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
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9,
                              color: AppColors.textDim,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: chartData,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.black.withOpacity(0.9),
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          final color = widget.biomarkerColors.values.elementAt(
                            spots.indexOf(spot),
                          );
                          return LineTooltipItem(
                            '${spot.y.toStringAsFixed(1)}',
                            TextStyle(
                              color: color,
                              fontFamily: 'monospace',
                              fontSize: 11,
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
        );
      },
    );
  }

  List<LineChartBarData> _generateChartData() {
    final lines = <LineChartBarData>[];

    for (final marker in widget.selectedBiomarkers) {
      final color = widget.biomarkerColors[marker] ?? const Color(0xFF00FFFF);
      final spots = <FlSpot>[];

      for (int i = 0; i < widget.labResults.length; i++) {
        final lwc = widget.labResults[i];
        final comparison = lwc.biomarkerChanges.where(
          (bc) => bc.name.toLowerCase() == marker.toLowerCase(),
        ).firstOrNull;

        if (comparison?.currentValue != null) {
          spots.add(FlSpot(i.toDouble(), comparison!.currentValue!));
        }
      }

      if (spots.isNotEmpty) {
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
              color: color.withOpacity(0.1),
            ),
            // Animate line drawing
            dashArray: _animation.value < 1.0 ? [5, 5] : null,
          ),
        );
      }
    }

    return lines;
  }

  Widget _buildEmptyState() {
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
              'SELECT BIOMARKERS',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: AppColors.textMid,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
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
              Icons.warning_amber_outlined,
              size: 48,
              color: const Color(0xFFFF9800),
            ),
            const SizedBox(height: 16),
            Text(
              'AWAITING DATA',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: const Color(0xFFFF9800),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload labs to track biomarkers',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: AppColors.textDim,
              ),
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
