// Comprehensive peptide library with detailed information
class StudyLink {
  final String title;
  final String url;
  final String source;
  final int year;
  const StudyLink({required this.title, required this.url, required this.source, required this.year});
}

// PepScore: Research quality scoring (0-100)
class PepScore {
  final int publication;     // 25% — Published in peer-reviewed sources
  final int evidence;        // 35% — Clinical/human evidence quality
  final int methodology;     // 25% — Research rigor and design
  final int relevance;       // 15% — Relevance to human biohacking/health
  
  const PepScore({
    this.publication = 0,
    this.evidence = 0,
    this.methodology = 0,
    this.relevance = 0,
  });
  
  // Calculate weighted overall score (0-100)
  int get overallScore => 
    ((publication * 0.25) + 
     (evidence * 0.35) + 
     (methodology * 0.25) + 
     (relevance * 0.15)).round();
  
  // Human-readable rating
  String get rating {
    final score = overallScore;
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Limited';
  }
}

class PeptideInfo {
  final String name;
  final String category;
  final String commonDoseRange; // e.g., "250-500"
  final String unit; // mg, mcg, etc.
  final String timing; // e.g., "1x weekly"
  final String route; // SC, IM, IV, etc.
  final String description;
  final List<String> effects;
  final List<String> sideEffects;
  final String safetyNotes;
  final int halfLife; // in hours, 0 if not applicable
  final List<StudyLink> studyLinks;
  final PepScore pepScore;

  const PeptideInfo({
    required this.name,
    required this.category,
    required this.commonDoseRange,
    required this.unit,
    required this.timing,
    required this.route,
    required this.description,
    required this.effects,
    required this.sideEffects,
    required this.safetyNotes,
    required this.halfLife,
    this.studyLinks = const [],
    this.pepScore = const PepScore(),
  });
}

const Map<String, PeptideInfo> PEPTIDE_LIBRARY = {
  'BPC-157': PeptideInfo(
    name: 'BPC-157',
    category: 'Recovery',
    commonDoseRange: '250-500',
    unit: 'mcg',
    timing: '1x daily or 1x weekly',
    route: 'SC, IM',
    description:
        'Body Protection Compound studied for recovery, gut health, and injury healing. One of the most researched recovery peptides.',
    effects: ['Joint recovery', 'Gut health', 'Wound healing', 'Immune support'],
    sideEffects: ['Minimal side effects', 'Generally well tolerated'],
    safetyNotes:
        'Well studied in humans. No major safety concerns at therapeutic doses.',
    halfLife: 8,
    pepScore: PepScore(
      publication: 85,  // Multiple peer-reviewed papers
      evidence: 90,     // Strong human + animal evidence
      methodology: 80,  // Solid experimental design
      relevance: 95,    // Highly relevant for recovery
    ),
  ),
  'TB-500': PeptideInfo(
    name: 'TB-500',
    category: 'Recovery',
    commonDoseRange: '2.5-5',
    unit: 'mg',
    timing: '2x weekly',
    route: 'SC, IM',
    description:
        'Thymosin Beta-4. Recovery peptide known for tissue repair and wound healing.',
    effects: ['Tissue repair', 'Recovery', 'Injury healing', 'Inflammation'],
    sideEffects: ['Minimal', 'Well tolerated'],
    safetyNotes: 'Long-standing research. Safe at therapeutic doses.',
    halfLife: 0,
    pepScore: PepScore(
      publication: 80,  // Published in peer-reviewed literature
      evidence: 85,     // Good human + animal evidence
      methodology: 75,  // Solid but some limitations
      relevance: 90,    // Highly relevant for recovery
    ),
  ),
  'Semaglutide': PeptideInfo(
    name: 'Semaglutide',
    category: 'Metabolic',
    commonDoseRange: '0.3-1',
    unit: 'mg',
    timing: '1x weekly',
    route: 'SC',
    description:
        'GLP-1 receptor agonist. Powerful for appetite suppression and metabolic health.',
    effects: [
      'Appetite suppression',
      'Weight loss',
      'Blood sugar control',
      'Cardiovascular benefit'
    ],
    sideEffects: [
      'Nausea',
      'GI upset',
      'Potential pancreatitis',
      'Dehydration risk'
    ],
    safetyNotes:
        'Approved by FDA. Monitor for GI issues. Start low. Risk of pancreatitis at high doses.',
    halfLife: 168,
  ),
  'Tirzepatide': PeptideInfo(
    name: 'Tirzepatide',
    category: 'Metabolic',
    commonDoseRange: '2.5-10',
    unit: 'mg',
    timing: '1x weekly',
    route: 'SC',
    description:
        'Dual GLP-1/GIP receptor agonist. More potent than semaglutide for weight loss.',
    effects: [
      'Appetite suppression',
      'Weight loss',
      'Metabolic improvement',
      'Blood sugar control'
    ],
    sideEffects: [
      'Nausea',
      'Vomiting',
      'GI upset',
      'Pancreatitis risk'
    ],
    safetyNotes:
        'Newer than semaglutide. Stronger side effect profile. Monitor closely.',
    halfLife: 168,
  ),
  'Epitalon': PeptideInfo(
    name: 'Epitalon',
    category: 'Longevity',
    commonDoseRange: '10-30',
    unit: 'mg',
    timing: '1x daily or 1x weekly',
    route: 'SC',
    description:
        'Pineal peptide studied for longevity, sleep quality, and immune function.',
    effects: [
      'Sleep quality',
      'Immune function',
      'Longevity markers',
      'Circadian rhythm'
    ],
    sideEffects: ['Minimal'],
    safetyNotes:
        'Well tolerated. Long history of use in Russia. Limited human studies.',
    halfLife: 4,
  ),
  'CJC-1295': PeptideInfo(
    name: 'CJC-1295',
    category: 'Growth Hormone',
    commonDoseRange: '100-500',
    unit: 'mcg',
    timing: '2-3x weekly',
    route: 'SC',
    description: 'Growth hormone releasing hormone analog. Stimulates GH release.',
    effects: [
      'GH release',
      'Muscle growth',
      'Fat loss',
      'Recovery'
    ],
    sideEffects: ['Hunger increase', 'Water retention', 'Numbness/tingling'],
    safetyNotes: 'Monitor prolactin levels. Can cause hunger.',
    halfLife: 8,
  ),
  'Ipamorelin': PeptideInfo(
    name: 'Ipamorelin',
    category: 'Growth Hormone',
    commonDoseRange: '100-200',
    unit: 'mcg',
    timing: '1-3x daily',
    route: 'SC',
    description:
        'GH secretagogue. Gentler than CJC with fewer side effects.',
    effects: ['GH release', 'Lean muscle', 'Fat loss', 'Recovery'],
    sideEffects: ['Minimal', 'Mild hunger'],
    safetyNotes: 'Safer profile than other GH secretagogues.',
    halfLife: 2,
  ),
  'Semax': PeptideInfo(
    name: 'Semax',
    category: 'Cognitive',
    commonDoseRange: '100-500',
    unit: 'mcg',
    timing: '1-2x daily',
    route: 'Intranasal',
    description:
        'Neuroprotective peptide. Enhances cognition, memory, and focus.',
    effects: ['Focus', 'Memory', 'Cognitive enhancement', 'Stress resilience'],
    sideEffects: ['Minimal', 'Possible headache initially'],
    safetyNotes: 'Well tolerated. Russian research backing.',
    halfLife: 1,
  ),
  'GHK-Cu': PeptideInfo(
    name: 'GHK-Cu (Copper Peptide)',
    category: 'Aesthetic',
    commonDoseRange: '1-10',
    unit: 'mg',
    timing: 'Daily (topical or SC)',
    route: 'Topical, SC, or IM',
    description:
        'Copper-peptide complex. Used for skin, collagen, and anti-aging.',
    effects: [
      'Skin health',
      'Collagen production',
      'Wound healing',
      'Anti-aging'
    ],
    sideEffects: ['Minimal'],
    safetyNotes: 'Topical is safest. Injectable requires monitoring.',
    halfLife: 0,
  ),
  'Melanotan II': PeptideInfo(
    name: 'Melanotan II',
    category: 'Aesthetic',
    commonDoseRange: '0.5-1',
    unit: 'mg',
    timing: '1x daily during cycle',
    route: 'SC',
    description:
        'Melanocyte-stimulating hormone analog. Tanning and sexual function.',
    effects: ['Tanning', 'Sexual function', 'Appetite suppression'],
    sideEffects: ['Nausea', 'Flushing', 'Dark moles potential'],
    safetyNotes: 'Banned in many countries. Mole monitoring essential.',
    halfLife: 0,
  ),
  'PT-141': PeptideInfo(
    name: 'PT-141 (Bremelanotide)',
    category: 'Sexual Health',
    commonDoseRange: '0.5-2',
    unit: 'mg',
    timing: '1x per session',
    route: 'SC',
    description: 'Melanocortin agonist for sexual dysfunction.',
    effects: [
      'Sexual arousal',
      'Sexual function',
      'Libido enhancement'
    ],
    sideEffects: ['Nausea', 'Flushing', 'Darkening of moles'],
    safetyNotes: 'FDA approved for women. Monitor blood pressure.',
    halfLife: 0,
  ),
};

List<PeptideInfo> searchPeptides(String query) {
  if (query.isEmpty) {
    return PEPTIDE_LIBRARY.values.toList();
  }
  final lower = query.toLowerCase();
  return PEPTIDE_LIBRARY.values
      .where((p) =>
          p.name.toLowerCase().contains(lower) ||
          p.description.toLowerCase().contains(lower) ||
          p.category.toLowerCase().contains(lower))
      .toList();
}

List<PeptideInfo> getPeptidesByCategory(String category) {
  return PEPTIDE_LIBRARY.values
      .where((p) => p.category == category)
      .toList();
}

Set<String> getAllCategories() {
  return PEPTIDE_LIBRARY.values.map((p) => p.category).toSet();
}
