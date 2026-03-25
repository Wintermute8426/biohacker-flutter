// Peptide list sourced from Biohacker research
// All common therapeutic and performance peptides

const List<String> PEPTIDE_LIST = [
  // Recovery & Healing
  "BPC-157",
  "TB-500",
  "TB-4 (Thymosin Beta-4)",
  "KPV",
  "LL-37",
  "ARA-290",
  
  // Growth Hormone & Secretagogues
  "CJC-1295",
  "CJC-1295 w/DAC",
  "GHRP-2",
  "GHRP-6",
  "Hexarelin",
  "Ipamorelin",
  "Mod GRF 1-29",
  "Sermorelin",
  "Tesamorelin",
  "MK-677 (Ibutamoren)",
  
  // GLP-1 & Metabolic
  "Semaglutide",
  "Tirzepatide",
  "Retatrutide",
  "Liraglutide",
  "Dulaglutide",
  "Exenatide",
  "AOD-9604",
  "HGH Fragment 176-191",
  "Tesofensine",
  
  // Longevity & Aging
  "Epitalon",
  "Epithalon",
  "Pinealon",
  "Thymosin Alpha-1",
  
  // Cognitive & Neuroprotective
  "Semax",
  "Selank",
  "NA-Semax",
  "NA-Selank",
  "Dihexa",
  "Noopept",
  "NSI-189",
  "Cerebrolysin",
  "Cortexin",
  "P21",
  "Humanin",
  "MOTS-c",
  
  // Aesthetic & Skin
  "Melanotan I",
  "Melanotan II",
  "PT-141 (Bremelanotide)",
  "GHK-Cu (Copper Peptide)",
  "Matrixyl",
  "Argireline",
  
  // Muscle & Performance
  "Follistatin-344",
  "IGF-1 LR3",
  "IGF-1 DES",
  "MGF (Mechano Growth Factor)",
  "PEG-MGF",
  "YK-11",
  "ACE-031",
  
  // Sexual Health
  "Kisspeptin",
  "Gonadorelin",
  "Triptorelin",
  
  // Immune
  "Thymalin",
  "LL-37",
  
  // Sleep & Circadian
  "DSIP (Delta Sleep-Inducing Peptide)",
  
  // Experimental / Research
  "C-Max",
  "SS-31 (Elamipretide)",
  "FGL",
  "Adipotide",
  "5-Amino-1MQ",
  
  // Blends & Protocols
  "GLOW Protocol",
  "KLOW Protocol",
  "CJC-1295 (no DAC) + Ipamorelin",
];

// Common dosing ranges (in mg)
const Map<String, String> PEPTIDE_DOSES = {
  "BPC-157": "250-500",
  "TB-500": "2.5-5",
  "TB-4 (Thymosin Beta-4)": "2.5-5",
  "CJC-1295": "100-500",
  "CJC-1295 w/DAC": "500-1000",
  "GHRP-2": "100-300",
  "GHRP-6": "100-300",
  "Ipamorelin": "100-200",
  "Semaglutide": "0.3-1",
  "Tirzepatide": "2.5-10",
  "Retatrutide": "0.25-1.5",
  "Epitalon": "10-30",
  "Semax": "100-500",
  "Selank": "100-500",
  "Melanotan II": "0.5-1",
  "PT-141 (Bremelanotide)": "0.5-2",
  "GHK-Cu (Copper Peptide)": "1-10",
  "Follistatin-344": "100-200",
  "IGF-1 LR3": "20-50",
  "MGF (Mechano Growth Factor)": "100-200",
  "GLOW Protocol": "1-2",
  "KLOW Protocol": "1-2",
  "CJC-1295 (no DAC) + Ipamorelin": "100-200 each",
};

List<String> searchPeptides(String query) {
  if (query.isEmpty) return PEPTIDE_LIST;
  final lower = query.toLowerCase();
  return PEPTIDE_LIST
      .where((p) => p.toLowerCase().contains(lower))
      .toList();
}
