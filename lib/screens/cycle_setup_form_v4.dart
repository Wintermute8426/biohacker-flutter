import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../data/peptides.dart';
import '../widgets/peptide_selector.dart';

class CycleSetupFormV4 extends StatefulWidget {
  final String? defaultPeptideName;

  const CycleSetupFormV4({
    Key? key,
    this.defaultPeptideName,
  }) : super(key: key);

  @override
  State<CycleSetupFormV4> createState() => _CycleSetupFormV4State();
}

class _CycleSetupFormV4State extends State<CycleSetupFormV4> {
  // Reconstitution
  String? _selectedPeptide;
  double? _totalPeptideMg;
  double? _desiredDosageMg;
  double? _concentrationMl;
  double? _bacRequired;

  // Route
  String? _selectedRoute = 'Subcutaneous (SC)';
  final Map<String, String> _routeMap = {
    'Subcutaneous (SC)': 'SC',
    'Intramuscular (IM)': 'IM',
    'Intravenous (IV)': 'IV',
    'Intranasal': 'Intranasal',
  };

  // Cycle Duration (IN WEEKS)
  int? _cycleDurationWeeks;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showDateEditor = false;

  // Frequency
  String? _injectionFrequency = 'Daily';
  int? _totalInjections;
  List<int> _daysOfWeek = [];

  // Phases (like web app)
  List<DosePhase> _phases = [];

  // Schedule
  String? _scheduledTime = '08:00';

  // Controllers
  final _totalPeptideController = TextEditingController();
  final _desiredDosageController = TextEditingController();
  final _concentrationMlController = TextEditingController();
  final _cycleDurationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _selectedPeptide = widget.defaultPeptideName;
  }

  void _calculateReconstition() {
    if (_totalPeptideMg == null || _concentrationMl == null || _desiredDosageMg == null) {
      setState(() {
        _bacRequired = null;
      });
      return;
    }

    // BAC = (vial_mg × draw_ml) / desired_dose_per_draw
    // Example: 10mg vial, 0.2ml draw, want 1mg per draw = (10 × 0.2) / 1 = 2ml
    final bac = (_totalPeptideMg! * _concentrationMl!) / _desiredDosageMg!;

    setState(() {
      _bacRequired = bac;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Add ${_bacRequired!.toStringAsFixed(2)}ml BAC | ${_desiredDosageMg}mg per ${_concentrationMl}ml draw'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _updateCycleDuration() {
    if (_cycleDurationWeeks == null) return;
    
    final cycleDays = _cycleDurationWeeks! * 7;
    _endDate = _startDate!.add(Duration(days: cycleDays - 1));
    
    int? injections;
    List<int> daysOfWeek = [];
    
    switch (_injectionFrequency) {
      case 'Daily':
        injections = cycleDays;
        daysOfWeek = [0, 1, 2, 3, 4, 5, 6];
        break;
      case '3x/week':
        injections = (_cycleDurationWeeks! * 3);
        daysOfWeek = [1, 3, 5];
        break;
      case '1x/week':
        injections = _cycleDurationWeeks;
        daysOfWeek = [1];
        break;
    }

    setState(() {
      _totalInjections = injections;
      _daysOfWeek = daysOfWeek;
    });
    
    // Recalculate phase dates when cycle duration changes
    _recalculatePhaseDates();
  }

  void _addPhase(String phaseType) {
    // If desired dosage not set, use 1.0 as default
    final desiredDose = _desiredDosageMg ?? 1.0;
    
    // Default dosage depends on phase type
    double defaultDosage;
    if (phaseType == 'plateau') {
      // Plateau ALWAYS uses DESIRED DOSE
      defaultDosage = desiredDose;
    } else {
      // Ramp up/down default to half of desired dose
      defaultDosage = desiredDose / 2;
    }
    
    print('[ADD PHASE] Adding phase: type=$phaseType, dosage=$defaultDosage, desired=$desiredDose');
    
    setState(() {
      _phases.add(DosePhase(
        type: phaseType,
        startDate: _startDate,
        endDate: _endDate,
        dosage: defaultDosage,
        frequency: 'Daily',
        notes: '',
      ));
    });
    _recalculatePhaseDates();
  }

  void _recalculatePhaseDates() {
    if (_phases.isEmpty) {
      print('[RECALC] Skipping - no phases');
      return;
    }
    
    // If dates aren't set yet, use today as start and add duration
    DateTime cycleStart = _startDate ?? DateTime.now();
    DateTime cycleEnd = _endDate ?? cycleStart.add(Duration(days: (_cycleDurationWeeks ?? 4) * 7 - 1));
    
    print('[RECALC] Working with cycleStart=$cycleStart, cycleEnd=$cycleEnd');
    
    // Update form dates if they were null
    if (_startDate == null) _startDate = cycleStart;
    if (_endDate == null) _endDate = cycleEnd;

    print('[RECALC] Recalculating ${_phases.length} phases');
    final cycleDays = cycleEnd.difference(cycleStart).inDays + 1;
    print('[RECALC] Cycle: $cycleStart to $cycleEnd ($cycleDays days)');

    // Find ramp up and ramp down phases and their actual durations
    final rampUpIndex = _phases.indexWhere((p) => p.type == 'taper_up');
    final rampDownIndex = _phases.indexWhere((p) => p.type == 'taper_down');
    final plateauIndex = _phases.indexWhere((p) => p.type == 'plateau');

    print('[RECALC] Indices - RampUp: $rampUpIndex, RampDown: $rampDownIndex, Plateau: $plateauIndex');

    // Allocate Ramp Up from START
    if (rampUpIndex >= 0) {
      final phase = _phases[rampUpIndex];
      // Use user-defined duration if set, otherwise default to 7
      final rampUpDays = phase.userDefinedDurationDays ?? (phase.durationDays > 0 ? phase.durationDays : 7);
      final rampUpStart = cycleStart;
      final rampUpEnd = cycleStart.add(Duration(days: rampUpDays - 1));
      _phases[rampUpIndex] = phase.copyWith(startDate: rampUpStart, endDate: rampUpEnd);
      print('[RECALC] RampUp: $rampUpStart to $rampUpEnd ($rampUpDays days) [user-defined: ${phase.userDefinedDurationDays}]');
    }

    // Allocate Ramp Down to END
    if (rampDownIndex >= 0) {
      final phase = _phases[rampDownIndex];
      // Use user-defined duration if set, otherwise default to 7
      final rampDownDays = phase.userDefinedDurationDays ?? (phase.durationDays > 0 ? phase.durationDays : 7);
      final rampDownEnd = cycleEnd;
      final rampDownStart = cycleEnd.subtract(Duration(days: rampDownDays - 1));
      _phases[rampDownIndex] = phase.copyWith(startDate: rampDownStart, endDate: rampDownEnd);
      print('[RECALC] RampDown: $rampDownStart to $rampDownEnd ($rampDownDays days) [user-defined: ${phase.userDefinedDurationDays}]');
    }

    // Plateau fills middle
    if (plateauIndex >= 0) {
      final phase = _phases[plateauIndex];
      final plateauStart = rampUpIndex >= 0 && _phases[rampUpIndex].endDate != null
          ? _phases[rampUpIndex].endDate!.add(const Duration(days: 1))
          : cycleStart;
      final plateauEnd = rampDownIndex >= 0 && _phases[rampDownIndex].startDate != null
          ? _phases[rampDownIndex].startDate!.subtract(const Duration(days: 1))
          : cycleEnd;

      if (plateauStart.isBefore(plateauEnd) || plateauStart.isAtSameMomentAs(plateauEnd)) {
        _phases[plateauIndex] = phase.copyWith(startDate: plateauStart, endDate: plateauEnd);
        print('[RECALC] Plateau: $plateauStart to $plateauEnd');
      }
    }
  }

  void _removePhase(int index) {
    setState(() {
      _phases.removeAt(index);
    });
  }

  void _updatePhase(int index, DosePhase phase) {
    setState(() {
      _phases[index] = phase;
    });
  }

  List<Map<String, dynamic>> _generateDoseSchedule() {
    print('[DOSE GEN] Starting dose generation for ${_phases.length} phases');
    final doses = <Map<String, dynamic>>[];
    
    for (int phaseIdx = 0; phaseIdx < _phases.length; phaseIdx++) {
      final phase = _phases[phaseIdx];
      print('[DOSE GEN] Phase $phaseIdx (${phase.type}): startDate=${phase.startDate}, endDate=${phase.endDate}');
      
      if (phase.startDate == null || phase.endDate == null) {
        print('[DOSE GEN]   Skipping - null dates');
        continue;
      }
      
      final daysDiff = phase.endDate!.difference(phase.startDate!).inDays;
      print('[DOSE GEN]   Duration: $daysDiff days');
      
      // Determine dose for this phase
      double phaseDose = phase.dosage;
      print('[DOSE GEN]   Phase type: ${phase.type}, phase.dosage: ${phase.dosage}, _desiredDosageMg: $_desiredDosageMg');
      
      if (phase.type == 'plateau') {
        // Plateau uses DESIRED DOSE, not phase dosage
        phaseDose = _desiredDosageMg ?? phase.dosage;
        print('[DOSE GEN]   ✓ PLATEAU detected: Using desired dose: $phaseDose mg (phase dosage was ${phase.dosage})');
      } else if (phase.type == 'taper_up') {
        print('[DOSE GEN]   Taper UP: Using phase dosage: $phaseDose mg');
      } else if (phase.type == 'taper_down') {
        print('[DOSE GEN]   Taper DOWN: Using phase dosage: $phaseDose mg');
      } else {
        print('[DOSE GEN]   Unknown phase type: Using phase dosage: $phaseDose mg');
      }
      
      // Generate doses based on phase configuration
      int phaseDoseCount = 0;
      for (int i = 0; i <= daysDiff; i++) {
        final date = phase.startDate!.add(Duration(days: i));
        
        // Check if this is an injection day based on frequency
        bool isInjectionDay = false;
        switch (phase.frequency) {
          case 'Daily':
            isInjectionDay = true;
            break;
          case '3x/week':
            isInjectionDay = [1, 3, 5].contains(date.weekday % 7);
            break;
          case '1x/week':
            isInjectionDay = date.weekday == 1; // Monday
            break;
        }

        if (isInjectionDay) {
          final dayOffset = _startDate != null ? date.difference(_startDate!).inDays : i;
          doses.add({
            'date': date,
            'dayOffset': dayOffset,
            'dose': phaseDose,
            'phase': phase.type,
            'phaseNumber': phaseIdx + 1,
          });
          phaseDoseCount++;
        }
      }
      print('[DOSE GEN]   Generated $phaseDoseCount injection days');
    }

    print('[DOSE GEN] Total doses generated: ${doses.length}');
    return doses;
  }

  void _submit() {
    String? errorMsg;
    
    if (_selectedPeptide == null) errorMsg = 'Select a peptide';
    else if (_totalPeptideMg == null) errorMsg = 'Enter vial size (mg)';
    else if (_desiredDosageMg == null) errorMsg = 'Enter desired dosage (mg)';
    else if (_concentrationMl == null) errorMsg = 'Enter draw per injection (ml)';
    else if (_cycleDurationWeeks == null) errorMsg = 'Enter cycle duration (weeks)';
    else if (_startDate == null || _endDate == null) errorMsg = 'Cycle dates not set';
    else if (_phases.isEmpty) {
      errorMsg = 'Add at least one phase (Taper Up, Plateau, or Taper Down)';
      // Auto-add a plateau if user tries to submit without phases
      _addPhase('plateau');
      return;
    }

    if (errorMsg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Color(0xFFFF0040),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Ensure phase dates are calculated BEFORE generating schedule
    _recalculatePhaseDates();
    
    // DEBUG: Check form state before generating schedule
    print('[SUBMIT DEBUG] =======================================================');
    print('[SUBMIT DEBUG] desiredDosageMg: $_desiredDosageMg');
    print('[SUBMIT DEBUG] Phases count: ${_phases.length}');
    for (int i = 0; i < _phases.length; i++) {
      final p = _phases[i];
      print('[SUBMIT DEBUG] Phase $i: type=${p.type}, dosage=${p.dosage}, dates=${p.startDate} to ${p.endDate}, frequency=${p.frequency}');
    }
    print('[SUBMIT DEBUG] =======================================================');
    
    final schedule = _generateDoseSchedule();
    print('[SUBMIT DEBUG] Generated schedule with ${schedule.length} doses');
    for (final dose in schedule.take(10)) {
      print('[SUBMIT DEBUG]   Day ${dose['dayOffset']}: ${dose['dose']}mg (phase: ${dose['phase']}, date: ${dose['date']})');
    }
    print('[SUBMIT DEBUG] =======================================================');
    
    final routeShort = _routeMap[_selectedRoute] ?? 'SC';
    final cycleDays = (_cycleDurationWeeks ?? 0) * 7;
    final injections = _totalInjections ?? 0;

    Navigator.pop(context, {
      'peptideName': _selectedPeptide,
      'route': routeShort,
      'totalPeptideMg': _totalPeptideMg ?? 0,
      'desiredDosageMg': _desiredDosageMg ?? 0,
      'concentrationMl': _concentrationMl ?? 0,
      'bacRequired': _bacRequired ?? 0,
      'schedule': schedule,
      'scheduledTime': _scheduledTime ?? '08:00',
      'daysOfWeek': _daysOfWeek,
      'startDate': _startDate,
      'endDate': _endDate,
      'cycleDurationDays': cycleDays,
      'injectionFrequency': _injectionFrequency ?? 'Daily',
      'totalInjections': injections,
      'phases': _phases,
    });
  }

  @override
  Widget build(BuildContext context) {
    final cycleDays = _cycleDurationWeeks != null ? _cycleDurationWeeks! * 7 : 0;
    
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
              if (_totalPeptideMg != null && _concentrationMl != null && _desiredDosageMg != null) {
                _calculateReconstition();
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _concentrationMlController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: AppColors.primary),
            decoration: InputDecoration(
              labelText: 'DRAW PER INJECTION (ml)',
              labelStyle: TextStyle(color: AppColors.textMid, fontSize: 12),
              hintText: '0.1',
              border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (value) {
              _concentrationMl = double.tryParse(value);
              // Recalculate BAC with proper formula
              if (_concentrationMl != null && _totalPeptideMg != null && _desiredDosageMg != null) {
                _calculateReconstition();
              }
            },
          ),

          // Reconstitution summary with syringe visual
          if (_bacRequired != null && _concentrationMl != null) ...[
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
                  Text('DRAW PER INJECTION', style: TextStyle(color: AppColors.textMid, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  // REALISTIC SYRINGE VISUAL
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Plunger (darker, with grip)
                      Container(
                        width: 14,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.textMid,
                          border: Border.all(color: AppColors.primary, width: 1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 12,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(1), topRight: Radius.circular(1)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 1),
                      
                      // Barrel
                      Expanded(
                        child: Stack(
                          children: [
                            // Outer barrel border
                            Container(
                              height: 70,
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.accent, width: 2),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(6),
                                  bottomRight: Radius.circular(6),
                                ),
                              ),
                            ),
                            // Fill (liquid in barrel)
                            Container(
                              height: 70,
                              width: ((_concentrationMl ?? 0) / 1.0) * (MediaQuery.of(context).size.width - 100),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.4),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(4),
                                  bottomRight: Radius.circular(4),
                                ),
                              ),
                            ),
                            // Graduation marks
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('0', style: TextStyle(color: AppColors.textMid, fontSize: 8, fontWeight: FontWeight.bold)),
                                    Text('${_concentrationMl?.toStringAsFixed(3) ?? '0.0'}ml', style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold)),
                                    Text('1.0', style: TextStyle(color: AppColors.textMid, fontSize: 8, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Needle (thin tip)
                      Container(
                        width: 3,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 70,
                        color: AppColors.primary,
                      ),
                    ],
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

          const SizedBox(height: 24),

          // ===== CYCLE DURATION (IN WEEKS) =====
          Text('CYCLE DURATION', style: WintermmuteStyles.titleStyle.copyWith(fontSize: 14, letterSpacing: 1)),
          const SizedBox(height: 12),
          
          TextField(
            controller: _cycleDurationController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: AppColors.primary),
            decoration: InputDecoration(
              labelText: 'DURATION (weeks)',
              labelStyle: TextStyle(color: AppColors.textMid, fontSize: 12),
              hintText: 'e.g., 4',
              border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (value) {
              _cycleDurationWeeks = int.tryParse(value);
              _updateCycleDuration();
            },
          ),

          if (_cycleDurationWeeks != null) ...[
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
                  Text('Total duration: $cycleDays days ($_cycleDurationWeeks weeks)', 
                    style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('START: ${DateFormat('MMM d, yyyy').format(_startDate!)}', 
                    style: TextStyle(color: AppColors.textMid, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('END: ${DateFormat('MMM d, yyyy').format(_endDate!)}', 
                    style: TextStyle(color: AppColors.textMid, fontSize: 11)),
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
                      _endDate = date.add(Duration(days: cycleDays - 1));
                    });
                  }
                },
              ),
            ],
          ],

          const SizedBox(height: 24),

          // ===== INJECTION TIME (MOVED HERE) =====
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

          // ===== DOSING PHASES (LIKE WEB APP) =====
          Text('CREATE MULTI-PHASE DOSING', style: WintermmuteStyles.titleStyle.copyWith(fontSize: 14, letterSpacing: 1)),
          const SizedBox(height: 12),

          // Quick add buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _addPhase('taper_up'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    side: BorderSide(color: AppColors.primary, width: 1),
                  ),
                  child: Text('↗ Taper Up', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _addPhase('taper_down'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    side: BorderSide(color: AppColors.primary, width: 1),
                  ),
                  child: Text('↘ Taper Down', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Phase cards
          if (_phases.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(border: Border.all(color: AppColors.textMid, width: 1), borderRadius: BorderRadius.circular(4)),
              child: Center(child: Text('No phases added. Click above to add one.', style: TextStyle(color: AppColors.textMid, fontSize: 12))),
            )
          else
            Column(
              children: [
                for (int i = 0; i < _phases.length; i++) ...[
                  PhaseCard(
                    phaseNumber: i + 1,
                    phase: _phases[i],
                    cycleStart: _startDate,
                    cycleEnd: _endDate,
                    onUpdate: (phase) => _updatePhase(i, phase),
                    onDurationChange: _recalculatePhaseDates,
                    onRemove: () => _removePhase(i),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),

          // Add phase button
          GestureDetector(
            onTap: () => _addPhase('plateau'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 1, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text('+ Add Phase', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
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
    _concentrationMlController.dispose();
    _cycleDurationController.dispose();
    super.dispose();
  }
}

// ===== PHASE DATA MODEL =====
class DosePhase {
  final String type; // 'taper_up', 'taper_down', 'plateau'
  final DateTime? startDate;
  final DateTime? endDate;
  final double dosage;
  final String frequency; // 'Daily', '3x/week', '1x/week'
  final String notes;
  final int? userDefinedDurationDays; // User-entered duration (for ramp up/down)

  DosePhase({
    required this.type,
    this.startDate,
    this.endDate,
    required this.dosage,
    required this.frequency,
    required this.notes,
    this.userDefinedDurationDays,
  });

  DosePhase copyWith({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    double? dosage,
    String? frequency,
    String? notes,
    int? userDefinedDurationDays,
  }) {
    return DosePhase(
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      notes: notes ?? this.notes,
      userDefinedDurationDays: userDefinedDurationDays ?? this.userDefinedDurationDays,
    );
  }

  int get durationDays {
    if (startDate == null || endDate == null) return 0;
    return endDate!.difference(startDate!).inDays + 1;
  }
}

// ===== PHASE CARD WIDGET =====
class PhaseCard extends StatefulWidget {
  final int phaseNumber;
  final DosePhase phase;
  final DateTime? cycleStart;
  final DateTime? cycleEnd;
  final ValueChanged<DosePhase> onUpdate;
  final Function? onDurationChange; // Callback to recalculate all phases
  final VoidCallback onRemove;

  const PhaseCard({
    required this.phaseNumber,
    required this.phase,
    required this.onUpdate,
    required this.onRemove,
    this.cycleStart,
    this.cycleEnd,
    this.onDurationChange,
  });

  @override
  State<PhaseCard> createState() => _PhaseCardState();
}

class _PhaseCardState extends State<PhaseCard> {
  late TextEditingController _durationController;
  late TextEditingController _dosageController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    // Show user-defined duration if set, otherwise show calculated duration
    final displayDuration = widget.phase.userDefinedDurationDays ?? widget.phase.durationDays;
    _durationController = TextEditingController(text: displayDuration.toString());
    _dosageController = TextEditingController(text: widget.phase.dosage.toString());
    _notesController = TextEditingController(text: widget.phase.notes);
  }

  @override
  Widget build(BuildContext context) {
    final phaseLabel = widget.phase.type == 'taper_up' ? '↗ Taper Up' :
                       widget.phase.type == 'taper_down' ? '↘ Taper Down' : '═ Plateau';
    
    final dateRange = widget.phase.startDate != null && widget.phase.endDate != null
        ? '${DateFormat('MMM d').format(widget.phase.startDate!)} → ${DateFormat('MMM d').format(widget.phase.endDate!)}'
        : 'Auto-calculated';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Phase ${widget.phaseNumber} • $phaseLabel', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: widget.onRemove,
                child: Icon(Icons.close, color: Color(0xFFFF0040), size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // DATE RANGE (DISPLAY ONLY)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.textMid, width: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Dates:', style: TextStyle(color: AppColors.textMid, fontSize: 11)),
                Text(dateRange, style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // DURATION (INPUT FOR RAMP UP/DOWN)
          if (widget.phase.type != 'plateau') ...[
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: AppColors.primary),
              decoration: InputDecoration(
                labelText: 'DURATION (days)',
                labelStyle: TextStyle(color: AppColors.textMid, fontSize: 10),
                hintText: '7',
                border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (v) {
                final newDays = int.tryParse(v);
                if (newDays != null && newDays > 0) {
                  // Store the user-defined duration and update callback
                  widget.onUpdate(widget.phase.copyWith(userDefinedDurationDays: newDays));
                  Future.delayed(const Duration(milliseconds: 100), () {
                    widget.onDurationChange?.call();
                  });
                }
              },
            ),
            const SizedBox(height: 12),
          ],

          // DOSAGE | FREQUENCY
          Row(
            children: [
              Expanded(
                child: widget.phase.type == 'plateau'
                    ? // Plateau: show desired dose as read-only
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.textMid),
                        borderRadius: BorderRadius.circular(4),
                        color: AppColors.surface,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dosage (mg)', style: TextStyle(color: AppColors.textMid, fontSize: 10)),
                          const SizedBox(height: 4),
                          Text('${widget.phase.dosage}mg (Desired)', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                    : // Ramp up/down: editable
                    TextField(
                      controller: _dosageController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: AppColors.primary),
                      decoration: InputDecoration(
                        labelText: 'Dosage (mg)',
                        labelStyle: TextStyle(color: AppColors.textMid, fontSize: 10),
                        hintText: '50',
                        border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      onChanged: (v) {
                        widget.onUpdate(widget.phase.copyWith(dosage: double.tryParse(v) ?? widget.phase.dosage));
                      },
                    ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: widget.phase.frequency,
                  decoration: InputDecoration(
                    labelText: 'Frequency',
                    labelStyle: TextStyle(color: AppColors.textMid, fontSize: 10),
                    border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  ),
                  dropdownColor: AppColors.surface,
                  style: TextStyle(color: AppColors.primary, fontSize: 12),
                  items: ['Daily', '3x/week', '1x/week'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (value) {
                    widget.onUpdate(widget.phase.copyWith(frequency: value));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // NOTES
          TextField(
            controller: _notesController,
            style: TextStyle(color: AppColors.primary),
            decoration: InputDecoration(
              labelText: 'Notes (optional)',
              labelStyle: TextStyle(color: AppColors.textMid, fontSize: 10),
              hintText: 'e.g., slowly increase...',
              border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            maxLines: 1,
            onChanged: (v) {
              widget.onUpdate(widget.phase.copyWith(notes: v));
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _durationController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
