import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../services/weight_logs_database.dart';
import 'full_screen_modal.dart';

class WeightLogModal extends ConsumerStatefulWidget {
  final VoidCallback onSaved;

  const WeightLogModal({
    Key? key,
    required this.onSaved,
  }) : super(key: key);

  @override
  ConsumerState<WeightLogModal> createState() => _WeightLogModalState();
}

class _WeightLogModalState extends ConsumerState<WeightLogModal> {
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveWeight() async {
    // Validate weight is not empty
    if (_weightController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter your weight',
            style: WintermmuteStyles.bodyStyle,
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate weight is a valid positive number
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Weight must be a positive number',
            style: WintermmuteStyles.bodyStyle,
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate weight is in reasonable range (50-500 lbs)
    if (weight < 50 || weight > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Weight should be between 50 and 500 lbs',
            style: WintermmuteStyles.bodyStyle,
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate body fat percentage if provided
    final bodyFat = _bodyFatController.text.trim().isNotEmpty
        ? double.tryParse(_bodyFatController.text.trim())
        : null;

    if (bodyFat != null) {
      // Check if it's a valid number
      if (bodyFat < 0 || bodyFat > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Body fat % must be between 0 and 100',
              style: WintermmuteStyles.bodyStyle,
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Warn if body fat seems unrealistic (typically 3-50%)
      if (bodyFat < 3 || bodyFat > 50) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Body fat % seems unusual. Typical range is 3-50%',
              style: WintermmuteStyles.bodyStyle,
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final weightDb = WeightLogsDatabase();
      await weightDb.saveWeightLog(
        weightLbs: weight,
        bodyFatPercent: bodyFat,
        loggedAt: DateTime.now(),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (context.mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      print('Error saving weight: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving weight: $e',
              style: WintermmuteStyles.bodyStyle,
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FullScreenModal(
      title: 'Log Weight',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Weight input
              Text(
                'Weight (lbs)',
                style: WintermmuteStyles.bodyStyle.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: WintermmuteStyles.bodyStyle.copyWith(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Enter weight...',
                  hintStyle: WintermmuteStyles.bodyStyle
                      .copyWith(color: AppColors.textDim),
                  prefixIcon: Icon(
                    Icons.fitness_center,
                    color: AppColors.primary,
                  ),
                  suffixText: 'lbs',
                  suffixStyle: WintermmuteStyles.bodyStyle.copyWith(
                    color: AppColors.textMid,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                ),
              ),
              const SizedBox(height: 20),

              // Body fat % input (optional)
              Text(
                'Body Fat % (Optional)',
                style: WintermmuteStyles.bodyStyle.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bodyFatController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: WintermmuteStyles.bodyStyle.copyWith(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Enter body fat %...',
                  hintStyle: WintermmuteStyles.bodyStyle
                      .copyWith(color: AppColors.textDim),
                  prefixIcon: Icon(
                    Icons.percent,
                    color: AppColors.secondary,
                  ),
                  suffixText: '%',
                  suffixStyle: WintermmuteStyles.bodyStyle.copyWith(
                    color: AppColors.textMid,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.secondary, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                ),
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
                  hintText: 'Add any notes...',
                  hintStyle: WintermmuteStyles.bodyStyle
                      .copyWith(color: AppColors.textDim),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                    borderRadius: BorderRadius.circular(8),
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
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'CANCEL',
                        style: WintermmuteStyles.bodyStyle.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveWeight,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.background,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
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
