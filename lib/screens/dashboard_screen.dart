import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../services/cycles_database.dart';
import '../services/dose_logs_database.dart';
import 'research_screen.dart';
import 'weight_tracker_screen.dart';
import '../main.dart' show authProviderProvider;

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final cycleDb = CyclesDatabase();
  final doseDb = DoseLogsDatabase();

  late Future<List<Cycle>> activeCycles;
  late Future<List<DoseLog>> doseLogs;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    activeCycles = cycleDb.getActiveCycles();
    doseLogs = doseDb.getAllDoseLogs();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProviderProvider).user;
    final username = user?.email?.split('@')[0] ?? 'User';

    return SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Section: Welcome + Status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    color: AppColors.background,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SYSTEM STATUS',
                        style: WintermmuteStyles.smallStyle.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username.toUpperCase(),
                                style: WintermmuteStyles.titleStyle
                                    .copyWith(fontSize: 20),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Active User Session',
                                style: WintermmuteStyles.smallStyle.copyWith(
                                  color: AppColors.textMid,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent,
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ACTIVE CYCLES (Snapshot Grid)
                Text(
                  'ACTIVE CYCLES',
                  style: WintermmuteStyles.headerStyle.copyWith(fontSize: 14),
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

                    if (snapshot.hasError) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: WintermmuteStyles.cardDecoration,
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Error loading cycles',
                                style: WintermmuteStyles.bodyStyle
                                    .copyWith(color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: WintermmuteStyles.cardDecoration,
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.schedule_outlined,
                                color: AppColors.primary,
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No active cycles',
                                style: WintermmuteStyles.bodyStyle,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final cycles = snapshot.data!;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: cycles.length,
                      itemBuilder: (context, index) {
                        final cycle = cycles[index];
                        return _buildCycleCard(cycle);
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),

                // NEWS & UPDATES
                Text(
                  'NEWS & UPDATES',
                  style: WintermmuteStyles.headerStyle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 12),
                _buildNewsCard(
                  title: 'BPC-157 Research',
                  subtitle: 'New study on muscle repair',
                  icon: Icons.science_outlined,
                  color: AppColors.secondary,
                ),
                const SizedBox(height: 8),
                _buildNewsCard(
                  title: 'Protocol Update',
                  subtitle: 'Longevity stack now optimized',
                  icon: Icons.update_outlined,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 8),
                _buildNewsCard(
                  title: 'Q1 2026 Analysis',
                  subtitle: 'Protocol effectiveness report',
                  icon: Icons.analytics_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),

                // QUICK LINKS
                Text(
                  'QUICK LINKS',
                  style: WintermmuteStyles.headerStyle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ResearchScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.4),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            color: AppColors.surface,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.book_outlined,
                                color: AppColors.primary,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'RESEARCH',
                                style: WintermmuteStyles.smallStyle.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WeightTrackerWidget(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.accent.withOpacity(0.4),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            color: AppColors.surface,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.scale_outlined,
                                color: AppColors.accent,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'WEIGHT',
                                style: WintermmuteStyles.smallStyle.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          // Scanlines overlay
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

  Widget _buildCycleCard(Cycle cycle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
        color: AppColors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cycle.peptideName,
                style: WintermmuteStyles.smallStyle.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${cycle.dose}mg',
                style: WintermmuteStyles.smallStyle.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  cycle.frequency,
                  style: WintermmuteStyles.tinyStyle.copyWith(
                    color: AppColors.textMid,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
        color: AppColors.surface,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: WintermmuteStyles.smallStyle.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: WintermmuteStyles.tinyStyle.copyWith(
                    color: AppColors.textMid,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward,
            color: color.withOpacity(0.5),
            size: 16,
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
