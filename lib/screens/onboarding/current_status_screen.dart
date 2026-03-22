import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/wintermute_styles.dart';
import '../../services/onboarding_service.dart';
import 'onboarding_scaffold.dart';
import 'lab_habits_screen.dart';

class CurrentStatusScreen extends StatefulWidget {
  final OnboardingData data;

  const CurrentStatusScreen({Key? key, required this.data}) : super(key: key);

  @override
  State<CurrentStatusScreen> createState() => _CurrentStatusScreenState();
}

class _CurrentStatusScreenState extends State<CurrentStatusScreen> {
  bool _usedBefore = false;
  final List<String> _selectedPeptides = [];
  String _duration = '';
  String _cycleStatus = 'not_on_cycle';
  String _trainingLevel = 'moderate';

  static const List<String> _commonPeptides = [
    'BPC-157',
    'TB-500',
    'CJC-1295',
    'Ipamorelin',
    'Semaglutide',
    'Tirzepatide',
    'PT-141',
    'DSIP',
    'Selank',
    'Semax',
    'GHK-Cu',
    'Epithalon',
    'AOD-9604',
    'Tesamorelin',
    'MK-677',
  ];

  static const List<Map<String, String>> _durations = [
    {'value': '<3_months', 'label': '< 3 MONTHS'},
    {'value': '3-6_months', 'label': '3-6 MONTHS'},
    {'value': '6-12_months', 'label': '6-12 MONTHS'},
    {'value': '1+_years', 'label': '1+ YEARS'},
  ];

  static const List<Map<String, dynamic>> _trainingLevels = [
    {'value': 'sedentary', 'label': 'SEDENTARY', 'desc': 'Minimal activity', 'icon': Icons.weekend},
    {'value': 'moderate', 'label': 'MODERATE', 'desc': '3-4x per week', 'icon': Icons.directions_walk},
    {'value': 'active', 'label': 'ACTIVE', 'desc': '5-6x per week', 'icon': Icons.directions_run},
    {'value': 'athlete', 'label': 'ATHLETE', 'desc': 'Daily / competitive', 'icon': Icons.flash_on},
  ];

  @override
  void initState() {
    super.initState();
    _usedBefore = widget.data.usedPeptidesBefore;
    _selectedPeptides.addAll(widget.data.previousPeptides);
    _duration = widget.data.peptideExperienceDuration;
    _cycleStatus = widget.data.cycleStatus;
    _trainingLevel = widget.data.trainingLevel;
  }

  void _continue() {
    widget.data.usedPeptidesBefore = _usedBefore;
    widget.data.previousPeptides = List.from(_selectedPeptides);
    widget.data.peptideExperienceDuration = _duration;
    widget.data.cycleStatus = _cycleStatus;
    widget.data.trainingLevel = _trainingLevel;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LabHabitsScreen(data: widget.data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 3,
      stepLabel: 'FIELD_HISTORY',
      onNext: _continue,
      onBack: () => Navigator.pop(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            GlitchText(
              text: 'FIELD HISTORY',
              style: WintermmuteStyles.headerStyle.copyWith(
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Prior protocol deployment & current operational status',
              style: WintermmuteStyles.tinyStyle.copyWith(
                color: AppColors.textDim,
              ),
            ),

            const SizedBox(height: 24),

            // Have you used peptides before?
            Text(
              'PRIOR PEPTIDE DEPLOYMENT',
              style: WintermmuteStyles.smallStyle.copyWith(
                color: AppColors.amber,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OnboardingCard(
                    isSelected: !_usedBefore,
                    borderColor: AppColors.primary,
                    onTap: () => setState(() {
                      _usedBefore = false;
                      _selectedPeptides.clear();
                      _duration = '';
                    }),
                    child: Center(
                      child: Text(
                        'NEGATIVE',
                        style: WintermmuteStyles.bodyStyle.copyWith(
                          color: !_usedBefore ? AppColors.primary : AppColors.textMid,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OnboardingCard(
                    isSelected: _usedBefore,
                    borderColor: AppColors.accent,
                    onTap: () => setState(() => _usedBefore = true),
                    child: Center(
                      child: Text(
                        'AFFIRMATIVE',
                        style: WintermmuteStyles.bodyStyle.copyWith(
                          color: _usedBefore ? AppColors.accent : AppColors.textMid,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Conditional: prior peptides detail
            if (_usedBefore) ...[
              const SizedBox(height: 20),

              Text(
                'COMPOUNDS DEPLOYED',
                style: WintermmuteStyles.smallStyle.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select all that apply',
                style: WintermmuteStyles.tinyStyle.copyWith(
                  color: AppColors.textDim,
                ),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonPeptides.map((peptide) {
                  final isSelected = _selectedPeptides.contains(peptide);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedPeptides.remove(peptide);
                        } else {
                          _selectedPeptides.add(peptide);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.12)
                            : AppColors.surface,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.2),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        peptide,
                        style: WintermmuteStyles.tinyStyle.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.textMid,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              Text(
                'DEPLOYMENT DURATION',
                style: WintermmuteStyles.smallStyle.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _durations.map((d) {
                  final isSelected = _duration == d['value'];
                  return GestureDetector(
                    onTap: () => setState(() => _duration = d['value']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.amber.withOpacity(0.12)
                            : AppColors.surface,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.amber
                              : AppColors.amber.withOpacity(0.2),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        d['label']!,
                        style: WintermmuteStyles.tinyStyle.copyWith(
                          color: isSelected ? AppColors.amber : AppColors.textMid,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 24),

            // Cycle status
            Container(
              height: 1,
              color: AppColors.primary.withOpacity(0.1),
            ),

            const SizedBox(height: 20),

            Text(
              'CYCLE STATUS',
              style: WintermmuteStyles.smallStyle.copyWith(
                color: AppColors.amber,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OnboardingCard(
                    isSelected: _cycleStatus == 'not_on_cycle',
                    borderColor: AppColors.textMid,
                    onTap: () => setState(() => _cycleStatus = 'not_on_cycle'),
                    child: Column(
                      children: [
                        Icon(
                          Icons.pause_circle_outline,
                          color: _cycleStatus == 'not_on_cycle'
                              ? AppColors.textLight
                              : AppColors.textDim,
                          size: 22,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'NOT ON CYCLE',
                          style: WintermmuteStyles.tinyStyle.copyWith(
                            color: _cycleStatus == 'not_on_cycle'
                                ? AppColors.textLight
                                : AppColors.textDim,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OnboardingCard(
                    isSelected: _cycleStatus == 'active_cycle',
                    borderColor: AppColors.accent,
                    onTap: () => setState(() => _cycleStatus = 'active_cycle'),
                    child: Column(
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          color: _cycleStatus == 'active_cycle'
                              ? AppColors.accent
                              : AppColors.textDim,
                          size: 22,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ACTIVE CYCLE',
                          style: WintermmuteStyles.tinyStyle.copyWith(
                            color: _cycleStatus == 'active_cycle'
                                ? AppColors.accent
                                : AppColors.textDim,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (_cycleStatus == 'active_cycle') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.2),
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.accent, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You can add your active cycle details after setup.',
                        style: WintermmuteStyles.tinyStyle.copyWith(
                          color: AppColors.accent.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            Container(
              height: 1,
              color: AppColors.primary.withOpacity(0.1),
            ),

            const SizedBox(height: 20),

            // Training level
            Text(
              'TRAINING LEVEL',
              style: WintermmuteStyles.smallStyle.copyWith(
                color: AppColors.amber,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'For dosing calculations',
              style: WintermmuteStyles.tinyStyle.copyWith(
                color: AppColors.textDim,
              ),
            ),

            const SizedBox(height: 12),

            ...(_trainingLevels).map((level) {
              final isSelected = _trainingLevel == level['value'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OnboardingCard(
                  isSelected: isSelected,
                  borderColor: AppColors.primary,
                  onTap: () => setState(() => _trainingLevel = level['value'] as String),
                  child: Row(
                    children: [
                      Icon(
                        level['icon'] as IconData,
                        color: isSelected ? AppColors.primary : AppColors.textDim,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              level['label'] as String,
                              style: WintermmuteStyles.smallStyle.copyWith(
                                color: isSelected ? AppColors.primary : AppColors.textLight,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              level['desc'] as String,
                              style: WintermmuteStyles.tinyStyle.copyWith(
                                color: AppColors.textDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check, color: AppColors.primary, size: 18),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
