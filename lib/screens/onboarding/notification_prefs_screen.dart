import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/wintermute_styles.dart';
import '../../services/onboarding_service.dart';
import 'complete_screen.dart';

class NotificationPrefsScreen extends StatefulWidget {
  final OnboardingData data;

  const NotificationPrefsScreen({Key? key, required this.data}) : super(key: key);

  @override
  State<NotificationPrefsScreen> createState() => _NotificationPrefsScreenState();
}

class _NotificationPrefsScreenState extends State<NotificationPrefsScreen> {
  bool _doseReminders = true;
  int _reminderMinutes = 60;
  bool _labAlerts = true;
  bool _weeklyProgress = true;

  final List<int> _reminderOptions = [15, 30, 60, 120];

  @override
  void initState() {
    super.initState();
    _doseReminders = widget.data.doseRemindersEnabled;
    _reminderMinutes = widget.data.doseReminderMinutes;
    _labAlerts = widget.data.labAlertsEnabled;
    _weeklyProgress = widget.data.weeklyProgressEnabled;
  }

  void _continue() {
    widget.data.doseRemindersEnabled = _doseReminders;
    widget.data.doseReminderMinutes = _reminderMinutes;
    widget.data.labAlertsEnabled = _labAlerts;
    widget.data.weeklyProgressEnabled = _weeklyProgress;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompleteScreen(data: widget.data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'STEP 5 OF 6',
          style: WintermmuteStyles.smallStyle.copyWith(
            color: AppColors.primary,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: 5 / 6,
                  minHeight: 3,
                  backgroundColor: AppColors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Question
                    Text(
                      'Stay on track with reminders',
                      style: WintermmuteStyles.headerStyle.copyWith(
                        fontSize: 22,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'You can customize these anytime in Settings',
                      style: WintermmuteStyles.smallStyle.copyWith(
                        color: AppColors.textMid,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Dose reminders
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '📱',
                                style: TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Dose Reminders',
                                  style: WintermmuteStyles.bodyStyle.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _doseReminders,
                                onChanged: (val) => setState(() => _doseReminders = val),
                                activeColor: AppColors.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Notify me before scheduled doses',
                            style: WintermmuteStyles.smallStyle.copyWith(
                              color: AppColors.textMid,
                            ),
                          ),
                          if (_doseReminders) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Time before dose:',
                              style: WintermmuteStyles.smallStyle.copyWith(
                                color: AppColors.textMid,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: _reminderOptions.map((minutes) {
                                final isSelected = _reminderMinutes == minutes;
                                return GestureDetector(
                                  onTap: () => setState(() => _reminderMinutes = minutes),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withOpacity(0.2)
                                          : AppColors.background,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.border,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '$minutes min',
                                      style: WintermmuteStyles.smallStyle.copyWith(
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
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Lab alerts
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(
                          color: AppColors.accent.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '🧪',
                            style: TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lab Alerts',
                                  style: WintermmuteStyles.bodyStyle.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Remind me every 3 months',
                                  style: WintermmuteStyles.smallStyle.copyWith(
                                    color: AppColors.textMid,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _labAlerts,
                            onChanged: (val) => setState(() => _labAlerts = val),
                            activeColor: AppColors.accent,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Weekly progress
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(
                          color: AppColors.secondary.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '📊',
                            style: TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Weekly Progress',
                                  style: WintermmuteStyles.bodyStyle.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Summary of the week',
                                  style: WintermmuteStyles.smallStyle.copyWith(
                                    color: AppColors.textMid,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _weeklyProgress,
                            onChanged: (val) => setState(() => _weeklyProgress = val),
                            activeColor: AppColors.secondary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quiet hours info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.bedtime,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Quiet hours (22:00-08:00) are enabled by default. No notifications during sleep time.',
                              style: WintermmuteStyles.smallStyle.copyWith(
                                color: AppColors.textMid,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'NEXT',
                    style: WintermmuteStyles.bodyStyle.copyWith(
                      color: AppColors.background,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
