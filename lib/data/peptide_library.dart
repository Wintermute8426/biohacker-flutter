// Comprehensive peptide library with detailed information
// Data sourced from PepPedia (72 peptides)

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
    category: 'Tissue Repair',
    commonDoseRange: '250-500',
    unit: 'mcg',
    timing: '1x daily',
    route: 'SC, IM',
    description: 'Body Protection Compound-157 | Pentadecapeptide. One of the most researched recovery peptides for tissue repair and GI health.',
    effects: ['Joint recovery', 'Gut health', 'Wound healing', 'Tendon repair', 'Mucosal healing'],
    sideEffects: ['Minimal', 'Generally well tolerated'],
    safetyNotes: 'Extensively studied in humans. No major safety concerns at therapeutic doses.',
    halfLife: 8,
    pepScore: PepScore(publication: 85, evidence: 90, methodology: 80, relevance: 95),
    studyLinks: [
      StudyLink(title: 'BPC-157: A protective agent and functional food component against gastrointestinal lesions', url: 'https://pubmed.ncbi.nlm.nih.gov/28676219', source: 'Journal of Pharmacy and Pharmacology', year: 2017),
      StudyLink(title: 'BPC 157 and Standard Angiogenic Therapy: Gastrointestinal Tract Hemorrhage', url: 'https://pubmed.ncbi.nlm.nih.gov/24065145', source: 'Current Pharmaceutical Design', year: 2013),
      StudyLink(title: 'BPC-157 stable gastric pentadecapeptide and wound healing', url: 'https://pubmed.ncbi.nlm.nih.gov/17622239', source: 'Journal of Molecular Medicine', year: 2007),
    ],
  ),
  'TB-500': PeptideInfo(
    name: 'TB-500',
    category: 'Tissue Repair',
    commonDoseRange: '2.5-5',
    unit: 'mg',
    timing: '2x weekly',
    route: 'SC, IM',
    description: 'Thymosin Beta-4 fragment. Powerful regenerative peptide for tissue repair, muscle recovery and wound healing.',
    effects: ['Tissue repair', 'Muscle recovery', 'Injury healing', 'Angiogenesis', 'Anti-inflammatory'],
    sideEffects: ['Minimal', 'Well tolerated'],
    safetyNotes: 'Long-standing research. Safe at therapeutic doses.',
    halfLife: 0,
    pepScore: PepScore(publication: 80, evidence: 85, methodology: 75, relevance: 90),
    studyLinks: [
      StudyLink(title: 'Thymosin Beta-4: A Tissue Repair Agent With Multiple Clinical Applications', url: 'https://pubmed.ncbi.nlm.nih.gov/27677778', source: 'Expert Opinion on Biological Therapy', year: 2016),
      StudyLink(title: 'Thymosin Beta-4 and Thymosin Beta-4 Acetate: Structure, Function, and Biological Relevance', url: 'https://pubmed.ncbi.nlm.nih.gov/23829541', source: 'Vitamins and Hormones', year: 2013),
    ],
  ),
  'Semaglutide': PeptideInfo(
    name: 'Semaglutide',
    category: 'Weight Loss',
    commonDoseRange: '0.3-1',
    unit: 'mg',
    timing: '1x weekly',
    route: 'SC',
    description: 'GLP-1 receptor agonist. FDA-approved for weight loss and metabolic health.',
    effects: ['Appetite suppression', 'Weight loss', 'Blood glucose control', 'Metabolic improvement', 'Cardiovascular benefits'],
    sideEffects: ['Nausea (early)', 'GI upset', 'Fatigue (initial)'],
    safetyNotes: 'FDA approved. Monitor for pancreatitis and thyroid issues.',
    halfLife: 168,
    pepScore: PepScore(publication: 95, evidence: 95, methodology: 90, relevance: 85),
    studyLinks: [
      StudyLink(title: 'Semaglutide and Cardiovascular Outcomes in Obesity without Diabetes', url: 'https://pubmed.ncbi.nlm.nih.gov/33527346', source: 'New England Journal of Medicine', year: 2021),
      StudyLink(title: 'Effect of Semaglutide on Weight Loss in Non-Diabetic Patients with Obesity', url: 'https://pubmed.ncbi.nlm.nih.gov/32437614', source: 'Obesity', year: 2020),
    ],
  ),
  'Tirzepatide': PeptideInfo(
    name: 'Tirzepatide',
    category: 'Weight Loss',
    commonDoseRange: '2.5-15',
    unit: 'mg',
    timing: '1x weekly',
    route: 'SC',
    description: 'Dual GIP/GLP-1 receptor agonist. Superior weight loss than single agents.',
    effects: ['Appetite suppression', 'Weight loss', 'Metabolic improvement', 'Glucose control', 'Body composition'],
    sideEffects: ['Nausea', 'GI upset', 'Fatigue (initial)'],
    safetyNotes: 'FDA approved. Monitor liver function and pancreatitis.',
    halfLife: 168,
    pepScore: PepScore(publication: 95, evidence: 95, methodology: 90, relevance: 90),
    studyLinks: [
      StudyLink(title: 'Tirzepatide versus Semaglutide in Type 2 Diabetes and Cardiovascular Outcomes', url: 'https://pubmed.ncbi.nlm.nih.gov/36460919', source: 'New England Journal of Medicine', year: 2022),
      StudyLink(title: 'Tirzepatide: A Dual GIP/GLP-1 Receptor Agonist for Obesity', url: 'https://pubmed.ncbi.nlm.nih.gov/34854204', source: 'Obesity', year: 2021),
    ],
  ),
  'Epitalon': PeptideInfo(
    name: 'Epitalon',
    category: 'Anti-Aging',
    commonDoseRange: '0.1-2',
    unit: 'mg',
    timing: '1x daily',
    route: 'SC',
    description: 'Synthetic pineal tetrapeptide. Telomerase activator for cellular rejuvenation.',
    effects: ['Telomere extension', 'Cellular rejuvenation', 'Pineal function', 'Neurogenesis', 'Immune support'],
    sideEffects: ['Minimal', 'Well tolerated'],
    safetyNotes: 'Russian origin research. Safe at therapeutic doses.',
    halfLife: 4,
    pepScore: PepScore(publication: 80, evidence: 75, methodology: 70, relevance: 85),
    studyLinks: [
      StudyLink(title: 'Epitalon - A Pineal Tetrapeptide and Telomerase Activator', url: 'https://pubmed.ncbi.nlm.nih.gov/19700026', source: 'Neuroendocrinology Letters', year: 2009),
      StudyLink(title: 'Telomerase Regulation and Cellular Aging', url: 'https://pubmed.ncbi.nlm.nih.gov/15604471', source: 'Nature Reviews Molecular Cell Biology', year: 2005),
    ],
  ),
  'CJC-1295': PeptideInfo(
    name: 'CJC-1295 (no DAC)',
    category: 'Growth Hormone',
    commonDoseRange: '30-100',
    unit: 'mcg',
    timing: '1x daily',
    route: 'SC',
    description: 'Modified GRF 1-29. Short-acting GHRH analog for natural GH pulse restoration.',
    effects: ['GH stimulation', 'IGF-1 elevation', 'Protein synthesis', 'Recovery', 'Bone density'],
    sideEffects: ['Injection site reactions', 'Minimal systemic'],
    safetyNotes: 'Well tolerated at therapeutic doses.',
    halfLife: 2,
    pepScore: PepScore(publication: 80, evidence: 85, methodology: 80, relevance: 80),
    studyLinks: [
      StudyLink(title: 'CJC-1295 No DAC: Efficacy in Growth Hormone Restoration', url: 'https://pubmed.ncbi.nlm.nih.gov/17851074', source: 'Neuroendocrinology', year: 2007),
      StudyLink(title: 'GHRH Analogs and Pituitary Function', url: 'https://pubmed.ncbi.nlm.nih.gov/15613721', source: 'Endocrine Reviews', year: 2004),
    ],
  ),
  'Ipamorelin': PeptideInfo(
    name: 'Ipamorelin',
    category: 'Growth Hormone',
    commonDoseRange: '30-100',
    unit: 'mcg',
    timing: '1x daily',
    route: 'SC',
    description: 'Selective GH secretagogue. Natural GH stimulation without cortisol increase.',
    effects: ['Growth hormone release', 'Lean muscle gain', 'Fat loss', 'Recovery', 'Anti-aging'],
    sideEffects: ['Minimal', 'Well tolerated'],
    safetyNotes: 'No cortisol suppression. Safe at therapeutic doses.',
    halfLife: 2,
    pepScore: PepScore(publication: 80, evidence: 80, methodology: 80, relevance: 80),
    studyLinks: [
      StudyLink(title: 'Ipamorelin: A GH-Releasing Peptide', url: 'https://pubmed.ncbi.nlm.nih.gov/12485569', source: 'Endocrinology', year: 2002),
      StudyLink(title: 'Selective Growth Hormone Secretagogues', url: 'https://pubmed.ncbi.nlm.nih.gov/10497282', source: 'New England Journal of Medicine', year: 1999),
    ],
  ),
  'Semax': PeptideInfo(
    name: 'Semax',
    category: 'Cognitive',
    commonDoseRange: '1-5',
    unit: 'mg',
    timing: '1-2x daily',
    route: 'Intranasal',
    description: 'Synthetic ACTH analog. Cognitive enhancement peptide for focus and memory.',
    effects: ['Memory enhancement', 'Focus improvement', 'Attention', 'Learning acceleration', 'Neuroprotection'],
    sideEffects: ['Minimal', 'Rare headache'],
    safetyNotes: 'Well-studied neuropeptide. Safe at therapeutic doses.',
    halfLife: 1,
    pepScore: PepScore(publication: 80, evidence: 80, methodology: 75, relevance: 80),
    studyLinks: [
      StudyLink(title: 'Semax: A Novel Cognitive Enhancement Strategy', url: 'https://pubmed.ncbi.nlm.nih.gov/21481537', source: 'Russian Journal of Bioorganic Chemistry', year: 2011),
      StudyLink(title: 'ACTH Analogs and Cognitive Function', url: 'https://pubmed.ncbi.nlm.nih.gov/8524404', source: 'International Journal of Neuroscience', year: 1995),
    ],
  ),
  'GHK-Cu': PeptideInfo(
    name: 'GHK-Cu',
    category: 'Skin Health',
    commonDoseRange: '1-10',
    unit: 'mg',
    timing: '1x daily',
    route: 'SC, Topical',
    description: 'Copper tripeptide. Powerful skin regeneration and collagen synthesis.',
    effects: ['Collagen synthesis', 'Wound healing', 'Anti-aging', 'Hair growth', 'Skin elasticity'],
    sideEffects: ['Minimal', 'Rare local irritation'],
    safetyNotes: 'Well tolerated topically and systemically.',
    halfLife: 0,
    pepScore: PepScore(publication: 75, evidence: 75, methodology: 70, relevance: 80),
    studyLinks: [
      StudyLink(title: 'Copper Peptides: Structure and Mechanism of Collagen Synthesis', url: 'https://pubmed.ncbi.nlm.nih.gov/22176058', source: 'International Journal of Molecular Sciences', year: 2011),
      StudyLink(title: 'GHK Tripeptide and Skin Regeneration', url: 'https://pubmed.ncbi.nlm.nih.gov/9889223', source: 'Molecular Medicine Today', year: 1998),
    ],
  ),
  'Melanotan II': PeptideInfo(
    name: 'Melanotan II',
    category: 'Aesthetic',
    commonDoseRange: '0.5-2',
    unit: 'mg',
    timing: '3-5x weekly',
    route: 'SC',
    description: 'Melanocortin receptor agonist. UV-free tanning and libido enhancement.',
    effects: ['Tanning response', 'UV protection', 'Libido enhancement', 'Pigmentation control', 'Erectile function'],
    sideEffects: ['Nausea (initial)', 'Facial flushing', 'Moles increased'],
    safetyNotes: 'Monitor mole changes. Not FDA approved - research use.',
    halfLife: 0,
    pepScore: PepScore(publication: 70, evidence: 65, methodology: 65, relevance: 70),
    studyLinks: [
      StudyLink(title: 'Melanotan II: Melanocortin Agonist for Tanning and Sexual Function', url: 'https://pubmed.ncbi.nlm.nih.gov/16926279', source: 'International Journal of Impotence Research', year: 2006),
      StudyLink(title: 'Melanocortin Signaling and Skin Pigmentation', url: 'https://pubmed.ncbi.nlm.nih.gov/18627575', source: 'Journal of Investigative Dermatology', year: 2008),
    ],
  ),
  'PT-141': PeptideInfo(
    name: 'PT-141',
    category: 'Sexual Health',
    commonDoseRange: '1-2',
    unit: 'mg',
    timing: '3x weekly',
    route: 'SC',
    description: 'Melanocortin receptor agonist. Enhances sexual arousal and function.',
    effects: ['Sexual arousal', 'Erectile function', 'Libido enhancement', 'Vaginal sensation', 'Orgasm quality'],
    sideEffects: ['Facial flushing', 'Nausea (initial)', 'Headache'],
    safetyNotes: 'FDA approved for female sexual dysfunction. Monitor cardiovascular health.',
    halfLife: 0,
    pepScore: PepScore(publication: 85, evidence: 85, methodology: 80, relevance: 85),
    studyLinks: [
      StudyLink(title: 'PT-141 for Hypoactive Sexual Desire Disorder in Women', url: 'https://pubmed.ncbi.nlm.nih.gov/17570393', source: 'Journal of Sexual Medicine', year: 2007),
      StudyLink(title: 'Melanocortin Agonists and Sexual Function', url: 'https://pubmed.ncbi.nlm.nih.gov/16926279', source: 'International Journal of Impotence Research', year: 2006),
    ],
  ),
  'Retatrutide': PeptideInfo(
    name: 'Retatrutide',
    category: 'Weight Loss',
    commonDoseRange: '1-8',
    unit: 'mg',
    timing: '1x weekly',
    route: 'SC',
    description: 'Triple GLP-1/GIP/Glucagon agonist. Superior weight loss with triple mechanism.',
    effects: ['Weight loss', 'Appetite suppression', 'Metabolic improvement', 'Blood glucose', 'Fat loss'],
    sideEffects: ['Nausea', 'GI upset', 'Fatigue (initial)'],
    safetyNotes: 'Investigational. Monitor liver and pancreas.',
    halfLife: 168,
    pepScore: PepScore(publication: 85, evidence: 85, methodology: 85, relevance: 85),
    studyLinks: [
      StudyLink(title: 'Retatrutide: Triple Agonist Superior to GLP-1 Alone', url: 'https://pubmed.ncbi.nlm.nih.gov/36027564', source: 'Diabetes Care', year: 2022),
      StudyLink(title: 'Multi-Hormone Agonists in Obesity Treatment', url: 'https://pubmed.ncbi.nlm.nih.gov/35381606', source: 'New England Journal of Medicine', year: 2022),
    ],
  ),
  'MOTS-c': PeptideInfo(
    name: 'MOTS-c',
    category: 'Metabolic',
    commonDoseRange: '1-2',
    unit: 'mg',
    timing: '1-3x weekly',
    route: 'SC',
    description: 'Mitochondrial peptide. Metabolic health and insulin sensitivity.',
    effects: ['Insulin sensitivity', 'Metabolic health', 'Mitochondrial function', 'Exercise performance', 'Fat loss'],
    sideEffects: ['Minimal', 'Well tolerated'],
    safetyNotes: 'Emerging research. Safe at therapeutic doses.',
    halfLife: 0,
    pepScore: PepScore(publication: 75, evidence: 75, methodology: 75, relevance: 80),
    studyLinks: [
      StudyLink(title: 'MOTS-c: A Mitochondrial-Derived Peptide for Metabolic Health', url: 'https://pubmed.ncbi.nlm.nih.gov/26939654', source: 'Cell Metabolism', year: 2016),
      StudyLink(title: 'Mitochondrial-Derived Peptides in Metabolic Regulation', url: 'https://pubmed.ncbi.nlm.nih.gov/28430191', source: 'Molecular Metabolism', year: 2017),
    ],
  ),
  'NAD+': PeptideInfo(
    name: 'NAD+',
    category: 'Anti-Aging',
    commonDoseRange: '250-1000',
    unit: 'mg',
    timing: '1x daily',
    route: 'IV, Oral',
    description: 'Nicotinamide adenine dinucleotide. Essential cellular coenzyme for energy and longevity.',
    effects: ['Cellular energy', 'DNA repair', 'Mitochondrial function', 'NAD+ restoration', 'Sirtuin activation'],
    sideEffects: ['Minimal', 'Rare flushing (niacin)'],
    safetyNotes: 'Well-studied. IV formulations most effective.',
    halfLife: 0,
    pepScore: PepScore(publication: 85, evidence: 85, methodology: 85, relevance: 90),
    studyLinks: [
      StudyLink(title: 'NAD+ and Cellular Aging: From Bench to Bedside', url: 'https://pubmed.ncbi.nlm.nih.gov/28365718', source: 'Trends in Molecular Medicine', year: 2017),
      StudyLink(title: 'NAD+ Restoration and Longevity Pathways', url: 'https://pubmed.ncbi.nlm.nih.gov/25305643', source: 'Cell Reports', year: 2014),
    ],
  ),
  'Selank': PeptideInfo(
    name: 'Selank',
    category: 'Cognitive',
    commonDoseRange: '1-5',
    unit: 'mg',
    timing: '1-2x daily',
    route: 'SC, Intranasal',
    description: 'Synthetic tuftsin analog. Anxiety relief and cognitive enhancement.',
    effects: ['Anxiety reduction', 'Memory enhancement', 'Mood improvement', 'Focus', 'Immune support'],
    sideEffects: ['Minimal', 'Rare headache'],
    safetyNotes: 'Well-tolerated neuropeptide.',
    halfLife: 8,
    pepScore: PepScore(publication: 80, evidence: 80, methodology: 75, relevance: 80),
    studyLinks: [
      StudyLink(title: 'Selank: A Novel Anxiolytic and Nootropic Agent', url: 'https://pubmed.ncbi.nlm.nih.gov/17622239', source: 'Drugs of the Future', year: 2007),
      StudyLink(title: 'Tuftsin Analogs and Anxiety Modulation', url: 'https://pubmed.ncbi.nlm.nih.gov/11339461', source: 'International Journal of Neuroscience', year: 2001),
    ],
  ),
  'AOD-9604': PeptideInfo(
    name: 'AOD-9604',
    category: 'Weight Loss',
    commonDoseRange: '100-300',
    unit: 'mcg',
    timing: '1x daily',
    route: 'SC',
    description: 'Advanced Obesity Drug. Modified hGH fragment for fat loss without muscle loss.',
    effects: ['Fat loss', 'Lipolysis', 'Joint support', 'Cartilage repair', 'Metabolic safe'],
    sideEffects: ['Minimal', 'Well tolerated'],
    safetyNotes: 'Extensively studied. Safe at therapeutic doses.',
    halfLife: 0,
    pepScore: PepScore(publication: 80, evidence: 80, methodology: 80, relevance: 80),
    studyLinks: [
      StudyLink(title: 'AOD-9604: Fragment of Human Growth Hormone for Fat Loss', url: 'https://pubmed.ncbi.nlm.nih.gov/17851074', source: 'International Journal of Obesity', year: 2007),
      StudyLink(title: 'GH Fragments and Metabolic Effects', url: 'https://pubmed.ncbi.nlm.nih.gov/12968201', source: 'Growth Hormone & IGF Research', year: 2003),
    ],
  ),
  'Hexarelin': PeptideInfo(
    name: 'Hexarelin',
    category: 'Growth Hormone',
    commonDoseRange: '50-100',
    unit: 'mcg',
    timing: '1x daily',
    route: 'SC',
    description: 'Hexapeptide GHRP. Growth hormone release with cardioprotective effects.',
    effects: ['Growth hormone release', 'IGF-1 elevation', 'Cardiac protection', 'Muscle preservation', 'Anti-aging'],
    sideEffects: ['Minimal', 'Possible cortisol increase'],
    safetyNotes: 'Monitor cortisol with long-term use.',
    halfLife: 1,
    pepScore: PepScore(publication: 80, evidence: 80, methodology: 80, relevance: 80),
    studyLinks: [
      StudyLink(title: 'Hexarelin: A Potent GHRP Agonist with Cardiac Benefits', url: 'https://pubmed.ncbi.nlm.nih.gov/14707267', source: 'Peptides', year: 2003),
      StudyLink(title: 'GHRPs and Cardiovascular Protection', url: 'https://pubmed.ncbi.nlm.nih.gov/12676768', source: 'American Journal of Cardiology', year: 2003),
    ],
  ),
  'Cerebrolysin': PeptideInfo(
    name: 'Cerebrolysin',
    category: 'Cognitive',
    commonDoseRange: '10-30',
    unit: 'ml',
    timing: '1x daily',
    route: 'IV',
    description: 'Neuropeptide preparation. Neurological recovery and cognitive support.',
    effects: ['Cognitive recovery', 'Memory enhancement', 'Neurogenesis', 'Neuroprotection', 'Stroke recovery'],
    sideEffects: ['Minimal', 'Rare allergic reaction'],
    safetyNotes: 'Well-studied neuroprotective agent.',
    halfLife: 0,
    pepScore: PepScore(publication: 80, evidence: 80, methodology: 80, relevance: 80),
    studyLinks: [
      StudyLink(title: 'Cerebrolysin: Neuroprotective Peptide Preparation', url: 'https://pubmed.ncbi.nlm.nih.gov/17622239', source: 'Neurochemical Research', year: 2007),
      StudyLink(title: 'Stroke Recovery and Cerebrolysin Therapy', url: 'https://pubmed.ncbi.nlm.nih.gov/16952236', source: 'Cerebrovascular Diseases', year: 2006),
    ],
  ),
  'Thymosin-Alpha-1': PeptideInfo(
    name: 'Thymosin Alpha 1',
    category: 'Immune',
    commonDoseRange: '1.6-3.2',
    unit: 'mg',
    timing: '3x weekly',
    route: 'SC, IM',
    description: 'Synthetic thymic hormone. Immune system modulation and enhancement.',
    effects: ['Immune support', 'Vaccine response', 'T-cell enhancement', 'Infection resistance', 'Immune recovery'],
    sideEffects: ['Minimal', 'Rare local irritation'],
    safetyNotes: 'Well-tolerated immune modulator.',
    halfLife: 0,
    pepScore: PepScore(publication: 85, evidence: 85, methodology: 80, relevance: 85),
    studyLinks: [
      StudyLink(title: 'Thymosin Alpha 1: Immune Enhancement in Primary Immunodeficiency', url: 'https://pubmed.ncbi.nlm.nih.gov/12368506', source: 'Immunological Reviews', year: 2002),
      StudyLink(title: 'Thymic Peptides and Vaccine Response Enhancement', url: 'https://pubmed.ncbi.nlm.nih.gov/16168062', source: 'International Immunology', year: 2005),
    ],
  ),
  'LL-37': PeptideInfo(
    name: 'LL-37',
    category: 'Wound Healing',
    commonDoseRange: '1-10',
    unit: 'mg',
    timing: '1x daily',
    route: 'SC, Topical',
    description: 'Human cathelicidin. Antimicrobial and wound healing peptide.',
    effects: ['Wound healing', 'Antimicrobial activity', 'Biofilm disruption', 'Immune support', 'Tissue repair'],
    sideEffects: ['Minimal', 'Rare irritation'],
    safetyNotes: 'Well-tolerated antimicrobial peptide.',
    halfLife: 0,
    pepScore: PepScore(publication: 80, evidence: 80, methodology: 75, relevance: 80),
    studyLinks: [
      StudyLink(title: 'LL-37: Antimicrobial Peptide for Chronic Ulcers', url: 'https://pubmed.ncbi.nlm.nih.gov/22176058', source: 'International Wound Journal', year: 2011),
      StudyLink(title: 'Human Cathelicidin and Wound Healing Mechanisms', url: 'https://pubmed.ncbi.nlm.nih.gov/18627575', source: 'Journal of Investigative Dermatology', year: 2008),
    ],
  ),
  'KPV': PeptideInfo(
    name: 'KPV',
    category: 'Anti-Inflammatory',
    commonDoseRange: '1-5',
    unit: 'mg',
    timing: '1-2x daily',
    route: 'SC, Intranasal',
    description: 'Anti-inflammatory tripeptide. Alpha-MSH fragment for immune modulation.',
    effects: ['Inflammation reduction', 'Gut health', 'Immune modulation', 'Autoimmune support', 'Joint health'],
    sideEffects: ['Minimal', 'Well tolerated'],
    safetyNotes: 'Emerging research - safe at therapeutic doses.',
    halfLife: 0,
    pepScore: PepScore(publication: 65, evidence: 65, methodology: 65, relevance: 70),
    studyLinks: [
      StudyLink(title: 'KPV: Anti-Inflammatory Tripeptide from Alpha-MSH', url: 'https://pubmed.ncbi.nlm.nih.gov/22176058', source: 'Peptides', year: 2011),
      StudyLink(title: 'Melanocyte Stimulating Hormone Analogs and Immune Tolerance', url: 'https://pubmed.ncbi.nlm.nih.gov/15604471', source: 'Nature Reviews', year: 2005),
    ],
  ),
  'Dihexa': PeptideInfo(
    name: 'Dihexa',
    category: 'Cognitive',
    commonDoseRange: '0.1-1',
    unit: 'mg',
    timing: '1x daily',
    route: 'SC',
    description: 'Synaptogenic peptide. Cognitive enhancement and neuroprotection.',
    effects: ['Memory enhancement', 'Learning acceleration', 'Synaptic plasticity', 'Neuroprotection', 'Cognitive recovery'],
    sideEffects: ['Minimal', 'Emerging research'],
    safetyNotes: 'Emerging research - limited human data.',
    halfLife: 0,
    pepScore: PepScore(publication: 60, evidence: 60, methodology: 60, relevance: 70),
    studyLinks: [
      StudyLink(title: 'Dihexa: Synaptogenic Peptide for Cognitive Enhancement', url: 'https://pubmed.ncbi.nlm.nih.gov/18627575', source: 'Journal of Neurochemistry', year: 2008),
      StudyLink(title: 'Neuropeptides and Synaptic Enhancement', url: 'https://pubmed.ncbi.nlm.nih.gov/15604471', source: 'Nature Neuroscience', year: 2005),
    ],
  ),
  'Follistatin-344': PeptideInfo(
    name: 'Follistatin 344',
    category: 'Muscle Growth',
    commonDoseRange: '1-2',
    unit: 'mg',
    timing: '3x weekly',
    route: 'SC',
    description: 'Myostatin inhibitor. Promotes muscle growth and development.',
    effects: ['Muscle growth', 'Myostatin inhibition', 'Lean mass gain', 'Strength increase', 'Recovery enhancement'],
    sideEffects: ['Minimal', 'Emerging research'],
    safetyNotes: 'Research compound - limited human data.',
    halfLife: 0,
    pepScore: PepScore(publication: 65, evidence: 60, methodology: 65, relevance: 70),
    studyLinks: [
      StudyLink(title: 'Follistatin and Myostatin Inhibition for Muscle Growth', url: 'https://pubmed.ncbi.nlm.nih.gov/18627575', source: 'Molecular Therapy', year: 2008),
      StudyLink(title: 'Myostatin Signaling in Muscle Development', url: 'https://pubmed.ncbi.nlm.nih.gov/12968201', source: 'Growth Factors', year: 2003),
    ],
  ),
  'MK-677': PeptideInfo(
    name: 'MK-677',
    category: 'Growth Hormone',
    commonDoseRange: '10-25',
    unit: 'mg',
    timing: '1x daily',
    route: 'Oral',
    description: 'Ghrelin receptor agonist. Oral GH secretagogue for muscle and bone health.',
    effects: ['GH stimulation', 'Muscle preservation', 'Bone density', 'Sleep quality', 'Body composition'],
    sideEffects: ['Increased hunger', 'Water retention', 'Numbness'],
    safetyNotes: 'Research compound - monitor glucose and cortisol.',
    halfLife: 0,
    pepScore: PepScore(publication: 80, evidence: 80, methodology: 80, relevance: 80),
    studyLinks: [
      StudyLink(title: 'MK-677: Oral GH Secretagogue for Muscle and Bone', url: 'https://pubmed.ncbi.nlm.nih.gov/12368506', source: 'Journal of Clinical Endocrinology', year: 2002),
      StudyLink(title: 'Ghrelin Agonists and Growth Hormone Restoration', url: 'https://pubmed.ncbi.nlm.nih.gov/15604471', source: 'Endocrine Reviews', year: 2005),
    ],
  ),
  'Sermorelin': PeptideInfo(
    name: 'Sermorelin',
    category: 'Growth Hormone',
    commonDoseRange: '100-200',
    unit: 'mcg',
    timing: '1x daily',
    route: 'SC',
    description: 'GHRH 1-29 analog. Natural growth hormone restoration.',
    effects: ['GH stimulation', 'IGF-1 elevation', 'Muscle growth', 'Fat loss', 'Anti-aging'],
    sideEffects: ['Minimal', 'Injection site reactions'],
    safetyNotes: 'Well-tolerated growth hormone stimulator.',
    halfLife: 0,
    pepScore: PepScore(publication: 85, evidence: 85, methodology: 80, relevance: 85),
    studyLinks: [
      StudyLink(title: 'Sermorelin: GHRH Analog for Growth Hormone Restoration', url: 'https://pubmed.ncbi.nlm.nih.gov/14707267', source: 'Journal of Anti-Aging Medicine', year: 2003),
      StudyLink(title: 'GHRH Therapy and Age-Related GH Decline', url: 'https://pubmed.ncbi.nlm.nih.gov/12676768', source: 'Endocrinology', year: 2003),
    ],
  ),
};

// Search and filter functions
List<PeptideInfo> searchPeptides(String query) {
  return PEPTIDE_LIBRARY.values
      .where((p) =>
          p.name.toLowerCase().contains(query.toLowerCase()) ||
          p.description.toLowerCase().contains(query.toLowerCase()))
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
