import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../data/peptides.dart';
import '../services/cycles_database.dart';

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
  final db = CyclesDatabase();
  
  List<Cycle> savedCycles = [];
  List<String> filteredPeptides = PEPTIDE_LIST;
  
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
                  // Header
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

                  // PEPTIDE PICKER
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

                  // DOSE (mg)
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
                                letterSpacing: 0.5,
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
                                letterSpacing: 0.5,
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
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
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

                  // BAC WATER (ml)
                  Text(
                    'Bacteriostatic Water (ml)',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bacWaterMlController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: '2.0',
                      hintStyle: TextStyle(color: AppColors.textDim),
                      suffix: Text(
                        'ml',
                        style: TextStyle(color: AppColors.accent, fontSize: 12),
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // FREQUENCY
                  Text(
                    'Frequency',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
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

                  // DURATION
                  Text(
                    'Duration (weeks)',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
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

                  // ADVANCED DOSING
                  GestureDetector(
                    onTap: () => setModalState(() => _showAdvanced = !_showAdvanced),
                    child: Row(
                      children: [
                        Icon(
                          _showAdvanced
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ADVANCED DOSING (Ramping/Tapering)',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_showAdvanced) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customize doses for first and last weeks',
                            style: TextStyle(
                              color: AppColors.textMid,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Start dose (mg)',
                                      style: TextStyle(
                                        color: AppColors.textMid,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextField(
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '125',
                                        hintStyle: TextStyle(
                                          color: AppColors.textDim,
                                          fontSize: 11,
                                        ),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.border,
                                          ),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
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
                                      'End dose (mg)',
                                      style: TextStyle(
                                        color: AppColors.textMid,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextField(
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '125',
                                        hintStyle: TextStyle(
                                          color: AppColors.textDim,
                                          fontSize: 11,
                                        ),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.border,
                                          ),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
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

                  // CREATE BUTTON
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

                        final cycle = await db.saveCycle(
                          peptideName: _peptideController.text,
                          dose: dose,
                          route: _selectedRoute,
                          frequency: _selectedFrequency,
                          durationWeeks: weeks,
                          startDate: DateTime.now(),
                        );

                        if (cycle != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '✓ ${cycle.peptideName} cycle created',
                              ),
                              backgroundColor: AppColors.primary,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          _peptideController.clear();
                          _doseController.clear();
                          _bacWaterMlController.clear();
                          _weeksController.text = '8';
                          _selectedFrequency = '1x weekly';
                          _selectedRoute = 'SC (subcutaneous)';
                          _loadCycles();
                          Navigator.pop(context);
                        }
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
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        'CANCEL',
                        style: TextStyle(
                          color: AppColors.textMid,
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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

          // Content
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
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      cycle.peptideName,
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
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
                                        cycle.isActive ? 'ACTIVE' : 'INACTIVE',
                                        style: TextStyle(
                                          color: cycle.isActive
                                              ? AppColors.accent
                                              : AppColors.textDim,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
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
                                              color: AppColors.textLight,
                                              fontSize: 13,
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
                                              fontSize: 13,
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
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${cycle.durationWeeks} weeks • Started ${cycle.startDate.toString().split(' ')[0]}',
                                  style: TextStyle(
                                    color: AppColors.textDim,
                                    fontSize: 11,
                                  ),
                                ),
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
    super.dispose();
  }
}
