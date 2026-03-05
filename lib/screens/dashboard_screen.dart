import '../main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../services/cycles_database.dart';
import '../services/dose_logs_database.dart';
import 'weight_tracker_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final cycleDb = CyclesDatabase();
  final doseDb = DoseLogsDatabase();

  late Future<List<Cycle>> activeCycles;
  late Future<List<DoseLog>> recentDoses;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    activeCycles = cycleDb.getActiveCycles();
    recentDoses = doseDb.getAllDoseLogs();
    setState(() {});
  }

  String _getNextInjectionDue(Cycle cycle) {
    // Simple logic: if 1x weekly, next injection is in 7 days, etc.
    int daysPerDose = 7; // default
    if (cycle.frequency.contains('2x')) daysPerDose = 3;
    if (cycle.frequency.contains('3x')) daysPerDose = 2;
    if (cycle.frequency.contains('Daily')) daysPerDose = 1;

    final nextDue = DateTime.now().add(Duration(days: daysPerDose));
    final diff = nextDue.difference(DateTime.now()).inDays;
    return 'In $diff days';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProviderProvider).user;

    return SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'DASHBOARD',
              style: WintermmuteStyles.titleStyle,
            ),
            const SizedBox(height: 8),
            Text(
              'Welcome back, ${user?.email?.split('@')[0] ?? 'User'}',
              style: WintermmuteStyles.bodyStyle,
            ),
            const SizedBox(height: 24),

            // ACTIVE CYCLES
            Text(
              'ACTIVE CYCLES',
              style: WintermmuteStyles.headerStyle.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Cycle>>(
              future: activeCycles,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: WintermmuteStyles.cardDecoration,
                    child: Text(
                      'No active cycles. Go to Cycles tab to create one.',
                      style: WintermmuteStyles.bodyStyle,
                    ),
                  );
                }

                final cycles = snapshot.data!;
                return Column(
                  children: cycles.map((cycle) {
                    final daysRemaining =
                        cycle.endDate.difference(DateTime.now()).inDays;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: WintermmuteStyles.cardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cycle.peptideName.toUpperCase(),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${cycle.dose}mg • ${cycle.frequency}',
                                style: TextStyle(
                                  color: AppColors.textMid,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '$daysRemaining days left',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Next injection: ${_getNextInjectionDue(cycle)}',
                            style: TextStyle(
                              color: AppColors.textDim,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),

            // RECENT DOSES
            Text(
              'RECENT INJECTIONS',
              style: WintermmuteStyles.headerStyle.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<DoseLog>>(
              future: recentDoses,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: WintermmuteStyles.cardDecoration,
                    child: Text(
                      'No logged doses yet.',
                      style: WintermmuteStyles.bodyStyle,
                    ),
                  );
                }

                final doses = snapshot.data!.take(5).toList(); // Show last 5
                return Column(
                  children: doses.map((dose) {
                    final date = dose.loggedAt;
                    final formatted =
                        '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: WintermmuteStyles.cardDecoration,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${dose.doseAmount}mg',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                dose.route ?? 'Unknown route',
                                style: TextStyle(
                                  color: AppColors.textDim,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            formatted,
                            style: TextStyle(
                              color: AppColors.textMid,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // WEIGHT TRACKER
            const WeightTrackerWidget(),
          ],
        ),
      ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ScanlinesPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanlinesPainter extends CustomPainter {
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
