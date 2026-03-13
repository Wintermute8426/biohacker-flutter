import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../data/peptide_library.dart';
import '../widgets/city_background.dart';
import '../widgets/cyberpunk_rain.dart';

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

  void _showPeptideDetails(PeptideInfo peptide) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 120,
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
                  peptide.name.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    decoration: TextDecoration.none,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  color: AppColors.textMid,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Category badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                peptide.category,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              peptide.description,
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 13,
                height: 1.5,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 20),

            // PepScore
            _buildPepScoreSection(peptide),
            const SizedBox(height: 20),

            // Dosing info
            _buildInfoSection('DOSING', [
              '${peptide.commonDoseRange} ${peptide.unit}',
              'Timing: ${peptide.timing}',
              'Route: ${peptide.route}',
            ]),
            const SizedBox(height: 16),

            // Effects
            _buildEffectsList('EFFECTS', peptide.effects, AppColors.accent),
            const SizedBox(height: 16),

            // Side effects
            _buildEffectsList('SIDE EFFECTS', peptide.sideEffects, AppColors.error),
            const SizedBox(height: 16),

            // Safety notes
            _buildInfoSection('SAFETY', [peptide.safetyNotes]),
            const SizedBox(height: 16),

            // Study links
            if (peptide.studyLinks.isNotEmpty) ...[
              Text(
                'RESEARCH',
                style: TextStyle(
                  color: AppColors.textMid,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 8),
              ...peptide.studyLinks.map((study) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Link: ${study.url}'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withOpacity(0.15),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            study.title,
                            style: TextStyle(
                              color: AppColors.textMid,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                study.source,
                                style: TextStyle(
                                  color: AppColors.textDim,
                                  fontSize: 10,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${study.year}',
                                style: TextStyle(
                                  color: AppColors.textDim,
                                  fontSize: 10,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.link,
                                color: AppColors.textMid,
                                size: 12,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textMid,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            item,
            style: TextStyle(
              color: AppColors.textMid,
              fontSize: 12,
              decoration: TextDecoration.none,
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildEffectsList(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textMid,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map((item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.15),
                      border: Border.all(color: color.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        color: AppColors.textMid,
                        decoration: TextDecoration.none,
                        fontSize: 11,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildPepScoreSection(PeptideInfo peptide) {
    final score = peptide.pepScore;
    final overall = score.overallScore;
    final rating = score.rating;
    
    // Color based on score
    Color scoreColor;
    if (overall >= 80) {
      scoreColor = AppColors.accent; // Green
    } else if (overall >= 60) {
      scoreColor = Color(0xFFFFB700); // Orange
    } else {
      scoreColor = AppColors.error; // Red
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.15),
        border: Border.all(color: scoreColor.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall score row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RESEARCH QUALITY (PepScore)',
                style: TextStyle(
                  color: AppColors.textMid,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  decoration: TextDecoration.none,
                ),
              ),
              Text(
                '$overall/100',
                style: TextStyle(
                  color: AppColors.textMid,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Score bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: overall / 100,
              minHeight: 6,
              backgroundColor: AppColors.surface.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ),
          const SizedBox(height: 8),

          // Rating label
          Text(
            rating,
            style: TextStyle(
              color: scoreColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 12),

          // Component breakdown
          Text(
            'SCORE BREAKDOWN',
            style: TextStyle(
              color: AppColors.textMid,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildScoreMetric('Publication', score.publication, 25),
              _buildScoreMetric('Evidence', score.evidence, 35),
              _buildScoreMetric('Methodology', score.methodology, 25),
              _buildScoreMetric('Relevance', score.relevance, 15),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreMetric(String label, int score, int weight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.textDim,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
            Text(
              '${score}%',
              style: TextStyle(
                color: AppColors.textMid,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '($weight%)',
          style: TextStyle(
            color: AppColors.textDim,
            fontSize: 9,
            decoration: TextDecoration.none,
          ),
        ),
      ],
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
            AppColors.primary,
          ),
          _buildMetricExplanation(
            'EVIDENCE (35%)',
            'Quality of human clinical data. Highest weight because real-world results matter most.',
            AppColors.accent,
          ),
          _buildMetricExplanation(
            'METHODOLOGY (25%)',
            'Research rigor and experimental design. Proper controls, sample sizes, and statistical analysis.',
            Color(0xFFFFB700),
          ),
          _buildMetricExplanation(
            'RELEVANCE (15%)',
            'Applicability to human biohacking and health optimization. Theory is great, but practical benefit matters.',
            Color(0xFF00FFFF),
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
          border: Border(left: BorderSide(color: color.withOpacity(0.2), width: 3)),
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
              borderRadius: BorderRadius.circular(2),
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
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(4),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Header + Tabs
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.biotech, color: WintermmuteStyles.colorOrange, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'RESEARCH',
                      style: WintermmuteStyles.titleStyle,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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

          if (_tabIndex == 0) ...[
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search peptides...',
                  hintStyle: TextStyle(color: AppColors.textDim),
                  prefixIcon: Icon(Icons.search, color: AppColors.textMid),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Category filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                        color: AppColors.primary.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: Text(
                                        peptide.category,
                                        style: TextStyle(
                                          color: AppColors.primary,
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
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ScanlinesPainter(),
              ),
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
              ? AppColors.primary.withOpacity(0.15)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.primary.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textMid,
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
                ? AppColors.primary.withOpacity(0.15)
                : AppColors.surface.withOpacity(0.15),
            border: Border.all(
              color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.primary.withOpacity(0.2),
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textMid,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
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
      ..color = AppColors.primary.withOpacity(0.07)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
