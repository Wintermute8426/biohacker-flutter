import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../data/peptides.dart' show PEPTIDE_LIST;

class PeptideSelector extends StatefulWidget {
  final Function(String) onSelected;
  final String? initialValue;
  final String label;

  const PeptideSelector({
    Key? key,
    required this.onSelected,
    this.initialValue,
    this.label = 'PEPTIDE',
  }) : super(key: key);

  @override
  State<PeptideSelector> createState() => _PeptideSelectorState();
}

class _PeptideSelectorState extends State<PeptideSelector> {
  late TextEditingController _searchController;
  late String _selectedPeptide;
  List<String> _filteredPeptides = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedPeptide = widget.initialValue ?? '';
    _updateFilteredList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilteredList() {
    final query = _searchController.text.toLowerCase();
    final allPeptides = PEPTIDE_LIST;
    
    if (query.isEmpty) {
      _filteredPeptides = allPeptides;
    } else {
      _filteredPeptides = allPeptides
          .where((p) => p.toLowerCase().contains(query))
          .toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: WintermmuteStyles.headerStyle.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 8),

        // Search field
        TextField(
          controller: _searchController,
          onChanged: (_) => _updateFilteredList(),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search peptides...',
            hintStyle: TextStyle(color: AppColors.textDim),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            suffixIcon: _selectedPeptide.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      setState(() => _selectedPeptide = '');
                      _searchController.clear();
                      _updateFilteredList();
                    },
                    child: Icon(Icons.clear, color: AppColors.textMid, size: 18),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),

        // Selected peptide display
        if (_selectedPeptide.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary),
              borderRadius: BorderRadius.circular(4),
              color: AppColors.primary.withOpacity(0.1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedPeptide,
                  style: WintermmuteStyles.bodyStyle.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.check_circle, color: AppColors.primary, size: 18),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No peptide selected',
              style: WintermmuteStyles.tinyStyle.copyWith(color: AppColors.textMid),
            ),
          ),
        const SizedBox(height: 12),

        // Filtered list
        if (_filteredPeptides.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredPeptides.length,
              itemBuilder: (context, index) {
                final peptide = _filteredPeptides[index];
                final isSelected = peptide == _selectedPeptide;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPeptide = peptide;
                      _searchController.text = peptide;
                    });
                    widget.onSelected(peptide);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(color: AppColors.border.withOpacity(0.3)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            peptide,
                            style: WintermmuteStyles.bodyStyle.copyWith(
                              color: isSelected ? AppColors.primary : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check, color: AppColors.primary, size: 18),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        else if (_searchController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No peptides found',
              style: WintermmuteStyles.tinyStyle.copyWith(color: AppColors.textMid),
            ),
          ),
      ],
    );
  }
}
