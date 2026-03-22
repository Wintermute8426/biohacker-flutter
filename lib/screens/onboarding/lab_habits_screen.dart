import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/wintermute_styles.dart';
import '../../services/onboarding_service.dart';
import 'onboarding_scaffold.dart';
import 'notification_prefs_screen.dart';

class LabHabitsScreen extends StatefulWidget {
  final OnboardingData data;

  const LabHabitsScreen({Key? key, required this.data}) : super(key: key);

  @override
  State<LabHabitsScreen> createState() => _LabHabitsScreenState();
}

class _LabHabitsScreenState extends State<LabHabitsScreen> {
  String _frequency = 'never';
  final TextEditingController _lastLabController = TextEditingController();

  static const List<Map<String, dynamic>> _frequencies = [
    {
      'value': 'never',
      'label': 'NEVER / FIRST TIME',
      'desc': 'No prior bloodwork surveillance',
      'icon': Icons.do_not_disturb_alt,
      'color': AppColors.textMid,
    },
    {
      'value': 'every_6_months',
      'label': 'EVERY 6 MONTHS',
      'desc': 'Biannual diagnostic sweeps',
      'icon': Icons.calendar_today,
      'color': AppColors.amber,
    },
    {
      'value': 'every_3_months',
      'label': 'EVERY 3 MONTHS',
      'desc': 'Quarterly biomarker tracking',
      'icon': Icons.date_range,
      'color': AppColors.primary,
    },
    {
      'value': 'monthly',
      'label': 'MONTHLY',
      'desc': 'Advanced surveillance protocol',
      'icon': Icons.event_repeat,
      'color': AppColors.accent,
    },
  ];

  @override
  void initState() {
    super.initState();
    _frequency = widget.data.bloodworkFrequency;
    if (widget.data.lastLabDate != null) {
      _lastLabController.text = widget.data.lastLabDate!;
    }
  }

  @override
  void dispose() {
    _lastLabController.dispose();
    super.dispose();
  }

  void _continue() {
    widget.data.bloodworkFrequency = _frequency;
    widget.data.lastLabDate =
        _lastLabController.text.trim().isNotEmpty ? _lastLabController.text.trim() : null;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationPrefsScreen(data: widget.data),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.background,
              surface: AppColors.surface,
              onSurface: AppColors.textLight,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _lastLabController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 4,
      stepLabel: 'DIAGNOSTIC_INTEL',
      onNext: _continue,
      onBack: () => Navigator.pop(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            GlitchText(
              text: 'DIAGNOSTIC INTEL',
              style: WintermmuteStyles.headerStyle.copyWith(
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Bloodwork surveillance frequency & history',
              style: WintermmuteStyles.tinyStyle.copyWith(
                color: AppColors.textDim,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'BLOODWORK FREQUENCY',
              style: WintermmuteStyles.smallStyle.copyWith(
                color: AppColors.amber,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            ..._frequencies.map((freq) {
              final isSelected = _frequency == freq['value'];
              final Color color = freq['color'] as Color;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OnboardingCard(
                  isSelected: isSelected,
                  borderColor: color,
                  onTap: () => setState(() => _frequency = freq['value'] as String),
                  child: Row(
                    children: [
                      Icon(
                        freq['icon'] as IconData,
                        color: isSelected ? color : AppColors.textDim,
                        size: 22,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              freq['label'] as String,
                              style: WintermmuteStyles.smallStyle.copyWith(
                                color: isSelected ? color : AppColors.textLight,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              freq['desc'] as String,
                              style: WintermmuteStyles.tinyStyle.copyWith(
                                color: AppColors.textDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check, color: color, size: 18),
                    ],
                  ),
                ),
              );
            }),

            // Last lab date (conditional)
            if (_frequency != 'never') ...[
              const SizedBox(height: 16),

              Container(
                height: 1,
                color: AppColors.primary.withOpacity(0.1),
              ),

              const SizedBox(height: 16),

              Text(
                'LAST LAB DATE',
                style: WintermmuteStyles.smallStyle.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Optional // helps calibrate reminder schedule',
                style: WintermmuteStyles.tinyStyle.copyWith(
                  color: AppColors.textDim,
                ),
              ),

              const SizedBox(height: 10),

              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.25),
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        color: AppColors.primary.withOpacity(0.6),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _lastLabController.text.isNotEmpty
                            ? _lastLabController.text
                            : 'TAP TO SELECT DATE',
                        style: WintermmuteStyles.bodyStyle.copyWith(
                          color: _lastLabController.text.isNotEmpty
                              ? AppColors.textLight
                              : AppColors.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Info box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.15),
                ),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primary.withOpacity(0.5),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lab uploads can be configured after onboarding in the Labs section.',
                      style: WintermmuteStyles.tinyStyle.copyWith(
                        color: AppColors.textDim,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
