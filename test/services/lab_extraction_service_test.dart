import 'package:flutter_test/flutter_test.dart';
import 'package:biohacker_app/services/lab_extraction_service.dart';

void main() {
  group('LabExtractionService – parseBiomarkerJson', () {
    test('parses a valid biomarker JSON blob into keyed map', () {
      const raw = '''
{
  "biomarkers": [
    {"name": "Testosterone", "value": 847, "unit": "ng/dL", "reference_range": "300-1000", "status": "OPTIMAL"},
    {"name": "TSH",          "value": 1.8,  "unit": "mIU/L", "reference_range": "0.4-4.0",  "status": "NORMAL"},
    {"name": "LDL Cholesterol","value": 110, "unit": "mg/dL","reference_range": "0-130",     "status": "NORMAL"}
  ]
}''';

      final result = LabExtractionService.parseBiomarkerJsonForTest(raw);

      expect(result, isNotEmpty);
      expect(result.containsKey('testosterone'), isTrue);
      expect(result.containsKey('tsh'), isTrue);
      expect(result.containsKey('ldl_cholesterol'), isTrue);
      expect(result['testosterone']['value'], equals(847));
      expect(result['testosterone']['unit'], equals('ng/dL'));
      expect(result['testosterone']['status'], equals('OPTIMAL'));
      expect(result['tsh']['value'], equals(1.8));
    });

    test('returns empty map when biomarkers list is empty', () {
      const raw = '{"biomarkers": []}';
      final result = LabExtractionService.parseBiomarkerJsonForTest(raw);
      expect(result, isEmpty);
    });

    test('returns empty map for malformed / garbage JSON', () {
      const raw = 'this is not json at all!!!';
      final result = LabExtractionService.parseBiomarkerJsonForTest(raw);
      expect(result, isEmpty);
    });

    test('strips markdown code fences before parsing', () {
      const raw = '```json\n{"biomarkers": [{"name": "IGF-1", "value": 250, "unit": "ng/mL", "reference_range": "100-300", "status": "OPTIMAL"}]}\n```';
      final result = LabExtractionService.parseBiomarkerJsonForTest(raw);
      expect(result.containsKey('igf_1'), isTrue);
      expect(result['igf_1']['value'], equals(250));
    });

    test('converts biomarker names to snake_case keys', () {
      const raw = '''{"biomarkers": [
        {"name": "Free Testosterone", "value": 12.5, "unit": "pg/mL", "reference_range": "8-25", "status": "NORMAL"}
      ]}''';
      final result = LabExtractionService.parseBiomarkerJsonForTest(raw);
      expect(result.containsKey('free_testosterone'), isTrue);
    });

    test('skips entries with null name', () {
      const raw = '''{"biomarkers": [
        {"name": null, "value": 100},
        {"name": "Cortisol", "value": 15, "unit": "µg/dL", "reference_range": "5-20", "status": "NORMAL"}
      ]}''';
      final result = LabExtractionService.parseBiomarkerJsonForTest(raw);
      expect(result.length, equals(1));
      expect(result.containsKey('cortisol'), isTrue);
    });

    test('status defaults to NORMAL when not provided', () {
      const raw = '''{"biomarkers": [
        {"name": "Glucose", "value": 90, "unit": "mg/dL"}
      ]}''';
      final result = LabExtractionService.parseBiomarkerJsonForTest(raw);
      expect(result['glucose']['status'], equals('NORMAL'));
    });
  });

  group('ExtractionResult', () {
    test('isEmpty is true when data map is empty', () {
      final r = ExtractionResult(data: {}, model: 'none');
      expect(r.isEmpty, isTrue);
      expect(r.count, equals(0));
    });

    test('isEmpty is false when data has entries', () {
      final r = ExtractionResult(data: {'testosterone': {}}, model: 'gemini-2.5-flash');
      expect(r.isEmpty, isFalse);
      expect(r.count, equals(1));
    });

    test('model name is preserved', () {
      final r = ExtractionResult(data: {}, model: 'claude-sonnet-4-6');
      expect(r.model, equals('claude-sonnet-4-6'));
    });
  });

  group('LabExtractionService – no API keys configured', () {
    // When dart-define keys are empty (the case in unit tests), both
    // extractFromImage and extractFromPdf should return an empty fallback
    // without making any HTTP calls.

    test('extractFromImage returns empty result when no API keys', () async {
      final result = await LabExtractionService.extractFromImage(
        base64Image: 'ZmFrZQ==', // "fake" in base64
        mediaType: 'image/jpeg',
      );
      expect(result.model, equals('none'));
      expect(result.isEmpty, isTrue);
    });

    test('extractFromPdf returns empty result when no API keys', () async {
      final result = await LabExtractionService.extractFromPdf(
        base64Pdf: 'ZmFrZQ==',
        fileName: 'test.pdf',
      );
      expect(result.model, equals('none'));
      expect(result.isEmpty, isTrue);
    });
  });
}
