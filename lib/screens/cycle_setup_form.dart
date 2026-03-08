import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../data/peptides.dart';

class CycleSetupForm extends StatefulWidget {
  final String? defaultPeptideName;

  const CycleSetupForm({
    Key? key,
    this.defaultPeptideName,
  }) : super(key: key);

  @override
  State<CycleSetupForm> createState() => _CycleSetupFormState();
}

class _CycleSetupFormState extends State<CycleSetupForm> {
  // Reconstitution
  String? _selectedPeptide;
  double? _vialSizeMl;
  double? _desiredConcentration; // mg/ml
  double? _peptideAmount; // mg in vial (from library)
  double? _bacRequired; // calculated BAC in ml

  // Dosing strategy
  double? _rampUpStartDose;
  double? _rampUpIncrementPerDay;
  int? _rampUpDurationDays;
  
  double? _plateauDose;
  int? _plateauDurationDays;
  
  double? _rampDownDecrementPerDay;
  int? _rampDownDurationDays;

  // Schedule
  String? _scheduledTime = '08:00';
  List<int> _daysOfWeek = [1, 3, 5]; // Mon, Wed, Fri
  DateTime? _startDate;
  DateTime? _endDate;

  // Controllers
  final _vialSizeController = TextEditingController();
  final _desiredConcentrationController = TextEditingController();
  final _rampUpStartController = TextEditingController();
  final _rampUpIncrementController = TextEditingController();
  final _rampUpDaysController = TextEditingController();
  final _plateauDoseController = TextEditingController();
  final _plateauDaysController = TextEditingController();
  final _rampDownDecrementController = TextEditingController();
  final _rampDownDaysController = TextEditingController();

  final List<String> _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _selectedPeptide = widget.defaultPeptideName;
  }

  void _calculateBAC() {
    if (_vialSizeMl == null || _desiredConcentration == null || _peptideAmount == null) {
      setState(() => _bacRequired = null);
      return;
    }

    // Calculate: How much BAC to add to reach desired concentration?
    // Desired final volume: peptide_amount / desired_concentration (in mg/ml)
    // BAC needed = final_volume - vial_size
    final desiredFinalVolume = _peptideAmount! / _desiredConcentration!;
    final bacNeeded = desiredFinalVolume - _vialSizeMl!;

    setState(() => _bacRequired = bacNeeded > 0 ? bacNeeded : 0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _bacRequired != null
              ? 'Add ${_bacRequired!.toStringAsFixed(2)}ml BAC to ${_vialSizeMl}ml vial'
              : 'Invalid calculation',
        ),
        backgroundColor: _bacRequired != null ? AppColors.primary : AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<Map<String, dynamic>> _generateDoseSchedule() {
    final doses = <Map<String, dynamic>>[];
    int dayCounter = 0;

    // Ramp up phase
    if (_rampUpStartDose != null && _rampUpIncrementPerDay != null && _rampUpDurationDays != null) {
      for (int i = 0; i < _rampUpDurationDays!; i++) {
        final dose = _rampUpStartDose! + (_rampUpIncrementPerDay! * i);
        doses.add({
          'day': dayCounter,
          'dose': dose,
          'phase': 'ramp_up',
        });
        dayCounter++;
      }
    }

    // Plateau phase
    if (_plateauDose != null && _plateauDurationDays != null) {
      for (int i = 0; i < _plateauDurationDays!; i++) {
        doses.add({
          'day': dayCounter,
          'dose': _plateauDose,
          'phase': 'plateau',
        });
        dayCounter++;
      }
    }

    // Ramp down phase
    if (_rampDownDecrementPerDay != null && _rampDownDurationDays != null) {
      double currentDose = doses.isNotEmpty ? (doses.last['dose'] as double) : _plateauDose ?? _rampUpStartDose ?? 0;
      for (int i = 0; i < _rampDownDurationDays!; i++) {
        currentDose = (currentDose - (_rampDownDecrementPerDay! * i)).clamp(0, double.infinity);
        doses.add({
          'day': dayCounter,
          'dose': currentDose,
          'phase': 'ramp_down',
        });
        dayCounter++;
      }
    }

    return doses;
  }

  void _submit() {
    if (_selectedPeptide == null ||
        _vialSizeMl == null ||
        _desiredConcentration == null ||
        _startDate == null ||
        (_rampUpStartDose == null && _plateauDose == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Color(0xFFFF0040),
        ),
      );
      return;
    }

    final schedule = _generateDoseSchedule();
    if (schedule.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No doses generated. Check ramp/plateau settings'),
          backgroundColor: Color(0xFFFF0040),
        ),
      );
      return;
    }

    // Return all data to caller
    Navigator.pop(context, {
      'peptideName': _selectedPeptide,
      'vialSizeMl': _vialSizeMl,
      'desiredConcentration': _desiredConcentration,
      'bacRequired': _bacRequired,
      'schedule': schedule,
      'scheduledTime': _scheduledTime,
      'daysOfWeek': _daysOfWeek,
      'startDate': _startDate,
      'endDate': _endDate,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            'CYCLE SETUP',
            style: WintermmuteStyles.headerStyle,
          ),
          const SizedBox(height: 24),

          // ===== RECONSTITUTION SECTION =====
          Text(
            'RECONSTITUTION',
            style: WintermmuteStyles.titleStyle.copyWith(fontSize: 14, letterSpacing: 1),
          ),
          const SizedBox(height: 12),

          // Peptide selector
          DropdownButtonFormField<String>(
            initialValue: _selectedPeptide,
            decoration: InputDecoration(
              labelText: 'PEPTIDE',
              labelStyle: TextStyle(color: AppColors.textMid, fontSize: 12),
              border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            dropdownColor: AppColors.surface,
            style: TextStyle(color: AppColors.primary),
            items: PEPTIDE_LIST.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (value) {
              setState(() {
                _selectedPeptide = value;
                // Look up peptide amount
                _peptideAmount = 10; // TODO: Get from peptides.dart library
              });
            },
          ),
          const SizedBox(height: 12),

          // Vial size
          TextField(
            controller: _vialSizeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: AppColors.primary),
            decoration: InputDecoration(
              labelText: 'VIAL SIZE (ml)',
              labelStyle: TextStyle(color: AppColors.textMid, fontSize: 12),
              border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (value) {
              _vialSizeMl = double.tryParse(value);
              _calculateBAC();
            },
          ),
          const SizedBox(height: 12),

          // Desired concentration
          TextField(
            controller: _desiredConcentrationController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: AppColors.primary),
            decoration: InputDecoration(
              labelText: 'DESIRED CONCENTRATION (mg/ml)',
              labelStyle: TextStyle(color: AppColors.textMid, fontSize: 12),
              border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (value) {
              _desiredConcentration = double.tryParse(value);
              _calculateBAC();
            },
          ),

          // BAC display
          if (_bacRequired != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECONSTITUTION',
                    style: TextStyle(color: AppColors.primary, fontSize: 11, letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add ${_bacRequired!.toStringAsFixed(2)}ml BAC',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ===== DOSING STRATEGY SECTION =====
          Text(
            'DOSING STRATEGY',
            style: WintermmuteStyles.titleStyle.copyWith(fontSize: 14, letterSpacing: 1),
          ),
          const SizedBox(height: 12),

          // Ramp up
          Text(
            'RAMP UP (Optional)',
            style: TextStyle(color: AppColors.textMid, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _rampUpStartController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: AppColors.primary),
                  decoration: InputDecoration(
                    labelText: 'START (mg)',
                    labelStyle: TextStyle(color: AppColors.textMid, fontSize: 11),
                    border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  onChanged: (v) => _rampUpStartDose = double.tryParse(v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _rampUpIncrementController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: AppColors.primary),
                  decoration: InputDecoration(
                    labelText: '+/DAY (mg)',
                    labelStyle: TextStyle(color: AppColors.textMid, fontSize: 11),
                    border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  onChanged: (v) => _rampUpIncrementPerDay = double.tryParse(v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _rampUpDaysController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: AppColors.primary),
                  decoration: InputDecoration(
                    labelText: 'DAYS',
                    labelStyle: TextStyle(color: AppColors.textMid, fontSize: 11),
                    border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  onChanged: (v) => _rampUpDurationDays = int.tryParse(v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Plateau
          Text(
            'PLATEAU',
            style: TextStyle(color: AppColors.textMid, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _plateauDoseController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: AppColors.primary),
                  decoration: InputDecoration(
                    labelText: 'DOSE (mg)',
                    labelStyle: TextStyle(color: AppColors.textMid, fontSize: 11),
                    border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  onChanged: (v) => _plateauDose = double.tryParse(v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _plateauDaysController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: AppColors.primary),
                  decoration: InputDecoration(
                    labelText: 'DAYS',
                    labelStyle: TextStyle(color: AppColors.textMid, fontSize: 11),
                    border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  onChanged: (v) => _plateauDurationDays = int.tryParse(v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ramp down
          Text(
            'RAMP DOWN (Optional)',
            style: TextStyle(color: AppColors.textMid, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _rampDownDecrementController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: AppColors.primary),
                  decoration: InputDecoration(
                    labelText: '-/DAY (mg)',
                    labelStyle: TextStyle(color: AppColors.textMid, fontSize: 11),
                    border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  onChanged: (v) => _rampDownDecrementPerDay = double.tryParse(v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _rampDownDaysController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: AppColors.primary),
                  decoration: InputDecoration(
                    labelText: 'DAYS',
                    labelStyle: TextStyle(color: AppColors.textMid, fontSize: 11),
                    border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  onChanged: (v) => _rampDownDurationDays = int.tryParse(v),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ===== SCHEDULE SECTION =====
          Text(
            'SCHEDULE',
            style: WintermmuteStyles.titleStyle.copyWith(fontSize: 14, letterSpacing: 1),
          ),
          const SizedBox(height: 12),

          // Time picker
          ListTile(
            title: Text(
              'TIME',
              style: TextStyle(color: AppColors.textMid, fontSize: 12),
            ),
            trailing: Text(
              _scheduledTime ?? '08:00',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(
                  DateTime.parse('2000-01-01 ${_scheduledTime ?? "08:00"}'),
                ),
              );
              if (time != null) {
                setState(() => _scheduledTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
              }
            },
          ),

          // Days of week
          Text(
            'DAYS',
            style: TextStyle(color: AppColors.textMid, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: List.generate(7, (i) {
              final isSelected = _daysOfWeek.contains(i);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _daysOfWeek.remove(i);
                    } else {
                      _daysOfWeek.add(i);
                    }
                    _daysOfWeek.sort();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.textMid),
                    borderRadius: BorderRadius.circular(4),
                    color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
                  ),
                  child: Text(
                    _dayNames[i],
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textMid,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 12),

          // Start date
          ListTile(
            title: Text(
              'START DATE',
              style: TextStyle(color: AppColors.textMid, fontSize: 12),
            ),
            trailing: Text(
              _startDate != null ? DateFormat('MMM d, yyyy').format(_startDate!) : 'Select',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _startDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) setState(() => _startDate = date);
            },
          ),

          // End date (optional)
          ListTile(
            title: Text(
              'END DATE (Optional)',
              style: TextStyle(color: AppColors.textMid, fontSize: 12),
            ),
            trailing: Text(
              _endDate != null ? DateFormat('MMM d, yyyy').format(_endDate!) : 'Auto',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _endDate ?? _startDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) setState(() => _endDate = date);
            },
          ),

          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text(
                'CREATE CYCLE',
                style: TextStyle(
                  color: AppColors.background,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _vialSizeController.dispose();
    _desiredConcentrationController.dispose();
    _rampUpStartController.dispose();
    _rampUpIncrementController.dispose();
    _rampUpDaysController.dispose();
    _plateauDoseController.dispose();
    _plateauDaysController.dispose();
    _rampDownDecrementController.dispose();
    _rampDownDaysController.dispose();
    super.dispose();
  }
}
