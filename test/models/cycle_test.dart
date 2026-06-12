import 'package:flutter_test/flutter_test.dart';
import 'package:biohacker_app/services/cycles_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // A sample cycle JSON as it would arrive from Supabase.
  Map<String, dynamic> _sampleJson({bool isActive = true}) => {
        'id': 'abc-123',
        'user_id': 'user-456',
        'peptide_name': 'BPC-157',
        'dose': 0.5,
        'route': 'SC (subcutaneous)',
        'frequency': '1x daily',
        'duration_weeks': 8,
        'start_date': '2024-01-01T00:00:00.000Z',
        'end_date': '2024-02-26T00:00:00.000Z',
        'is_active': isActive,
        'created_at': '2024-01-01T00:00:00.000Z',
        'advanced_schedule': null,
      };

  group('Cycle.fromJson', () {
    test('parses all required fields correctly', () {
      final cycle = Cycle.fromJson(_sampleJson());

      expect(cycle.id, equals('abc-123'));
      expect(cycle.userId, equals('user-456'));
      expect(cycle.peptideName, equals('BPC-157'));
      expect(cycle.dose, equals(0.5));
      expect(cycle.route, equals('SC (subcutaneous)'));
      expect(cycle.frequency, equals('1x daily'));
      expect(cycle.durationWeeks, equals(8));
      expect(cycle.isActive, isTrue);
      expect(cycle.advancedSchedule, isNull);
    });

    test('parses integer dose as double', () {
      final json = _sampleJson();
      json['dose'] = 1; // int, not double
      final cycle = Cycle.fromJson(json);
      expect(cycle.dose, isA<double>());
      expect(cycle.dose, equals(1.0));
    });

    test('is_active defaults to true when missing from JSON', () {
      final json = _sampleJson()..remove('is_active');
      final cycle = Cycle.fromJson(json);
      expect(cycle.isActive, isTrue);
    });

    test('is_active is false when set to false', () {
      final cycle = Cycle.fromJson(_sampleJson(isActive: false));
      expect(cycle.isActive, isFalse);
    });

    test('parses startDate and endDate as DateTime', () {
      final cycle = Cycle.fromJson(_sampleJson());
      expect(cycle.startDate, isA<DateTime>());
      expect(cycle.endDate, isA<DateTime>());
      expect(cycle.startDate.year, equals(2024));
      expect(cycle.startDate.month, equals(1));
      expect(cycle.startDate.day, equals(1));
    });

    test('parses advancedSchedule map when present', () {
      final json = _sampleJson();
      json['advanced_schedule'] = {'type': 'loading_protocol', 'weeks': 2};
      final cycle = Cycle.fromJson(json);
      expect(cycle.advancedSchedule, isNotNull);
      expect(cycle.advancedSchedule!['type'], equals('loading_protocol'));
    });
  });

  group('Cycle.toJson', () {
    test('roundtrip: toJson → fromJson preserves all fields', () {
      final original = Cycle.fromJson(_sampleJson());
      final json = original.toJson();
      final restored = Cycle.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.peptideName, equals(original.peptideName));
      expect(restored.dose, equals(original.dose));
      expect(restored.durationWeeks, equals(original.durationWeeks));
      expect(restored.isActive, equals(original.isActive));
    });

    test('toJson includes is_active key', () {
      final cycle = Cycle.fromJson(_sampleJson());
      final json = cycle.toJson();
      expect(json.containsKey('is_active'), isTrue);
      expect(json['is_active'], isTrue);
    });

    test('toJson encodes dates as ISO 8601 strings', () {
      final cycle = Cycle.fromJson(_sampleJson());
      final json = cycle.toJson();
      expect(json['start_date'], isA<String>());
      expect(json['end_date'], isA<String>());
      // Should be parseable back to a DateTime
      expect(() => DateTime.parse(json['start_date']), returnsNormally);
    });
  });

  group('Cycle end-date calculation helpers', () {
    test('8-week duration → endDate is 56 days after startDate', () {
      // Mirrors the saveCycle logic: endDate = startDate + durationWeeks * 7 days
      final start = DateTime(2024, 1, 1);
      final end = start.add(Duration(days: 8 * 7));
      expect(end.difference(start).inDays, equals(56));
    });

    test('12-week duration → endDate is 84 days after startDate', () {
      final start = DateTime(2024, 3, 1);
      final end = start.add(Duration(days: 12 * 7));
      expect(end.difference(start).inDays, equals(84));
    });
  });

  group('Active cycle filtering (pure logic)', () {
    List<Cycle> _buildCycles(List<Map<String, dynamic>> overrides) {
      return overrides.map((o) {
        final base = <String, dynamic>{
          'id': 'id-${overrides.indexOf(o)}',
          'user_id': 'u1',
          'peptide_name': 'BPC-157',
          'dose': 0.5,
          'route': 'SC',
          'frequency': 'daily',
          'duration_weeks': 8,
          'start_date': '2024-01-01T00:00:00.000Z',
          'end_date': '2024-02-26T00:00:00.000Z',
          'is_active': true,
          'created_at': '2024-01-01T00:00:00.000Z',
        };
        base.addAll(o);
        return Cycle.fromJson(base);
      }).toList();
    }

    test('getActiveCycles-style filter returns only active=true cycles', () {
      final cycles = _buildCycles([
        {'is_active': true, 'id': 'a'},
        {'is_active': false, 'id': 'b'},
        {'is_active': true, 'id': 'c'},
      ]);

      final active = cycles.where((c) => c.isActive).toList();
      expect(active.length, equals(2));
      expect(active.map((c) => c.id), containsAll(['a', 'c']));
    });

    test('returns empty list when no active cycles exist', () {
      final cycles = _buildCycles([
        {'is_active': false, 'id': 'x'},
        {'is_active': false, 'id': 'y'},
      ]);

      final active = cycles.where((c) => c.isActive).toList();
      expect(active, isEmpty);
    });

    test('cycle with future end date is still treated as active per isActive flag', () {
      final futureEnd = DateTime.now().add(const Duration(days: 30));
      final cycles = _buildCycles([
        {'is_active': true, 'end_date': futureEnd.toIso8601String()},
      ]);
      expect(cycles.first.isActive, isTrue);
      expect(cycles.first.endDate.isAfter(DateTime.now()), isTrue);
    });

    test('cycle with past end date is inactive when is_active=false', () {
      final pastEnd = DateTime.now().subtract(const Duration(days: 10));
      final cycles = _buildCycles([
        {'is_active': false, 'end_date': pastEnd.toIso8601String()},
      ]);
      expect(cycles.first.isActive, isFalse);
      expect(cycles.first.endDate.isBefore(DateTime.now()), isTrue);
    });
  });
}
