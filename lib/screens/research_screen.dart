import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../data/peptide_library.dart';
import '../widgets/city_background.dart';
import '../widgets/cyberpunk_rain.dart';
import '../widgets/app_header.dart';
import '../widgets/full_screen_modal.dart';

class ResearchScreen extends StatefulWidget {
  const ResearchScreen({Key? key}) : super(key: key);

  @override
  State<ResearchScreen> createState() => _ResearchScreenState();
}

class _ResearchScreenState extends State<ResearchScreen> {
  final _searchController = TextEditingController();
  late List<PeptideInfo> _displayedPeptides;
  String? _selectedCategory;
  int _tabIndex = 0; // 0 = Peptides, 1 = Quality Guide, 2 = Methodology

  @override
  void initState() {
    super.initState();
    _displayedPeptides = PEPTIDE_LIBRARY.values.toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (_selectedCategory != null) {
        final byCat = getPeptidesByCategory(_selectedCategory!);
        _displayedPeptides = byCat
            .where((p) =>
                p.name.toLowerCase().contains(query.toLowerCase()) ||
                p.description.toLowerCase().contains(query.toLowerCase()))
            .toList();
      } else {
        _displayedPeptides = searchPeptides(query);
      }
    });
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = category;
      if (category == null) {
        _displayedPeptides = searchPeptides(_searchController.text);
      } else {
        final byCat = getPeptidesByCategory(category);
        _displayedPeptides = byCat
            .where((p) =>
                p.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                p.description.toLowerCase().contains(_searchController.text.toLowerCase()))
            .toList();
      }
    });
  }

  String _getFullRouteName(String route) {
    final routeMap = {
      'SC': 'Subcutaneous',
      'IM': 'Intramuscular',
      'Oral': 'Oral',
      'IV': 'Intravenous',
    };
    return routeMap[route] ?? route;
  }

  void _showPeptideDetails(PeptideInfo peptide) {
    final peptideId = 'PEPT-${peptide.name.hashCode.abs().toString().substring(0, 3)}';
    
    FullScreenModal.show(
      context: context,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 32),
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.black,
            ),
            child: Stack(
              children: [
                // Top-left: Category badge
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withOpacity(0.15),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.category, color: AppColors.amber.withOpacity(0.8), size: 10),
                        SizedBox(width: 4),
                        Text(
                          peptide.category.toUpperCase(),
                          style: TextStyle(
                            color: AppColors.amber.withOpacity(0.85),
                            fontSize: 8,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Top-right: Peptide ID badge
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: const BoxDecoration(
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.science, color: AppColors.amber.withOpacity(0.8), size: 10),
                        SizedBox(width: 3),
                        Text(
                          peptideId,
                          style: TextStyle(
                            color: AppColors.amber.withOpacity(0.9),
                            fontSize: 8,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Peptide name (below badges)
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Text(
                    peptide.name.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.amber,
                      fontSize: 18,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ===== > OVERVIEW =====
          _buildDetailSection('OVERVIEW', Icons.info_outline, AppColors.amber,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peptide.description,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 13,
                    height: 1.5,
                    decoration: TextDecoration.none,
                  ),
                ),
                if (peptide.effects.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(width: 3, height: 11, color: AppColors.accent.withOpacity(0.6)),
                      const SizedBox(width: 6),
                      Text(
                        'EFFECTS',
                        style: TextStyle(color: AppColors.accent, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold, letterSpacing: 1, decoration: TextDecoration.none),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...peptide.effects.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(_getEffectIcon(item), color: AppColors.accent.withOpacity(0.7), size: 13),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(item, style: const TextStyle(color: AppColors.textLight, fontSize: 12, fontFamily: 'monospace', decoration: TextDecoration.none, height: 1.3)),
                        ),
                      ],
                    ),
                  )),
                ],
                if (peptide.sideEffects.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(width: 3, height: 11, color: AppColors.error.withOpacity(0.6)),
                      const SizedBox(width: 6),
                      Text(
                        'POTENTIAL SIDE EFFECTS',
                        style: TextStyle(color: AppColors.error.withOpacity(0.8), fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold, letterSpacing: 1, decoration: TextDecoration.none),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...peptide.sideEffects.take(3).map((effect) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('▸ $effect', style: TextStyle(color: AppColors.textMid, fontSize: 11, fontFamily: 'monospace', decoration: TextDecoration.none)),
                  )),
                ],
              ],
            ),
          ),

          // ===== > QUALITY METRICS =====
          _buildDetailSection('QUALITY METRICS', Icons.assessment, AppColors.amber,
            _buildPepScoreContent(peptide),
          ),

          // ===== > PROTOCOL DATA =====
          _buildDetailSection('PROTOCOL DATA', Icons.medication, AppColors.amber,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dosing
                Row(
                  children: [
                    Container(width: 3, height: 11, color: AppColors.amber.withOpacity(0.6)),
                    const SizedBox(width: 6),
                    Text('DOSING', style: TextStyle(color: AppColors.amber, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold, letterSpacing: 1, decoration: TextDecoration.none)),
                  ],
                ),
                const SizedBox(height: 8),
                ...[
                  '${peptide.commonDoseRange} ${peptide.unit}',
                  'Timing: ${peptide.timing}',
                  'Route: ${_getFullRouteName(peptide.route)}',
                ].map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('▸', style: TextStyle(color: AppColors.amber, fontSize: 12, decoration: TextDecoration.none)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item, style: const TextStyle(color: AppColors.textMid, fontSize: 12, fontFamily: 'monospace', height: 1.5, decoration: TextDecoration.none))),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
                // Safety
                Row(
                  children: [
                    Container(width: 3, height: 11, color: AppColors.primary.withOpacity(0.6)),
                    const SizedBox(width: 6),
                    Text('SAFETY', style: TextStyle(color: AppColors.primary, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold, letterSpacing: 1, decoration: TextDecoration.none)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('▸', style: TextStyle(color: AppColors.primary, fontSize: 12, decoration: TextDecoration.none)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(peptide.safetyNotes, style: const TextStyle(color: AppColors.textMid, fontSize: 12, fontFamily: 'monospace', height: 1.5, decoration: TextDecoration.none))),
                  ],
                ),
              ],
            ),
          ),

          // ===== > INTELLIGENCE =====
          if (peptide.studyLinks.isNotEmpty)
            _buildIntelligenceSection(peptide),

          // Footer with dystopian data strip
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF050505),
              ),
              child: Column(
                children: [
                  // Top hex strip
                  Text(
                    '0x${peptideId.hashCode.abs().toRadixString(16).toUpperCase().padLeft(8, '0')} • DATA CLASSIFIED • CORPO-ACCESS ONLY',
                    style: TextStyle(
                      color: AppColors.amber.withOpacity(0.5),
                      fontSize: 8,
                      fontFamily: 'monospace',
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Terminal-style data row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'REF: ${peptideId}',
                        style: TextStyle(
                          color: AppColors.amber.withOpacity(0.6),
                          fontSize: 9,
                          fontFamily: 'monospace',
                          decoration: TextDecoration.none,
                        ),
                      ),
                      Text(
                        '■ VERIFIED',
                        style: TextStyle(
                          color: AppColors.accent.withOpacity(0.7),
                          fontSize: 9,
                          fontFamily: 'monospace',
                          decoration: TextDecoration.none,
                        ),
                      ),
                      Text(
                        'v2.6.${DateTime.now().year}',
                        style: TextStyle(
                          color: AppColors.amber.withOpacity(0.6),
                          fontSize: 9,
                          fontFamily: 'monospace',
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Bottom hex strip
                  Text(
                    '>>> END TRANSMISSION • LIBERATED: 2026 • SOVEREIGN ACCESS <<<',
                    style: TextStyle(
                      color: AppColors.amber.withOpacity(0.5),
                      fontSize: 8,
                      fontFamily: 'monospace',
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  // PepScore content (used inside > QUALITY METRICS section)
  Widget _buildPepScoreContent(PeptideInfo peptide) {
    final score = peptide.pepScore;
    final overall = score.overallScore;
    final rating = score.rating;

    Color scoreColor;
    if (rating == 'Excellent') {
      scoreColor = AppColors.amber;
    } else if (rating == 'Good') {
      scoreColor = const Color(0xFFFFD740);
    } else if (rating == 'Fair') {
      scoreColor = AppColors.error;
    } else {
      scoreColor = AppColors.error;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating badge + score
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$overall',
                  style: TextStyle(color: scoreColor, fontSize: 36, fontFamily: 'monospace', fontWeight: FontWeight.bold, decoration: TextDecoration.none),
                ),
                Text(
                  '/100',
                  style: TextStyle(color: scoreColor.withOpacity(0.6), fontSize: 18, fontFamily: 'monospace', decoration: TextDecoration.none),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: const BoxDecoration(
              ),
              child: Text(rating.toUpperCase(), style: TextStyle(color: scoreColor, fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Progress bar
        LinearProgressIndicator(
          value: overall / 100,
          minHeight: 6,
          backgroundColor: Colors.black,
          valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
        ),
        const SizedBox(height: 16),

        Text('SCORE BREAKDOWN', style: TextStyle(color: AppColors.textDim, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold, letterSpacing: 1, decoration: TextDecoration.none)),
        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildEnhancedScoreMetric('Publication', score.publication, 25),
            _buildEnhancedScoreMetric('Evidence', score.evidence, 35),
            _buildEnhancedScoreMetric('Methodology', score.methodology, 25),
            _buildEnhancedScoreMetric('Relevance', score.relevance, 15),
          ],
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.accent; // Green
    if (score >= 60) return const Color(0xFFFFD740); // Yellow
    return AppColors.error; // Red
  }

  Widget _buildEnhancedScoreMetric(String label, int score, int weight) {
    final metricColor = _getScoreColor(score);
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textMid,
                  fontSize: 10,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
              Text(
                '${score}%',
                style: TextStyle(
                  color: metricColor,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Weight: $weight%',
            style: TextStyle(
              color: AppColors.textDim,
              fontSize: 8,
              fontFamily: 'monospace',
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  // ===== PROFILE-STYLE SECTION CARD (terminal aesthetic) =====
  Widget _buildDetailSection(String title, IconData icon, Color accentColor, Widget child) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _ScanlinesPainter())),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 4, height: 14, color: accentColor.withOpacity(0.6)),
                  const SizedBox(width: 8),
                  Icon(icon, color: accentColor, size: 13),
                  const SizedBox(width: 8),
                  Text(
                    '> $title',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ],
      ),
    );
  }

  // Full-width section card (for Dosing, Safety, etc.)
  Widget _buildFullWidthSection(String title, IconData icon, List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.amber.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Scanlines overlay
            Positioned.fill(
              child: CustomPaint(
                painter: _ScanlinesPainter(),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: AppColors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.amber.withOpacity(0.7),
                        fontSize: 11,
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '▸',
                        style: TextStyle(
                          color: AppColors.amber,
                          fontSize: 12,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            color: AppColors.textMid,
                            fontSize: 12,
                            fontFamily: 'monospace',
                            height: 1.5,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Effects section with bordered chips
  IconData _getEffectIcon(String effect) {
    final effectLower = effect.toLowerCase();
    if (effectLower.contains('growth') || effectLower.contains('gh') || effectLower.contains('hormone')) return Icons.trending_up;
    if (effectLower.contains('muscle') || effectLower.contains('protein')) return Icons.fitness_center;
    if (effectLower.contains('wound') || effectLower.contains('healing') || effectLower.contains('repair')) return Icons.healing;
    if (effectLower.contains('tendon') || effectLower.contains('ligament') || effectLower.contains('bone')) return Icons.accessibility_new;
    if (effectLower.contains('inflammation') || effectLower.contains('inflammatory')) return Icons.local_fire_department;
    if (effectLower.contains('angiogenesis') || effectLower.contains('vascular')) return Icons.water_drop;
    if (effectLower.contains('recovery')) return Icons.refresh;
    if (effectLower.contains('fat') || effectLower.contains('metabolism')) return Icons.whatshot;
    if (effectLower.contains('sleep')) return Icons.bedtime;
    if (effectLower.contains('neuro') || effectLower.contains('brain')) return Icons.psychology;
    if (effectLower.contains('collagen')) return Icons.layers;
    if (effectLower.contains('igf') || effectLower.contains('synthesis')) return Icons.science;
    return Icons.check_circle_outline;
  }

  Widget _buildEffectsSection(String title, List<String> items, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.2),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ScanlinesPainter(),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      title == 'EFFECTS' ? Icons.auto_awesome : Icons.warning,
                      color: accentColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        color: accentColor.withOpacity(0.7),
                        fontSize: 10,
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Clean list with icons (no borders per item)
                ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _getEffectIcon(item),
                        color: accentColor.withOpacity(0.7), // Force rebuild: amber icons
                        size: 14,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 12,
                            fontFamily: 'monospace',
                            decoration: TextDecoration.none,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Study card with full-width styling
  Widget _buildStudyCard(StudyLink study) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Link: ${study.url}'),
                duration: const Duration(seconds: 1),
                backgroundColor: AppColors.amber.withOpacity(0.9),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.2),
            ),
            child: Stack(
              children: [
                // Scanlines overlay
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ScanlinesPainter(),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Study title
                    Text(
                      study.title,
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Source and year
                    Row(
                      children: [
                        Icon(
                          Icons.source,
                          color: AppColors.amber.withOpacity(0.7),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          study.source,
                          style: TextStyle(
                            color: AppColors.textMid,
                            fontSize: 11,
                            fontFamily: 'monospace',
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.calendar_today,
                          color: AppColors.amber.withOpacity(0.7),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${study.year}',
                          style: TextStyle(
                            color: AppColors.textMid,
                            fontSize: 11,
                            fontFamily: 'monospace',
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const Spacer(),
                        // View study button
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: const BoxDecoration(
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.link,
                                color: AppColors.amber,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'VIEW',
                                style: TextStyle(
                                  color: AppColors.amber,
                                  fontSize: 9,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPepScoreMethodology() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PEPSCORE METHODOLOGY',
            style: TextStyle(
              color: AppColors.textMid,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'PepScore is a research quality framework that evaluates peptide evidence across 4 dimensions:',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
              height: 1.5,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 20),

          _buildMetricExplanation(
            'PUBLICATION (25%)',
            'Peer-reviewed journal citations and mainstream scientific presence. Higher = more published research.',
            AppColors.amber,
          ),
          _buildMetricExplanation(
            'EVIDENCE (35%)',
            'Quality of human clinical data. Highest weight because real-world results matter most.',
            AppColors.amber,
          ),
          _buildMetricExplanation(
            'METHODOLOGY (25%)',
            'Research rigor and experimental design. Proper controls, sample sizes, and statistical analysis.',
            Color(0xFFFFB700),
          ),
          _buildMetricExplanation(
            'RELEVANCE (15%)',
            'Applicability to human biohacking and health optimization. Theory is great, but practical benefit matters.',
            AppColors.amber,
          ),

          const SizedBox(height: 24),
          Text(
            'OVERALL SCORE',
            style: TextStyle(
              color: AppColors.textMid,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '(Publication × 0.25) + (Evidence × 0.35) + (Methodology × 0.25) + (Relevance × 0.15)',
            style: TextStyle(
              color: AppColors.textMid,
              fontSize: 11,
              fontFamily: 'monospace',
              decoration: TextDecoration.none,
            ),
          ),

          const SizedBox(height: 20),
          Text(
            'RATINGS',
            style: TextStyle(
              color: AppColors.textMid,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 8),
          _buildRatingBadge('Excellent', 80, AppColors.accent),
          _buildRatingBadge('Good', 60, Color(0xFFFFB700)),
          _buildRatingBadge('Fair', 40, Color(0xFFFF9500)),
          _buildRatingBadge('Limited', 0, AppColors.error),
        ],
      ),
    );
  }

  Widget _buildMetricExplanation(String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.15),
          border: Border.all(
            color: color.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppColors.textMid,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                color: AppColors.textMid,
                fontSize: 11,
                height: 1.4,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBadge(String label, int minScore, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label ($minScore+)',
            style: TextStyle(
              color: AppColors.textMid,
              fontSize: 11,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityGuide() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PEPTIDE QUALITY GUIDE',
            style: TextStyle(
              color: AppColors.textMid,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 20),

          _buildQualityCriterion(
            'PURITY & TESTING',
            'Look for 3rd-party testing (HPLC, Mass Spec). Reputable suppliers test every batch. Minimum 98% purity.',
            '⭐⭐⭐',
          ),
          _buildQualityCriterion(
            'SOURCE & REPUTATION',
            'Check company history, customer reviews, and transparency. Established suppliers with consistent quality are safer.',
            '⭐⭐⭐',
          ),
          _buildQualityCriterion(
            'CERTIFICATES OF ANALYSIS',
            'Always request CoA. Should include purity %, impurity identification, and microbiological testing.',
            '⭐⭐⭐',
          ),
          _buildQualityCriterion(
            'STORAGE CONDITIONS',
            'Peptides degrade in heat/light. Check if supplier uses proper cold storage (2-8°C or frozen). Ask about shipment conditions.',
            '⭐⭐',
          ),
          _buildQualityCriterion(
            'PRICE INDICATORS',
            'If price is significantly cheaper than others, quality may be compromised. Legitimate peptides cost money to synthesize.',
            '⭐⭐',
          ),
          _buildQualityCriterion(
            'RECONSTITUTION & STABILITY',
            'Request info on reconstitution protocol and shelf life after reconstitution. Varies by peptide (3-14 days typically).',
            '⭐',
          ),

          const SizedBox(height: 24),

          Text(
            'RED FLAGS ⚠️',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 12),
          ...['No CoA available', 'No 3rd-party testing', 'Suspiciously cheap', 'Poor packaging/storage', 'No company info', 'Overpromised results']
              .map((flag) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.close, color: AppColors.error, size: 16),
                        const SizedBox(width: 8),
                        Text(flag, style: TextStyle(color: AppColors.textMid, fontSize: 12, decoration: TextDecoration.none)),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildQualityCriterion(String title, String description, String importance) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textMid,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
                Text(
                  importance,
                  style: TextStyle(
                    color: AppColors.textMid,
                    fontSize: 11,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                color: AppColors.textMid,
                fontSize: 11,
                height: 1.5,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = getAllCategories().toList()..sort();

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
                // Header using reusable widget
                AppHeader(
            icon: Icons.biotech,
            iconColor: WintermmuteStyles.colorOrange,
            title: 'RESEARCH',
                ),
                const SizedBox(height: 12),
                // Tabs
                Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildTab('Peptides', 0),
                    const SizedBox(width: 12),
                    _buildTab('Quality Guide', 1),
                    const SizedBox(width: 12),
                    _buildTab('Methodology', 2),
                  ],
                ),
              ],
            ),
                ),

                Expanded(
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                if (_tabIndex == 0) ...[
                  // Search bar
                  Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.textLight),
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search peptides...',
                  hintStyle: TextStyle(color: AppColors.textDim),
                  prefixIcon: Icon(Icons.search, color: AppColors.textMid),
                  filled: true,
                  fillColor: Colors.black,
                ),
              ),
                  ),
                  const SizedBox(height: 12),

                  // Category filter
                  Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip(null, 'All'),
                    ...categories.map((cat) => _buildCategoryChip(cat, cat)),
                  ],
                ),
              ),
                  ),
                  const SizedBox(height: 16),

                  // Peptide list
                  Expanded(
                    child: _displayedPeptides.isEmpty
                  ? Center(
                      child: Text(
                        'No peptides found',
                        style: TextStyle(
                          color: AppColors.textMid,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _displayedPeptides.length,
                      itemBuilder: (context, index) {
                        final peptide = _displayedPeptides[index];
                        return GestureDetector(
                          onTap: () => _showPeptideDetails(peptide),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: WintermmuteStyles.cardDecoration,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        peptide.name,
                                        style: TextStyle(
                                          color: AppColors.textMid,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.amber.withOpacity(0.15),
                                      ),
                                      child: Text(
                                        peptide.category,
                                        style: TextStyle(
                                          color: AppColors.amber,
                                          fontSize: 10,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  peptide.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.textMid,
                                    fontSize: 12,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${peptide.commonDoseRange} ${peptide.unit}',
                                      style: TextStyle(
                                        color: AppColors.textMid,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                    Text(
                                      peptide.studyLinks.isNotEmpty
                                          ? '${peptide.studyLinks.length} studies'
                                          : 'No studies',
                                      style: TextStyle(
                                        color: AppColors.textDim,
                                        fontSize: 10,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      ),
                  ),
                ] else if (_tabIndex == 1) ...[
                  Expanded(child: _buildQualityGuide()),
                ] else if (_tabIndex == 2) ...[
                  Expanded(child: _buildPepScoreMethodology()),
                ],
                        ],
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

  Widget _buildTab(String label, int index) {
    final isSelected = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.amber.withOpacity(0.15)
              : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.amber : AppColors.textMid,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _onCategorySelected(category),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.amber.withOpacity(0.15)
                : AppColors.surface.withOpacity(0.15),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.amber : AppColors.textMid,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntelligenceSection(PeptideInfo peptide) {
    return _buildDetailSection('INTELLIGENCE', Icons.biotech, AppColors.amber,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source count badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 6,
                children: [
                  _buildAmberTag('PHARMA-SOURCED'),
                  _buildAmberTag('CORPO-INTEL'),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: const BoxDecoration(
                ),
                child: Text('${peptide.studyLinks.length} SOURCES', style: TextStyle(color: AppColors.amber, fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Study list
          ...peptide.studyLinks.map((study) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () async {
                final uri = Uri.parse(study.url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFF050505),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.link, color: AppColors.amber.withOpacity(0.7), size: 12),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(study.title, style: TextStyle(color: AppColors.amber.withOpacity(0.9), fontSize: 11, fontFamily: 'monospace', decoration: TextDecoration.underline)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${study.source} • ${study.year}', style: TextStyle(color: AppColors.textDim, fontSize: 9, fontFamily: 'monospace', decoration: TextDecoration.none)),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAmberTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: const BoxDecoration(
      ),
      child: Text(label, style: TextStyle(color: AppColors.amber.withOpacity(0.7), fontSize: 7, fontFamily: 'monospace', decoration: TextDecoration.none)),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.amber.withOpacity(0.07)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
