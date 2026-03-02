import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../data/dosing_calculator.dart';

class AdvancedDosingWidget extends StatefulWidget {
  final int totalWeeks;
  final String frequency;
  final double defaultDose;
  final Function(DosingSchedule) onScheduleSet;

  const AdvancedDosingWidget({
    Key? key,
    required this.totalWeeks,
    required this.frequency,
    required this.defaultDose,
    required this.onScheduleSet,
  }) : super(key: key);

  @override
  State<AdvancedDosingWidget> createState() => _AdvancedDosingWidgetState();
}

class _AdvancedDosingWidgetState extends State<AdvancedDosingWidget> {
  late TextEditingController _startDoseController;
  late TextEditingController _endDoseController;
  late TextEditingController _peakDoseController;
  String _dosageType = 'flat'; // flat, rampUp, rampDown, rampUpAndDown
  DosingSchedule? _preview;

  @override
  void initState() {
    super.initState();
    _startDoseController = TextEditingController(text: widget.defaultDose.toString());
    _endDoseController = TextEditingController(text: widget.defaultDose.toString());
    _peakDoseController = TextEditingController(text: widget.defaultDose.toString());
    _updatePreview();
  }

  void _updatePreview() {
    final startDose = double.tryParse(_startDoseController.text) ?? widget.defaultDose;
    final endDose = double.tryParse(_endDoseController.text) ?? widget.defaultDose;
    final peakDose = double.tryParse(_peakDoseController.text) ?? widget.defaultDose;

    DosingSchedule schedule;

    switch (_dosageType) {
      case 'rampUp':
        schedule = DosingProfiles.rampUp(
          startDose: startDose,
          endDose: peakDose,
          weeks: widget.totalWeeks,
          frequency: widget.frequency,
        );
        break;
      case 'rampDown':
        schedule = DosingProfiles.rampDown(
          startDose: peakDose,
          endDose: endDose,
          weeks: widget.totalWeeks,
          frequency: widget.frequency,
        );
        break;
      case 'rampUpAndDown':
        schedule = DosingProfiles.rampUpAndDown(
          startDose: startDose,
          peakDose: peakDose,
          endDose: endDose,
          weeks: widget.totalWeeks,
          frequency: widget.frequency,
        );
        break;
      default: // flat
        schedule = DosingProfiles.flatDose(
          dose: startDose,
          weeks: widget.totalWeeks,
          frequency: widget.frequency,
        );
    }

    setState(() => _preview = schedule);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 60,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DOSING SCHEDULE',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),

          // Dosage Type Selector
          Text(
            'Schedule Type',
            style: TextStyle(
              color: AppColors.textMid,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildTypeButton('Flat', 'flat'),
              _buildTypeButton('Ramp Up', 'rampUp'),
              _buildTypeButton('Ramp Down', 'rampDown'),
              _buildTypeButton('Ramp Up/Down', 'rampUpAndDown'),
            ],
          ),
          const SizedBox(height: 20),

          // Input Fields
          if (_dosageType == 'flat')
            _buildFlatDoseInput()
          else if (_dosageType == 'rampUp')
            _buildRampUpInput()
          else if (_dosageType == 'rampDown')
            _buildRampDownInput()
          else
            _buildRampUpAndDownInput(),

          const SizedBox(height: 20),

          // Preview
          if (_preview != null) ...[
            Text(
              'PREVIEW',
              style: TextStyle(
                color: AppColors.textMid,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._preview!.getWeeklySchedule().entries.take(5).map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Week ${e.key}',
                            style: TextStyle(
                              color: AppColors.textMid,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '${e.value.toStringAsFixed(2)} mg',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (_preview!.totalWeeks > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '... (${_preview!.totalWeeks - 5} more weeks)',
                        style: TextStyle(
                          color: AppColors.textDim,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                if (_preview != null) {
                  widget.onScheduleSet(_preview!);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                'SET SCHEDULE',
                style: TextStyle(
                  color: AppColors.background,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String label, String value) {
    final isSelected = _dosageType == value;
    return GestureDetector(
      onTap: () {
        setState(() => _dosageType = value);
        _updatePreview();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textMid,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFlatDoseInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dose (mg)',
          style: TextStyle(
            color: AppColors.textMid,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _startDoseController,
          style: const TextStyle(color: Colors.white),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => _updatePreview(),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRampUpInput() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start (mg)',
                      style: TextStyle(color: AppColors.textMid, fontSize: 11)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _startDoseController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _updatePreview(),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Peak (mg)',
                      style: TextStyle(color: AppColors.textMid, fontSize: 11)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _peakDoseController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _updatePreview(),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRampDownInput() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Peak (mg)',
                      style: TextStyle(color: AppColors.textMid, fontSize: 11)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _peakDoseController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _updatePreview(),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('End (mg)',
                      style: TextStyle(color: AppColors.textMid, fontSize: 11)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _endDoseController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _updatePreview(),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRampUpAndDownInput() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start (mg)',
                      style: TextStyle(color: AppColors.textMid, fontSize: 11)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _startDoseController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _updatePreview(),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Peak (mg)',
                      style: TextStyle(color: AppColors.textMid, fontSize: 11)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _peakDoseController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _updatePreview(),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('End (mg)',
                      style: TextStyle(color: AppColors.textMid, fontSize: 11)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _endDoseController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _updatePreview(),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _startDoseController.dispose();
    _endDoseController.dispose();
    _peakDoseController.dispose();
    super.dispose();
  }
}
