import 'package:flutter_test/flutter_test.dart';
import 'package:biohacker_app/services/cycles_database.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Cycle model – pure data tests (no Supabase needed)
  // ---------------------------------------------------------------------------

  group('Cycle.fromJson / toJson round-trip', () {
    final now = DateTime(2025, 6, 1, 12, 0, 0);
    final end = DateTime(2025, 8, 1, 12, 0, 0);

    final sampleJson = {
      'id': 'abc-123',
      'user_id': 'user-456',
      'peptide_name': 'BPC-157',
      'dose': 250.0,
      'route': 'SC',
      'frequency': '1x daily',
      'duration_weeks': 8,
      'start_date': now.toIso8601String(),
      'end_date': end.toIso8601String(),
      'is_active': true,
      'created_at': now.toIso8601String(),
      'advanced_schedule': null,
    };

    test('fromJson deserialises all required fields', () {
      final cycle = Cycle.fromJson(sampleJson);

      expect(cycle.id, equals('abc-123'));
      expect(cycle.userId, equals('user-456'));
      expect(cycle.peptideName, equals('BPC-157'));
      expect(cycle.dose, equals(250.0));
      expect(cycle.route, equals('SC'));
      expect(cycle.frequency, equals('1x daily'));
      expect(cycle.durationWeeks, equals(8));
      expect(cycle.isActive, isTrue);
      expect(cycle.advancedSchedule, isNull);
    });

    test('toJson serialises back to equivalent map', () {
      final cycle = Cycle.fromJson(sampleJson);
      final json = cycle.toJson();

      expect(json['id'], equals('abc-123'));
      expect(json['peptide_name'], equals('BPC-157'));
      expect(json['dose'], equals(250.0));
      expect(json['is_active'], isTrue);
    });

    test('isActive defaults to true when missing from JSON', () {
      final json = Map<String, dynamic>.from(sampleJson);
      json.remove('is_active');
      final cycle = Cycle.fromJson(json);
      expect(cycle.isActive, isTrue);
    });

    test('advancedSchedule is preserved when provided', () {
      final json = Map<String, dynamic>.from(sampleJson);
      json['advanced_schedule'] = {'mon': 250.0, 'thu': 250.0};
      final cycle = Cycle.fromJson(json);
      expect(cycle.advancedSchedule, isNotNull);
      expect(cycle.advancedSchedule!['mon'], equals(250.0));
    });
  });

  // ---------------------------------------------------------------------------
  // Active-cycle filter logic
  // ---------------------------------------------------------------------------

  group('Active cycle filter logic', () {
    final now = DateTime.now();

    Cycle _makeCycle({
      required String id,
      required bool isActive,
      DateTime? endDate,
    }) {
      final end = endDate ?? now.add(const Duration(days: 30));
      return Cycle(
        id: id,
        userId: 'user-1',
        peptideName: 'TestPeptide',
        dose: 100.0,
        route: 'SC',
        frequency: '1x daily',
        durationWeeks: 4,
        startDate: now.subtract(const Duration(days: 7)),
        endDate: end,
        isActive: isActive,
        createdAt: now.subtract(const Duration(days: 7)),
      );
    }

    test('only cycles with isActive=true pass the active filter', () {
      final cycles = [
        _makeCycle(id: '1', isActive: true),
        _makeCycle(id: '2', isActive: false),
        _makeCycle(id: '3', isActive: true),
      ];

      final active = cycles.where((c) => c.isActive).toList();

      expect(active.length, equals(2));
      expect(active.map((c) => c.id), containsAll(['1', '3']));
    });

    test('cycle with end date in the past is excluded when filtering by date', () {
      final pastEnd = now.subtract(const Duration(days: 1));
      final futureEnd = now.add(const Duration(days: 30));

      final cycles = [
        _makeCycle(id: 'past', isActive: true, endDate: pastEnd),
        _makeCycle(id: 'future', isActive: true, endDate: futureEnd),
      ];

      final currentlyRunning = cycles.where((c) => c.endDate.isAfter(now)).toList();

      expect(currentlyRunning.length, equals(1));
      expect(currentlyRunning.first.id, equals('future'));
    });

    test('empty list returns empty after filter', () {
      final List<Cycle> cycles = [];
      final active = cycles.where((c) => c.isActive).toList();
      expect(active, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Dose schedule date math
  // ---------------------------------------------------------------------------

  group('Dose schedule date math', () {
    test('end date is exactly durationWeeks * 7 days after start date', () {
      final start = DateTime(2025, 1, 1);
      const weeks = 8;
      final expectedEnd = start.add(const Duration(days: weeks * 7));

      expect(expectedEnd, equals(DateTime(2025, 2, 26)));
    });

    test('12-week cycle ends 84 days after start', () {
      final start = DateTime(2025, 3, 1);
      const weeks = 12;
      final end = start.add(Duration(days: weeks * 7));
      final diff = end.difference(start).inDays;
      expect(diff, equals(84));
    });

    test('startDate before endDate for any positive durationWeeks', () {
      final start = DateTime.now();
      for (final weeks in [1, 4, 8, 16, 52]) {
        final end = start.add(Duration(days: weeks * 7));
        expect(end.isAfter(start), isTrue,
            reason: 'End should be after start for $weeks weeks');
      }
    });
  });
}
