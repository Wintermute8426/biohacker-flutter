import 'package:flutter/material.dart';
import '../theme/colors.dart';

class LabsScreen extends StatefulWidget {
  const LabsScreen({Key? key}) : super(key: key);

  @override
  State<LabsScreen> createState() => _LabsScreenState();
}

class _LabsScreenState extends State<LabsScreen> {
  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'UPLOAD LAB RESULTS',
            style: TextStyle(color: AppColors.primary, letterSpacing: 1),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description, color: AppColors.primary, size: 48),
              const SizedBox(height: 16),
              Text(
                'Upload PDF from your lab provider',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMid),
              ),
              const SizedBox(height: 8),
              Text(
                'Coming soon: Automatic parsing with AI',
                style: TextStyle(color: AppColors.textDim, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: AppColors.textDim)),
            ),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PDF upload feature coming soon'),
                    backgroundColor: Colors.orange,
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Select PDF'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LABS',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showUploadDialog,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('UPLOAD'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Empty State
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(Icons.favorite_border, color: AppColors.primary, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'No lab results',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textMid,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload or log your lab results here',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textDim,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
