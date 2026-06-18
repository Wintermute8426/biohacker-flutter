import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Dual-model lab extraction service.
///
/// Strategy:
///   1. Try Gemini 2.5 Flash (cheap, schema-enforced JSON, ~$0.15/M tokens)
///   2. Fall back to Claude Sonnet 4.6 (lowest hallucination rate, ~$3/M tokens)
///
/// Build-time dart-defines required:
///   --dart-define=GEMINI_API_KEY=...
///   --dart-define=ANTHROPIC_API_KEY=...
class LabExtractionService {
  static const String _geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY');
  static const String _anthropicApiKey =
      String.fromEnvironment('ANTHROPIC_API_KEY');

  static const String _geminiModel = 'gemini-2.5-flash';
  static const String _claudeModel = 'claude-sonnet-4-6';

  static const String _geminiBase =
      'https://generativelanguage.googleapis.com/v1beta/models';

  static const String _biomarkerPrompt =
      'Extract ALL biomarker values from this lab result. '
      'Return ONLY valid JSON matching this schema exactly — no markdown, no explanation: '
      '{"biomarkers": [{"name": "Testosterone", "value": 847, "unit": "ng/dL", '
      '"reference_range": "300-1000", "status": "OPTIMAL"}]}. '
      'Status must be one of: OPTIMAL, NORMAL, SUBOPTIMAL, LOW, HIGH, CRITICAL. '
      'Use standard biomarker names (e.g. "Testosterone", "TSH", "LDL Cholesterol"). '
      'Include every biomarker found. If no lab results visible, return {"biomarkers": []}.';

  static const String _pdfBiomarkerPrompt =
      'Extract ALL biomarker values from every page of this lab result PDF. '
      'Return ONLY valid JSON matching this schema exactly — no markdown, no explanation: '
      '{"biomarkers": [{"name": "Testosterone", "value": 847, "unit": "ng/dL", '
      '"reference_range": "300-1000", "status": "OPTIMAL"}]}. '
      'Status must be one of: OPTIMAL, NORMAL, SUBOPTIMAL, LOW, HIGH, CRITICAL. '
      'Use standard biomarker names. Include every biomarker found across all pages. '
      'If no lab results visible, return {"biomarkers": []}.';

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Extract biomarkers from a lab image (camera/gallery).
  /// Returns a map of snake_case biomarker keys → value/unit/status objects.
  static Future<ExtractionResult> extractFromImage({
    required String base64Image,
    required String mediaType,
  }) async {
    // 1. Try Gemini
    if (_geminiApiKey.isNotEmpty) {
      try {
        if (kDebugMode) print('[LabExtraction] Trying Gemini 2.5 Flash for image...');
        final result = await _geminiExtractImage(base64Image, mediaType);
        if (result.isNotEmpty) {
          if (kDebugMode) print('[LabExtraction] Gemini succeeded: ${result.length} markers');
          return ExtractionResult(data: result, model: _geminiModel);
        }
        if (kDebugMode) print('[LabExtraction] Gemini returned empty — falling back to Claude');
      } catch (e) {
        if (kDebugMode) print('[LabExtraction] Gemini failed: $e — falling back to Claude');
      }
    }

    // 2. Fall back to Claude Sonnet
    if (_anthropicApiKey.isNotEmpty) {
      if (kDebugMode) print('[LabExtraction] Trying Claude $_claudeModel for image...');
      final result = await _claudeExtractImage(base64Image, mediaType);
      if (kDebugMode) print('[LabExtraction] Claude succeeded: ${result.length} markers');
      return ExtractionResult(data: result, model: _claudeModel);
    }

    if (kDebugMode) print('[LabExtraction] No API keys configured');
    return ExtractionResult(data: {}, model: 'none');
  }

  /// Extract biomarkers from a lab PDF (file picker).
  /// Returns a map of snake_case biomarker keys → value/unit/status objects.
  static Future<ExtractionResult> extractFromPdf({
    required String base64Pdf,
    required String fileName,
  }) async {
    // 1. Try Gemini
    if (_geminiApiKey.isNotEmpty) {
      try {
        if (kDebugMode) print('[LabExtraction] Trying Gemini 2.5 Flash for PDF: $fileName');
        final result = await _geminiExtractPdf(base64Pdf);
        if (result.isNotEmpty) {
          if (kDebugMode) print('[LabExtraction] Gemini succeeded: ${result.length} markers');
          return ExtractionResult(data: result, model: _geminiModel);
        }
        if (kDebugMode) print('[LabExtraction] Gemini returned empty — falling back to Claude');
      } catch (e) {
        if (kDebugMode) print('[LabExtraction] Gemini failed: $e — falling back to Claude');
      }
    }

    // 2. Fall back to Claude Sonnet
    if (_anthropicApiKey.isNotEmpty) {
      if (kDebugMode) print('[LabExtraction] Trying Claude $_claudeModel for PDF: $fileName');
      final result = await _claudeExtractPdf(base64Pdf);
      if (kDebugMode) print('[LabExtraction] Claude succeeded: ${result.length} markers');
      return ExtractionResult(data: result, model: _claudeModel);
    }

    if (kDebugMode) print('[LabExtraction] No API keys configured');
    return ExtractionResult(data: {}, model: 'none');
  }

  // ---------------------------------------------------------------------------
  // Gemini 2.5 Flash
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> _geminiExtractImage(
    String base64Image,
    String mediaType,
  ) async {
    final url = Uri.parse(
        '$_geminiBase/$_geminiModel:generateContent?key=$_geminiApiKey');

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'inline_data': {
                'mime_type': mediaType,
                'data': base64Image,
              }
            },
            {'text': _biomarkerPrompt},
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.1,
        'maxOutputTokens': 8192,
      },
    });

    final response = await http
        .post(url,
            headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 60));

    return _parseGeminiResponse(response);
  }

  static Future<Map<String, dynamic>> _geminiExtractPdf(
      String base64Pdf) async {
    final url = Uri.parse(
        '$_geminiBase/$_geminiModel:generateContent?key=$_geminiApiKey');

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'inline_data': {
                'mime_type': 'application/pdf',
                'data': base64Pdf,
              }
            },
            {'text': _pdfBiomarkerPrompt},
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.1,
        'maxOutputTokens': 8192,
      },
    });

    final response = await http
        .post(url,
            headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 120));

    return _parseGeminiResponse(response);
  }

  static Map<String, dynamic> _parseGeminiResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception(
          'Gemini API error ${response.statusCode}: ${response.body}');
    }

    final apiResponse = jsonDecode(response.body);
    final text = apiResponse['candidates']?[0]?['content']?['parts']?[0]
            ?['text'] ??
        '{}';

    if (kDebugMode) print('[LabExtraction] Gemini raw response: $text');
    return _parseBiomarkerJson(text);
  }

  // ---------------------------------------------------------------------------
  // Claude Sonnet 4.6 (fallback)
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> _claudeExtractImage(
    String base64Image,
    String mediaType,
  ) async {
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'x-api-key': _anthropicApiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'model': _claudeModel,
        'max_tokens': 8192,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': mediaType,
                  'data': base64Image,
                }
              },
              {'type': 'text', 'text': _biomarkerPrompt},
            ]
          }
        ]
      }),
    ).timeout(const Duration(seconds: 60));

    return _parseClaudeResponse(response);
  }

  static Future<Map<String, dynamic>> _claudeExtractPdf(
      String base64Pdf) async {
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'x-api-key': _anthropicApiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'model': _claudeModel,
        'max_tokens': 8192,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'document',
                'source': {
                  'type': 'base64',
                  'media_type': 'application/pdf',
                  'data': base64Pdf,
                }
              },
              {'type': 'text', 'text': _pdfBiomarkerPrompt},
            ]
          }
        ]
      }),
    ).timeout(const Duration(seconds: 120));

    return _parseClaudeResponse(response);
  }

  static Map<String, dynamic> _parseClaudeResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception(
          'Claude API error ${response.statusCode}: ${response.body}');
    }

    final apiResponse = jsonDecode(response.body);
    final text = apiResponse['content']?[0]?['text'] ?? '{}';

    if (kDebugMode) print('[LabExtraction] Claude raw response: $text');
    return _parseBiomarkerJson(text);
  }

  // ---------------------------------------------------------------------------
  // Shared JSON parser
  // ---------------------------------------------------------------------------

  /// Exposed for unit tests only.
  @visibleForTesting
  static Map<String, dynamic> parseBiomarkerJsonForTest(String raw) =>
      _parseBiomarkerJson(raw);

  static Map<String, dynamic> _parseBiomarkerJson(String raw) {
    String jsonStr = raw.trim();

    // Strip markdown fences if present
    if (jsonStr.startsWith('```')) {
      jsonStr =
          jsonStr.replaceAll(RegExp(r'```[a-z]*\n?', caseSensitive: false), '').trim();
    }

    // Extract first JSON object if there's surrounding text
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(jsonStr);
    if (jsonMatch != null) jsonStr = jsonMatch.group(0)!;

    final Map<String, dynamic> result = {};
    try {
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      final biomarkers = parsed['biomarkers'] as List? ?? [];

      for (final bm in biomarkers) {
        if (bm['name'] == null) continue;
        final key = (bm['name'] as String)
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
            .replaceAll(RegExp(r'^_+|_+$'), '');

        result[key] = {
          'value': bm['value'],
          'unit': bm['unit'] ?? '',
          'reference_range': bm['reference_range'] ?? '',
          'status': (bm['status'] ?? 'NORMAL').toString().toUpperCase(),
        };
      }
    } catch (e) {
      if (kDebugMode) print('[LabExtraction] JSON parse error: $e\nRaw: $jsonStr');
    }

    return result;
  }
}

/// Result from extraction including which model was used.
class ExtractionResult {
  final Map<String, dynamic> data;
  final String model;

  const ExtractionResult({required this.data, required this.model});

  bool get isEmpty => data.isEmpty;
  int get count => data.length;
}
