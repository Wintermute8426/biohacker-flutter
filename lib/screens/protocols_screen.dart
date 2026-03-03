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

  // Biohacker official protocols with detailed descriptions
  final Map<String, String> protocolDetails = {
    'bh-bpc157': 'BPC-157 (Body Protection Compound-157) is a pentadecapeptide that accelerates healing of damaged tissues, improves gut health, and promotes recovery from injuries. Ideal for joint pain, tendon damage, and muscle strains. Works best when combined with proper rest and mobility work.',
    'bh-tb500': 'Thymosin Beta-4 (TB-500) is a naturally occurring peptide that promotes tissue repair and regeneration. Excellent for muscle recovery, wound healing, and joint support. Can be stacked with BPC-157 for synergistic effects.',
    'bh-ghkcu': 'GHK-Cu (Copper Tripeptide) stimulates collagen synthesis and skin regeneration. Ideal for hair growth, skin elasticity, and anti-aging. Can be used topically or systemically for enhanced results.',
    'bh-epitalon': 'Epitalon is a pineal peptide that activates telomerase and extends telomere length. Promotes cellular rejuvenation, improves sleep quality, and supports immune function. The ultimate longevity protocol.',
    'bh-thymosin': 'Thymosin Alpha-1 enhances immune function and supports vaccine response. Essential for preventative health and immune optimization. Particularly useful during cold/flu season.',
    'bh-full-recovery': 'Complete injury recovery protocol combining BPC-157 + TB-500 for maximum healing. Targets joint repair, muscle recovery, and tissue regeneration. 12-week protocol for serious injuries.',
    'bh-hair-growth': 'Hair growth protocol using GHK-Cu + Semax. Stimulates follicle activation while improving scalp health and circulation. Best results over 12-16 weeks.',
    'bh-longevity': 'Ultimate longevity stack: Epitalon for telomere extension + NAD+ for cellular energy + immune support. Comprehensive anti-aging protocol.',
    'bh-immune-boost': 'Preventative immune protocol: Thymosin Alpha-1 + seasonal immune support. Strengthens immune defenses before illness onset.',
  };

  final List<ProtocolTemplate> biohackerProtocols = [
    ProtocolTemplate(
      id: 'bh-bpc157',
      name: 'BPC-157 Recovery',
      description: 'Tissue repair and injury healing',
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
      name: 'TB-500 Healing',
      description: 'Accelerated tissue and muscle recovery',
      peptideName: 'TB-500',
      dose: 5,
      route: 'SC (subcutaneous)',
      frequency: '2x weekly',
      durationWeeks: 12,
      usageCount: 0,
      isPublic: true,
    ),
    ProtocolTemplate(
      id: 'bh-ghkcu',
      name: 'GHK-Cu Hair & Skin',
      description: 'Collagen synthesis for hair and skin regeneration',
      peptideName: 'GHK-Cu',
      dose: 5,
      route: 'SC (subcutaneous)',
      frequency: '1x daily',
      durationWeeks: 12,
      usageCount: 0,
      isPublic: true,
    ),
    ProtocolTemplate(
      id: 'bh-epitalon',
      name: 'Epitalon Longevity',
      description: 'Telomere extension and cellular rejuvenation',
      peptideName: 'Epitalon',
      dose: 1,
      route: 'SC (subcutaneous)',
      frequency: '1x daily',
      durationWeeks: 10,
      usageCount: 0,
      isPublic: true,
    ),
    ProtocolTemplate(
      id: 'bh-thymosin',
      name: 'Thymosin Alpha-1 Immune',
      description: 'Preventative immune optimization',
      peptideName: 'Thymosin Alpha-1',
      dose: 1.6,
      route: 'SC (subcutaneous)',
      frequency: '3x weekly',
      durationWeeks: 8,
      usageCount: 0,
      isPublic: true,
    ),
    ProtocolTemplate(
      id: 'bh-full-recovery',
      name: 'STACK: Complete Injury Recovery',
      description: 'BPC-157 + TB-500 for maximum healing potential',
      peptideName: 'BPC-157 + TB-500',
      dose: 250,
      route: 'SC (subcutaneous)',
      frequency: '1x daily + 2x weekly',
      durationWeeks: 12,
      usageCount: 0,
      isPublic: true,
    ),
    ProtocolTemplate(
      id: 'bh-hair-growth',
      name: 'STACK: Hair Growth Protocol',
      description: 'GHK-Cu + Semax for follicle activation',
      peptideName: 'GHK-Cu + Semax',
      dose: 5,
      route: 'SC + Intranasal',
      frequency: '1x daily',
      durationWeeks: 16,
      usageCount: 0,
      isPublic: true,
    ),
    ProtocolTemplate(
      id: 'bh-longevity',
      name: 'STACK: Ultimate Longevity',
      description: 'Epitalon for telomeres + NAD+ for energy',
      peptideName: 'Epitalon',
      dose: 1,
      route: 'SC (subcutaneous)',
      frequency: '1x daily',
      durationWeeks: 12,
      usageCount: 0,
      isPublic: true,
    ),
    ProtocolTemplate(
      id: 'bh-immune-boost',
      name: 'Preventative Immune Protocol',
      description: 'Strengthen defenses before illness onset',
      peptideName: 'Thymosin Alpha-1',
      dose: 1.6,
      route: 'SC (subcutaneous)',
      frequency: '3x weekly',
      durationWeeks: 8,
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

  void _showProtocolDetail(ProtocolTemplate protocol) {
    final detail = protocolDetails[protocol.id] ?? protocol.description ?? 'No details available.';

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    protocol.name.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  color: AppColors.textMid,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Protocol details
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                detail,
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Specs
            Text(
              'PROTOCOL SPECS',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Column(
                children: [
                  _buildSpecRow('Peptide(s)', protocol.peptideName),
                  _buildSpecRow('Dose', '${protocol.dose}mg'),
                  _buildSpecRow('Route', protocol.route),
                  _buildSpecRow('Frequency', protocol.frequency),
                  _buildSpecRow('Duration', '${protocol.durationWeeks} weeks'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Start button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showStartFromProtocolModal(protocol);
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

  Widget _buildSpecRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMid,
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolCard(ProtocolTemplate protocol) {
    return GestureDetector(
      onTap: () => _showProtocolDetail(protocol),
      child: Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showProtocolDetail(protocol),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                    ),
                    child: Text(
                      'DETAILS',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showStartFromProtocolModal(protocol),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                    ),
                    child: Text(
                      'START',
                      style: TextStyle(
                        color: AppColors.background,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
