import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../data/peptides.dart';
import '../widgets/peptide_selector.dart';

class CycleSetupFormV2 extends StatefulWidget {
  final String? defaultPeptideName;

  const CycleSetupFormV2({
    Key? key,
    this.defaultPeptideName,
  }) : super(key: key);

  @override
  State<CycleSetupFormV2> createState() => _CycleSetupFormV2State();
}

class _CycleSetupFormV2State extends State<CycleSetupFormV2> {
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

  // Dates & Frequency
  DateTime? _startDate;
  DateTime? _endDate;
  int? _totalCycleDays;
  int? _totalCycleWeeks;
  String? _injectionFrequency = 'Daily';
  int? _totalInjections;
  List<int> _daysOfWeek = [];

  // Phases
  int? _rampUpDays;
  double? _rampUpStartDose;
  double? _rampUpIncrementPerDay;
  int? _plateauDays;
  double? _plateauDose;
  int? _rampDownDays;
  double? _rampDownDecrementPerDay;

  // Schedule
  String? _scheduledTime = '08:00';

  // Controllers
  final _totalPeptideController = TextEditingController();
  final _desiredDosageController = TextEditingController();
  final _concentrationMgController = TextEditingController();
  final _concentrationMlController = TextEditingController();
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

  void _calculateCycleDates() {
    if (_startDate == null || _endDate == null) {
      setState(() {
        _totalCycleDays = null;
        _totalCycleWeeks = null;
        _totalInjections = null;
      });
      return;
    }

    final days = _endDate!.difference(_startDate!).inDays + 1;
    final weeks = (days / 7).ceil();
    
    int? injections;
    List<int> daysOfWeek = [];
    
    switch (_injectionFrequency) {
      case 'Daily':
        injections = days;
        daysOfWeek = [0, 1, 2, 3, 4, 5, 6];
        break;
      case '3x/week':
        injections = (days / 7 * 3).ceil();
        daysOfWeek = [1, 3, 5]; // Mon, Wed, Fri
        break;
      case '1x/week':
        injections = weeks;
        daysOfWeek = [1]; // Monday
        break;
    }

    setState(() {
      _totalCycleDays = days;
      _totalCycleWeeks = weeks;
      _totalInjections = injections;
      _daysOfWeek = daysOfWeek;
    });
  }

  void _calculateReconstition() {
    if (_totalPeptideMg == null || _concentrationMg == null || _concentrationMl == null) {
      setState(() {
        _bacRequired = null;
        _totalVolume = null;
      });
      return;
    }

    // Validate positive values
    if (_totalPeptideMg! <= 0 || _concentrationMg! <= 0 || _concentrationMl! <= 0) {
      setState(() {
        _bacRequired = null;
        _totalVolume = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All values must be greater than 0'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Validate reasonable ranges
    if (_totalPeptideMg! > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vial size seems unusually high (>1000mg)'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_concentrationMl! > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draw volume seems unusually high (>10ml)'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
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
        content: Text(
          'Add ${_bacRequired!.toStringAsFixed(1)}ml BAC | ${_concentrationMg}mg in ${_concentrationMl}ml per injection',
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  int? _getTotalPhaseDays() {
    int total = 0;
    if (_rampUpDays != null) total += _rampUpDays!;
    if (_plateauDays != null) total += _plateauDays!;
    if (_rampDownDays != null) total += _rampDownDays!;
    return total > 0 ? total : null;
  }

  String _getPhaseValidationMessage() {
    if (_totalCycleDays == null) return '';
    
    final totalPhase = _getTotalPhaseDays();
    if (totalPhase == null) return '';
    
    if (totalPhase > (_totalCycleDays ?? 0)) {
      return '⚠️ Phases exceed cycle length! ($totalPhase days vs $_totalCycleDays days)';
    } else if (totalPhase < (_totalCycleDays ?? 0)) {
      final remaining = (_totalCycleDays ?? 0) - totalPhase;
      return '✓ Phases use $totalPhase of $_totalCycleDays days ($remaining days remaining)';
    } else {
      return '✓ Phases perfectly fit cycle ($totalPhase days)';
    }
  }

  String _getPhaseTimeline() {
    if (_startDate == null || _totalCycleDays == null) return '';
    
    final buf = <String>[];
    int dayOffset = 0;

    if (_rampUpDays != null && _rampUpDays! > 0) {
      final start = _startDate!.add(Duration(days: dayOffset));
      final end = start.add(Duration(days: _rampUpDays! - 1));
      buf.add('Ramp: ${DateFormat('MMM d').format(start)}–${DateFormat('d').format(end)}');
      dayOffset += _rampUpDays!;
    }

    if (_plateauDays != null && _plateauDays! > 0) {
      final start = _startDate!.add(Duration(days: dayOffset));
      final end = start.add(Duration(days: _plateauDays! - 1));
      buf.add('Plateau: ${DateFormat('MMM d').format(start)}–${DateFormat('d').format(end)}');
      dayOffset += _plateauDays!;
    }

    if (_rampDownDays != null && _rampDownDays! > 0) {
      final start = _startDate!.add(Duration(days: dayOffset));
      final end = start.add(Duration(days: _rampDownDays! - 1));
      buf.add('Ramp down: ${DateFormat('MMM d').format(start)}–${DateFormat('d').format(end)}');
    }

    return buf.join(' | ');
  }

  List<Map<String, dynamic>> _generateDoseSchedule() {
    final doses = <Map<String, dynamic>>[];
    int dayOffset = 0;
    int injectionCount = 0;

    if (_rampUpStartDose != null && _rampUpIncrementPerDay != null && _rampUpDays != null) {
      for (int i = 0; i < _rampUpDays!; i++) {
        if (_daysOfWeek.contains((dayOffset) % 7)) {
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

    if (_plateauDose != null && _plateauDays != null) {
      for (int i = 0; i < _plateauDays!; i++) {
        if (_daysOfWeek.contains((dayOffset) % 7)) {
          doses.add({
            'dayOffset': dayOffset,
            'dose': _plateauDose,
            'phase': 'plateau',
          });
        }
        dayOffset++;
      }
    }

    if (_rampDownDecrementPerDay != null && _rampDownDays != null) {
      double currentDose = doses.isNotEmpty ? (doses.last['dose'] as double) : _plateauDose ?? _rampUpStartDose ?? 0;
      int rampDownCount = 0;
      for (int i = 0; i < _rampDownDays!; i++) {
        if (_daysOfWeek.contains((dayOffset) % 7)) {
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
    final totalPhase = _getTotalPhaseDays() ?? 0;
    final cycleDays = _totalCycleDays ?? 0;

    // Validate required fields
    if (_selectedPeptide == null ||
        _totalPeptideMg == null ||
        _desiredDosageMg == null ||
        _concentrationMg == null ||
        _concentrationMl == null ||
        _startDate == null ||
        _endDate == null ||
        (_rampUpStartDose == null && _plateauDose == null) ||
        totalPhase > cycleDays) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields and fix phase validation'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate all numeric values are positive
    if (_totalPeptideMg! <= 0 || _desiredDosageMg! <= 0 ||
        _concentrationMg! <= 0 || _concentrationMl! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All dose amounts must be greater than 0'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate date range
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date cannot be before start date'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate phase values if provided
    if (_rampUpStartDose != null && _rampUpStartDose! < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ramp up start dose cannot be negative'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_rampUpIncrementPerDay != null && _rampUpIncrementPerDay! < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ramp up increment cannot be negative'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_rampUpDays != null && _rampUpDays! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ramp up duration must be at least 1 day'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_plateauDose != null && _plateauDose! < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plateau dose cannot be negative'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_plateauDays != null && _plateauDays! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plateau duration must be at least 1 day'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_rampDownDecrementPerDay != null && _rampDownDecrementPerDay! < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ramp down decrement cannot be negative'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_rampDownDays != null && _rampDownDays! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ramp down duration must be at least 1 day'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final schedule = _generateDoseSchedule();
    if (schedule.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No doses generated. Check ramp/plateau settings'),
          backgroundColor: AppColors.error,
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
                            color: AppColors.accent.withOpacity(0.15),
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
                                  color: AppColors.accent.withOpacity(0.15),
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

          // ===== DATES & FREQUENCY =====
          Text('CYCLE DATES & FREQUENCY', style: WintermmuteStyles.titleStyle.copyWith(fontSize: 14, letterSpacing: 1)),
          const SizedBox(height: 12),
          
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('START DATE', style: TextStyle(color: AppColors.textMid, fontSize: 12)),
            trailing: Text(_startDate != null ? DateFormat('MMM d, yyyy').format(_startDate!) : 'Select', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            onTap: () async {
              final date = await showDatePicker(context: context, initialDate: _startDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
              if (date != null) {
                setState(() => _startDate = date);
                _calculateCycleDates();
              }
            },
          ),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('END DATE', style: TextStyle(color: AppColors.textMid, fontSize: 12)),
            trailing: Text(_endDate != null ? DateFormat('MMM d, yyyy').format(_endDate!) : 'Select', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            onTap: () async {
              final date = await showDatePicker(context: context, initialDate: _endDate ?? _startDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
              if (date != null) {
                setState(() => _endDate = date);
                _calculateCycleDates();
              }
            },
          ),

          if (_totalCycleDays != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: AppColors.accent, width: 0.5), borderRadius: BorderRadius.circular(4)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CYCLE DURATION', style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Text('${_totalCycleDays} days (${_totalCycleWeeks} weeks)', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          Text('INJECTION FREQUENCY', style: TextStyle(color: AppColors.textMid, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
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
              _calculateCycleDates();
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

          // ===== PHASES =====
          Text('DOSING PHASES', style: WintermmuteStyles.titleStyle.copyWith(fontSize: 14, letterSpacing: 1)),
          const SizedBox(height: 12),

          Text('RAMP UP (Optional)', style: TextStyle(color: AppColors.textMid, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
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
                  decoration: InputDecoration(labelText: '+/DAY (mg)', labelStyle: TextStyle(color: AppColors.textMid, fontSize: 11), border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
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
          const SizedBox(height: 12),

          Text('PLATEAU', style: TextStyle(color: AppColors.textMid, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _plateauDoseController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: AppColors.primary),
                  decoration: InputDecoration(labelText: 'DOSE (mg)', labelStyle: TextStyle(color: AppColors.textMid, fontSize: 11), border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                  onChanged: (v) => setState(() => _plateauDose = double.tryParse(v)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _plateauDaysController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: AppColors.primary),
                  decoration: InputDecoration(labelText: 'DAYS', labelStyle: TextStyle(color: AppColors.textMid, fontSize: 11), border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                  onChanged: (v) => setState(() => _plateauDays = int.tryParse(v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text('RAMP DOWN (Optional)', style: TextStyle(color: AppColors.textMid, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _rampDownDecrementController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: AppColors.primary),
                  decoration: InputDecoration(labelText: '-/DAY (mg)', labelStyle: TextStyle(color: AppColors.textMid, fontSize: 11), border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
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

          // Phase validation & timeline
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final totalPhase = _getTotalPhaseDays() ?? 0;
              final cycleDays = _totalCycleDays ?? 999;
              final isExceeded = totalPhase > cycleDays;
              final borderColor = isExceeded ? AppColors.error : AppColors.accent;
              
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor, width: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_getPhaseValidationMessage(), style: TextStyle(color: borderColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    if (_getPhaseTimeline().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(_getPhaseTimeline(), style: TextStyle(color: AppColors.accent, fontSize: 10)),
                    ],
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // ===== SCHEDULE TIME =====
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
