import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../data/peptide_library.dart';

class ResearchScreen extends StatefulWidget {
  const ResearchScreen({Key? key}) : super(key: key);

  @override
  State<ResearchScreen> createState() => _ResearchScreenState();
}

class _ResearchScreenState extends State<ResearchScreen> {
  final _searchController = TextEditingController();
  late List<PeptideInfo> _displayedPeptides;
  String? _selectedCategory;
  int _tabIndex = 0; // 0 = Peptides, 1 = Quality Guide

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
                  peptide.name.toUpperCase(),
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
            const SizedBox(height: 12),

            // Category badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                peptide.category,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
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
              ),
            ),
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
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
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
                        color: AppColors.primary.withOpacity(0.05),
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
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
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
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${study.year}',
                                style: TextStyle(
                                  color: AppColors.textDim,
                                  fontSize: 10,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.link,
                                color: AppColors.accent,
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
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
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
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
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
                      color: color.withOpacity(0.1),
                      border: Border.all(color: color.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
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
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
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
                        Text(flag, style: TextStyle(color: AppColors.textMid, fontSize: 12)),
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
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
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
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  importance,
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Tabs
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RESEARCH',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildTab('Peptides', 0),
                    const SizedBox(width: 12),
                    _buildTab('Quality Guide', 1),
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
                        style: TextStyle(color: AppColors.textMid),
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
                                    Expanded(
                                      child: Text(
                                        peptide.name,
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: Text(
                                        peptide.category,
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 10,
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
                                        color: AppColors.accent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      peptide.studyLinks.isNotEmpty
                                          ? '${peptide.studyLinks.length} studies'
                                          : 'No studies',
                                      style: TextStyle(
                                        color: AppColors.textDim,
                                        fontSize: 10,
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
          ],
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
              ? AppColors.primary.withOpacity(0.2)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
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
                ? AppColors.primary.withOpacity(0.2)
                : AppColors.surface,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textMid,
              fontSize: 11,
              fontWeight: FontWeight.bold,
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
