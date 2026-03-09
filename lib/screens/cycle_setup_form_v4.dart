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
    if (_totalPeptideMg == null || _concentrationMl == null) {
      setState(() {
        _bacRequired = null;
      });
      return;
    }

    setState(() {
      _bacRequired = _totalPeptideMg;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Add ${_bacRequired!.toStringAsFixed(1)}ml BAC | Draw ${_concentrationMl}ml per injection'),
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
  }

  void _addPhase(String phaseType) {
    final defaultStart = _startDate ?? DateTime.now();
    final defaultEnd = _endDate ?? DateTime.now().add(const Duration(days: 6));
    
    setState(() {
      _phases.add(DosePhase(
        type: phaseType, // 'taper_up', 'taper_down', 'plateau'
        startDate: defaultStart,
        endDate: defaultEnd,
        dosage: 50,
        frequency: 'Daily',
        notes: '',
      ));
    });
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
    final doses = <Map<String, dynamic>>[];
    
    for (final phase in _phases) {
      if (phase.startDate == null || phase.endDate == null) continue;
      
      final daysDiff = phase.endDate!.difference(phase.startDate!).inDays;
      
      // Generate doses based on phase configuration
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
            'dose': phase.dosage,
            'phase': phase.type,
            'phaseNumber': _phases.indexOf(phase) + 1,
          });
        }
      }
    }

    return doses;
  }

  void _submit() {
    if (_selectedPeptide == null ||
        _totalPeptideMg == null ||
        _desiredDosageMg == null ||
        _concentrationMl == null ||
        _cycleDurationWeeks == null ||
        _startDate == null ||
        _phases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields and add at least one phase'),
          backgroundColor: Color(0xFFFF0040),
        ),
      );
      return;
    }

    final schedule = _generateDoseSchedule();
    final routeShort = _routeMap[_selectedRoute] ?? 'SC';

    Navigator.pop(context, {
      'peptideName': _selectedPeptide,
      'route': routeShort,
      'totalPeptideMg': _totalPeptideMg,
      'desiredDosageMg': _desiredDosageMg,
      'concentrationMl': _concentrationMl,
      'bacRequired': _bacRequired,
      'schedule': schedule,
      'scheduledTime': _scheduledTime,
      'daysOfWeek': _daysOfWeek,
      'startDate': _startDate,
      'endDate': _endDate,
      'cycleDurationDays': _cycleDurationWeeks! * 7,
      'injectionFrequency': _injectionFrequency,
      'totalInjections': _totalInjections,
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
              _calculateReconstition();
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
              if (_concentrationMl != null && _totalPeptideMg != null) {
                setState(() {
                  _bacRequired = _totalPeptideMg;
                });
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
                  Row(
                    children: [
                      // Syringe plunger
                      Container(
                        width: 20,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.6),
                          border: Border.all(color: AppColors.accent, width: 1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Icon(Icons.arrow_forward, color: AppColors.background, size: 12),
                      ),
                      const SizedBox(width: 2),
                      // Syringe barrel (1ml)
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.accent, width: 2),
                                borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                              ),
                            ),
                            // Fill amount
                            Container(
                              width: ((_concentrationMl ?? 0) / 1.0) * (MediaQuery.of(context).size.width - 120),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.5),
                                borderRadius: const BorderRadius.only(topRight: Radius.circular(6), bottomRight: Radius.circular(6)),
                              ),
                            ),
                            // Graduation marks and labels
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text('0', style: TextStyle(color: AppColors.textMid, fontSize: 9)),
                                    Text('${_concentrationMl?.toStringAsFixed(2)}ml', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                                    Text('1ml', style: TextStyle(color: AppColors.textMid, fontSize: 9)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
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

  DosePhase({
    required this.type,
    this.startDate,
    this.endDate,
    required this.dosage,
    required this.frequency,
    required this.notes,
  });

  DosePhase copyWith({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    double? dosage,
    String? frequency,
    String? notes,
  }) {
    return DosePhase(
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      notes: notes ?? this.notes,
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
  final VoidCallback onRemove;

  const PhaseCard({
    required this.phaseNumber,
    required this.phase,
    required this.onUpdate,
    required this.onRemove,
    this.cycleStart,
    this.cycleEnd,
  });

  @override
  State<PhaseCard> createState() => _PhaseCardState();
}

class _PhaseCardState extends State<PhaseCard> {
  late TextEditingController _dosageController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _dosageController = TextEditingController(text: widget.phase.dosage.toString());
    _notesController = TextEditingController(text: widget.phase.notes);
  }

  @override
  Widget build(BuildContext context) {
    final phaseLabel = widget.phase.type == 'taper_up' ? '↗ Taper Up' :
                       widget.phase.type == 'taper_down' ? '↘ Taper Down' : '═ Plateau';

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
          
          // DATE RANGE
          Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('START', style: TextStyle(color: AppColors.textMid, fontSize: 10)),
                  trailing: Text(
                    widget.phase.startDate != null ? DateFormat('MMM d').format(widget.phase.startDate!) : 'Select',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  onTap: () async {
                    final start = await showDatePicker(
                      context: context,
                      initialDate: widget.phase.startDate ?? widget.cycleStart ?? DateTime.now(),
                      firstDate: widget.cycleStart ?? DateTime.now(),
                      lastDate: widget.cycleEnd ?? DateTime.now().add(const Duration(days: 365)),
                    );
                    if (start != null) {
                      widget.onUpdate(widget.phase.copyWith(startDate: start));
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('END', style: TextStyle(color: AppColors.textMid, fontSize: 10)),
                  trailing: Text(
                    widget.phase.endDate != null ? DateFormat('MMM d').format(widget.phase.endDate!) : 'Select',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  onTap: () async {
                    final end = await showDatePicker(
                      context: context,
                      initialDate: widget.phase.endDate ?? widget.cycleEnd ?? DateTime.now(),
                      firstDate: widget.cycleStart ?? DateTime.now(),
                      lastDate: widget.cycleEnd ?? DateTime.now().add(const Duration(days: 365)),
                    );
                    if (end != null) {
                      widget.onUpdate(widget.phase.copyWith(endDate: end));
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // DOSAGE | FREQUENCY
          Row(
            children: [
              Expanded(
                child: TextField(
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

          // Duration summary
          if (widget.phase.startDate != null && widget.phase.endDate != null) ...[
            const SizedBox(height: 8),
            Text('Duration: ${widget.phase.durationDays} days', style: TextStyle(color: AppColors.accent, fontSize: 10, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
