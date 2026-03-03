import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/colors.dart';
import '../services/cycles_database.dart';
import '../services/dose_logs_database.dart';
import 'weight_tracker_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
    final user = context.watch<AuthProvider>().user;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'DASHBOARD',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Welcome back, ${user?.email?.split('@')[0] ?? 'User'}',
              style: TextStyle(
                color: AppColors.textMid,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // ACTIVE CYCLES
            Text(
              'ACTIVE CYCLES',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
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
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'No active cycles. Go to Cycles tab to create one.',
                      style: TextStyle(color: AppColors.textMid),
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
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
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
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
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
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'No logged doses yet.',
                      style: TextStyle(color: AppColors.textMid),
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
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
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
    );
  }
}
