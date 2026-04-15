import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../data/peptides.dart';
import '../widgets/peptide_selector.dart';
import '../widgets/common/matte_card.dart';
import '../widgets/common/cyber_button.dart';
import '../widgets/common/scanlines_painter.dart' as common;
import 'package:flutter/foundation.dart';

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

  // VALIDATION STATE
  final Map<String, String?> _fieldErrors = {
    'peptide': null,
    'vialSize': null,
    'desiredDose': null,
    'draw': null,
    'cycleDuration': null,
    'startDate': null,
    'phases': null,
  };

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

  // ===== VALIDATION METHODS =====
  
  void _validatePeptide() {
    setState(() {
      _fieldErrors['peptide'] = _selectedPeptide == null ? 'Select a peptide' : null;
    });
  }

  void _validateVialSize() {
    setState(() {
      if (_totalPeptideMg == null) {
        _fieldErrors['vialSize'] = 'Required';
      } else if (_totalPeptideMg! < 5 || _totalPeptideMg! > 500) {
        _fieldErrors['vialSize'] = 'Vial size should be 5-500mg';
      } else {
        _fieldErrors['vialSize'] = null;
      }
    });
    
    // Re-validate dose since it depends on vial size
    _validateDesiredDose();
  }

  void _validateDesiredDose() {
    setState(() {
      if (_desiredDosageMg == null) {
        _fieldErrors['desiredDose'] = 'Required';
      } else if (_desiredDosageMg! < 0.1 || _desiredDosageMg! > 10) {
        _fieldErrors['desiredDose'] = 'Dose should be 0.1-10mg';
      } else if (_totalPeptideMg != null && _desiredDosageMg! > _totalPeptideMg!) {
        _fieldErrors['desiredDose'] = 'Dose can\'t exceed vial size';
      } else {
        _fieldErrors['desiredDose'] = null;
      }
    });
  }

  void _validateDraw() {
    setState(() {
      if (_concentrationMl == null) {
        _fieldErrors['draw'] = 'Required';
      } else if (_concentrationMl! < 0.05 || _concentrationMl! > 1.0) {
        _fieldErrors['draw'] = 'Draw should be 0.05-1.0ml';
      } else {
        _fieldErrors['draw'] = null;
      }
    });
  }

  void _validateCycleDuration() {
    setState(() {
      final rawValue = _cycleDurationController.text.trim();
      
      if (_cycleDurationWeeks == null) {
        if (rawValue.isEmpty) {
          _fieldErrors['cycleDuration'] = 'Required';
        } else {
          // User entered something but int.tryParse failed
          _fieldErrors['cycleDuration'] = 'Must be a whole number (e.g., 4, not 4.5)';
        }
      } else if (_cycleDurationWeeks! < 1 || _cycleDurationWeeks! > 52) {
        _fieldErrors['cycleDuration'] = 'Cycle should be 1-52 weeks';
      } else {
        _fieldErrors['cycleDuration'] = null;
      }
    });
  }

  void _validateStartDate() {
    setState(() {
      if (_startDate == null) {
        _fieldErrors['startDate'] = 'Select start date';
      } else {
        // Compare dates only (ignore time)
        final today = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );
        if (_startDate!.isBefore(today)) {
          _fieldErrors['startDate'] = 'Start date can\'t be in the past';
        } else {
          _fieldErrors['startDate'] = null;
        }
      }
    });
  }

  void _validatePhases() {
    setState(() {
      // Phases are now optional - skip validation if empty
      if (_phases.isEmpty) {
        _fieldErrors['phases'] = null;
      } else if (_cycleDurationWeeks != null) {
        final totalDays = _cycleDurationWeeks! * 7;
        final totalPhaseDays = _phases.fold<int>(
          0,
          (sum, phase) => sum + (phase.endDate != null && phase.startDate != null
              ? phase.endDate!.difference(phase.startDate!).inDays + 1
              : 0),
        );
        if (totalPhaseDays > totalDays) {
          _fieldErrors['phases'] = 'Phases exceed cycle duration';
        } else {
          _fieldErrors['phases'] = null;
        }
      } else {
        _fieldErrors['phases'] = null;
      }
    });
  }

  bool _isFormValid() {
    return _selectedPeptide != null &&
        _totalPeptideMg != null &&
        _desiredDosageMg != null &&
        _concentrationMl != null &&
        _cycleDurationWeeks != null &&
        _startDate != null &&
        _fieldErrors.values.every((error) => error == null);
  }

  void _validateAllFields() {
    _validatePeptide();
    _validateVialSize();
    _validateDesiredDose();
    _validateDraw();
    _validateCycleDuration();
    _validateStartDate();
    _validatePhases();
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
    
    if (kDebugMode) {
      print('[ADD PHASE] Adding phase: type=$phaseType, dosage=$defaultDosage, desired=$desiredDose');
    }
    
    setState(() {
      _phases.add(DosePhase(
        type: phaseType,
        startDate: _startDate,
        endDate: _endDate,
        dosage: defaultDosage,
        frequency: 'Daily',
        notes: '',
      ));
      
      // AUTO-ADD PLATEAU: If both ramp_up and ramp_down exist, auto-add plateau in between
      final hasRampUp = _phases.any((p) => p.type == 'taper_up');
      final hasRampDown = _phases.any((p) => p.type == 'taper_down');
      final hasPlateau = _phases.any((p) => p.type == 'plateau');
      
      if (hasRampUp && hasRampDown && !hasPlateau) {
        if (kDebugMode) {
          print('[AUTO PLATEAU] Both ramp phases detected - auto-adding plateau');
        }
        _phases.add(DosePhase(
          type: 'plateau',
          startDate: _startDate,
          endDate: _endDate,
          dosage: desiredDose, // Plateau always at FULL desired dose
          frequency: 'Daily',
          notes: '',
        ));
      }
    });
    _recalculatePhaseDates();
  }

  void _recalculatePhaseDates() {
    if (_phases.isEmpty) {
      if (kDebugMode) {
        print('[RECALC] Skipping - no phases');
      }
      return;
    }
    
    // If dates aren't set yet, use today as start and add duration
    DateTime cycleStart = _startDate ?? DateTime.now();
    DateTime cycleEnd = _endDate ?? cycleStart.add(Duration(days: (_cycleDurationWeeks ?? 4) * 7 - 1));
    
    if (kDebugMode) {
      print('[RECALC] Working with cycleStart=$cycleStart, cycleEnd=$cycleEnd');
    }
    
    // Update form dates if they were null
    if (_startDate == null) _startDate = cycleStart;
    if (_endDate == null) _endDate = cycleEnd;

    if (kDebugMode) {
      print('[RECALC] Recalculating ${_phases.length} phases');
    }
    final cycleDays = cycleEnd.difference(cycleStart).inDays + 1;
    if (kDebugMode) {
      print('[RECALC] Cycle: $cycleStart to $cycleEnd ($cycleDays days)');
    }

    // Find ramp up and ramp down phases and their actual durations
    final rampUpIndex = _phases.indexWhere((p) => p.type == 'taper_up');
    final rampDownIndex = _phases.indexWhere((p) => p.type == 'taper_down');
    final plateauIndex = _phases.indexWhere((p) => p.type == 'plateau');

    if (kDebugMode) {
      print('[RECALC] Indices - RampUp: $rampUpIndex, RampDown: $rampDownIndex, Plateau: $plateauIndex');
    }

    // Allocate Ramp Up from START
    if (rampUpIndex >= 0) {
      final phase = _phases[rampUpIndex];
      // Use user-defined duration if set, otherwise default to 7
      final rampUpDays = phase.userDefinedDurationDays ?? (phase.durationDays > 0 ? phase.durationDays : 7);
      final rampUpStart = cycleStart;
      final rampUpEnd = cycleStart.add(Duration(days: rampUpDays - 1));
      _phases[rampUpIndex] = phase.copyWith(startDate: rampUpStart, endDate: rampUpEnd);
      if (kDebugMode) {
        print('[RECALC] RampUp: $rampUpStart to $rampUpEnd ($rampUpDays days) [user-defined: ${phase.userDefinedDurationDays}]');
      }
    }

    // Allocate Ramp Down to END
    if (rampDownIndex >= 0) {
      final phase = _phases[rampDownIndex];
      // Use user-defined duration if set, otherwise default to 7
      final rampDownDays = phase.userDefinedDurationDays ?? (phase.durationDays > 0 ? phase.durationDays : 7);
      final rampDownEnd = cycleEnd;
      final rampDownStart = cycleEnd.subtract(Duration(days: rampDownDays - 1));
      _phases[rampDownIndex] = phase.copyWith(startDate: rampDownStart, endDate: rampDownEnd);
      if (kDebugMode) {
        print('[RECALC] RampDown: $rampDownStart to $rampDownEnd ($rampDownDays days) [user-defined: ${phase.userDefinedDurationDays}]');
      }
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
        if (kDebugMode) {
          print('[RECALC] Plateau: $plateauStart to $plateauEnd');
        }
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

  Widget _buildCRTCard({
    required String sectionTitle,
    required List<Widget> children,
    Color borderColor = AppColors.amber,
    IconData icon = Icons.terminal,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Scanlines
          Positioned.fill(
            child: CustomPaint(
              painter: common.ScanlinesPainter(
                opacity: 0.04,
                spacing: 3.0,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header (profile style)
              Row(
                children: [
                  Container(width: 4, height: 14, color: borderColor.withOpacity(0.6)),
                  const SizedBox(width: 8),
                  Icon(icon, color: borderColor, size: 13),
                  const SizedBox(width: 8),
                  Text(
                    '> ${sectionTitle.toUpperCase()}',
                    style: TextStyle(
                      color: borderColor,
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCRTButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: onPressed == null ? color.withOpacity(0.3) : color.withOpacity(0.8),
            width: 2,
          ),
          boxShadow: onPressed != null
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: onPressed == null ? color.withOpacity(0.3) : color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: onPressed == null ? color.withOpacity(0.3) : color,
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _generateDoseSchedule() {
    if (kDebugMode) {
      print('[DOSE GEN] Starting dose generation for ${_phases.length} phases');
    }
    final doses = <Map<String, dynamic>>[];
    
    for (int phaseIdx = 0; phaseIdx < _phases.length; phaseIdx++) {
      final phase = _phases[phaseIdx];
      if (kDebugMode) {
        print('[DOSE GEN] Phase $phaseIdx (${phase.type}): startDate=${phase.startDate}, endDate=${phase.endDate}');
      }
      
      if (phase.startDate == null || phase.endDate == null) {
        if (kDebugMode) {
          print('[DOSE GEN]   Skipping - null dates');
        }
        continue;
      }
      
      final daysDiff = phase.endDate!.difference(phase.startDate!).inDays;
      if (kDebugMode) {
        print('[DOSE GEN]   Duration: $daysDiff days');
      }
      
      // Determine dose for this phase
      double phaseDose = phase.dosage;
      if (kDebugMode) {
        print('[DOSE GEN]   Phase type: ${phase.type}, phase.dosage: ${phase.dosage}, _desiredDosageMg: $_desiredDosageMg');
      }
      
      if (phase.type == 'plateau') {
        // Plateau uses DESIRED DOSE, not phase dosage
        phaseDose = _desiredDosageMg ?? phase.dosage;
        if (kDebugMode) {
          print('[DOSE GEN]   ✓ PLATEAU detected: Using desired dose: $phaseDose mg (phase dosage was ${phase.dosage})');
        }
      } else if (phase.type == 'taper_up') {
        if (kDebugMode) {
          print('[DOSE GEN]   Taper UP: Using phase dosage: $phaseDose mg');
        }
      } else if (phase.type == 'taper_down') {
        if (kDebugMode) {
          print('[DOSE GEN]   Taper DOWN: Using phase dosage: $phaseDose mg');
        }
      } else {
        if (kDebugMode) {
          print('[DOSE GEN]   Unknown phase type: Using phase dosage: $phaseDose mg');
        }
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
      if (kDebugMode) {
        print('[DOSE GEN]   Generated $phaseDoseCount injection days');
      }
    }

    if (kDebugMode) {
      print('[DOSE GEN] Total doses generated: ${doses.length}');
    }
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

    if (errorMsg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Ensure phase dates are calculated BEFORE generating schedule
    _recalculatePhaseDates();
    
    // DEBUG: Check form state before generating schedule
    if (kDebugMode) {
      print('[SUBMIT DEBUG] =======================================================');
    }
    if (kDebugMode) {
      print('[SUBMIT DEBUG] desiredDosageMg: $_desiredDosageMg');
    }
    if (kDebugMode) {
      print('[SUBMIT DEBUG] totalPeptideMg: $_totalPeptideMg');
    }
    if (kDebugMode) {
      print('[SUBMIT DEBUG] concentrationMl: $_concentrationMl');
    }
    if (kDebugMode) {
      print('[SUBMIT DEBUG] Phases count: ${_phases.length}');
    }
    for (int i = 0; i < _phases.length; i++) {
      final p = _phases[i];
      if (kDebugMode) {
        print('[SUBMIT DEBUG] 🔹 Phase $i: type=${p.type}, dosage=${p.dosage}mg, userDefined=${p.userDefinedDurationDays}, dates=${p.startDate?.toString().split(' ')[0]} to ${p.endDate?.toString().split(' ')[0]}, freq=${p.frequency}');
      }
    }
    if (kDebugMode) {
      print('[SUBMIT DEBUG] =======================================================');
    }
    
    final schedule = _generateDoseSchedule();
    if (kDebugMode) {
      print('[SUBMIT DEBUG] Generated schedule with ${schedule.length} doses');
    }
    if (kDebugMode) {
      print('[SUBMIT DEBUG] Doses by phase:');
    }
    
    final rampUpDoses = schedule.where((d) => d['phase'] == 'taper_up').toList();
    final plateauDoses = schedule.where((d) => d['phase'] == 'plateau').toList();
    final rampDownDoses = schedule.where((d) => d['phase'] == 'taper_down').toList();
    
    if (kDebugMode) {
      print('[SUBMIT DEBUG]   Ramp Up: ${rampUpDoses.length} doses at ${rampUpDoses.isNotEmpty ? rampUpDoses.first['dose'] : 'N/A'}mg');
    }
    if (kDebugMode) {
      print('[SUBMIT DEBUG]   Plateau: ${plateauDoses.length} doses at ${plateauDoses.isNotEmpty ? plateauDoses.first['dose'] : 'N/A'}mg');
    }
    if (kDebugMode) {
      print('[SUBMIT DEBUG]   Ramp Down: ${rampDownDoses.length} doses at ${rampDownDoses.isNotEmpty ? rampDownDoses.first['dose'] : 'N/A'}mg');
    }
    if (kDebugMode) {
      print('[SUBMIT DEBUG] Sample doses:');
    }
    for (final dose in schedule.take(10)) {
      if (kDebugMode) {
        print('[SUBMIT DEBUG]   ${dose['dose']}mg (${dose['phase']})');
      }
    }
    if (kDebugMode) {
      print('[SUBMIT DEBUG] =======================================================');
    }
    
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
        left: 0,
        right: 0,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 60,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.black,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.flash_on, color: AppColors.amber.withOpacity(0.7), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'PROTOCOL SETUP',
                          style: TextStyle(
                            color: AppColors.amber.withOpacity(0.7),
                            fontSize: 9,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'NEW ENHANCEMENT CYCLE',
                      style: TextStyle(
                        color: AppColors.amber,
                        fontSize: 18,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.amber.withOpacity(0.8), width: 1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    'ROGUE-2',
                    style: TextStyle(
                      color: AppColors.amber.withOpacity(0.9),
                      fontSize: 8,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ===== PEPTIDE =====
          _buildCRTCard(
            sectionTitle: 'Peptide Selection',
            borderColor: AppColors.primary,
            icon: Icons.biotech,
            children: [
              PeptideSelector(
                initialValue: _selectedPeptide,
                label: 'Select peptide',
                onSelected: (peptide) {
                  setState(() => _selectedPeptide = peptide);
                  _validatePeptide();
                },
              ),
              if (_fieldErrors['peptide'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_fieldErrors['peptide']!, style: TextStyle(color: AppColors.error, fontSize: 10)),
                ),
            ],
          ),

          // ===== DOSING PROTOCOL =====
          _buildCRTCard(
            sectionTitle: 'Dosing Protocol',
            borderColor: AppColors.amber,
            icon: Icons.science,
            children: [
              TextField(
                  controller: _totalPeptideController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    color: AppColors.amber.withOpacity(0.9),
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    labelText: 'VIAL SIZE (mg)',
                    labelStyle: TextStyle(
                      color: AppColors.amber.withOpacity(0.5),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                    hintText: 'e.g., 10',
                    helperText: '5-500mg recommended',
                    helperStyle: TextStyle(color: AppColors.textMid.withOpacity(0.6), fontSize: 10),
                    prefixIcon: Icon(Icons.science, color: AppColors.amber, size: 18),
                    errorText: _fieldErrors['vialSize'],
                    errorStyle: TextStyle(color: AppColors.error, fontSize: 11),
                    filled: true,
                    fillColor: Colors.black,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.amber.withOpacity(0.4),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.amber.withOpacity(0.8),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.error,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (value) {
                    _totalPeptideMg = double.tryParse(value);
                    _validateVialSize();
                    _calculateReconstition();
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _desiredDosageController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    color: AppColors.amber.withOpacity(0.9),
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    labelText: 'DESIRED DOSAGE PER INJECTION (mg)',
                    labelStyle: TextStyle(
                      color: AppColors.amber.withOpacity(0.5),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                    hintText: 'e.g., 1',
                    helperText: '0.1-10mg recommended',
                    helperStyle: TextStyle(color: AppColors.textMid.withOpacity(0.6), fontSize: 10),
                    suffixIcon: Icon(Icons.science, color: AppColors.amber, size: 18),
                    errorText: _fieldErrors['desiredDose'],
                    errorStyle: TextStyle(color: AppColors.error, fontSize: 11),
                    filled: true,
                    fillColor: Colors.black,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.amber.withOpacity(0.4),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.amber.withOpacity(0.8),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.error,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (value) {
                    _desiredDosageMg = double.tryParse(value);
                    _validateDesiredDose();
                    if (_totalPeptideMg != null && _concentrationMl != null && _desiredDosageMg != null) {
                      _calculateReconstition();
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _concentrationMlController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    color: AppColors.amber.withOpacity(0.9),
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    labelText: 'DRAW PER INJECTION (ml)',
                    labelStyle: TextStyle(
                      color: AppColors.amber.withOpacity(0.5),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                    hintText: '0.1',
                    helperText: '0.05-1.0ml recommended',
                    helperStyle: TextStyle(color: AppColors.textMid.withOpacity(0.6), fontSize: 10),
                    suffixIcon: Icon(Icons.water_drop, color: AppColors.amber, size: 18),
                    errorText: _fieldErrors['draw'],
                    errorStyle: TextStyle(color: AppColors.error, fontSize: 11),
                    filled: true,
                    fillColor: Colors.black,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.amber.withOpacity(0.4),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.amber.withOpacity(0.8),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.error,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (value) {
                    _concentrationMl = double.tryParse(value);
                    _validateDraw();
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
                    color: const Color(0xFF050505),
                    border: Border.all(color: AppColors.amber.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RECONSTITUTION INSTRUCTIONS', style: TextStyle(color: AppColors.amber, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Add BAC (sterile water):', style: TextStyle(color: AppColors.textMid, fontSize: 12)),
                          Text('${_bacRequired!.toStringAsFixed(1)}ml', style: TextStyle(color: AppColors.amber, fontSize: 14, fontWeight: FontWeight.bold)),
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
                              border: Border.all(color: AppColors.amber, width: 1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  width: 12,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.amber,
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
                                    border: Border.all(color: AppColors.amber, width: 2),
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
                                    color: AppColors.amber.withOpacity(0.15),
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
                                        Text('${_concentrationMl?.toStringAsFixed(3) ?? '0.0'}ml', style: TextStyle(color: AppColors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
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
                              color: AppColors.amber,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 70,
                            color: AppColors.amber,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          // ===== ROUTE & FREQUENCY =====
          _buildCRTCard(
            sectionTitle: 'Route & Frequency',
            borderColor: AppColors.amber,
            icon: Icons.route,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedRoute,
                decoration: InputDecoration(
                  labelText: 'INJECTION ROUTE',
                  labelStyle: TextStyle(
                    color: AppColors.amber.withOpacity(0.5),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  filled: true,
                  fillColor: Colors.black,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.amber.withOpacity(0.4), width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.amber.withOpacity(0.8), width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                dropdownColor: Colors.black,
                style: TextStyle(color: AppColors.amber.withOpacity(0.9), fontSize: 14, fontFamily: 'monospace'),
                items: _routeMap.keys.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (value) => setState(() => _selectedRoute = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _injectionFrequency,
                decoration: InputDecoration(
                  labelText: 'FREQUENCY',
                  labelStyle: TextStyle(
                    color: AppColors.amber.withOpacity(0.5),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  filled: true,
                  fillColor: Colors.black,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.amber.withOpacity(0.4), width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.amber.withOpacity(0.8), width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                dropdownColor: Colors.black,
                style: TextStyle(color: AppColors.amber.withOpacity(0.9), fontSize: 14, fontFamily: 'monospace'),
                items: ['Daily', '3x/week', '1x/week'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: (value) {
                  setState(() => _injectionFrequency = value);
                  _updateCycleDuration();
                },
              ),
            ],
          ),

          // ===== CYCLE TIMELINE =====
          _buildCRTCard(
            sectionTitle: 'Cycle Timeline',
            borderColor: AppColors.accent,
            icon: Icons.timeline,
            children: [
              TextField(
                controller: _cycleDurationController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: AppColors.amber.withOpacity(0.9),
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  labelText: 'DURATION (weeks)',
                  labelStyle: TextStyle(
                    color: AppColors.amber.withOpacity(0.5),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  hintText: 'e.g., 4',
                  helperText: '1-52 weeks recommended',
                  helperStyle: TextStyle(color: AppColors.textMid.withOpacity(0.6), fontSize: 10),
                  errorText: _fieldErrors['cycleDuration'],
                  errorStyle: TextStyle(color: AppColors.error, fontSize: 11),
                  filled: true,
                  fillColor: Colors.black,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.amber.withOpacity(0.4),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.amber.withOpacity(0.8),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.error,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (value) {
                  _cycleDurationWeeks = int.tryParse(value);
                  _validateCycleDuration();
                  _validatePhases();
                  _updateCycleDuration();
                },
              ),

              if (_cycleDurationWeeks != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF050505),
                    border: Border.all(color: AppColors.accent.withOpacity(0.25), width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total duration: $cycleDays days ($_cycleDurationWeeks weeks)',
                        style: TextStyle(color: AppColors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
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
                          style: TextStyle(color: AppColors.amber.withOpacity(0.7), fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_showDateEditor) ...[
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.calendar_today, color: AppColors.amber, size: 18),
                    title: Text('START DATE', style: TextStyle(color: AppColors.textMid, fontSize: 12)),
                    trailing: Text(DateFormat('MMM d').format(_startDate!), style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold)),
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
            ],
          ),

          // ===== INJECTION TIMING =====
          _buildCRTCard(
            sectionTitle: 'Injection Timing',
            borderColor: AppColors.accent,
            icon: Icons.schedule,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.access_time, color: AppColors.amber, size: 18),
                title: Text('TIME', style: TextStyle(color: AppColors.textMid, fontSize: 12)),
                trailing: Text(_scheduledTime ?? '08:00', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold)),
                onTap: () async {
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(DateTime.parse('2000-01-01 ${_scheduledTime ?? "08:00"}')));
                  if (time != null) {
                    setState(() => _scheduledTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
                  }
                },
              ),
            ],
          ),

          // ===== ADVANCED DOSING =====
          _buildCRTCard(
            sectionTitle: 'Advanced Dosing',
            borderColor: AppColors.secondary,
            icon: Icons.layers,
            children: [
              // Quick add buttons
              Row(
                children: [
                  Expanded(
                    child: _buildCRTButton(
                      label: '↗ TAPER UP',
                      icon: Icons.trending_up,
                      color: AppColors.amber,
                      onPressed: () => _addPhase('taper_up'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCRTButton(
                      label: '↘ TAPER DOWN',
                      icon: Icons.trending_down,
                      color: AppColors.amber,
                      onPressed: () => _addPhase('taper_down'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Phase cards
              if (_phases.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF050505),
                    border: Border.all(color: AppColors.secondary.withOpacity(0.2), width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(child: Text('No phases added. Click above to add one.', style: TextStyle(color: AppColors.textDim, fontSize: 12, fontFamily: 'monospace'))),
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
              const SizedBox(height: 12),
              _buildCRTButton(
                label: '+ ADD PLATEAU PHASE',
                icon: Icons.add,
                color: AppColors.amber,
                onPressed: () => _addPhase('plateau'),
              ),
            ],
          ),

          // Bottom buttons with more padding
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _buildCRTButton(
                    label: 'CANCEL',
                    icon: Icons.close,
                    color: AppColors.textDim,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildCRTButton(
                    label: _isFormValid() ? 'CREATE PROTOCOL' : 'COMPLETE FORM',
                    icon: Icons.rocket_launch,
                    color: AppColors.amber,
                    onPressed: _isFormValid() ? _submit : null,
                  ),
                ),
              ],
            ),
          ),

          // Show validation summary if form invalid
          if (!_isFormValid() && (_selectedPeptide != null || _totalPeptideMg != null || _cycleDurationWeeks != null)) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  border: Border.all(color: AppColors.error.withOpacity(0.5), width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('⚠️ Fix the following to continue:', style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._fieldErrors.entries
                        .where((e) => e.value != null)
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('• ${e.value}', style: TextStyle(color: AppColors.error, fontSize: 10)),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ],
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
        color: const Color(0xFF0A0A0A),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Phase ${widget.phaseNumber} • $phaseLabel', style: TextStyle(color: AppColors.amber, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace', letterSpacing: 1)),
              GestureDetector(
                onTap: widget.onRemove,
                child: Icon(Icons.close, color: AppColors.error, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // DATE RANGE (DISPLAY ONLY)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: AppColors.amber.withOpacity(0.3), width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Dates:', style: TextStyle(color: AppColors.textMid, fontSize: 11)),
                Text(dateRange, style: TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // DURATION (INPUT FOR RAMP UP/DOWN)
          if (widget.phase.type != 'plateau') ...[
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: AppColors.amber.withOpacity(0.9), fontSize: 13, fontFamily: 'monospace'),
              decoration: InputDecoration(
                labelText: 'DURATION (days)',
                labelStyle: TextStyle(color: AppColors.amber.withOpacity(0.5), fontSize: 10, fontFamily: 'monospace'),
                hintText: '7',
                filled: true,
                fillColor: Colors.black,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.amber.withOpacity(0.4), width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.amber.withOpacity(0.8), width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
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
                        border: Border.all(color: AppColors.amber.withOpacity(0.4)),
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.black,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dosage (mg)', style: TextStyle(color: AppColors.textMid, fontSize: 10)),
                          const SizedBox(height: 4),
                          Text('${widget.phase.dosage}mg (Desired)', style: TextStyle(color: AppColors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                    : // Ramp up/down: editable
                    TextField(
                      controller: _dosageController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: AppColors.amber.withOpacity(0.9), fontSize: 13, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        labelText: 'Dosage (mg)',
                        labelStyle: TextStyle(color: AppColors.amber.withOpacity(0.5), fontSize: 10, fontFamily: 'monospace'),
                        hintText: '50',
                        filled: true,
                        fillColor: Colors.black,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.amber.withOpacity(0.4), width: 1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.amber.withOpacity(0.8), width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
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
                    labelStyle: TextStyle(color: AppColors.amber.withOpacity(0.5), fontSize: 10, fontFamily: 'monospace'),
                    filled: true,
                    fillColor: Colors.black,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.amber.withOpacity(0.4), width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.amber.withOpacity(0.8), width: 2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  ),
                  dropdownColor: Colors.black,
                  style: TextStyle(color: AppColors.amber.withOpacity(0.9), fontSize: 12, fontFamily: 'monospace'),
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
            style: TextStyle(color: AppColors.amber.withOpacity(0.9), fontSize: 13, fontFamily: 'monospace'),
            decoration: InputDecoration(
              labelText: 'Notes (optional)',
              labelStyle: TextStyle(color: AppColors.amber.withOpacity(0.5), fontSize: 10, fontFamily: 'monospace'),
              hintText: 'e.g., slowly increase...',
              filled: true,
              fillColor: Colors.black,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.amber.withOpacity(0.4), width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.amber.withOpacity(0.8), width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
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
