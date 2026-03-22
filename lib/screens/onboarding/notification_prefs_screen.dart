import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/wintermute_styles.dart';
import '../../services/onboarding_service.dart';
import 'onboarding_scaffold.dart';
import 'profile_details_screen.dart';

class NotificationPrefsScreen extends StatefulWidget {
  final OnboardingData data;

  const NotificationPrefsScreen({Key? key, required this.data}) : super(key: key);

  @override
  State<NotificationPrefsScreen> createState() => _NotificationPrefsScreenState();
}

class _NotificationPrefsScreenState extends State<NotificationPrefsScreen> {
  bool _doseReminders = true;
  String _doseTime = '08:00';
  String _labFrequency = 'every_3_months';
  bool _cycleMilestones = true;
  bool _researchUpdates = true;

  static const List<String> _timeOptions = [
    '06:00',
    '08:00',
    '10:00',
    '12:00',
    '18:00',
    '20:00',
    '22:00',
  ];

  static const List<Map<String, String>> _labFrequencies = [
    {'value': 'never', 'label': 'NEVER'},
    {'value': 'every_6_months', 'label': '6 MO'},
    {'value': 'every_3_months', 'label': '3 MO'},
    {'value': 'monthly', 'label': 'MONTHLY'},
  ];

  @override
  void initState() {
    super.initState();
    _doseReminders = widget.data.doseRemindersEnabled;
    _doseTime = widget.data.doseReminderTime;
    _labFrequency = widget.data.labReminderFrequency;
    _cycleMilestones = widget.data.cycleMilestonesEnabled;
    _researchUpdates = widget.data.researchUpdatesEnabled;
  }

  void _continue() {
    widget.data.doseRemindersEnabled = _doseReminders;
    widget.data.doseReminderTime = _doseTime;
    widget.data.labReminderFrequency = _labFrequency;
    widget.data.cycleMilestonesEnabled = _cycleMilestones;
    widget.data.researchUpdatesEnabled = _researchUpdates;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileDetailsScreen(data: widget.data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 5,
      stepLabel: 'COMMS_CONFIG',
      onNext: _continue,
      onBack: () => Navigator.pop(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            GlitchText(
              text: 'COMMS CONFIGURATION',
              style: WintermmuteStyles.headerStyle.copyWith(
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Signal preferences & alert thresholds',
              style: WintermmuteStyles.tinyStyle.copyWith(
                color: AppColors.textDim,
              ),
            ),

            const SizedBox(height: 24),

            // Dose reminders
            _buildNotifSection(
              title: 'DOSE REMINDERS',
              color: AppColors.primary,
              icon: Icons.alarm,
              enabled: _doseReminders,
              onToggle: (val) => setState(() => _doseReminders = val),
              child: _doseReminders
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          'PREFERRED TIME',
                          style: WintermmuteStyles.tinyStyle.copyWith(
                            color: AppColors.textDim,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _timeOptions.map((time) {
                            final isSelected = _doseTime == time;
                            return GestureDetector(
                              onTap: () => setState(() => _doseTime = time),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withOpacity(0.15)
                                      : AppColors.background,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.primary.withOpacity(0.2),
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  time,
                                  style: WintermmuteStyles.tinyStyle.copyWith(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textMid,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    )
                  : null,
            ),

            const SizedBox(height: 14),

            // Lab reminders
            _buildNotifSection(
              title: 'LAB REMINDERS',
              color: AppColors.accent,
              icon: Icons.science,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'REMINDER FREQUENCY',
                    style: WintermmuteStyles.tinyStyle.copyWith(
                      color: AppColors.textDim,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: _labFrequencies.map((freq) {
                      final isSelected = _labFrequency == freq['value'];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _labFrequency = freq['value']!),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent.withOpacity(0.15)
                                  : AppColors.background,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accent
                                    : AppColors.accent.withOpacity(0.2),
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Center(
                              child: Text(
                                freq['label']!,
                                style: WintermmuteStyles.tinyStyle.copyWith(
                                  color: isSelected
                                      ? AppColors.accent
                                      : AppColors.textMid,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Cycle milestones
            _buildNotifSection(
              title: 'CYCLE MILESTONES',
              color: AppColors.amber,
              icon: Icons.flag,
              enabled: _cycleMilestones,
              onToggle: (val) => setState(() => _cycleMilestones = val),
              subtitle: 'Start / mid-point / end-of-cycle alerts',
            ),

            const SizedBox(height: 14),

            // Research updates
            _buildNotifSection(
              title: 'RESEARCH UPDATES',
              color: AppColors.secondary,
              icon: Icons.article,
              enabled: _researchUpdates,
              onToggle: (val) => setState(() => _researchUpdates = val),
              subtitle: 'New studies & protocol intelligence',
            ),

            const SizedBox(height: 16),

            // Customize later note
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.12),
                ),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune,
                    color: AppColors.primary.withOpacity(0.4),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All signal preferences can be reconfigured in Settings.',
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

  Widget _buildNotifSection({
    required String title,
    required Color color,
    required IconData icon,
    bool? enabled,
    ValueChanged<bool>? onToggle,
    String? subtitle,
    Widget? child,
  }) {
    return OnboardingCard(
      borderColor: color,
      isSelected: enabled ?? true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: WintermmuteStyles.smallStyle.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (onToggle != null)
                SizedBox(
                  height: 24,
                  child: Switch(
                    value: enabled ?? false,
                    onChanged: onToggle,
                    activeColor: color,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: WintermmuteStyles.tinyStyle.copyWith(
                color: AppColors.textDim,
              ),
            ),
          ],
          if (child != null) child,
        ],
      ),
    );
  }
}
