import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/lab_result.dart';

// FUNC-003: This service is DISABLED until:
//   1. BLOODWORK_AI_API_KEY is set in .env
//   2. _readFile() has been verified against the actual file-source used
// If the API key is absent, uploadLabPdf() throws a clear disabled error.

class BloodworkService {
  static const String _apiUrl = 'https://api.bloodworkai.com/v1';

  /// Upload PDF and extract biomarkers.
  /// Returns LabResult with extracted data.
  /// Throws if BLOODWORK_AI_API_KEY is not configured in .env.
  static Future<LabResult> uploadLabPdf({
    required String filePath,
    required String userId,
    String? cycleId,
    String? notes,
  }) async {
    const apiKey = String.fromEnvironment('BLOODWORK_AI_API_KEY');
    if (apiKey.isEmpty) {
      throw Exception(
        'BloodworkAI is not configured. '
        'Pass --dart-define=BLOODWORK_AI_API_KEY=... at build time to enable this feature.',
      );
    }

    try {
      final fileBytes = await _readFile(filePath);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_apiUrl/extract'),
      );

      request.headers['Authorization'] = 'Bearer $apiKey';
      request.fields['user_id'] = userId;
      if (cycleId != null) request.fields['cycle_id'] = cycleId;
      if (notes != null) request.fields['notes'] = notes;

      request.files.add(http.MultipartFile(
        'pdf_file',
        Stream.value(fileBytes),
        fileBytes.length,
        filename: filePath.split('/').last,
      ));

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 2),
        onTimeout: () => throw Exception('Upload timeout - BloodworkAI API'),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final extractedData = _parseBloodworkResponse(jsonResponse);

        return LabResult(
          id: jsonResponse['result_id'] ?? _generateId(),
          userId: userId,
          cycleId: cycleId,
          pdfPath: filePath,
          extractedData: extractedData,
          uploadDate: DateTime.now(),
          processedDate: DateTime.now(),
          notes: notes,
        );
      } else {
        throw Exception('Upload failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('BloodworkAI upload error: $e');
    }
  }

  /// Parse BloodworkAI API response
  static Map<String, dynamic> _parseBloodworkResponse(Map<String, dynamic> response) {
    return {
      // Hormones
      'testosterone': response['biomarkers']?['testosterone']?['value'],
      'testosterone_percent': response['biomarkers']?['testosterone']?['percentile'],
      'testosterone_status': response['biomarkers']?['testosterone']?['status'],
      'cortisol': response['biomarkers']?['cortisol']?['value'],
      'cortisol_status': response['biomarkers']?['cortisol']?['status'],

      // Metabolic
      'glucose': response['biomarkers']?['glucose']?['value'],
      'glucose_status': response['biomarkers']?['glucose']?['status'],
      'insulin': response['biomarkers']?['insulin']?['value'],
      'hba1c': response['biomarkers']?['hba1c']?['value'],

      // Lipids
      'total_cholesterol': response['biomarkers']?['cholesterol']?['total'],
      'ldl': response['biomarkers']?['cholesterol']?['ldl'],
      'hdl': response['biomarkers']?['cholesterol']?['hdl'],
      'triglycerides': response['biomarkers']?['cholesterol']?['triglycerides'],

      // Thyroid
      'tsh': response['biomarkers']?['thyroid']?['tsh'],
      't3': response['biomarkers']?['thyroid']?['t3'],
      't4': response['biomarkers']?['thyroid']?['t4'],
      't4_free': response['biomarkers']?['thyroid']?['t4_free'],

      // Liver/Kidney
      'ast': response['biomarkers']?['liver']?['ast'],
      'alt': response['biomarkers']?['liver']?['alt'],
      'creatinine': response['biomarkers']?['kidney']?['creatinine'],

      // Inflammation
      'crp': response['biomarkers']?['inflammation']?['crp'],
      'esr': response['biomarkers']?['inflammation']?['esr'],

      // Blood
      'hemoglobin': response['biomarkers']?['blood']?['hemoglobin'],
      'hematocrit': response['biomarkers']?['blood']?['hematocrit'],
      'wbc': response['biomarkers']?['blood']?['wbc'],

      // Summary
      'overall_status': response['summary']?['overall_status'],
      'key_findings': List<String>.from(response['summary']?['key_findings'] ?? []),
      'recommendations': List<String>.from(response['summary']?['recommendations'] ?? []),

      'extracted_at': response['processed_at'] ?? DateTime.now().toIso8601String(),
    };
  }

  /// Read file bytes from device storage using dart:io
  static Future<List<int>> _readFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }
    return file.readAsBytes();
  }

  static String _generateId() {
    return 'lab_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Mock response for testing (only used in debug/test contexts)
  static Map<String, dynamic> getMockResponse() {
    return {
      'result_id': _generateId(),
      'biomarkers': {
        'testosterone': {'value': 650, 'percentile': 75, 'status': 'OPTIMAL'},
        'cortisol': {'value': 12, 'status': 'NORMAL'},
        'glucose': {'value': 95, 'status': 'NORMAL'},
        'cholesterol': {
          'total': 185,
          'ldl': 110,
          'hdl': 50,
          'triglycerides': 90,
        },
        'thyroid': {
          'tsh': 1.5,
          't4_free': 1.2,
        },
      },
      'summary': {
        'overall_status': 'HEALTHY',
        'key_findings': ['Testosterone levels optimal', 'Metabolic health good'],
        'recommendations': ['Continue current protocol', 'Retest in 3 months'],
      },
      'processed_at': DateTime.now().toIso8601String(),
    };
  }
}
