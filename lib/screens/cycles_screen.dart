import 'package:flutter/material.dart';
import '../theme/colors.dart';

class CyclesScreen extends StatefulWidget {
  const CyclesScreen({Key? key}) : super(key: key);

  @override
  State<CyclesScreen> createState() => _CyclesScreenState();
}

class _CyclesScreenState extends State<CyclesScreen> {
  final _nameController = TextEditingController();
  final _peptideController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int _durationDays = 30;

  void _showNewCycleDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'NEW CYCLE',
            style: TextStyle(color: AppColors.primary, letterSpacing: 1),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Cycle name (e.g., Epitalon)',
                    hintStyle: TextStyle(color: AppColors.textDim),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _peptideController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Primary peptide',
                    hintStyle: TextStyle(color: AppColors.textDim),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Duration:',
                      style: TextStyle(color: AppColors.textMid),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: _durationDays.toDouble(),
                        min: 7,
                        max: 365,
                        divisions: 50,
                        label: '$_durationDays days',
                        activeColor: AppColors.primary,
                        onChanged: (value) {
                          setState(() => _durationDays = value.toInt());
                        },
                      ),
                    ),
                  ],
                ),
                Text(
                  '$_durationDays days',
                  style: TextStyle(color: AppColors.primary, fontSize: 16),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppColors.textDim)),
            ),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cycle "${_nameController.text}" created!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                  _nameController.clear();
                  _peptideController.clear();
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Create'),
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
                  'CYCLES',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showNewCycleDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('NEW'),
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
                  Text(
                    'No cycles',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textMid,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first cycle to get started',
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

  @override
  void dispose() {
    _nameController.dispose();
    _peptideController.dispose();
    super.dispose();
  }
}
