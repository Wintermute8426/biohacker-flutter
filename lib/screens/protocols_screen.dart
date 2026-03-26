import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../services/protocol_templates_database.dart';
import '../services/cycles_database.dart';
import '../data/peptides.dart';
import '../widgets/scanline_overlay.dart';
import '../widgets/cyberpunk_rain.dart';
import '../widgets/city_background.dart';
import '../widgets/app_header.dart';
import '../widgets/common/empty_state.dart';

class ProtocolsScreen extends StatefulWidget {
  const ProtocolsScreen({Key? key}) : super(key: key);

  @override
  State<ProtocolsScreen> createState() => _ProtocolsScreenState();
}

class _ProtocolsScreenState extends State<ProtocolsScreen> {
  final protocolDb = ProtocolTemplatesDatabase();
  final cycleDb = CyclesDatabase();
  List<ProtocolTemplate> myProtocols = [];
  List<ProtocolTemplate> communityProtocols = [];
  bool isLoading = true;

  // 6 Sovereign Protocol Stacks
  final List<Map<String, dynamic>> protocolStacks = [
    {
      'id': 'bh-muscle-recovery',
      'name': 'MUSCLE RECOVERY',
      'goal': 'Tissue repair, inflammation reduction',
      'description': 'Post-workout repair stack combining BPC-157 for tissue healing and TB-500 for systemic regeneration. Synergistic approach to reducing recovery time and preventing re-injury.',
      'duration': '4 WEEKS',
      'accentColor': const Color(0xFF39FF14),
      'peptides': [
        {'name': 'BPC-157', 'dose': 250.0, 'doseDisplay': '250mcg', 'route': 'SC', 'frequency': '1x daily', 'weeks': 4},
        {'name': 'TB-500', 'dose': 2.0, 'doseDisplay': '2mg', 'route': 'SC', 'frequency': '2x weekly', 'weeks': 4},
      ],
    },
    {
      'id': 'bh-longevity',
      'name': 'LONGEVITY STACK',
      'goal': 'Telomere protection, cellular regeneration',
      'description': 'Anti-aging protocol targeting cellular longevity. Epitalon extends telomeres, GHK-Cu drives collagen and tissue renewal, NAD+ restores mitochondrial energy production.',
      'duration': '2–8 WEEKS',
      'accentColor': const Color(0xFF00FFFF),
      'peptides': [
        {'name': 'Epitalon', 'dose': 10.0, 'doseDisplay': '10mg', 'route': 'SC', 'frequency': '1x daily', 'weeks': 2},
        {'name': 'GHK-Cu', 'dose': 2.0, 'doseDisplay': '2mg', 'route': 'SC', 'frequency': '1x daily', 'weeks': 8},
        {'name': 'NAD+', 'dose': 100.0, 'doseDisplay': '100mg', 'route': 'SC', 'frequency': '2x weekly', 'weeks': 8},
      ],
    },
    {
      'id': 'bh-focus-cognition',
      'name': 'FOCUS & COGNITION',
      'goal': 'Neuroprotection, focus enhancement',
      'description': 'Cognitive optimization stack for mental clarity and neuroprotection. Semax and Selank modulate BDNF and anxiety pathways. Cerebrolysin provides neurotrophic peptides for neuroplasticity.',
      'duration': '4 WEEKS',
      'accentColor': const Color(0xFFFFAA00),
      'peptides': [
        {'name': 'Semax', 'dose': 300.0, 'doseDisplay': '300mcg', 'route': 'Intranasal', 'frequency': '1x daily', 'weeks': 4},
        {'name': 'Selank', 'dose': 300.0, 'doseDisplay': '300mcg', 'route': 'Intranasal', 'frequency': '1x daily', 'weeks': 4},
        {'name': 'Cerebrolysin', 'dose': 5.0, 'doseDisplay': '5ml', 'route': 'IM', 'frequency': '3x weekly', 'weeks': 4},
      ],
    },
    {
      'id': 'bh-acl-recovery',
      'name': 'ACL SURGERY RECOVERY',
      'goal': 'Tendon repair, collagen synthesis',
      'description': 'Post-surgical healing protocol targeting tendon and ligament repair. High-dose BPC-157 accelerates tissue regeneration while TB-500 promotes systemic healing and GHK-Cu drives collagen formation.',
      'duration': '12 WEEKS',
      'accentColor': const Color(0xFFFF0040),
      'peptides': [
        {'name': 'BPC-157', 'dose': 500.0, 'doseDisplay': '500mcg', 'route': 'SC', 'frequency': '1x daily', 'weeks': 12},
        {'name': 'TB-500', 'dose': 5.0, 'doseDisplay': '5mg', 'route': 'SC', 'frequency': '2x weekly', 'weeks': 12},
        {'name': 'GHK-Cu', 'dose': 2.0, 'doseDisplay': '2mg', 'route': 'SC', 'frequency': '1x daily', 'weeks': 12},
      ],
    },
    {
      'id': 'bh-metabolic',
      'name': 'METABOLIC OPTIMIZATION',
      'goal': 'Fat loss, GH stimulation',
      'description': 'Metabolic recomposition stack for body composition and insulin sensitivity. Semaglutide drives appetite regulation and fat loss while Tesamorelin stimulates growth hormone for visceral fat reduction.',
      'duration': '12 WEEKS',
      'accentColor': const Color(0xFFFF00FF),
      'peptides': [
        {'name': 'Semaglutide', 'dose': 0.5, 'doseDisplay': '0.5mg', 'route': 'SC', 'frequency': '1x weekly', 'weeks': 12},
        {'name': 'Tesamorelin', 'dose': 1.0, 'doseDisplay': '1mg', 'route': 'SC', 'frequency': '1x daily', 'weeks': 12},
      ],
    },
    {
      'id': 'bh-performance',
      'name': 'PERFORMANCE ENHANCEMENT',
      'goal': 'GH release, recovery, endurance',
      'description': 'Performance stack for strength and endurance athletes. Ipamorelin and CJC-1295 synergize for pulsatile GH release. BPC-157 accelerates recovery between sessions to maximize adaptation.',
      'duration': '8 WEEKS',
      'accentColor': const Color(0xFF39FF14),
      'peptides': [
        {'name': 'Ipamorelin', 'dose': 200.0, 'doseDisplay': '200mcg', 'route': 'SC', 'frequency': '2x daily', 'weeks': 8},
        {'name': 'CJC-1295 no DAC', 'dose': 100.0, 'doseDisplay': '100mcg', 'route': 'SC', 'frequency': '2x daily', 'weeks': 8},
        {'name': 'BPC-157', 'dose': 250.0, 'doseDisplay': '250mcg', 'route': 'SC', 'frequency': '1x daily', 'weeks': 8},
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProtocols();
  }

  void _loadProtocols() async {
    setState(() => isLoading = true);
    final myTemplates = await protocolDb.getUserProtocols();
    final communityTemp = await protocolDb.getCommunityProtocols();
    setState(() {
      myProtocols = myTemplates;
      communityProtocols = communityTemp;
      isLoading = false;
    });
  }

  Future<void> _initiateSovereignProtocol(Map<String, dynamic> stack) async {
    final peptides = stack['peptides'] as List<dynamic>;
    final protocolName = stack['name'] as String;

    for (final pep in peptides) {
      final peptide = pep as Map<String, dynamic>;
      await cycleDb.saveCycle(
        peptideName: peptide['name'] as String,
        dose: (peptide['dose'] as num).toDouble(),
        route: peptide['route'] as String,
        frequency: peptide['frequency'] as String,
        durationWeeks: peptide['weeks'] as int,
        startDate: DateTime.now(),
      );
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ $protocolName initiated — ${peptides.length} cycle${peptides.length > 1 ? 's' : ''} created',
          ),
          backgroundColor: AppColors.accent,
        ),
      );
    }
  }

  void _showProtocolDetail(Map<String, dynamic> stack) {
    final peptides = stack['peptides'] as List<dynamic>;
    final accentColor = stack['accentColor'] as Color;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A0A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      builder: (context) => ScanlineOverlay(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  border: Border(
                    bottom: BorderSide(color: accentColor.withOpacity(0.25), width: 1),
                    left: BorderSide(color: accentColor, width: 3),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    Icon(Icons.biotech, color: accentColor, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '> ${stack['name']}',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 13,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.textDim, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Goal + duration row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: accentColor.withOpacity(0.25)),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            stack['duration'] as String,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 10,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            stack['goal'] as String,
                            style: TextStyle(
                              color: AppColors.textMid,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Protocol Intel section
                    Row(
                      children: [
                        Container(width: 3, height: 12, color: AppColors.amber.withOpacity(0.8)),
                        const SizedBox(width: 8),
                        Text(
                          '> PROTOCOL INTEL',
                          style: TextStyle(
                            color: AppColors.amber,
                            fontSize: 10,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border(
                          left: BorderSide(color: AppColors.amber.withOpacity(0.6), width: 3),
                          top: BorderSide(color: AppColors.borderDim, width: 1),
                          right: BorderSide(color: AppColors.borderDim, width: 1),
                          bottom: BorderSide(color: AppColors.borderDim, width: 1),
                        ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      child: Text(
                        stack['description'] as String,
                        style: TextStyle(
                          color: AppColors.textMid,
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Peptides section header
                    Row(
                      children: [
                        Container(width: 3, height: 12, color: accentColor.withOpacity(0.6)),
                        const SizedBox(width: 8),
                        Text(
                          '> PEPTIDE COMPOSITION',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 10,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Peptide cards
                    ...peptides.map((pep) {
                      final peptide = pep as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border(
                            left: BorderSide(color: accentColor.withOpacity(0.6), width: 2),
                            top: BorderSide(color: AppColors.borderDim, width: 1),
                            right: BorderSide(color: AppColors.borderDim, width: 1),
                            bottom: BorderSide(color: AppColors.borderDim, width: 1),
                          ),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              peptide['name'] as String,
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 12,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${peptide['doseDisplay']} ${peptide['route']} • ${peptide['frequency']} • ${peptide['weeks']} weeks',
                              style: TextStyle(color: AppColors.textMid, fontSize: 10, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 20),

                    // Initiate button
                    GestureDetector(
                      onTap: () => _initiateSovereignProtocol(stack),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: accentColor.withOpacity(0.25), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.15),
                              blurRadius: 12,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow, color: accentColor, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'INITIATE PROTOCOL',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 13,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateProtocolModal() {
    final nameController = TextEditingController();
    final goalController = TextEditingController();
    final currentDoseController = TextEditingController();
    final currentPeptideWeeksController = TextEditingController(text: '8');
    String currentPeptide = PEPTIDE_LIST.first;
    String currentRoute = 'SC (subcutaneous)';
    String currentFrequency = '1x daily';
    final List<Map<String, dynamic>> peptideStack = [];
    bool makePublic = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A0A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        side: BorderSide(color: Color(0xFF39FF14), width: 0),
      ),
      builder: (context) => ScanlineOverlay(
        child: StatefulBuilder(
          builder: (context, setModalState) => SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 0,
              right: 0,
              top: 0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modal header bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    border: Border(
                      bottom: BorderSide(color: AppColors.accent.withOpacity(0.25), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(width: 4, height: 14, color: AppColors.accent),
                      const SizedBox(width: 10),
                      Icon(Icons.add_circle_outline, color: AppColors.accent, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        '> DESIGN PROTOCOL',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ─── PROTOCOL INFO ───
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.accent.withOpacity(0.25), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 4, height: 14, color: AppColors.accent.withOpacity(0.6)),
                          const SizedBox(width: 8),
                          Icon(Icons.info_outline, color: AppColors.accent, size: 13),
                          const SizedBox(width: 8),
                          Text(
                            '> PROTOCOL INFO',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        style: TextStyle(
                          color: AppColors.amber.withOpacity(0.9),
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                        decoration: InputDecoration(
                          labelText: 'PROTOCOL NAME',
                          labelStyle: TextStyle(color: AppColors.amber.withOpacity(0.5), fontSize: 12, fontFamily: 'monospace'),
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
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: goalController,
                        style: TextStyle(
                          color: AppColors.amber.withOpacity(0.9),
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'GOAL / DESCRIPTION',
                          labelStyle: TextStyle(color: AppColors.amber.withOpacity(0.5), fontSize: 12, fontFamily: 'monospace'),
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
                      ),
                    ],
                  ),
                ),

                // ─── PEPTIDE STACK ───
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.primary.withOpacity(0.25), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 4, height: 14, color: AppColors.primary.withOpacity(0.6)),
                          const SizedBox(width: 8),
                          Icon(Icons.biotech, color: AppColors.primary, size: 13),
                          const SizedBox(width: 8),
                          Text(
                            '> PEPTIDE STACK',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const Spacer(),
                          if (peptideStack.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                '${peptideStack.length} ADDED',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 9,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Added peptides list
                      if (peptideStack.isNotEmpty) ...[
                        ...peptideStack.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final p = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              border: Border(
                                left: BorderSide(color: AppColors.primary.withOpacity(0.6), width: 2),
                                top: BorderSide(color: AppColors.borderDim, width: 1),
                                right: BorderSide(color: AppColors.borderDim, width: 1),
                                bottom: BorderSide(color: AppColors.borderDim, width: 1),
                              ),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(4),
                                bottomRight: Radius.circular(4),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p['name'] as String,
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${p['dose']} · ${p['route']} · ${p['frequency']} · ${p['weeks'] ?? 8}w',
                                        style: TextStyle(
                                          color: AppColors.textDim,
                                          fontSize: 10,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setModalState(() => peptideStack.removeAt(idx)),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.close, color: AppColors.textDim, size: 16),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        Container(
                          height: 1,
                          margin: const EdgeInsets.only(bottom: 14),
                          color: AppColors.borderDim,
                        ),
                      ],

                      // Configure next peptide to add
                      Text(
                        peptideStack.isEmpty ? 'ADD FIRST PEPTIDE' : 'ADD ANOTHER PEPTIDE',
                        style: TextStyle(
                          color: AppColors.textDim,
                          fontSize: 10,
                          fontFamily: 'monospace',
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: currentPeptide,
                        dropdownColor: Colors.black,
                        style: TextStyle(color: AppColors.amber.withOpacity(0.9), fontSize: 14, fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          labelText: 'PEPTIDE',
                          labelStyle: TextStyle(color: AppColors.amber.withOpacity(0.5), fontSize: 12, fontFamily: 'monospace'),
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
                        items: PEPTIDE_LIST.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (val) => setModalState(() => currentPeptide = val!),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: currentDoseController,
                        style: TextStyle(
                          color: AppColors.amber.withOpacity(0.9),
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'DOSE (mg or mcg)',
                          labelStyle: TextStyle(color: AppColors.amber.withOpacity(0.5), fontSize: 12, fontFamily: 'monospace'),
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
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: currentRoute,
                        dropdownColor: Colors.black,
                        style: TextStyle(color: AppColors.amber.withOpacity(0.9), fontSize: 14, fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          labelText: 'INJECTION ROUTE',
                          labelStyle: TextStyle(color: AppColors.amber.withOpacity(0.5), fontSize: 12, fontFamily: 'monospace'),
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
                        items: ['SC (subcutaneous)', 'IM (intramuscular)', 'IV (intravenous)', 'Intranasal', 'Oral']
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (val) => setModalState(() => currentRoute = val!),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: currentFrequency,
                        dropdownColor: Colors.black,
                        style: TextStyle(color: AppColors.amber.withOpacity(0.9), fontSize: 14, fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          labelText: 'FREQUENCY',
                          labelStyle: TextStyle(color: AppColors.amber.withOpacity(0.5), fontSize: 12, fontFamily: 'monospace'),
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
                        items: ['1x daily', '2x daily', '1x weekly', '2x weekly', '3x weekly']
                            .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                            .toList(),
                        onChanged: (val) => setModalState(() => currentFrequency = val!),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: currentPeptideWeeksController,
                        style: TextStyle(
                          color: AppColors.amber.withOpacity(0.9),
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'DURATION (weeks)',
                          labelStyle: TextStyle(color: AppColors.amber.withOpacity(0.5), fontSize: 12, fontFamily: 'monospace'),
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
                      ),
                      const SizedBox(height: 14),

                      // ADD PEPTIDE button
                      GestureDetector(
                        onTap: () {
                          final dose = currentDoseController.text.trim();
                          if (dose.isEmpty) return;
                          final weeks = int.tryParse(currentPeptideWeeksController.text.trim()) ?? 8;
                          setModalState(() {
                            peptideStack.add({
                              'name': currentPeptide,
                              'dose': dose,
                              'route': currentRoute,
                              'frequency': currentFrequency,
                              'weeks': weeks,
                            });
                            currentDoseController.clear();
                            currentPeptideWeeksController.text = '8';
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.primary.withOpacity(0.6), width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: AppColors.primary, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'ADD PEPTIDE',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── SHARING OPTIONS ───
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.primary.withOpacity(0.15), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 4, height: 14, color: AppColors.primary.withOpacity(0.4)),
                          const SizedBox(width: 8),
                          Icon(Icons.share, color: AppColors.primary.withOpacity(0.7), size: 13),
                          const SizedBox(width: 8),
                          Text(
                            '> SHARING OPTIONS',
                            style: TextStyle(
                              color: AppColors.primary.withOpacity(0.7),
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () => setModalState(() => makePublic = !makePublic),
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: makePublic ? AppColors.accent.withOpacity(0.15) : Colors.black,
                                border: Border.all(
                                  color: makePublic ? AppColors.accent : AppColors.textDim,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: makePublic
                                  ? Icon(Icons.check, color: AppColors.accent, size: 12)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'SHARE WITH COMMUNITY',
                              style: TextStyle(
                                color: makePublic ? AppColors.accent : AppColors.textMid,
                                fontSize: 11,
                                fontFamily: 'monospace',
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── SUBMIT BUTTON ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                  child: GestureDetector(
                    onTap: () async {
                      if (nameController.text.trim().isEmpty || peptideStack.isEmpty) return;
                      final weeks = peptideStack
                          .map((p) => (p['weeks'] as int?) ?? 8)
                          .reduce((a, b) => a > b ? a : b);
                      final firstPeptide = peptideStack.first;

                      final peptidesJson = json.encode({
                        'goal': goalController.text,
                        'peptides': peptideStack,
                      });

                      await protocolDb.saveProtocol(
                        name: nameController.text,
                        description: peptidesJson,
                        peptideName: firstPeptide['name'] as String,
                        dose: double.tryParse(firstPeptide['dose'].toString()) ?? 1.0,
                        route: firstPeptide['route'] as String,
                        frequency: firstPeptide['frequency'] as String,
                        durationWeeks: weeks,
                        isPublic: makePublic,
                      );

                      Navigator.pop(context);
                      _loadProtocols();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ Protocol saved: ${nameController.text}'),
                          backgroundColor: AppColors.accent,
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.accent.withOpacity(0.8),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_outlined, color: AppColors.accent, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'SAVE PROTOCOL',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 13,
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

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStartFromProtocolModal(ProtocolTemplate protocol) {
    final durationController = TextEditingController(text: protocol.durationWeeks.toString());

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A0A),
      isScrollControlled: true,
      builder: (context) => ScanlineOverlay(
        child: SingleChildScrollView(
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
              Row(
                children: [
                  Container(width: 3, height: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '> CLONE PROTOCOL',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                protocol.name,
                style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
              if (protocol.description != null) ...[
                const SizedBox(height: 8),
                Text(protocol.description!, style: TextStyle(color: AppColors.textMid, fontSize: 12)),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: AppColors.borderDim),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${protocol.peptideName} • ${protocol.dose}mg',
                      style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 6),
                    Text('Route: ${protocol.route}', style: TextStyle(color: AppColors.textMid, fontSize: 11)),
                    Text('Frequency: ${protocol.frequency}', style: TextStyle(color: AppColors.textMid, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                style: const TextStyle(color: AppColors.textLight),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Duration (weeks)',
                  labelStyle: TextStyle(color: AppColors.primary),
                  filled: true,
                  fillColor: Colors.black,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final duration = int.tryParse(durationController.text) ?? protocol.durationWeeks;

                  await cycleDb.saveCycle(
                    peptideName: protocol.peptideName,
                    dose: protocol.dose,
                    route: protocol.route,
                    frequency: protocol.frequency,
                    durationWeeks: duration,
                    startDate: DateTime.now(),
                  );

                  await protocolDb.incrementUsage(protocol.id!);

                  Navigator.pop(context);
                  _loadProtocols();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✓ Cycle started from "${protocol.name}"'),
                      backgroundColor: AppColors.accent,
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.primary.withOpacity(0.8), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.12),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'START CYCLE',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color accentColor) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: accentColor),
        const SizedBox(width: 8),
        Icon(icon, color: accentColor, size: 14),
        const SizedBox(width: 8),
        Text(
          '> $title',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: accentColor,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildStackCard(Map<String, dynamic> stack) {
    final peptides = stack['peptides'] as List<dynamic>;
    final accentColor = stack['accentColor'] as Color;

    return GestureDetector(
      onTap: () => _showProtocolDetail(stack),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(4),
          border: Border(
            left: BorderSide(color: accentColor, width: 3),
            top: BorderSide(color: accentColor.withOpacity(0.2), width: 1),
            right: BorderSide(color: accentColor.withOpacity(0.2), width: 1),
            bottom: BorderSide(color: accentColor.withOpacity(0.2), width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: name + duration badge
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      stack['name'] as String,
                      style: TextStyle(
                        color: accentColor,
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: accentColor.withOpacity(0.4), width: 1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      stack['duration'] as String,
                      style: TextStyle(
                        color: accentColor.withOpacity(0.8),
                        fontSize: 9,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Goal text
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                stack['goal'] as String,
                style: TextStyle(
                  color: AppColors.textMid,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),

            // Peptide chips
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: peptides.map((pep) {
                  final peptide = pep as Map<String, dynamic>;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.08),
                      border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.science, color: accentColor.withOpacity(0.7), size: 10),
                        const SizedBox(width: 4),
                        Text(
                          '${peptide['name']}  ${peptide['doseDisplay']}  ${peptide['weeks']}w',
                          style: TextStyle(
                            color: accentColor.withOpacity(0.9),
                            fontSize: 10,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // Divider + action button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: accentColor.withOpacity(0.2), width: 1),
                ),
              ),
              child: GestureDetector(
                onTap: () => _showProtocolDetail(stack),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow, color: accentColor, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'INITIATE PROTOCOL',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 10,
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
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityProtocolCard(ProtocolTemplate protocol) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(color: AppColors.primary, width: 3),
          top: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 1),
          right: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 1),
          bottom: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        protocol.name,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${protocol.peptideName}  ${protocol.dose}mg  •  ${protocol.frequency}',
                        style: TextStyle(
                          color: AppColors.textMid,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                if (protocol.usageCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '${protocol.usageCount}x USED',
                      style: TextStyle(
                        color: AppColors.primary.withOpacity(0.7),
                        fontSize: 9,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (protocol.description != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                protocol.description!,
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 1),
              ),
            ),
            child: GestureDetector(
              onTap: () => _showStartFromProtocolModal(protocol),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.download_outlined, color: AppColors.primary, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'CLONE PROTOCOL',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // City background layer
          const Positioned.fill(
            child: CityBackground(
              enabled: true,
              animateLights: true,
              opacity: 0.3,
            ),
          ),
          // Rain effect layer
          const Positioned.fill(
            child: CyberpunkRain(
              enabled: true,
              particleCount: 40,
              opacity: 0.25,
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                // Header
                AppHeader(
                  icon: Icons.biotech,
                  iconColor: AppColors.accent,
                  title: 'PROTOCOLS',
                ),

                // Design Protocol button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: GestureDetector(
                    onTap: _showCreateProtocolModal,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.accent.withOpacity(0.75),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.12),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 4, height: 14, color: AppColors.accent),
                          const SizedBox(width: 10),
                          Icon(Icons.add_circle_outline, color: AppColors.accent, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'DESIGN PROTOCOL',
                            style: TextStyle(
                              color: AppColors.accent,
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

                // Content
                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isLoading)
                              Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                ),
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── SOVEREIGN PROTOCOLS ──
                                  _buildSectionHeader('SOVEREIGN PROTOCOLS', Icons.shield, AppColors.accent),
                                  const SizedBox(height: 12),
                                  ...protocolStacks.map((stack) => _buildStackCard(stack)),
                                  const SizedBox(height: 24),

                                  // ── COMMUNITY INTEL ──
                                  _buildSectionHeader('COMMUNITY INTEL', Icons.people, AppColors.primary),
                                  const SizedBox(height: 12),
                                  if (communityProtocols.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 20),
                                      child: EmptyState(
                                        icon: Icons.people_outline,
                                        title: 'No community intel yet',
                                        message: 'Design a protocol and share it to contribute',
                                      ),
                                    )
                                  else
                                    ...communityProtocols.map((p) => _buildCommunityProtocolCard(p)),
                                ],
                              ),
                          ],
                        ),
                      ),
                      // Scanlines overlay
                      Positioned.fill(
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
        ],
      ),
    );
  }
}

class _ScanlinesPainter extends CustomPainter {
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
