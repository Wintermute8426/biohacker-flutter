import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../services/protocol_templates_database.dart';
import '../services/cycles_database.dart';
import '../data/peptides.dart';

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

  // Biohacker official protocols
  final List<ProtocolTemplate> biohackerProtocols = [
    ProtocolTemplate(
      id: 'bh-bpc157',
      name: 'BPC-157 Recovery Stack',
      description: 'Tissue repair and recovery protocol for injury healing',
      peptideName: 'BPC-157',
      dose: 250,
      route: 'SC (subcutaneous)',
      frequency: '1x daily',
      durationWeeks: 8,
      usageCount: 0,
      isPublic: true,
    ),
    ProtocolTemplate(
      id: 'bh-tb500',
      name: 'TB-500 Healing Protocol',
      description: 'Thymosin Beta-4 for accelerated tissue repair',
      peptideName: 'TB-500',
      dose: 5,
      route: 'SC (subcutaneous)',
      frequency: '2x weekly',
      durationWeeks: 12,
      usageCount: 0,
      isPublic: true,
    ),
    ProtocolTemplate(
      id: 'bh-cjc1295',
      name: 'CJC-1295 Growth Stack',
      description: 'Growth hormone stimulation for muscle and strength',
      peptideName: 'CJC-1295 (no DAC)',
      dose: 100,
      route: 'SC (subcutaneous)',
      frequency: '1x daily',
      durationWeeks: 16,
      usageCount: 0,
      isPublic: true,
    ),
    ProtocolTemplate(
      id: 'bh-semax',
      name: 'Semax Cognitive Stack',
      description: 'Cognitive enhancement and neuroprotection',
      peptideName: 'Semax',
      dose: 5,
      route: 'Intranasal',
      frequency: '2x daily',
      durationWeeks: 8,
      usageCount: 0,
      isPublic: true,
    ),
    ProtocolTemplate(
      id: 'bh-melanotan',
      name: 'Melanotan II Aesthetic',
      description: 'UV-free tanning and aesthetic enhancement',
      peptideName: 'Melanotan II',
      dose: 1,
      route: 'SC (subcutaneous)',
      frequency: '3x weekly',
      durationWeeks: 10,
      usageCount: 0,
      isPublic: true,
    ),
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

  void _showCreateProtocolModal() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final doseController = TextEditingController();
    final weeksController = TextEditingController(text: '8');
    String selectedPeptide = PEPTIDE_LIST.first;
    String selectedRoute = 'SC (subcutaneous)';
    String selectedFrequency = '1x weekly';
    bool makePublic = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
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
                'CREATE PROTOCOL',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Protocol Name',
                  labelStyle: TextStyle(color: AppColors.primary),
                  border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: AppColors.primary),
                  border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: selectedPeptide,
                isExpanded: true,
                dropdownColor: AppColors.surface,
                items: PEPTIDE_LIST.map((p) => DropdownMenuItem(value: p, child: Text(p, style: TextStyle(color: Colors.white)))).toList(),
                onChanged: (val) => setModalState(() => selectedPeptide = val!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: doseController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Dose (mg)',
                  labelStyle: TextStyle(color: AppColors.primary),
                  border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: selectedRoute,
                isExpanded: true,
                dropdownColor: AppColors.surface,
                items: ['SC (subcutaneous)', 'IM (intramuscular)', 'IV (intravenous)', 'Intranasal', 'Oral']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r, style: TextStyle(color: Colors.white))))
                    .toList(),
                onChanged: (val) => setModalState(() => selectedRoute = val!),
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: selectedFrequency,
                isExpanded: true,
                dropdownColor: AppColors.surface,
                items: ['1x daily', '2x daily', '1x weekly', '2x weekly', '3x weekly']
                    .map((f) => DropdownMenuItem(value: f, child: Text(f, style: TextStyle(color: Colors.white))))
                    .toList(),
                onChanged: (val) => setModalState(() => selectedFrequency = val!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weeksController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Duration (weeks)',
                  labelStyle: TextStyle(color: AppColors.primary),
                  border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: makePublic,
                    onChanged: (val) => setModalState(() => makePublic = val ?? false),
                    activeColor: AppColors.primary,
                  ),
                  Text(
                    'Share publicly (Community)',
                    style: TextStyle(color: AppColors.textMid, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () async {
                    final dose = double.tryParse(doseController.text) ?? 1;
                    final weeks = int.tryParse(weeksController.text) ?? 8;

                    await protocolDb.saveProtocol(
                      name: nameController.text,
                      description: descController.text.isEmpty ? null : descController.text,
                      peptideName: selectedPeptide,
                      dose: dose,
                      route: selectedRoute,
                      frequency: selectedFrequency,
                      durationWeeks: weeks,
                      isPublic: makePublic,
                    );

                    Navigator.pop(context);
                    _loadProtocols();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✓ Protocol created: ${nameController.text}'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('CREATE PROTOCOL', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showStartFromProtocolModal(ProtocolTemplate protocol) {
    final durationController = TextEditingController(text: protocol.durationWeeks.toString());

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
              'START FROM PROTOCOL',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              protocol.name,
              style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            if (protocol.description != null) ...[
              const SizedBox(height: 8),
              Text(protocol.description!, style: TextStyle(color: AppColors.textMid, fontSize: 12)),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${protocol.peptideName} • ${protocol.dose}mg',
                    style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Route: ${protocol.route}', style: TextStyle(color: AppColors.textMid, fontSize: 11)),
                  Text('Frequency: ${protocol.frequency}', style: TextStyle(color: AppColors.textMid, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: durationController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Duration (weeks)',
                labelStyle: TextStyle(color: AppColors.primary),
                border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () async {
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('START CYCLE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocolCard(ProtocolTemplate protocol) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      protocol.name,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${protocol.peptideName} • ${protocol.dose}mg • ${protocol.frequency}',
                      style: TextStyle(
                        color: AppColors.textMid,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (protocol.usageCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    'Used ${protocol.usageCount}x',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (protocol.description != null) ...[
            const SizedBox(height: 8),
            Text(
              protocol.description!,
              style: TextStyle(
                color: AppColors.textDim,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: () => _showStartFromProtocolModal(protocol),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
              ),
              child: Text(
                'START CYCLE',
                style: TextStyle(
                  color: AppColors.background,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PROTOCOLS',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                ElevatedButton(
                  onPressed: _showCreateProtocolModal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                  ),
                  child: Text(
                    'NEW',
                    style: TextStyle(color: AppColors.background, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
                  // Biohacker Protocols
                  Text(
                    'BIOHACKER PROTOCOLS',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...biohackerProtocols.map((protocol) => _buildProtocolCard(protocol)),
                  const SizedBox(height: 24),

                  // My Protocols
                  if (myProtocols.isNotEmpty) ...[
                    Text(
                      'MY PROTOCOLS',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...myProtocols.map((protocol) => _buildProtocolCard(protocol)),
                    const SizedBox(height: 24),
                  ],

                  // Community Protocols
                  if (communityProtocols.isNotEmpty) ...[
                    Text(
                      'COMMUNITY PROTOCOLS',
                      style: TextStyle(
                        color: const Color(0xFF00FFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...communityProtocols.map((protocol) => _buildProtocolCard(protocol)),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
