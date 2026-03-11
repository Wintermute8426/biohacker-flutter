import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../services/weight_logs_database.dart';

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
    if (_weightController.text.isEmpty) {
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

    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid weight',
            style: WintermmuteStyles.bodyStyle,
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final bodyFat = _bodyFatController.text.isNotEmpty
        ? double.tryParse(_bodyFatController.text)
        : null;

    if (bodyFat != null && (bodyFat < 0 || bodyFat > 100)) {
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
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: ListView(
            controller: scrollController,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMid,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  Icon(
                    Icons.scale_outlined,
                    color: AppColors.accent,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Log Weight',
                    style: WintermmuteStyles.titleStyle,
                  ),
                ],
              ),
              const SizedBox(height: 24),

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
      },
    );
  }
}
