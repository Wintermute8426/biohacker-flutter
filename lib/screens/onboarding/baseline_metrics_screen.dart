import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/wintermute_styles.dart';
import '../../services/onboarding_service.dart';
import 'notification_prefs_screen.dart';

class BaselineMetricsScreen extends StatefulWidget {
  final OnboardingData data;

  const BaselineMetricsScreen({Key? key, required this.data}) : super(key: key);

  @override
  State<BaselineMetricsScreen> createState() => _BaselineMetricsScreenState();
}

class _BaselineMetricsScreenState extends State<BaselineMetricsScreen> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _bodyFatController = TextEditingController();
  bool _showLabsSection = false;

  // Lab controllers
  final TextEditingController _testosteroneController = TextEditingController();
  final TextEditingController _igf1Controller = TextEditingController();
  final TextEditingController _hghController = TextEditingController();
  final TextEditingController _cortisolController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.data.baselineWeight != null) {
      _weightController.text = widget.data.baselineWeight!.toStringAsFixed(1);
    }
    if (widget.data.baselineBodyFat != null) {
      _bodyFatController.text = widget.data.baselineBodyFat!.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _testosteroneController.dispose();
    _igf1Controller.dispose();
    _hghController.dispose();
    _cortisolController.dispose();
    super.dispose();
  }

  void _continue() {
    // Weight is required
    if (_weightController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter your current weight',
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

    // Body fat is optional but validate if provided
    double? bodyFat;
    if (_bodyFatController.text.trim().isNotEmpty) {
      bodyFat = double.tryParse(_bodyFatController.text);
      if (bodyFat == null || bodyFat < 0 || bodyFat > 50) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Body fat % should be between 0-50',
              style: WintermmuteStyles.bodyStyle,
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    // Build labs JSON if any values provided
    Map<String, dynamic>? labs;
    if (_testosteroneController.text.isNotEmpty ||
        _igf1Controller.text.isNotEmpty ||
        _hghController.text.isNotEmpty ||
        _cortisolController.text.isNotEmpty) {
      labs = {};
      if (_testosteroneController.text.isNotEmpty) {
        labs['testosterone'] = double.tryParse(_testosteroneController.text);
      }
      if (_igf1Controller.text.isNotEmpty) {
        labs['igf1'] = double.tryParse(_igf1Controller.text);
      }
      if (_hghController.text.isNotEmpty) {
        labs['hgh'] = double.tryParse(_hghController.text);
      }
      if (_cortisolController.text.isNotEmpty) {
        labs['cortisol'] = double.tryParse(_cortisolController.text);
      }
    }

    widget.data.baselineWeight = weight;
    widget.data.baselineBodyFat = bodyFat;
    widget.data.baselineLabs = labs;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationPrefsScreen(data: widget.data),
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
          'STEP 4 OF 6',
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
                  value: 4 / 6,
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
                      'Let\'s record your starting point',
                      style: WintermmuteStyles.headerStyle.copyWith(
                        fontSize: 22,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Track your progress over time',
                      style: WintermmuteStyles.smallStyle.copyWith(
                        color: AppColors.textMid,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Weight field (required)
                    _buildTextField(
                      controller: _weightController,
                      label: 'Current Weight (lbs) *',
                      hint: '185',
                      required: true,
                    ),

                    const SizedBox(height: 20),

                    // Body fat field (optional)
                    _buildTextField(
                      controller: _bodyFatController,
                      label: 'Body Fat % (optional)',
                      hint: '12.5',
                      required: false,
                    ),

                    const SizedBox(height: 24),

                    // Optional labs section
                    GestureDetector(
                      onTap: () => setState(() => _showLabsSection = !_showLabsSection),
                      child: Container(
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
                            Icon(
                              _showLabsSection
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Have recent bloodwork? (Optional)',
                                style: WintermmuteStyles.bodyStyle.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_showLabsSection) ...[
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _testosteroneController,
                        label: 'Testosterone (ng/dL)',
                        hint: '650',
                        required: false,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _igf1Controller,
                        label: 'IGF-1 (ng/mL)',
                        hint: '210',
                        required: false,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _hghController,
                        label: 'HGH (ng/mL)',
                        hint: '0.5',
                        required: false,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _cortisolController,
                        label: 'Cortisol (μg/dL)',
                        hint: '12',
                        required: false,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Info box
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
                            Icons.info_outline,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You can add or update baseline lab values anytime in Settings.',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool required,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      style: WintermmuteStyles.bodyStyle,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: WintermmuteStyles.smallStyle.copyWith(
          color: AppColors.textMid,
        ),
        hintText: hint,
        hintStyle: WintermmuteStyles.smallStyle.copyWith(
          color: AppColors.textDim,
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: AppColors.primary.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: AppColors.primary.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
