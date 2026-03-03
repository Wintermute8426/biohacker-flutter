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
  List<ProtocolTemplate> protocols = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProtocols();
  }

  void _loadProtocols() async {
    setState(() => isLoading = true);
    final templates = await protocolDb.getUserProtocols();
    setState(() {
      protocols = templates;
      isLoading = false;
    });
  }

  void _showSaveProtocolModal(String peptideName, double dose, String route,
      String frequency, int durationWeeks) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

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
                Text(
                  'SAVE AS PROTOCOL',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
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
            const SizedBox(height: 16),
            Text(
              'Protocol Name',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g., "BPC-157 Recovery Stack"',
                hintStyle: TextStyle(color: AppColors.textDim),
                border:
                    OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Description (optional)',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Notes about this protocol...',
                hintStyle: TextStyle(color: AppColors.textDim),
                border:
                    OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
              ),
            ),
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
                  Text('Protocol Details:', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Peptide: $peptideName', style: TextStyle(color: AppColors.textMid, fontSize: 11)),
                  Text('Dose: ${dose}mg', style: TextStyle(color: AppColors.textMid, fontSize: 11)),
                  Text('Route: $route', style: TextStyle(color: AppColors.textMid, fontSize: 11)),
                  Text('Frequency: $frequency', style: TextStyle(color: AppColors.textMid, fontSize: 11)),
                  Text('Duration: ${durationWeeks} weeks', style: TextStyle(color: AppColors.textMid, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
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
                    peptideName: peptideName,
                    dose: dose,
                    route: route,
                    frequency: frequency,
                    durationWeeks: durationWeeks,
                  );

                  Navigator.pop(context);
                  _loadProtocols();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✓ Protocol saved: ${nameController.text}'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('SAVE PROTOCOL', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                IconButton(
                  icon: const Icon(Icons.close),
                  color: AppColors.textMid,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              protocol.name,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (protocol.description != null) ...[
              const SizedBox(height: 8),
              Text(
                protocol.description!,
                style: TextStyle(color: AppColors.textMid, fontSize: 12),
              ),
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
            Text(
              'Duration (weeks)',
              style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: durationController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 8),
            Text(
              'Saved cycle templates for quick reuse',
              style: TextStyle(color: AppColors.textMid, fontSize: 12),
            ),
            const SizedBox(height: 24),
            if (isLoading)
              Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            else if (protocols.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    'No protocols saved yet.\n\nComplete a cycle and tap "Save as Protocol" to create templates.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMid, fontSize: 12),
                  ),
                ),
              )
            else
              Column(
                children: [
                  ...protocols.map((protocol) {
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                ),
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
                  }),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
