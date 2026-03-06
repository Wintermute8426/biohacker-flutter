import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../services/dose_logs_service.dart';

class AddSymptomsModal extends StatefulWidget {
  final String doseLogId;
  final String peptideName;
  final DateTime scheduledAt;
  final VoidCallback onCompleted;

  const AddSymptomsModal({
    Key? key,
    required this.doseLogId,
    required this.peptideName,
    required this.scheduledAt,
    required this.onCompleted,
  }) : super(key: key);

  @override
  State<AddSymptomsModal> createState() => _AddSymptomsModalState();
}

class _AddSymptomsModalState extends State<AddSymptomsModal> {
  late TextEditingController _descriptionController;
  int _severity = 5; // 1-10 scale
  bool _isLoading = false;

  final List<String> _commonSymptoms = [
    'Headache',
    'Nausea',
    'Fatigue',
    'Dizziness',
    'Appetite change',
    'Sleep issues',
    'Muscle soreness',
    'Rash',
    'Fever',
    'Flu-like',
  ];

  List<String> _selectedSymptoms = [];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitSymptoms() async {
    if (_selectedSymptoms.isEmpty && _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or describe at least one symptom'),
          backgroundColor: Color(0xFFFF0040),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = DoseLogsService(Supabase.instance.client);
      
      final symptomsData = {
        'symptoms': _selectedSymptoms,
        'severity': _severity,
        'description': _descriptionController.text.isNotEmpty 
          ? _descriptionController.text 
          : null,
        'logged_at': DateTime.now().toIso8601String(),
      };

      await service.addSymptoms(widget.doseLogId, symptomsData);
      // Auto-mark as COMPLETED after symptoms logged
      await service.markAsCompleted(widget.doseLogId);

      print('[DEBUG] Symptoms added and dose marked as COMPLETED');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Symptoms logged for ${widget.peptideName}'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
        widget.onCompleted();
      }
    } catch (e) {
      print('[ERROR] Failed to add symptoms: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
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
          'ADD SYMPTOMS',
          style: WintermmuteStyles.headerStyle.copyWith(fontSize: 16),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Peptide info
            Text(
              widget.peptideName,
              style: WintermmuteStyles.headerStyle.copyWith(
                color: AppColors.primary,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scheduled: ${widget.scheduledAt.toString().substring(0, 16)}',
              style: WintermmuteStyles.tinyStyle.copyWith(color: AppColors.textMid),
            ),
            const SizedBox(height: 24),

            // Common symptoms chips
            Text(
              'COMMON SYMPTOMS',
              style: WintermmuteStyles.headerStyle.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonSymptoms.map((symptom) {
                final isSelected = _selectedSymptoms.contains(symptom);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedSymptoms.remove(symptom);
                      } else {
                        _selectedSymptoms.add(symptom);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                    ),
                    child: Text(
                      symptom,
                      style: WintermmuteStyles.tinyStyle.copyWith(
                        color: isSelected ? AppColors.primary : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Severity slider
            Text(
              'SEVERITY (1-10)',
              style: WintermmuteStyles.headerStyle.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _severity.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: _severity > 7 
                      ? Color(0xFFFF0040) 
                      : _severity > 4 
                        ? Color(0xFFFFA500) 
                        : AppColors.primary,
                    onChanged: (value) {
                      setState(() => _severity = value.toInt());
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _severity.toString(),
                    style: WintermmuteStyles.bodyStyle.copyWith(
                      color: _severity > 7 
                        ? Color(0xFFFF0040) 
                        : _severity > 4 
                          ? Color(0xFFFFA500) 
                          : AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Additional description
            Text(
              'ADDITIONAL NOTES (optional)',
              style: WintermmuteStyles.headerStyle.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Describe any additional symptoms or details...',
                hintStyle: TextStyle(color: AppColors.textDim),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitSymptoms,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'LOG SYMPTOMS',
                        style: WintermmuteStyles.bodyStyle.copyWith(
                          color: AppColors.background,
                          fontWeight: FontWeight.bold,
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
