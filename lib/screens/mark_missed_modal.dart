import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../services/dose_logs_service.dart';

class MarkMissedModal extends StatefulWidget {
  final String doseLogId;
  final String peptideName;
  final DateTime scheduledAt;
  final VoidCallback onCompleted;

  const MarkMissedModal({
    Key? key,
    required this.doseLogId,
    required this.peptideName,
    required this.scheduledAt,
    required this.onCompleted,
  }) : super(key: key);

  @override
  State<MarkMissedModal> createState() => _MarkMissedModalState();
}

class _MarkMissedModalState extends State<MarkMissedModal> {
  late TextEditingController _reasonController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitMissed() async {
    setState(() => _isLoading = true);

    try {
      final service = DoseLogsService(Supabase.instance.client);
      await service.markAsMissed(widget.doseLogId);

      print('[DEBUG] Dose marked as MISSED');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${widget.peptideName} marked as MISSED'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
        widget.onCompleted();
      }
    } catch (e) {
      print('[ERROR] Failed to mark dose as missed: $e');
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
          'MARK AS MISSED',
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

            // Reason (optional)
            Text(
              'Why did you miss this dose? (optional)',
              style: WintermmuteStyles.headerStyle.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textLight),
              decoration: InputDecoration(
                hintText: 'e.g., "Forgot", "Was traveling", "Felt sick"',
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
                onPressed: _isLoading ? null : _submitMissed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.textLight),
                        ),
                      )
                    : Text(
                        'CONFIRM MISSED',
                        style: WintermmuteStyles.bodyStyle.copyWith(
                          color: AppColors.textLight,
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
