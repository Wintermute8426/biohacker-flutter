import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../services/dose_schedule_service.dart';
import '../services/side_effects_database.dart';
import 'full_screen_modal.dart';

class SideEffectsModal extends ConsumerStatefulWidget {
  final DoseInstance dose;
  final VoidCallback onSaved;

  const SideEffectsModal({
    Key? key,
    required this.dose,
    required this.onSaved,
  }) : super(key: key);

  @override
  ConsumerState<SideEffectsModal> createState() => _SideEffectsModalState();
}

class _SideEffectsModalState extends ConsumerState<SideEffectsModal> {
  final _notesController = TextEditingController();
  double _severity = 3.0;
  final Set<String> _selectedSymptoms = {};

  final List<String> _symptomOptions = [
    'Injection site pain',
    'Nausea',
    'Headache',
    'Fatigue',
    'Dizziness',
    'Insomnia',
    'Anxiety',
    'Mood changes',
    'Appetite change',
    'Joint pain',
    'Muscle soreness',
    'Water retention',
    'Acne',
    'Other',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveSideEffects() async {
    try {
      if (_selectedSymptoms.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please select at least one symptom',
              style: WintermmuteStyles.bodyStyle,
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final sideEffectsDb = SideEffectsDatabase();

      // Log each symptom separately
      for (final symptom in _selectedSymptoms) {
        await sideEffectsDb.logSideEffect(
          cycleId: widget.dose.cycleId,
          symptom: symptom,
          severity: _severity.toInt(),
          loggedAt: widget.dose.date,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );
      }

      if (context.mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Side effects logged successfully',
              style: WintermmuteStyles.bodyStyle,
            ),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      print('Error logging side effects: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error logging side effects',
              style: WintermmuteStyles.bodyStyle,
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FullScreenModal(
      title: 'Log Side Effects',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Peptide info
          Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.background,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.dose.peptideName} - ${widget.dose.doseAmount}mg',
                      style: WintermmuteStyles.bodyStyle.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.dose.date.year}-${widget.dose.date.month.toString().padLeft(2, '0')}-${widget.dose.date.day.toString().padLeft(2, '0')} • ${widget.dose.time}',
                      style: WintermmuteStyles.smallStyle
                          .copyWith(color: AppColors.textMid),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Severity slider
              Text(
                'Severity (1-5)',
                style: WintermmuteStyles.bodyStyle.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _severity,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: _severity.toInt().toString(),
                      activeColor: AppColors.accent,
                      inactiveColor: AppColors.border,
                      onChanged: (value) {
                        setState(() {
                          _severity = value;
                        });
                      },
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      border: Border.all(color: AppColors.accent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _severity.toInt().toString(),
                        style: WintermmuteStyles.titleStyle.copyWith(
                          color: AppColors.accent,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Symptom checkboxes
              Text(
                'Symptoms',
                style: WintermmuteStyles.bodyStyle.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _symptomOptions.map((symptom) {
                  final isSelected = _selectedSymptoms.contains(symptom);
                  return FilterChip(
                    label: Text(
                      symptom,
                      style: WintermmuteStyles.bodyStyle.copyWith(
                        color: isSelected
                            ? AppColors.background
                            : AppColors.textMid,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSymptoms.add(symptom);
                        } else {
                          _selectedSymptoms.remove(symptom);
                        }
                      });
                    },
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.accent,
                    checkmarkColor: AppColors.background,
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.border,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Notes field
              Text(
                'Notes (Optional)',
                style: WintermmuteStyles.bodyStyle.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                style: WintermmuteStyles.bodyStyle,
                decoration: InputDecoration(
                  hintText: 'Additional details...',
                  hintStyle: WintermmuteStyles.bodyStyle
                      .copyWith(color: AppColors.textDim),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'CANCEL',
                        style: WintermmuteStyles.bodyStyle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveSideEffects,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'SAVE',
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
  }
}
