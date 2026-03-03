class LabResult {
  final String id;
  final String userId;
  final String? cycleId;
  final String pdfPath;
  final Map<String, dynamic> extractedData;
  final DateTime uploadDate;
  final DateTime? processedDate;
  final String? notes;

  LabResult({
    required this.id,
    required this.userId,
    this.cycleId,
    required this.pdfPath,
    required this.extractedData,
    required this.uploadDate,
    this.processedDate,
    this.notes,
  });

  factory LabResult.fromJson(Map<String, dynamic> json) {
    return LabResult(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      cycleId: json['cycle_id'],
      pdfPath: json['pdf_file_path'] ?? '',
      extractedData: Map<String, dynamic>.from(json['extracted_data'] ?? {}),
      uploadDate: DateTime.parse(json['upload_date'] ?? DateTime.now().toIso8601String()),
      processedDate: json['processed_date'] != null ? DateTime.parse(json['processed_date']) : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'cycle_id': cycleId,
      'pdf_file_path': pdfPath,
      'extracted_data': extractedData,
      'upload_date': uploadDate.toIso8601String(),
      'processed_date': processedDate?.toIso8601String(),
      'notes': notes,
    };
  }

  // Convenience getters for common biomarkers
  double? get testosterone => (extractedData['testosterone'] as num?)?.toDouble();
  double? get cortisol => (extractedData['cortisol'] as num?)?.toDouble();
  double? get glucose => (extractedData['glucose'] as num?)?.toDouble();
  double? get testosterone_percent => (extractedData['testosterone_percent'] as num?)?.toDouble();
  String? get testosteroneStatus => extractedData['testosterone_status'];
  String? get cortisolStatus => extractedData['cortisol_status'];
}
