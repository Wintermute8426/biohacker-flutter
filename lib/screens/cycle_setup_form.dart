import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../data/peptides.dart';
import '../widgets/peptide_selector.dart';

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
  double? _peptideAmountMg; // total mg of peptide powder
  double? _desiredConcentration; // mg/ml (calculated or user-set)
  double? _waterRequired; // calculated water in ml
  double? _mlPerDose; // calculated ml per mg dose (for 1ml syringe)

  // Route (full names)
  String? _selectedRoute = 'Subcutaneous (SC)';
  
  final Map<String, String> _routeMap = {
    'Subcutaneous (SC)': 'SC',
    'Intramuscular (IM)': 'IM',
    'Intravenous (IV)': 'IV',
    'Intranasal': 'Intranasal',
  };

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

  void _calculateReconstition() {
    if (_vialSizeMl == null || _peptideAmountMg == null || _desiredConcentration == null) {
      setState(() {
        _waterRequired = null;
        _mlPerDose = null;
      });
      return;
    }

    // Calculate water needed
    // Final volume = peptide / concentration
    final finalVolume = _peptideAmountMg! / _desiredConcentration!;
    final waterNeeded = finalVolume - 0; // assume peptide powder volume is negligible
    
    // Calculate ml per dose for 1ml syringe
    // If concentration is 5mg/ml, then 1mg = 0.2ml
    final mlPerMg = 1.0 / _desiredConcentration!;

    setState(() {
      _waterRequired = waterNeeded;
      _mlPerDose = mlPerMg;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Add ${_waterRequired!.toStringAsFixed(2)}ml water | ${_mlPerDose!.toStringAsFixed(2)}ml per 1mg dose',
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<Map<String, dynamic>> _generateDoseSchedule() {
    final doses = <Map<String, dynamic>>[];
    int dayCounter = 0;

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

  String _formatPhaseInfo() {
    final buf = <String>[];
    if (_rampUpDurationDays != null && _rampUpDurationDays! > 0) {
      final startDate = _startDate ?? DateTime.now();
      final endDate = startDate.add(Duration(days: _rampUpDurationDays! - 1));
      buf.add('Ramp up: ${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d').format(endDate)}');
    }
    if (_plateauDurationDays != null && _plateauDurationDays! > 0) {
      int offset = (_rampUpDurationDays ?? 0);
      final startDate = (_startDate ?? DateTime.now()).add(Duration(days: offset));
      final endDate = startDate.add(Duration(days: _plateauDurationDays! - 1));
      buf.add('Plateau: ${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMm d').format(endDate)}');
    }
    if (_rampDownDurationDays != null && _rampDownDurationDays! > 0) {
      int offset = (_rampUpDurationDays ?? 0) + (_plateauDurationDays ?? 0);
      final startDate = (_startDate ?? DateTime.now()).add(Duration(days: offset));
      final endDate = startDate.add(Duration(days: _rampDownDurationDays! - 1));
      buf.add('Ramp down: ${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d').format(endDate)}');
    }
    return buf.join(' | ');
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

    final routeShort = _routeMap[_selectedRoute] ?? 'SC';

    Navigator.pop(context, {
      'peptideName': _selectedPeptide,
      'route': routeShort,
      'vialSizeMl': _vialSizeMl,
      'peptideAmountMg': _peptideAmountMg,
      'desiredConcentration': _desiredConcentration,
      'waterRequired': _waterRequired,
      'mlPerDose': _mlPerDose,
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

          // ===== PEPTIDE SELECTION =====
          Text(
            'PEPTIDE',
            style: WintermmuteStyles.titleStyle.copyWith(fontSize: 14, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          PeptideSelector(
            initialValue: _selectedPeptide,
            label: 'Select peptide',
            onSelected: (peptide) {
              setState(() {
                _selectedPeptide = peptide;
                _peptideAmount = 10; // TODO: Get from peptides.dart library
              });
            },
          ),
          const SizedBox(height: 24),

          // ===== RECONSTITUTION SECTION =====
          Text(
            'RECONSTITUTION',
            style: WintermmuteStyles.titleStyle.copyWith(fontSize: 14, letterSpacing: 1),
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
              hintText: 'e.g., 2',
              hintStyle: TextStyle(color: AppColors.textDim, fontSize: 11),
              border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (value) {
              _vialSizeMl = double.tryParse(value);
              _calculateReconstition();
            },
          ),
          const SizedBox(height: 12),

          // Peptide amount
          TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: AppColors.primary),
            decoration: InputDecoration(
              labelText: 'PEPTIDE AMOUNT (mg)',
              labelStyle: TextStyle(color: AppColors.textMid, fontSize: 12),
              hintText: 'Total mg of powder you have (e.g., 10)',
              hintStyle: TextStyle(color: AppColors.textDim, fontSize: 11),
              border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (value) {
              _peptideAmountMg = double.tryParse(value);
              _calculateReconstition();
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
              hintText: 'e.g., 5 (for 5mg per ml)',
              hintStyle: TextStyle(color: AppColors.textDim, fontSize: 11),
              border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (value) {
              _desiredConcentration = double.tryParse(value);
              _calculateReconstition();
            },
          ),

          // Reconstitution summary
          if (_waterRequired != null && _mlPerDose != null) ...[
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
                    'RECONSTITUTION STEPS',
                    style: TextStyle(color: AppColors.primary, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add water:',
                        style: TextStyle(color: AppColors.textMid, fontSize: 12),
                      ),
                      Text(
                        '${_waterRequired!.toStringAsFixed(2)}ml',
                        style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Per 1mg dose (1ml syringe):',
                        style: TextStyle(color: AppColors.textMid, fontSize: 12),
                      ),
                      Text(
                        'Draw ${_mlPerDose!.toStringAsFixed(2)}ml',
                        style: TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ===== DATES SECTION =====
          Text(
            'CYCLE DATES',
            style: WintermmuteStyles.titleStyle.copyWith(fontSize: 14, letterSpacing: 1),
          ),
          const SizedBox(height: 12),

          // Start date
          ListTile(
            contentPadding: EdgeInsets.zero,
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
            contentPadding: EdgeInsets.zero,
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

          // ===== INJECTION ROUTE =====
          Text(
            'ROUTE',
            style: WintermmuteStyles.titleStyle.copyWith(fontSize: 14, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedRoute,
            decoration: InputDecoration(
              labelText: 'INJECTION ROUTE',
              labelStyle: TextStyle(color: AppColors.textMid, fontSize: 12),
              border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            dropdownColor: AppColors.surface,
            style: TextStyle(color: AppColors.primary),
            items: _routeMap.keys.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (value) {
              setState(() => _selectedRoute = value);
            },
          ),

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
                  onChanged: (v) => setState(() => _rampUpStartDose = double.tryParse(v)),
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
                  onChanged: (v) => setState(() => _rampUpIncrementPerDay = double.tryParse(v)),
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
                  onChanged: (v) => setState(() => _rampUpDurationDays = int.tryParse(v)),
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
                  onChanged: (v) => setState(() => _plateauDose = double.tryParse(v)),
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
                  onChanged: (v) => setState(() => _plateauDurationDays = int.tryParse(v)),
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
                  onChanged: (v) => setState(() => _rampDownDecrementPerDay = double.tryParse(v)),
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
                  onChanged: (v) => setState(() => _rampDownDurationDays = int.tryParse(v)),
                ),
              ),
            ],
          ),

          // Phase timeline
          if (_formatPhaseInfo().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent, width: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatPhaseInfo(),
                style: TextStyle(color: AppColors.accent, fontSize: 11),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ===== SCHEDULE SECTION =====
          Text(
            'SCHEDULE',
            style: WintermmuteStyles.titleStyle.copyWith(fontSize: 14, letterSpacing: 1),
          ),
          const SizedBox(height: 12),

          // Time picker
          ListTile(
            contentPadding: EdgeInsets.zero,
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
