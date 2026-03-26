import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../data/peptides.dart';
import '../data/dosing_calculator.dart';
import '../services/cycles_database.dart';
import '../services/dose_logs_database.dart';
import '../services/dose_logs_service.dart';
import '../services/side_effects_database.dart';
import '../services/protocol_templates_database.dart';
import '../services/dose_schedule_service.dart';
import '../screens/cycle_setup_form_v4.dart';
import '../screens/insights_screen.dart';
import '../screens/protocols_screen.dart';
import '../widgets/advanced_dosing_widget.dart';
import '../widgets/wintermute_dialog.dart';
import '../widgets/peptide_selector.dart';
import '../widgets/cyberpunk_frame.dart';
import '../widgets/cyberpunk_background.dart';
import '../widgets/expandable_cycle_card.dart';
import '../widgets/app_header.dart';
import '../widgets/common/empty_state.dart';

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
  final protocolDb = ProtocolTemplatesDatabase();
  late final DoseScheduleService doseScheduleService;

  @override
  void initState() {
    super.initState();
    doseScheduleService = DoseScheduleService(Supabase.instance.client);
    _loadCycles();
  }
  
  List<Cycle> savedCycles = [];

  DosingSchedule? _selectedDosingSchedule;
  
  String _selectedFrequency = '1x weekly';
  String _selectedRoute = 'SC (subcutaneous)';
  bool _showAdvanced = false;
  bool _isLoading = true;

  void _loadCycles() async {
    setState(() => _isLoading = true);
    final cycles = await db.getUserCycles();
    setState(() {
      savedCycles = cycles;
      _isLoading = false;
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
                              style: const TextStyle(color: AppColors.textLight),
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
                                      style: const TextStyle(color: AppColors.textLight),
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
                        final weeks = int.tryParse(_weeksController.text) ?? cycle.durationWeeks;
                        
                        await db.updateCycle(
                          cycleId: cycle.id,
                          peptideName: _peptideController.text,
                          dose: dose,
                          route: _selectedRoute,
                          frequency: _selectedFrequency,
                          durationWeeks: weeks,
                        );
                        _loadCycles();
                        _peptideController.clear();
                        _doseController.clear();
                        _weeksController.clear();
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
                    style: const TextStyle(color: AppColors.textLight),
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
                          endDate: DateTime.now(),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✓ Dosing schedule set'),
              backgroundColor: AppColors.accent,
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  void _showLogDoseDialog(Cycle cycle) {
    _doseAmountController.clear();
    _notesController.clear();
    String selectedRoute = cycle.route;
    String selectedSite = 'Left shoulder';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LOG DOSE',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _doseAmountController,
              style: const TextStyle(color: AppColors.textLight),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Dose (mg)',
                labelStyle: TextStyle(color: AppColors.textMid),
                hintText: '${cycle.dose}',
                hintStyle: TextStyle(color: AppColors.textDim),
                border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Route: $selectedRoute',
              style: TextStyle(color: AppColors.textMid, fontSize: 11),
            ),
            const SizedBox(height: 12),
            Text(
              'Site: $selectedSite',
              style: TextStyle(color: AppColors.textMid, fontSize: 11),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              style: const TextStyle(color: AppColors.textLight),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                labelStyle: TextStyle(color: AppColors.textMid),
                border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () async {
                  final dose = double.tryParse(_doseAmountController.text) ?? cycle.dose;
                  await doseDb.logDose(
                    cycleId: cycle.id,
                    doseAmount: dose,
                    loggedAt: DateTime.now(),
                    route: selectedRoute,
                    location: selectedSite,
                    notes: _notesController.text.isEmpty ? null : _notesController.text,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✓ Dose logged (${dose}mg)'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('SAVE DOSE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
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
                      child: Text(s, style: const TextStyle(color: AppColors.textLight)),
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
                  style: const TextStyle(color: AppColors.textLight),
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

                  PeptideSelector(
                    initialValue: _peptideController.text.isNotEmpty ? _peptideController.text : null,
                    label: 'PEPTIDE',
                    onSelected: (peptide) {
                      _peptideController.text = peptide;
                    },
                  ),
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
                              style: const TextStyle(color: AppColors.textLight, fontSize: 16),
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
                                      style: const TextStyle(color: AppColors.textLight, fontSize: 12),
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
                    style: const TextStyle(color: AppColors.textLight, fontSize: 16),
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
                        // Use new unified cycle setup form
                        Navigator.pop(context); // Close this old modal
                        await _showNewUnifiedCycleSetup();
                        return;

                        // OLD LOGIC BELOW - DEPRECATED
                        print('[DEBUG CREATE CYCLE] Button pressed');
                        print('[DEBUG CREATE CYCLE] Peptide: "${_peptideController.text}"');
                        print('[DEBUG CREATE CYCLE] Dose: "${_doseController.text}"');
                        
                        if (_peptideController.text.isEmpty ||
                            _doseController.text.isEmpty) {
                          print('[DEBUG CREATE CYCLE] Validation failed - showing snackbar');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill in peptide and dose'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        print('[DEBUG CREATE CYCLE] Validation passed');
                        final peptideName = _peptideController.text;
                        final dose = double.tryParse(_doseController.text) ?? 0;
                        final weeks = int.tryParse(_weeksController.text) ?? 8;
                        print('[DEBUG CREATE CYCLE] Parsed values - peptide: $peptideName, dose: $dose, weeks: $weeks');

                        // Save cycle and capture the actual returned cycle with real UUID
                        print('[DEBUG CREATE CYCLE] Calling db.saveCycle()...');
                        late Cycle createdCycle;
                        try {
                          final result = await db.saveCycle(
                            peptideName: peptideName,
                            dose: dose,
                            route: _selectedRoute,
                            frequency: _selectedFrequency,
                            durationWeeks: weeks,
                            startDate: DateTime.now(),
                            advancedSchedule: _selectedDosingSchedule?.toJson(),
                          );
                          
                          print('[DEBUG CREATE CYCLE] saveCycle returned: ${result?.id}');
                          
                          if (result == null) {
                            print('[DEBUG CREATE CYCLE] result is null');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Error creating cycle'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                            return;
                          }
                          createdCycle = result;
                          print('[DEBUG CREATE CYCLE] createdCycle is valid - peptideName: ${createdCycle.peptideName}, id: ${createdCycle.id}');
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✓ $peptideName cycle created'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        } catch (e, stackTrace) {
                          print('[DEBUG CREATE CYCLE] Exception in saveCycle: $e');
                          print('[DEBUG CREATE CYCLE] Stack trace: $stackTrace');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Exception: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                          return;
                        }
                        
                        // OLD CODE REMOVED - Using new unified CycleSetupForm now
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
    return CyberpunkBackground(
      cityOpacity: 0.3,
      rainOpacity: 0.25,
      rainParticleCount: 40,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
            body: Column(
              children: [
                // Header using reusable widget
                const AppHeader(
                  icon: Icons.autorenew,
                  iconColor: WintermmuteStyles.colorGreen,
                  title: 'CYCLES',
                ),

                // Terminal-style create button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: GestureDetector(
                    onTap: _showNewUnifiedCycleSetup,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.75),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.15),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 4, height: 14, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Icon(Icons.add_circle_outline, color: AppColors.primary, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'INITIATE NEW CYCLE',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: Stack(
                    children: [
                      _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : savedCycles.isEmpty
                    ? const SingleChildScrollView(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            SizedBox(height: 80),
                            EmptyState(
                              icon: Icons.autorenew,
                              title: 'No cycles yet',
                              message: 'Create your first cycle to start tracking peptide protocols',
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: savedCycles.length,
                        addAutomaticKeepAlives: true, // Keep expanded state
                        addRepaintBoundaries: true, // Optimize repaints
                        itemBuilder: (context, index) {
                          final cycle = savedCycles[index];

                          // Use new expandable cycle card (matte Wintermute style)
                          // Add key for better rebuild performance
                          return ExpandableCycleCard(
                            key: ValueKey(cycle.id),
                            cycle: cycle,
                            loadCycleSummary: _loadCycleSummary,
                            onEdit: () => _showEditCycle(cycle),
                            onComplete: () => _showCompleteCycle(cycle),
                            onDelete: () => _showDeleteConfirmation(cycle),
                          );

                          /* OLD CODE - COMMENTED OUT - REPLACED WITH EXPANDABLE CARD
                          // Full old card code removed to use new ExpandableCycleCard widget
                          // which provides inline expansion without navigation
                          */
                        },
                      ),
                      // Scanlines overlay - use const for performance
                      const Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _ScanlinesPainter(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // DEPRECATED: _showConfigureDosesFlow - replaced by _showNewUnifiedCycleSetup
  // Keeping for reference but not used anymore

  Future<void> _showNewUnifiedCycleSetup() async {
    if (!mounted) return;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) => const CycleSetupFormV4(),
    );

    if (result == null) {
      print('[DEBUG UNIFIED] Setup cancelled');
      return;
    }

    print('[DEBUG UNIFIED] Setup result: $result');

    try {
      final peptideName = result['peptideName'] as String?;
      final route = result['route'] as String?;
      final totalPeptideMg = result['totalPeptideMg'] as double?;
      final desiredDosageMg = result['desiredDosageMg'] as double?;
      final concentrationMl = result['concentrationMl'] as double?;
      final bacRequired = result['bacRequired'] as double?;
      final schedule = result['schedule'] as List<Map<String, dynamic>>?;
      final scheduledTime = result['scheduledTime'] as String? ?? '08:00';
      final daysOfWeek = result['daysOfWeek'] as List<int>? ?? [0,1,2,3,4,5,6];
      final startDate = result['startDate'] as DateTime?;
      final endDate = result['endDate'] as DateTime?;

      if (peptideName == null || startDate == null || schedule == null) {
        throw Exception('Missing required cycle data');
      }

      // 1. Create the cycle
      print('[DEBUG UNIFIED] Creating cycle for $peptideName');
      final firstDose = schedule!.isNotEmpty 
          ? ((schedule![0]['dose'] as num?)?.toDouble() ?? desiredDosageMg ?? 1.0)
          : (desiredDosageMg ?? 1.0);
      final cycleDurationWeeks = (endDate?.difference(startDate!).inDays ?? 56) ~/ 7;
      
      final createdCycle = await db.saveCycle(
        peptideName: peptideName,
        dose: firstDose,
        route: route ?? 'SC',
        frequency: '${daysOfWeek.length}x weekly',
        durationWeeks: cycleDurationWeeks,
        startDate: startDate!,
      );

      if (createdCycle == null) {
        throw Exception('Failed to create cycle');
      }

      print('[DEBUG UNIFIED] Cycle created: ${createdCycle.id}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ $peptideName cycle created'),
            backgroundColor: AppColors.primary,
          ),
        );
      }

      // 2. Generate dose_schedules for each unique dose amount in schedule
      // For simplicity, create one master schedule and let dose_logs vary by day
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Create a master schedule with the first dose amount (or desired dose)
      final masterSchedule = await doseScheduleService.createDoseSchedule(
        userId: userId,
        cycleId: createdCycle.id,
        peptideName: peptideName,
        doseAmount: firstDose,
        route: route ?? 'SC',
        scheduledTime: scheduledTime,
        daysOfWeek: daysOfWeek,
        startDate: startDate!,
        endDate: endDate,
        notes: 'Peptide: ${totalPeptideMg}mg | Add ${bacRequired?.toStringAsFixed(1)}ml BAC | Draw ${concentrationMl}ml for ${desiredDosageMg}mg dose',
      );

      if (masterSchedule == null) {
        throw Exception('Failed to create dose schedule');
      }

      print('[DEBUG UNIFIED] Master schedule created: ${masterSchedule!.id}');

      // 3. Create dose_logs for each day in the ramp schedule
      final doseLogsService = DoseLogsService(Supabase.instance.client);
      int createdDoseLogs = 0;

      if (schedule!.isEmpty) {
        print('[DEBUG UNIFIED] No doses in schedule, skipping dose log creation');
      } else {
        for (final dose in schedule!) {
        final dayOffset = dose['dayOffset'] as int? ?? 0;
        final doseAmount = (dose['dose'] as num?)?.toDouble() ?? 0.0;
        final doseDate = dose['date'] as DateTime?;
        final phase = dose['phase'] as String? ?? 'plateau';

        // Use actual date from schedule if available, otherwise calculate
        final actualDoseDate = doseDate ?? startDate.add(Duration(days: dayOffset));
        final timeParts = scheduledTime.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final doseDateTime = DateTime(actualDoseDate.year, actualDoseDate.month, actualDoseDate.day, hour, minute);

        // Insert into dose_logs
        print('[DEBUG UNIFIED] Inserting dose_log: amount=${doseAmount}mg, date=$doseDateTime, phase=$phase');
        try {
          final insertData = {
            'user_id': userId,
            'cycle_id': createdCycle.id,
            'dose_amount': doseAmount,
            'logged_at': doseDateTime.toIso8601String(),
            'notes': 'Phase: $phase',
          };
          print('[DEBUG UNIFIED]   Data: $insertData');
          
          final doseLog = await Supabase.instance.client.from('dose_logs').insert(insertData).select().single();

          createdDoseLogs++;
          print('[DEBUG UNIFIED] ✓ Created dose_log: ${doseLog['id']} for ${doseAmount}mg (phase: $phase)');
        } catch (e, stackTrace) {
          print('[DEBUG UNIFIED] ✗ FAILED to create dose_log for day $dayOffset: $e');
          print('[DEBUG UNIFIED]   Stack: $stackTrace');
          rethrow; // Re-throw so outer catch sees it
        }
      }
      }

      print('[DEBUG UNIFIED] Created $createdDoseLogs dose logs');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ $createdDoseLogs doses scheduled'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // 4. Reload cycles
      _loadCycles();
    } catch (e, stackTrace) {
      print('[DEBUG UNIFIED] Error: $e');
      print('[DEBUG UNIFIED] Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ERROR: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showSaveAsProtocolDialog(Cycle cycle) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('SAVE AS PROTOCOL', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Protocol Name',
                style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.textLight),
                decoration: InputDecoration(
                  hintText: 'e.g., "${cycle.peptideName} Recovery"',
                  hintStyle: TextStyle(color: AppColors.textDim),
                  border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Description (optional)',
                style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descController,
                style: const TextStyle(color: AppColors.textLight),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Notes about this protocol...',
                  hintStyle: TextStyle(color: AppColors.textDim),
                  border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
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
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a protocol name')),
                );
                return;
              }

              await protocolDb.saveProtocol(
                name: nameController.text,
                description: descController.text.isEmpty ? null : descController.text,
                peptideName: cycle.peptideName,
                dose: cycle.dose,
                route: cycle.route,
                frequency: cycle.frequency,
                durationWeeks: cycle.durationWeeks,
              );

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ Protocol saved: ${nameController.text}'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: Text('SAVE', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _loadCycleSummary(String cycleId) async {
    try {
      // ISSUE 2: Query dose_logs to get missed doses
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        return {
          'totalDoses': 0,
          'lastDose': null,
          'recentSideEffects': [],
          'missedDoses': [],
        };
      }

      // Fetch all dose logs for this cycle
      final response = await Supabase.instance.client
          .from('dose_logs')
          .select()
          .eq('user_id', userId)
          .eq('cycle_id', cycleId)
          .order('logged_at', ascending: false);

      final allDoseLogs = response as List;
      final totalDoses = allDoseLogs.length;

      // ISSUE 2: Filter for missed doses
      final missedDoseLogs = allDoseLogs
          .where((log) => log['status'] == 'MISSED')
          .toList();

      print('[ISSUE2 DEBUG] Cycle $cycleId: ${missedDoseLogs.length} missed doses out of $totalDoses total');

      // Build missed dose list with date + amount
      final missedDoses = missedDoseLogs.take(5).map((log) {
        final loggedAt = DateTime.parse(log['logged_at'] as String);
        final doseAmount = (log['dose_amount'] as num?)?.toDouble() ?? 0;
        final dateStr = '${loggedAt.month}/${loggedAt.day}/${loggedAt.year}';
        return '$dateStr (${doseAmount}mg)';
      }).toList();

      String? lastDose;
      if (allDoseLogs.isNotEmpty) {
        final last = allDoseLogs.first;
        final loggedAt = DateTime.parse(last['logged_at'] as String);
        lastDose = '${loggedAt.month}/${loggedAt.day}/${loggedAt.year}';
      }

      // Fetch side effects
      final sideEffects = await sideEffectDb.getCycleSideEffects(cycleId);
      final recentSideEffects = sideEffects
          .take(3)
          .map((e) => '${e.symptom} (${e.severity}/10)')
          .toList();

      return {
        'totalDoses': totalDoses,
        'lastDose': lastDose,
        'recentSideEffects': recentSideEffects,
        'missedDoses': missedDoses,
      };
    } catch (e) {
      print('[ISSUE2 ERROR] Error loading cycle summary: $e');
      return {
        'totalDoses': 0,
        'lastDose': null,
        'recentSideEffects': [],
        'missedDoses': [],
      };
    }
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

class _ScanlinesPainter extends CustomPainter {
  const _ScanlinesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.07)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
