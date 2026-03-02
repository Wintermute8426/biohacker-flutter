import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../data/peptides.dart';
import '../data/dosing_calculator.dart';
import '../services/cycles_database.dart';
import '../services/dose_logs_database.dart';
import '../services/side_effects_database.dart';
import '../widgets/advanced_dosing_widget.dart';

class CyclesScreen extends StatefulWidget {
  const CyclesScreen({Key? key}) : super(key: key);

  @override
  State<CyclesScreen> createState() => _CyclesScreenState();
}

class _CyclesScreenState extends State<CyclesScreen> {
  final _peptideController = TextEditingController();
  final _doseController = TextEditingController();
  final _weeksController = TextEditingController(text: '8');
  final _bacWaterMlController = TextEditingController();
  final _notesController = TextEditingController();
  final _doseAmountController = TextEditingController();
  final _sideEffectNotesController = TextEditingController();
  final _advancedStartDoseController = TextEditingController();
  final _advancedEndDoseController = TextEditingController();
  final db = CyclesDatabase();
  final doseDb = DoseLogsDatabase();
  final sideEffectDb = SideEffectsDatabase();
  
  List<Cycle> savedCycles = [];
  List<String> filteredPeptides = PEPTIDE_LIST;
  DosingSchedule? _selectedDosingSchedule;
  
  String _selectedFrequency = '1x weekly';
  String _selectedRoute = 'SC (subcutaneous)';
  bool _showAdvanced = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCycles();
  }

  void _loadCycles() async {
    setState(() => _isLoading = true);
    final cycles = await db.getUserCycles();
    setState(() {
      savedCycles = cycles;
      _isLoading = false;
    });
  }

  void _filterPeptides(String query) {
    setState(() {
      filteredPeptides = searchPeptides(query);
    });
  }

  void _selectPeptide(String peptide) {
    setState(() {
      _peptideController.text = peptide;
      filteredPeptides = [];
    });
  }

  void _showDeleteConfirmation(Cycle cycle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'DELETE CYCLE?',
          style: TextStyle(color: AppColors.error, letterSpacing: 1),
        ),
        content: Text(
          'Remove ${cycle.peptideName} cycle? This cannot be undone.',
          style: TextStyle(color: AppColors.textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: TextStyle(color: AppColors.textDim)),
          ),
          TextButton(
            onPressed: () async {
              final success = await db.deleteCycle(cycle.id);
              if (success) {
                _loadCycles();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ Cycle deleted'),
                    backgroundColor: AppColors.accent,
                  ),
                );
              }
              Navigator.pop(context);
            },
            child: Text('DELETE', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showEditCycle(Cycle cycle) {
    _peptideController.text = cycle.peptideName;
    _doseController.text = cycle.dose.toString();
    _weeksController.text = cycle.durationWeeks.toString();
    _selectedRoute = cycle.route;
    _selectedFrequency = cycle.frequency;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'EDIT CYCLE',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: AppColors.textMid,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // DOSE
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dose (mg)',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _doseController,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Route',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: DropdownButton<String>(
                                value: _selectedRoute,
                                isExpanded: true,
                                underline: const SizedBox(),
                                dropdownColor: AppColors.surface,
                                items: [
                                  'SC (subcutaneous)',
                                  'IM (intramuscular)',
                                  'IV (intravenous)',
                                  'Intranasal',
                                  'Oral',
                                ].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? value) {
                                  if (value != null) {
                                    setModalState(() => _selectedRoute = value);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // FREQUENCY
                  Text(
                    'Frequency',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      '1x weekly',
                      '2x weekly',
                      '3x weekly',
                      'Daily',
                      '2x daily',
                    ].map((String freq) {
                      final isSelected = _selectedFrequency == freq;
                      return GestureDetector(
                        onTap: () => setModalState(() => _selectedFrequency = freq),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            freq,
                            style: TextStyle(
                              color: isSelected ? AppColors.primary : AppColors.textMid,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () async {
                        final dose = double.tryParse(_doseController.text) ?? cycle.dose;
                        await db.updateCycle(
                          cycleId: cycle.id,
                        );
                        _loadCycles();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('✓ Cycle updated'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        'SAVE CHANGES',
                        style: TextStyle(
                          color: AppColors.background,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCompleteCycle(Cycle cycle) {
    _notesController.clear();
    double effectiveness = 5;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'COMPLETE CYCLE',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: AppColors.textMid,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'End of Cycle Log',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Effectiveness
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Effectiveness',
                        style: TextStyle(
                          color: AppColors.textMid,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${effectiveness.toStringAsFixed(1)}/10',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: effectiveness,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: effectiveness.toStringAsFixed(1),
                    activeColor: AppColors.primary,
                    onChanged: (value) {
                      setModalState(() => effectiveness = value);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Notes
                  Text(
                    'Notes & Observations',
                    style: TextStyle(
                      color: AppColors.textMid,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'How did you feel? Any side effects? Results?',
                      hintStyle: TextStyle(color: AppColors.textDim, fontSize: 12),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () async {
                        await db.updateCycle(
                          cycleId: cycle.id,
                          isActive: false,
                        );
                        _loadCycles();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✓ ${cycle.peptideName} cycle completed (${effectiveness.toStringAsFixed(1)}/10)'),
                            backgroundColor: AppColors.accent,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        'MARK COMPLETE',
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
          },
        );
      },
    );
  }

  void _showAdvancedDosingModal(StateSetter setModalState) {
    final weeks = int.tryParse(_weeksController.text) ?? 8;
    final dose = double.tryParse(_doseController.text) ?? 250;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (context) => AdvancedDosingWidget(
        totalWeeks: weeks,
        frequency: _selectedFrequency,
        defaultDose: dose,
        onScheduleSet: (schedule) {
          setModalState(() {
            _selectedDosingSchedule = schedule;
          });
        },
      ),
    );
  }

  void _showLogDoseDialog(Cycle cycle) {
    _doseAmountController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('LOG DOSE', style: TextStyle(color: AppColors.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _doseAmountController,
              style: const TextStyle(color: Colors.white),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Dose amount (mg)',
                hintStyle: TextStyle(color: AppColors.textDim),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: TextStyle(color: AppColors.textDim)),
          ),
          TextButton(
            onPressed: () async {
              final dose = double.tryParse(_doseAmountController.text);
              if (dose != null) {
                await doseDb.logDose(
                  cycleId: cycle.id,
                  doseAmount: dose,
                  loggedAt: DateTime.now(),
                  route: cycle.route,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ Dose logged: ${dose}mg'),
                    backgroundColor: AppColors.primary,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: Text('LOG', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showLogSideEffectDialog(Cycle cycle) {
    _sideEffectNotesController.clear();
    String selectedSymptom = SideEffectsDatabase.SYMPTOM_OPTIONS.first;
    int severity = 5;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('LOG SYMPTOM', style: TextStyle(color: AppColors.primary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: selectedSymptom,
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  items: SideEffectsDatabase.SYMPTOM_OPTIONS.map((s) {
                    return DropdownMenuItem<String>(
                      value: s,
                      child: Text(s, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedSymptom = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Severity', style: TextStyle(color: AppColors.textMid)),
                    Text('$severity/10', style: TextStyle(color: AppColors.primary)),
                  ],
                ),
                Slider(
                  value: severity.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (value) {
                    setDialogState(() => severity = value.toInt());
                  },
                  activeColor: AppColors.primary,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _sideEffectNotesController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Notes (optional)',
                    hintStyle: TextStyle(color: AppColors.textDim),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL', style: TextStyle(color: AppColors.textDim)),
            ),
            TextButton(
              onPressed: () async {
                await sideEffectDb.logSideEffect(
                  cycleId: cycle.id,
                  symptom: selectedSymptom,
                  severity: severity,
                  loggedAt: DateTime.now(),
                  notes: _sideEffectNotesController.text.isEmpty
                      ? null
                      : _sideEffectNotesController.text,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ Symptom logged: $selectedSymptom'),
                    backgroundColor: AppColors.primary,
                  ),
                );
                Navigator.pop(context);
              },
              child: Text('LOG', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewCycleDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CREATE CYCLE',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: AppColors.textMid,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Peptide',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _peptideController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onChanged: _filterPeptides,
                    decoration: InputDecoration(
                      hintText: 'Search peptides...',
                      hintStyle: TextStyle(color: AppColors.textDim, fontSize: 12),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  if (filteredPeptides.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: filteredPeptides.map((p) {
                          return GestureDetector(
                            onTap: () => _selectPeptide(p),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppColors.border,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Text(
                                p,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dose (mg)',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _doseController,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: '250',
                                hintStyle: TextStyle(color: AppColors.textDim),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Route',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: DropdownButton<String>(
                                value: _selectedRoute,
                                isExpanded: true,
                                underline: const SizedBox(),
                                dropdownColor: AppColors.surface,
                                items: [
                                  'SC (subcutaneous)',
                                  'IM (intramuscular)',
                                  'IV (intravenous)',
                                  'Intranasal',
                                  'Oral',
                                ].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? value) {
                                  if (value != null) {
                                    setModalState(() => _selectedRoute = value);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Frequency',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      '1x weekly',
                      '2x weekly',
                      '3x weekly',
                      'Daily',
                      '2x daily',
                    ].map((String freq) {
                      final isSelected = _selectedFrequency == freq;
                      return GestureDetector(
                        onTap: () => setModalState(() => _selectedFrequency = freq),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.2)
                                : AppColors.surface,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            freq,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textMid,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Duration (weeks)',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _weeksController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '8',
                      hintStyle: TextStyle(color: AppColors.textDim),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Advanced Dosing Button
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () => _showAdvancedDosingModal(setModalState),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: BorderSide(color: AppColors.accent),
                        ),
                      ),
                      child: Text(
                        _selectedDosingSchedule == null
                            ? 'SET ADVANCED DOSING (Optional)'
                            : '✓ ADVANCED DOSING SET',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_peptideController.text.isEmpty ||
                            _doseController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill in peptide and dose'),
                              backgroundColor: Color(0xFFFF0040),
                            ),
                          );
                          return;
                        }

                        final dose = double.tryParse(_doseController.text) ?? 0;
                        final weeks = int.tryParse(_weeksController.text) ?? 8;

                        await db.saveCycle(
                          peptideName: _peptideController.text,
                          dose: dose,
                          route: _selectedRoute,
                          frequency: _selectedFrequency,
                          durationWeeks: weeks,
                          startDate: DateTime.now(),
                          advancedSchedule: _selectedDosingSchedule?.toJson(),
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✓ ${_peptideController.text} cycle created'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                        _peptideController.clear();
                        _doseController.clear();
                        _weeksController.text = '8';
                        _selectedFrequency = '1x weekly';
                        _selectedRoute = 'SC (subcutaneous)';
                        _selectedDosingSchedule = null;
                        _loadCycles();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        'CREATE CYCLE',
                        style: TextStyle(
                          color: AppColors.background,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CYCLES',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showNewCycleDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('NEW'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : savedCycles.isEmpty
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.event_available,
                                    color: AppColors.primary,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No cycles',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppColors.textMid,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Create your first cycle to get started',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textDim,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: savedCycles.length,
                        itemBuilder: (context, index) {
                          final cycle = savedCycles[index];
                          final daysRemaining = cycle.endDate.difference(DateTime.now()).inDays;
                          final totalDays = cycle.durationWeeks * 7;
                          final progress = ((totalDays - daysRemaining) / totalDays).clamp(0.0, 1.0);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        cycle.peptideName.toUpperCase(),
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cycle.isActive
                                            ? AppColors.accent.withOpacity(0.2)
                                            : AppColors.textDim.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        cycle.isActive ? 'ACTIVE' : 'COMPLETE',
                                        style: TextStyle(
                                          color: cycle.isActive
                                              ? AppColors.accent
                                              : AppColors.textDim,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Dose, Route, Frequency Grid
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Dose',
                                            style: TextStyle(
                                              color: AppColors.textDim,
                                              fontSize: 11,
                                            ),
                                          ),
                                          Text(
                                            '${cycle.dose} mg',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Route',
                                            style: TextStyle(
                                              color: AppColors.textDim,
                                              fontSize: 11,
                                            ),
                                          ),
                                          Text(
                                            cycle.route,
                                            style: TextStyle(
                                              color: AppColors.textLight,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Frequency',
                                            style: TextStyle(
                                              color: AppColors.textDim,
                                              fontSize: 11,
                                            ),
                                          ),
                                          Text(
                                            cycle.frequency,
                                            style: TextStyle(
                                              color: AppColors.textLight,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Duration & Progress
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${cycle.durationWeeks} weeks',
                                      style: TextStyle(
                                        color: AppColors.textMid,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      daysRemaining > 0
                                          ? '$daysRemaining days left'
                                          : 'Completed',
                                      style: TextStyle(
                                        color: daysRemaining > 0
                                            ? AppColors.accent
                                            : AppColors.textDim,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Progress Bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 4,
                                    backgroundColor: AppColors.border,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Action Buttons Row 1
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    if (cycle.isActive) ...[
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              _showLogDoseDialog(cycle),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                              color: AppColors.accent,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                          ),
                                          child: Text(
                                            'LOG DOSE',
                                            style: TextStyle(
                                              color: AppColors.accent,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              _showLogSideEffectDialog(cycle),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                              color: AppColors.accent,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                          ),
                                          child: Text(
                                            'LOG SYMPTOM',
                                            style: TextStyle(
                                              color: AppColors.accent,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Action Buttons Row 2
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    if (cycle.isActive) ...[
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              _showEditCycle(cycle),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                              color: AppColors.primary,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                          ),
                                          child: Text(
                                            'EDIT',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              _showCompleteCycle(cycle),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.accent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                          ),
                                          child: Text(
                                            'COMPLETE',
                                            style: TextStyle(
                                              color: AppColors.background,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            _showDeleteConfirmation(cycle),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: AppColors.error,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                        ),
                                        child: Text(
                                          'DELETE',
                                          style: TextStyle(
                                            color: AppColors.error,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _peptideController.dispose();
    _doseController.dispose();
    _weeksController.dispose();
    _bacWaterMlController.dispose();
    _notesController.dispose();
    _doseAmountController.dispose();
    _sideEffectNotesController.dispose();
    super.dispose();
  }
}
