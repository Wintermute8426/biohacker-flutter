import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../services/weight_logs_database.dart';

class WeightTrackerWidget extends StatefulWidget {
  const WeightTrackerWidget({Key? key}) : super(key: key);

  @override
  State<WeightTrackerWidget> createState() => _WeightTrackerWidgetState();
}

class _WeightTrackerWidgetState extends State<WeightTrackerWidget> {
  final db = WeightLogsDatabase();
  late Future<List<WeightLog>> _weightLogsFuture;

  @override
  void initState() {
    super.initState();
    _refreshWeights();
  }

  void _refreshWeights() {
    setState(() {
      _weightLogsFuture = db.getWeightLogs(limit: 10);
    });
  }

  void _showLogWeightModal() {
    final weightController = TextEditingController();
    final bodyFatController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LOG WEIGHT',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  color: AppColors.textMid,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date
            Text(
              'Date',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  selectedDate = picked;
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedDate.toString().split(' ')[0],
                      style: TextStyle(color: AppColors.primary, fontSize: 14),
                    ),
                    Icon(Icons.calendar_today, color: AppColors.textMid, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Weight (lbs)
            Text(
              'Weight (lbs)',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: weightController,
              style: const TextStyle(color: AppColors.textLight),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '185.5',
                hintStyle: TextStyle(color: AppColors.textDim),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Body Fat %
            Text(
              'Body Fat % (optional)',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: bodyFatController,
              style: const TextStyle(color: AppColors.textLight),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '15.5',
                hintStyle: TextStyle(color: AppColors.textDim),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () async {
                  final weight = double.tryParse(weightController.text);
                  if (weight == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid weight')),
                    );
                    return;
                  }

                  final bodyFat = double.tryParse(bodyFatController.text);

                  try {
                    final result = await db.saveWeightLog(
                      weightLbs: weight,
                      bodyFatPercent: bodyFat,
                      loggedAt: selectedDate,
                    );

                    if (result != null) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ Weight logged: ${weight}lbs${bodyFat != null ? ' / ${bodyFat}% BF' : ''}'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                      _refreshWeights(); // Reload data from database
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('❌ Failed to save weight'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    print('Error in save button: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Error: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  'SAVE WEIGHT',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A).withOpacity(0.85),
        border: Border.all(color: AppColors.primary.withOpacity(0.25), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 3, height: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Icon(Icons.monitor_weight, color: AppColors.primary, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    '> WEIGHT TRACKER',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _showLogWeightModal,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    border: Border.all(color: AppColors.accent.withOpacity(0.5), width: 1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    'LOG',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          FutureBuilder<List<WeightLog>>(
            future: _weightLogsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: SizedBox(
                    height: 30,
                    width: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text(
                  'No weights logged yet. Tap LOG to start tracking.',
                  style: TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                );
              }

              final logs = snapshot.data!;
              final latest = logs.first;

              return Column(
                children: [
                  // Latest weight
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF000000),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LATEST',
                              style: TextStyle(
                                color: AppColors.textDim,
                                fontFamily: 'monospace',
                                fontSize: 9,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              '${latest.weightLbs} lbs',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              latest.loggedAt.toString().split(' ')[0],
                              style: TextStyle(
                                color: AppColors.textDim,
                                fontSize: 11,
                              ),
                            ),
                            if (latest.bodyFatPercent != null)
                              Text(
                                '${latest.bodyFatPercent}% BF',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Simple trend chart (if multiple entries)
                  if (logs.length > 1) ...[
                    Text(
                      '> TREND',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSimpleChart(logs),
                    const SizedBox(height: 16),
                  ],

                  // Recent entries
                  Text(
                    '> HISTORY (${logs.length})',
                    style: TextStyle(
                      color: AppColors.textDim,
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...logs.map((log) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            log.loggedAt.toString().split(' ')[0],
                            style: TextStyle(
                              color: AppColors.textMid,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '${log.weightLbs} lbs${log.bodyFatPercent != null ? ' / ${log.bodyFatPercent}%' : ''}',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleChart(List<WeightLog> logs) {
    // Reverse to show oldest on left
    final sortedLogs = logs.reversed.toList();
    
    if (sortedLogs.length < 2) {
      return const SizedBox.shrink();
    }

    // Find min/max weight for scaling
    final weights = sortedLogs.map((l) => l.weightLbs).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final range = maxWeight - minWeight;
    final padding = range * 0.1; // 10% padding

    const chartHeight = 80.0;
    const barWidth = 3.0;
    const spacing = 2.0;

    return Container(
      height: chartHeight + 30,
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.15),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(3),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          SizedBox(
            height: chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                sortedLogs.length,
                (index) {
                  final log = sortedLogs[index];
                  final normalizedWeight =
                      (log.weightLbs - (minWeight - padding)) / (range + padding * 2);
                  final height = (chartHeight * normalizedWeight).clamp(2.0, chartHeight);

                  return Tooltip(
                    message: '${log.weightLbs}lbs\n${log.loggedAt.toString().split(' ')[0]}',
                    child: Container(
                      width: barWidth,
                      height: height,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${minWeight.toStringAsFixed(1)}',
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 9,
                ),
              ),
              Text(
                '${maxWeight.toStringAsFixed(1)}',
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
