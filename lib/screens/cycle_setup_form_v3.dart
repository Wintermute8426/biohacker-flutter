import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../data/peptides.dart';
import '../widgets/peptide_selector.dart';

class CycleSetupFormV3 extends StatefulWidget {
  final String? defaultPeptideName;

  const CycleSetupFormV3({
    Key? key,
    this.defaultPeptideName,
  }) : super(key: key);

  @override
  State<CycleSetupFormV3> createState() => _CycleSetupFormV3State();
}

class _CycleSetupFormV3State extends State<CycleSetupFormV3> {
  // Reconstitution
  String? _selectedPeptide;
  double? _totalPeptideMg;
  double? _desiredDosageMg;
  double? _concentrationMg;
  double? _concentrationMl;
  double? _bacRequired;
  double? _totalVolume;

  // Route
  String? _selectedRoute = 'Subcutaneous (SC)';
  final Map<String, String> _routeMap = {
    'Subcutaneous (SC)': 'SC',
    'Intramuscular (IM)': 'IM',
    'Intravenous (IV)': 'IV',
    'Intranasal': 'Intranasal',
  };

  // Cycle Duration
  int? _cycleDurationDays;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showDateEditor = false;

  // Frequency
  String? _injectionFrequency = 'Daily';
  int? _totalInjections;
  List<int> _daysOfWeek = [];

  // Titration phases
  int? _rampUpDays;
  double? _rampUpStartDose;
  double? _rampUpIncrementPerDay;
  int? _rampDownDays;
  double? _rampDownDecrementPerDay;
  int? _plateauDays; // Auto-calculated

  // Schedule
  String? _scheduledTime = '08:00';

  // Controllers
  final _totalPeptideController = TextEditingController();
  final _desiredDosageController = TextEditingController();
  final _concentrationMgController = TextEditingController();
  final _concentrationMlController = TextEditingController();
  final _cycleDurationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _selectedPeptide = widget.defaultPeptideName;
  }

  void _calculateReconstition() {
    if (_totalPeptideMg == null || _concentrationMg == null || _concentrationMl == null) {
      setState(() {
        _bacRequired = null;
        _totalVolume = null;
      });
      return;
    }

    final mgPerMl = _concentrationMg! / _concentrationMl!;
    final totalVol = _totalPeptideMg! / mgPerMl;
    final bac = totalVol;

    setState(() {
      _totalVolume = totalVol;
      _bacRequired = bac;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Add ${_bacRequired!.toStringAsFixed(1)}ml BAC | ${_concentrationMg}mg in ${_concentrationMl}ml per injection'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _updateCycleDuration() {
    if (_cycleDurationDays == null) return;
    
    _endDate = _startDate!.add(Duration(days: _cycleDurationDays! - 1));
    
    int? injections;
    List<int> daysOfWeek = [];
    
    switch (_injectionFrequency) {
      case 'Daily':
        injections = _cycleDurationDays;
        daysOfWeek = [0, 1, 2, 3, 4, 5, 6];
        break;
      case '3x/week':
        injections = ((_cycleDurationDays! / 7) * 3).ceil();
        daysOfWeek = [1, 3, 5];
        break;
      case '1x/week':
        injections = (_cycleDurationDays! / 7).ceil();
        daysOfWeek = [1];
        break;
    }

    setState(() {
      _totalInjections = injections;
      _daysOfWeek = daysOfWeek;
      _calculatePlateauDays();
    });
  }

  void _calculatePlateauDays() {
    if (_cycleDurationDays == null) return;
    
    int usedDays = (_rampUpDays ?? 0) + (_rampDownDays ?? 0);
    if (usedDays < _cycleDurationDays!) {
      _plateauDays = _cycleDurationDays! - usedDays;
    } else {
      _plateauDays = 0;
    }
  }

  void _showTitrationModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (context) => TitrationModal(
        cycleDurationDays: _cycleDurationDays,
        onRampUpChanged: (days, startDose, increment) {
          setState(() {
            _rampUpDays = days;
            _rampUpStartDose = startDose;
            _rampUpIncrementPerDay = increment;
            _calculatePlateauDays();
          });
        },
        onRampDownChanged: (days, decrement) {
          setState(() {
            _rampDownDays = days;
            _rampDownDecrementPerDay = decrement;
            _calculatePlateauDays();
          });
        },
        initialRampUpDays: _rampUpDays,
        initialRampUpStart: _rampUpStartDose,
        initialRampUpIncrement: _rampUpIncrementPerDay,
        initialRampDownDays: _rampDownDays,
        initialRampDownDecrement: _rampDownDecrementPerDay,
      ),
    );
  }

  List<Map<String, dynamic>> _generateDoseSchedule() {
    final doses = <Map<String, dynamic>>[];
    int dayOffset = 0;
    int injectionCount = 0;

    // Ramp up
    if (_rampUpStartDose != null && _rampUpIncrementPerDay != null && _rampUpDays != null) {
      for (int i = 0; i < _rampUpDays!; i++) {
        if (_daysOfWeek.contains(dayOffset % 7)) {
          final dose = _rampUpStartDose! + (_rampUpIncrementPerDay! * injectionCount);
          doses.add({
            'dayOffset': dayOffset,
            'dose': dose,
            'phase': 'ramp_up',
          });
          injectionCount++;
        }
        dayOffset++;
      }
    }

    // Plateau
    if (_plateauDays != null && _plateauDays! > 0) {
      final plateauDose = doses.isNotEmpty ? (doses.last['dose'] as double) : (_rampUpStartDose ?? 0);
      for (int i = 0; i < _plateauDays!; i++) {
        if (_daysOfWeek.contains(dayOffset % 7)) {
          doses.add({
            'dayOffset': dayOffset,
            'dose': plateauDose,
            'phase': 'plateau',
          });
        }
        dayOffset++;
      }
    }

    // Ramp down
    if (_rampDownDecrementPerDay != null && _rampDownDays != null) {
      double currentDose = doses.isNotEmpty ? (doses.last['dose'] as double) : 0;
      int rampDownCount = 0;
      for (int i = 0; i < _rampDownDays!; i++) {
        if (_daysOfWeek.contains(dayOffset % 7)) {
          currentDose = (currentDose - (_rampDownDecrementPerDay! * rampDownCount)).clamp(0, double.infinity);
          doses.add({
            'dayOffset': dayOffset,
            'dose': currentDose,
            'phase': 'ramp_down',
          });
          rampDownCount++;
        }
        dayOffset++;
      }
    }

    return doses;
  }

  void _submit() {
    if (_selectedPeptide == null ||
        _totalPeptideMg == null ||
        _desiredDosageMg == null ||
        _concentrationMg == null ||
        _concentrationMl == null ||
        _cycleDurationDays == null ||
        _startDate == null ||
        (_rampUpStartDose == null && _plateauDays == null)) {
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
          content: Text('No doses generated. Check settings'),
          backgroundColor: Color(0xFFFF0040),
        ),
      );
      return;
    }

    final routeShort = _routeMap[_selectedRoute] ?? 'SC';

    Navigator.pop(context, {
      'peptideName': _selectedPeptide,
      'route': routeShort,
      'totalPeptideMg': _totalPeptideMg,
      'desiredDosageMg': _desiredDosageMg,
      'concentrationMg': _concentrationMg,
      'concentrationMl': _concentrationMl,
      'bacRequired': _bacRequired,
      'totalVolume': _totalVolume,
      'schedule': schedule,
      'scheduledTime': _scheduledTime,
      'daysOfWeek': _daysOfWeek,
      'startDate': _startDate,
      'endDate': _endDate,
      'cycleDurationDays': _cycleDurationDays,
      'injectionFrequency': _injectionFrequency,
      'totalInjections': _totalInjections,
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
          Text('CYCLE SETUP', style: WintermmuteStyles.headerStyle),
          const SizedBox(height: 24),

          // ===== PEPTIDE =====
          Text('PEPTIDE', style: WintermmuteStyles.titleStyle.copyWith(fontSize: 14, letterSpacing: 1)),
          const SizedBox(height: 12),
          PeptideSelector(
            initialValue: _selectedPeptide,
            label: 'Select peptide',
            onSelected: (peptide) => setState(() => _selectedPeptide = peptide),
          ),
          const SizedBox(height: 24),

          // ===== RECONSTITUTION =====
          Text('RECONSTITUTION', style: WintermmuteStyles.titleStyle.copyWith(fontSize: 14, letterSpacing: 1)),
          const SizedBox(height: 12),
          TextField(
            controller: _totalPeptideController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: AppColors.primary),
            decoration: InputDecoration(
              labelText: 'VIAL SIZE (mg)',
              labelStyle: TextStyle(color: AppColors.textMid, fontSize: 12),
              hintText: 'e.g., 10',
              border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (value) {
              _totalPeptideMg = double.tryParse(value);
              _calculateReconstition();
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desiredDosageController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: AppColors.primary),
            decoration: InputDecoration(
              labelText: 'DESIRED DOSAGE PER INJECTION (mg)',
              labelStyle: TextStyle(color: AppColors.textMid, fontSize: 12),
              hintText: 'e.g., 1',
              border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (value) {
              _desiredDosageMg = double.tryParse(value);
              _calculateReconstition();
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _concentrationMgController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: AppColors.primary),
                  decoration: InputDecoration(
                    labelText: 'DESIRED: X mg',
                    labelStyle: TextStyle(color: AppColors.textMid, fontSize: 12),
                    hintText: '1',
                    border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                  onChanged: (value) {
                    _concentrationMg = double.tryParse(value);
                    _calculateReconstition();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('in', style: TextStyle(color: AppColors.textMid, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _concentrationMlController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: AppColors.primary),
                  decoration: InputDecoration(
                    labelText: 'Y ml',
                    labelStyle: TextStyle(color: AppColors.textMid, fontSize: 12),
                    hintText: '0.1',
                    border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                  onChanged: (value) {
                    _concentrationMl = double.tryParse(value);
                    _calculateReconstition();
                  },
                ),
              ),
            ],
          ),

          // Reconstitution summary
          if (_bacRequired != null && _concentrationMg != null && _concentrationMl != null) ...[
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
                  Text('RECONSTITUTION INSTRUCTIONS', style: TextStyle(color: AppColors.primary, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Add BAC (sterile water):', style: TextStyle(color: AppColors.textMid, fontSize: 12)),
                      Text('${_bacRequired!.toStringAsFixed(1)}ml', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('PER INJECTION: ', style: TextStyle(color: AppColors.textMid, fontSize: 11)),
                      Text('${_concentrationMg}mg in ${_concentrationMl}ml', style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.6),
                            border: Border.all(color: AppColors.accent, width: 1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Icon(Icons.arrow_forward, color: AppColors.background, size: 12),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.accent, width: 2),
                                  borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                                ),
                              ),
                              Container(
                                width: (_concentrationMl! / 1.0) * (MediaQuery.of(context).size.width - 120),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.5),
                                  borderRadius: const BorderRadius.only(topRight: Radius.circular(6), bottomRight: Radius.circular(6)),
                                ),
                              ),
                              Positioned.fill(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(padding: const EdgeInsets.only(left: 8, top: 4), child: Text('0', style: TextStyle(color: AppColors.textMid, fontSize: 9))),
                                    Padding(padding: const EdgeInsets.only(left: 8, bottom: 4), child: Text('1ml', style: TextStyle(color: AppColors.textMid, fontSize: 9))),
                                  ],
                                ),
                              ),
                              Positioned(
                                left: (_concentrationMl! / 1.0) * (MediaQuery.of(context).size.width - 120) / 2,
                                top: 0,
                                bottom: 0,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('${_concentrationMl}ml', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ===== ROUTE =====
          Text('ROUTE', style: WintermmuteStyles.titleStyle.copyWith(fontSize: 14, letterSpacing: 1)),
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
            onChanged: (value) => setState(() => _selectedRoute = value),
          ),

          const SizedBox(height: 24),

          // ===== CYCLE DURATION =====
          Text('CYCLE DURATION', style: WintermmuteStyles.titleStyle.copyWith(fontSize: 14, letterSpacing: 1)),
          const SizedBox(height: 12),
          
          TextField(
            controller: _cycleDurationController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: AppColors.primary),
            decoration: InputDecoration(
              labelText: 'DURATION (days)',
              labelStyle: TextStyle(color: AppColors.textMid, fontSize: 12),
              hintText: 'e.g., 28',
              border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (value) {
              _cycleDurationDays = int.tryParse(value);
              _updateCycleDuration();
            },
          ),

          if (_cycleDurationDays != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent, width: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('START DATE: ${DateFormat('MMM d, yyyy').format(_startDate!)}', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('END DATE: ${DateFormat('MMM d, yyyy').format(_endDate!)}', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => setState(() => _showDateEditor = !_showDateEditor),
                    child: Text(
                      _showDateEditor ? 'Hide date editor' : 'Edit dates',
                      style: TextStyle(color: AppColors.accent, fontSize: 11, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
            
            if (_showDateEditor) ...[
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('START DATE', style: TextStyle(color: AppColors.textMid, fontSize: 12)),
                trailing: Text(DateFormat('MMM d').format(_startDate!), style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                onTap: () async {
                  final date = await showDatePicker(context: context, initialDate: _startDate!, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (date != null) {
                    setState(() {
                      _startDate = date;
                      _endDate = date.add(Duration(days: _cycleDurationDays! - 1));
                    });
                  }
                },
              ),
            ],
          ],

          const SizedBox(height: 24),

          // ===== FREQUENCY =====
          Text('INJECTION FREQUENCY', style: WintermmuteStyles.titleStyle.copyWith(fontSize: 14, letterSpacing: 1)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _injectionFrequency,
            decoration: InputDecoration(
              labelText: 'FREQUENCY',
              labelStyle: TextStyle(color: AppColors.textMid, fontSize: 12),
              border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            dropdownColor: AppColors.surface,
            style: TextStyle(color: AppColors.primary),
            items: ['Daily', '3x/week', '1x/week'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
            onChanged: (value) {
              setState(() => _injectionFrequency = value);
              _updateCycleDuration();
            },
          ),

          if (_totalInjections != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: AppColors.primary, width: 0.5), borderRadius: BorderRadius.circular(4)),
              child: Text('Total injections: $_totalInjections', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],

          const SizedBox(height: 24),

          // ===== TITRATION BUTTON =====
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _showTitrationModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                side: BorderSide(color: AppColors.accent, width: 2),
              ),
              child: Text(
                'TITRATION',
                style: TextStyle(color: AppColors.background, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 16),
              ),
            ),
          ),

          // Show phase summary
          if (_rampUpDays != null || _rampDownDays != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: AppColors.accent, width: 0.5), borderRadius: BorderRadius.circular(4)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PHASES', style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  if (_rampUpDays != null && _rampUpDays! > 0)
                    Text('Ramp up: ${_rampUpDays} days (${_rampUpStartDose}mg → ${(_rampUpStartDose ?? 0) + ((_rampUpIncrementPerDay ?? 0) * (_rampUpDays ?? 0))}mg)', style: TextStyle(color: AppColors.primary, fontSize: 11)),
                  if (_plateauDays != null && _plateauDays! > 0) ...[
                    const SizedBox(height: 4),
                    Text('Plateau: $_plateauDays days', style: TextStyle(color: AppColors.primary, fontSize: 11)),
                  ],
                  if (_rampDownDays != null && _rampDownDays! > 0) ...[
                    const SizedBox(height: 4),
                    Text('Ramp down: $_rampDownDays days', style: TextStyle(color: AppColors.primary, fontSize: 11)),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ===== INJECTION TIME =====
          Text('INJECTION TIME', style: WintermmuteStyles.titleStyle.copyWith(fontSize: 14, letterSpacing: 1)),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('TIME', style: TextStyle(color: AppColors.textMid, fontSize: 12)),
            trailing: Text(_scheduledTime ?? '08:00', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            onTap: () async {
              final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(DateTime.parse('2000-01-01 ${_scheduledTime ?? "08:00"}')));
              if (time != null) {
                setState(() => _scheduledTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
              }
            },
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text('CREATE CYCLE', style: TextStyle(color: AppColors.background, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _totalPeptideController.dispose();
    _desiredDosageController.dispose();
    _concentrationMgController.dispose();
    _concentrationMlController.dispose();
    _cycleDurationController.dispose();
    super.dispose();
  }
}

// TITRATION MODAL
class TitrationModal extends StatefulWidget {
  final int? cycleDurationDays;
  final ValueChanged<(int?, double?, double?)> onRampUpChanged;
  final ValueChanged<(int?, double?)> onRampDownChanged;
  final int? initialRampUpDays;
  final double? initialRampUpStart;
  final double? initialRampUpIncrement;
  final int? initialRampDownDays;
  final double? initialRampDownDecrement;

  const TitrationModal({
    required this.cycleDurationDays,
    required this.onRampUpChanged,
    required this.onRampDownChanged,
    this.initialRampUpDays,
    this.initialRampUpStart,
    this.initialRampUpIncrement,
    this.initialRampDownDays,
    this.initialRampDownDecrement,
  });

  @override
  State<TitrationModal> createState() => _TitrationModalState();
}

class _TitrationModalState extends State<TitrationModal> {
  late int? _rampUpDays;
  late double? _rampUpStartDose;
  late double? _rampUpIncrementPerDay;
  late int? _rampDownDays;
  late double? _rampDownDecrementPerDay;

  final _rampUpDaysController = TextEditingController();
  final _rampUpStartController = TextEditingController();
  final _rampUpIncrementController = TextEditingController();
  final _rampDownDaysController = TextEditingController();
  final _rampDownDecrementController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rampUpDays = widget.initialRampUpDays;
    _rampUpStartDose = widget.initialRampUpStart;
    _rampUpIncrementPerDay = widget.initialRampUpIncrement;
    _rampDownDays = widget.initialRampDownDays;
    _rampDownDecrementPerDay = widget.initialRampDownDecrement;

    if (_rampUpDays != null) _rampUpDaysController.text = _rampUpDays.toString();
    if (_rampUpStartDose != null) _rampUpStartController.text = _rampUpStartDose.toString();
    if (_rampUpIncrementPerDay != null) _rampUpIncrementController.text = _rampUpIncrementPerDay.toString();
    if (_rampDownDays != null) _rampDownDaysController.text = _rampDownDays.toString();
    if (_rampDownDecrementPerDay != null) _rampDownDecrementController.text = _rampDownDecrementPerDay.toString();
  }

  void _save() {
    widget.onRampUpChanged((_rampUpDays, _rampUpStartDose, _rampUpIncrementPerDay));
    widget.onRampDownChanged((_rampDownDays, _rampDownDecrementPerDay));
    Navigator.pop(context);
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
          Text('TITRATION', style: WintermmuteStyles.headerStyle),
          const SizedBox(height: 24),

          Text('RAMP UP (Optional)', style: TextStyle(color: AppColors.textMid, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _rampUpStartController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: AppColors.primary),
                  decoration: InputDecoration(labelText: 'START (mg)', labelStyle: TextStyle(color: AppColors.textMid, fontSize: 11), border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                  onChanged: (v) => setState(() => _rampUpStartDose = double.tryParse(v)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _rampUpIncrementController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: AppColors.primary),
                  decoration: InputDecoration(labelText: '+/INJ (mg)', labelStyle: TextStyle(color: AppColors.textMid, fontSize: 11), border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                  onChanged: (v) => setState(() => _rampUpIncrementPerDay = double.tryParse(v)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _rampUpDaysController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: AppColors.primary),
                  decoration: InputDecoration(labelText: 'DAYS', labelStyle: TextStyle(color: AppColors.textMid, fontSize: 11), border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                  onChanged: (v) => setState(() => _rampUpDays = int.tryParse(v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text('RAMP DOWN (Optional)', style: TextStyle(color: AppColors.textMid, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _rampDownDecrementController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: AppColors.primary),
                  decoration: InputDecoration(labelText: '-/INJ (mg)', labelStyle: TextStyle(color: AppColors.textMid, fontSize: 11), border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                  onChanged: (v) => setState(() => _rampDownDecrementPerDay = double.tryParse(v)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _rampDownDaysController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: AppColors.primary),
                  decoration: InputDecoration(labelText: 'DAYS', labelStyle: TextStyle(color: AppColors.textMid, fontSize: 11), border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                  onChanged: (v) => setState(() => _rampDownDays = int.tryParse(v)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text('DONE', style: TextStyle(color: AppColors.background, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _rampUpDaysController.dispose();
    _rampUpStartController.dispose();
    _rampUpIncrementController.dispose();
    _rampDownDaysController.dispose();
    _rampDownDecrementController.dispose();
    super.dispose();
  }
}
