import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../services/cycle_service.dart';
import '../services/dose_schedule_service.dart';
import 'dose_schedule_form.dart';

class ConfigureDosesScreen extends ConsumerStatefulWidget {
  final String cycleId;

  const ConfigureDosesScreen({
    Key? key,
    required this.cycleId,
  }) : super(key: key);

  @override
  ConsumerState<ConfigureDosesScreen> createState() =>
      _ConfigureDosesScreenState();
}

class _ConfigureDosesScreenState extends ConsumerState<ConfigureDosesScreen> {
  late Future<Cycle?> _cycleFuture;
  final List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final service = ref.read(cycleServiceProvider);
    _cycleFuture = service.getCycle(widget.cycleId);
  }

  Future<void> _addDoseSchedule(String peptideName, double doseAmount) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => DoseScheduleForm(
          cycleId: widget.cycleId,
          peptideName: peptideName,
          defaultDoseAmount: doseAmount,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _schedules.add(result);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result['peptideName']} schedule saved')),
      );
    }
  }

  Future<void> _saveAllSchedules() async {
    if (_schedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one dose schedule')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('No user logged in');

      final service = ref.read(doseScheduleServiceProvider);

      // Create all dose schedules in parallel
      final futures = _schedules.map((schedule) {
        return service.createDoseSchedule(
          userId: userId,
          cycleId: widget.cycleId,
          peptideName: schedule['peptideName'],
          doseAmount: schedule['doseAmount'],
          route: schedule['route'],
          scheduledTime: schedule['scheduledTime'],
          daysOfWeek: List<int>.from(schedule['daysOfWeek']),
          startDate: schedule['startDate'],
          endDate: schedule['endDate'],
          notes: schedule['notes'],
        );
      });

      await Future.wait(futures);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All dose schedules created!')),
        );
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'CONFIGURE DOSES',
          style: WintermmuteStyles.titleStyle.copyWith(fontSize: 18),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: FutureBuilder<Cycle?>(
        future: _cycleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'Cycle not found',
                style: WintermmuteStyles.bodyStyle,
              ),
            );
          }

          final cycle = snapshot.data!;
          final peptideList =
              cycle.peptides is List ? cycle.peptides as List : [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cycle info
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
                        'Cycle: ${cycle.name}',
                        style: WintermmuteStyles.headerStyle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${peptideList.length} peptide${peptideList.length == 1 ? '' : 's'}',
                        style: WintermmuteStyles.bodyStyle.copyWith(
                          color: AppColors.textMid,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Peptides to configure
                Text(
                  'PEPTIDES IN THIS CYCLE',
                  style: WintermmuteStyles.headerStyle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 12),
                if (peptideList.isEmpty)
                  Text(
                    'No peptides in this cycle',
                    style: WintermmuteStyles.bodyStyle.copyWith(
                      color: AppColors.textMid,
                    ),
                  )
                else
                  ...peptideList.map((peptide) {
                    // peptide is a map from the cycle data
                    final name = peptide is Map ? peptide['name'] ?? 'Unknown' : peptide;
                    final dose = peptide is Map ? peptide['dose'] ?? 0.0 : 0.0;

                    return GestureDetector(
                      onTap: () => _addDoseSchedule(name, dose),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: WintermmuteStyles.bodyStyle.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${dose}mg',
                                  style: WintermmuteStyles.smallStyle.copyWith(
                                    color: AppColors.textMid,
                                  ),
                                ),
                              ],
                            ),
                            Icon(Icons.arrow_forward, color: AppColors.primary),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                const SizedBox(height: 24),

                // Configured schedules
                if (_schedules.isNotEmpty) ...[
                  Text(
                    'CONFIGURED SCHEDULES',
                    style: WintermmuteStyles.headerStyle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  ..._schedules.map((schedule) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                schedule['peptideName'],
                                style: WintermmuteStyles.bodyStyle.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                              Icon(
                                Icons.check_circle,
                                color: AppColors.accent,
                                size: 18,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${schedule['doseAmount']}mg ${schedule['route']} at ${schedule['scheduledTime']} on ${schedule['daysOfWeek'].join(', ')}',
                            style: WintermmuteStyles.smallStyle.copyWith(
                              color: AppColors.textMid,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 24),
                ],

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'CANCEL',
                          style: WintermmuteStyles.bodyStyle.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveAllSchedules,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.background,
                                  ),
                                ),
                              )
                            : Text(
                                'SAVE ALL (${_schedules.length})',
                                style: WintermmuteStyles.bodyStyle.copyWith(
                                  color: AppColors.background,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
