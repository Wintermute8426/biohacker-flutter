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

  // Protocol stacks - each protocol contains multiple peptides
  final Map<String, Map<String, dynamic>> protocolStacks = {
    'bh-injury-recovery': {
      'name': 'INJURY RECOVERY STACK',
      'description': 'Complete injury recovery combining BPC-157 for tissue repair + TB-500 for regeneration. Synergistic stack for joint damage, muscle strains, and serious injuries.',
      'peptides': [
        {'name': 'BPC-157', 'dose': 250, 'route': 'SC', 'frequency': '1x daily', 'weeks': 12},
        {'name': 'TB-500', 'dose': 5, 'route': 'SC', 'frequency': '2x weekly', 'weeks': 12},
      ],
    },
    'bh-hair-health': {
      'name': 'HAIR HEALTH STACK',
      'description': 'Hair growth optimization combining GHK-Cu for collagen synthesis + Semax for follicle activation. Best results over 12-16 weeks with consistent use.',
      'peptides': [
        {'name': 'GHK-Cu', 'dose': 5, 'route': 'SC', 'frequency': '1x daily', 'weeks': 16},
        {'name': 'Semax', 'dose': 5, 'route': 'Intranasal', 'frequency': '2x daily', 'weeks': 16},
      ],
    },
    'bh-longevity': {
      'name': 'LONGEVITY STACK',
      'description': 'Ultimate anti-aging combining Epitalon for telomere extension + thymic peptides for immune support. Comprehensive cellular rejuvenation protocol.',
      'peptides': [
        {'name': 'Epitalon', 'dose': 1, 'route': 'SC', 'frequency': '1x daily', 'weeks': 12},
        {'name': 'Thymosin Alpha-1', 'dose': 1.6, 'route': 'SC', 'frequency': '3x weekly', 'weeks': 12},
      ],
    },
    'bh-preventative-health': {
      'name': 'PREVENTATIVE HEALTH STACK',
      'description': 'Proactive immune optimization for year-round wellness. Thymosin Alpha-1 strengthens immune defenses before illness onset. Use seasonally or continuously.',
      'peptides': [
        {'name': 'Thymosin Alpha-1', 'dose': 1.6, 'route': 'SC', 'frequency': '3x weekly', 'weeks': 10},
      ],
    },
    'bh-skin-recovery': {
      'name': 'SKIN RECOVERY STACK',
      'description': 'Skin regeneration combining GHK-Cu for collagen + BPC-157 for tissue repair. Ideal for acne recovery, wound healing, and skin elasticity.',
      'peptides': [
        {'name': 'GHK-Cu', 'dose': 5, 'route': 'SC', 'frequency': '1x daily', 'weeks': 12},
        {'name': 'BPC-157', 'dose': 250, 'route': 'SC', 'frequency': '1x daily', 'weeks': 12},
      ],
    },
  };

  // Convert protocol stacks to display format
  List<Map<String, dynamic>> getBiohackerProtocols() {
    return protocolStacks.entries.map((e) => {
      'id': e.key,
      ...e.value,
    }).toList();
  }

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
      builder: (context) => ScanlineOverlay(
        child: StatefulBuilder(
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
                style: const TextStyle(color: AppColors.textLight),
                decoration: InputDecoration(
                  labelText: 'Protocol Name',
                  labelStyle: TextStyle(color: AppColors.primary),
                  border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: const TextStyle(color: AppColors.textLight),
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
                items: PEPTIDE_LIST.map((p) => DropdownMenuItem(value: p, child: Text(p, style: TextStyle(color: AppColors.textLight)))).toList(),
                onChanged: (val) => setModalState(() => selectedPeptide = val!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: doseController,
                style: const TextStyle(color: AppColors.textLight),
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
                    .map((r) => DropdownMenuItem(value: r, child: Text(r, style: TextStyle(color: AppColors.textLight))))
                    .toList(),
                onChanged: (val) => setModalState(() => selectedRoute = val!),
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: selectedFrequency,
                isExpanded: true,
                dropdownColor: AppColors.surface,
                items: ['1x daily', '2x daily', '1x weekly', '2x weekly', '3x weekly']
                    .map((f) => DropdownMenuItem(value: f, child: Text(f, style: TextStyle(color: AppColors.textLight))))
                    .toList(),
                onChanged: (val) => setModalState(() => selectedFrequency = val!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weeksController,
                style: const TextStyle(color: AppColors.textLight),
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
      ),
    );
  }

  void _showStartFromProtocolModal(ProtocolTemplate protocol) {
    final durationController = TextEditingController(text: protocol.durationWeeks.toString());

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
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
              decoration: WintermmuteStyles.cardDecoration,
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
              style: const TextStyle(color: AppColors.textLight),
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
      ),
    );
  }

  void _showStackDetail(Map<String, dynamic> stack) {
    final peptides = stack['peptides'] as List<dynamic>;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    (stack['name'] as String).toUpperCase(),
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

            // Stack description
            Container(
              padding: const EdgeInsets.all(14),
              decoration: WintermmuteStyles.cardDecoration,
              child: Text(
                stack['description'] as String,
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Peptides in stack
            Text(
              'PEPTIDES IN STACK',
              style: TextStyle(
                color: AppColors.textMid,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            ...peptides.map((pep) {
              final peptide = pep as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: WintermmuteStyles.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      peptide['name'] as String,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${peptide['dose']}mg', style: TextStyle(color: AppColors.textMid, fontSize: 11)),
                        Text(peptide['route'] as String, style: TextStyle(color: AppColors.textMid, fontSize: 11)),
                        Text(peptide['frequency'] as String, style: TextStyle(color: AppColors.textMid, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),

            // Start button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✓ Stack "${stack['name']}" — create individual cycles for each peptide'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('CREATE STACK', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
          ),
        ),
      ),
    );
  }

  void _showProtocolDetail(ProtocolTemplate protocol) {
    _showStackDetail({});
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
    final peptideNames = peptides.map((p) => (p as Map<String, dynamic>)['name']).join(' + ');

    return GestureDetector(
      onTap: () => _showStackDetail(stack),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A).withOpacity(0.85),
          border: Border.all(color: AppColors.primary.withOpacity(0.25), width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stack['name'] as String,
              style: TextStyle(
                color: AppColors.primary,
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Peptides: $peptideNames',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              stack['description'] as String,
              style: TextStyle(
                color: AppColors.textDim,
                fontSize: 11,
                fontStyle: FontStyle.italic,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showStackDetail(stack),
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
                    onPressed: () => _showStackDetail(stack),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface.withOpacity(0.15), // Matte style
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                    ),
                    child: Text(
                      'START',
                      style: TextStyle(
                        color: AppColors.textLight,
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

  Widget _buildProtocolCard(ProtocolTemplate protocol) {
    return GestureDetector(
      onTap: () => _showProtocolDetail(protocol),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A).withOpacity(0.85),
          border: Border.all(color: AppColors.accent.withOpacity(0.25), width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.all(16),
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
                          color: AppColors.accent,
                          fontFamily: 'monospace',
                          fontSize: 12,
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
                      color: AppColors.surface.withOpacity(0.15),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'Used ${protocol.usageCount}x',
                      style: TextStyle(
                        color: AppColors.textMid,
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
                  decoration: TextDecoration.none,
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
                      backgroundColor: AppColors.surface.withOpacity(0.15), // Matte style
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                    ),
                    child: Text(
                      'START',
                      style: TextStyle(
                        color: AppColors.textLight,
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
            floatingActionButton: FloatingActionButton(
              onPressed: _showCreateProtocolModal,
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.add),
            ),
            body: Column(
            children: [
              // Header using reusable widget
              AppHeader(
                icon: Icons.list_alt,
                iconColor: WintermmuteStyles.colorGreen,
                title: 'PROTOCOLS',
              ),
              // Content
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
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
                            // Biohacker Protocols (Stacks)
                            _buildSectionHeader('BIOHACKER PROTOCOL STACKS', Icons.layers, AppColors.primary),
                            const SizedBox(height: 12),
                            ...getBiohackerProtocols().map((stack) => _buildStackCard(stack)),
                            const SizedBox(height: 20),

                            // My Protocols
                            _buildSectionHeader('MY PROTOCOLS', Icons.person, AppColors.accent),
                            const SizedBox(height: 12),
                            if (myProtocols.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: EmptyState(
                                  icon: Icons.add_circle_outline,
                                  title: 'No custom protocols',
                                  message: 'Create your own protocol templates',
                                ),
                              )
                            else
                              ...myProtocols.map((protocol) => _buildProtocolCard(protocol)),
                            const SizedBox(height: 20),

                            // Community Protocols
                            _buildSectionHeader('COMMUNITY PROTOCOLS', Icons.people, AppColors.secondary),
                            const SizedBox(height: 12),
                            if (communityProtocols.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: EmptyState(
                                  icon: Icons.people_outline,
                                  title: 'No community protocols',
                                  message: 'Check back later for shared protocols',
                                ),
                              )
                            else
                              ...communityProtocols.map((protocol) => _buildProtocolCard(protocol)),
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
