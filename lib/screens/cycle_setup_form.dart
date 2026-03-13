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
  double? _totalPeptideMg; // total amount of peptide (e.g., 10mg)
  double? _desiredDosageMg; // desired per-injection dose (e.g., 1mg)
  double? _concentrationMg; // desired mg per ml (e.g., 1mg)
  double? _concentrationMl; // per how many ml (e.g., 0.1ml)
  double? _bacRequired; // calculated BAC in ml
  double? _totalVolume; // calculated total volume needed

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

  void _calculateReconstition() {
    if (_totalPeptideMg == null || _concentrationMg == null || _concentrationMl == null) {
      setState(() {
        _bacRequired = null;
        _totalVolume = null;
      });
      return;
    }

    // Calculate total volume needed
    // Total peptide / desired mg per ml = total volume
    // e.g., 10mg / (1mg per 0.1ml) = 10mg / 10mg per ml = 1ml total
    final mgPerMl = _concentrationMg! / _concentrationMl!;
    final totalVol = _totalPeptideMg! / mgPerMl;
    
    // BAC needed = total volume (peptide volume is negligible)
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
        _totalPeptideMg == null ||
        _desiredDosageMg == null ||
        _concentrationMg == null ||
        _concentrationMl == null ||
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
                // TODO: Get peptide amount from peptides.dart library
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

          // Vial size (total peptide)
          TextField(
            controller: _totalPeptideController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: AppColors.primary),
            decoration: InputDecoration(
              labelText: 'VIAL SIZE (mg)',
              labelStyle: TextStyle(color: AppColors.textMid, fontSize: 12),
              hintText: 'e.g., 10 (for 10mg KVP vial)',
              hintStyle: TextStyle(color: AppColors.textDim, fontSize: 11),
              border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (value) {
              _totalPeptideMg = double.tryParse(value);
              _calculateReconstition();
            },
          ),
          const SizedBox(height: 12),

          // Desired dosage per injection
          TextField(
            controller: _desiredDosageController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: AppColors.primary),
            decoration: InputDecoration(
              labelText: 'DESIRED DOSAGE PER INJECTION (mg)',
              labelStyle: TextStyle(color: AppColors.textMid, fontSize: 12),
              hintText: 'e.g., 1 (for 1mg per day)',
              hintStyle: TextStyle(color: AppColors.textDim, fontSize: 11),
              border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMid)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (value) {
              _desiredDosageMg = double.tryParse(value);
              _calculateReconstition();
            },
          ),
          const SizedBox(height: 12),

          // Desired concentration - mg per ml
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
                    hintStyle: TextStyle(color: AppColors.textDim, fontSize: 11),
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
                child: Text(
                  'in',
                  style: TextStyle(color: AppColors.textMid, fontSize: 12),
                ),
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
                    hintStyle: TextStyle(color: AppColors.textDim, fontSize: 11),
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

          // Reconstitution summary with visual syringe
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
                  Text(
                    'RECONSTITUTION INSTRUCTIONS',
                    style: TextStyle(color: AppColors.primary, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add BAC (sterile water):',
                        style: TextStyle(color: AppColors.textMid, fontSize: 12),
                      ),
                      Text(
                        '${_bacRequired!.toStringAsFixed(1)}ml',
                        style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'PER INJECTION: ',
                        style: TextStyle(color: AppColors.textMid, fontSize: 11),
                      ),
                      Text(
                        '${_concentrationMg}mg in ${_concentrationMl}ml',
                        style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Visual 1ml syringe barrel
                  SizedBox(
                    height: 60,
                    child: Row(
                      children: [
                        // Plunger (left side)
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
                        // Syringe barrel
                        Expanded(
                          child: Stack(
                            children: [
                              // Barrel background
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.accent, width: 2),
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                ),
                              ),
                              // Filled portion (liquid)
                              Container(
                                width: (_concentrationMl! / 1.0) * (MediaQuery.of(context).size.width - 120),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.15),
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(6),
                                    bottomRight: Radius.circular(6),
                                  ),
                                ),
                              ),
                              // Graduation marks and labels
                              Positioned.fill(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8, top: 4),
                                      child: Text(
                                        '0',
                                        style: TextStyle(color: AppColors.textMid, fontSize: 9),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8, bottom: 4),
                                      child: Text(
                                        '1ml',
                                        style: TextStyle(color: AppColors.textMid, fontSize: 9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Draw amount label (centered on fill)
                              Positioned(
                                left: (_concentrationMl! / 1.0) * (MediaQuery.of(context).size.width - 120) / 2,
                                top: 0,
                                bottom: 0,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${_concentrationMl}ml',
                                      style: TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
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
