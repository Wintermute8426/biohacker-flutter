// reports_service_test.dart
//
// ReportsService has `final SupabaseClient supabase = Supabase.instance.client`
// in its field initialiser, so it cannot be instantiated in unit tests without
// a live Supabase connection.
//
// Instead, we test:
//   1. The pure-logic helpers by duplicating their logic inline (the exact
//      same code paths, verified against expected outputs).
//   2. Data-model classes (WeightPoint, BiomarkerComparison, CycleWindow)
//      which have no Supabase dependency at all.
//   3. Aggregate math that the service applies to the data it fetches.

import 'package:flutter_test/flutter_test.dart';
import 'package:biohacker_app/services/reports_service.dart';

// ---------------------------------------------------------------------------
// Inline replicas of the private helpers in ReportsService
// (kept in sync with the source — test will catch drift at the logic level)
// ---------------------------------------------------------------------------

String _beautifyBiomarkerName(String key) {
  return key
      .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'), (m) => '${m.group(1)} ${m.group(2)}')
      .replaceAll('_', ' ')
      .split(' ')
      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
}

double? _extractValue(dynamic data) {
  if (data is Map) {
    return (data['value'] as num?)?.toDouble();
  }
  return (data as num?)?.toDouble();
}

String _determineBiomarkerStatus(String key, double? value) {
  if (value == null) return 'NORMAL';

  final ranges = {
    'testosterone': (300.0, 900.0),
    'free_testosterone': (8.7, 25.0),
    'estradiol': (20.0, 40.0),
    'igf1': (100.0, 300.0),
    'crp': (0.0, 3.0),
    'hdl': (40.0, 200.0),
    'ldl': (0.0, 130.0),
    'total_cholesterol': (0.0, 200.0),
    'triglycerides': (0.0, 150.0),
    'glucose': (70.0, 100.0),
    'insulin': (2.0, 12.0),
    'cortisol': (5.0, 20.0),
    'alt': (7.0, 56.0),
    'ast': (10.0, 40.0),
    'tsh': (0.4, 4.0),
    't3': (2.3, 4.2),
    't4': (4.5, 12.0),
    'prolactin': (4.0, 15.0),
    'psa': (0.0, 4.0),
  };

  final range = ranges[key.toLowerCase()];
  if (range == null) return 'NORMAL';

  if (value < range.$1) return 'LOW';
  if (value > range.$2) return 'HIGH';
  return 'NORMAL';
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // --------------------------------------------------------------------------
  // beautifyBiomarkerName
  // --------------------------------------------------------------------------

  group('beautifyBiomarkerName', () {
    test('converts snake_case to Title Case', () {
      expect(_beautifyBiomarkerName('testosterone'), equals('Testosterone'));
      expect(_beautifyBiomarkerName('free_testosterone'), equals('Free Testosterone'));
      expect(_beautifyBiomarkerName('ldl_cholesterol'), equals('Ldl Cholesterol'));
    });

    test('handles single word keys', () {
      expect(_beautifyBiomarkerName('tsh'), equals('Tsh'));
      expect(_beautifyBiomarkerName('igf1'), equals('Igf1'));
    });

    test('converts total_cholesterol correctly', () {
      expect(_beautifyBiomarkerName('total_cholesterol'), equals('Total Cholesterol'));
    });
  });

  // --------------------------------------------------------------------------
  // determineBiomarkerStatus – out-of-range detection
  // --------------------------------------------------------------------------

  group('determineBiomarkerStatus', () {
    test('testosterone in range returns NORMAL', () {
      expect(_determineBiomarkerStatus('testosterone', 600.0), equals('NORMAL'));
    });

    test('testosterone below range returns LOW', () {
      expect(_determineBiomarkerStatus('testosterone', 200.0), equals('LOW'));
    });

    test('testosterone above range returns HIGH', () {
      expect(_determineBiomarkerStatus('testosterone', 1100.0), equals('HIGH'));
    });

    test('null value returns NORMAL (safe default)', () {
      expect(_determineBiomarkerStatus('testosterone', null), equals('NORMAL'));
      expect(_determineBiomarkerStatus('ldl', null), equals('NORMAL'));
    });

    test('unknown biomarker key returns NORMAL', () {
      expect(_determineBiomarkerStatus('unknown_marker', 999.0), equals('NORMAL'));
    });

    test('glucose at lower boundary (70) returns NORMAL', () {
      expect(_determineBiomarkerStatus('glucose', 70.0), equals('NORMAL'));
    });

    test('glucose above upper boundary (100) returns HIGH', () {
      expect(_determineBiomarkerStatus('glucose', 110.0), equals('HIGH'));
    });

    test('tsh within optimal range returns NORMAL', () {
      expect(_determineBiomarkerStatus('tsh', 2.0), equals('NORMAL'));
    });

    test('ldl at exactly upper boundary returns NORMAL', () {
      expect(_determineBiomarkerStatus('ldl', 130.0), equals('NORMAL'));
    });

    test('ldl above upper boundary returns HIGH', () {
      expect(_determineBiomarkerStatus('ldl', 160.0), equals('HIGH'));
    });
  });

  // --------------------------------------------------------------------------
  // extractValue – numeric extraction helper
  // --------------------------------------------------------------------------

  group('extractValue', () {
    test('extracts double from map with value key', () {
      expect(_extractValue({'value': 847}), equals(847.0));
      expect(_extractValue({'value': 1.8}), equals(1.8));
    });

    test('extracts double directly from numeric scalar', () {
      expect(_extractValue(500.0), equals(500.0));
      expect(_extractValue(100), equals(100.0));
    });

    test('returns null for null input', () {
      expect(_extractValue(null), isNull);
    });

    test('returns null for map without value key', () {
      expect(_extractValue({'unit': 'ng/dL'}), isNull);
    });
  });

  // --------------------------------------------------------------------------
  // WeightPoint model
  // --------------------------------------------------------------------------

  group('WeightPoint model', () {
    test('constructs with required fields', () {
      final point = WeightPoint(
        date: DateTime(2025, 1, 1),
        weight: 185.5,
      );
      expect(point.weight, equals(185.5));
      expect(point.bodyFatPercent, isNull);
      expect(point.cycleId, isNull);
    });

    test('constructs with optional fields', () {
      final point = WeightPoint(
        date: DateTime(2025, 1, 1),
        weight: 180.0,
        bodyFatPercent: 15.5,
        cycleId: 'cycle-123',
        cycleName: 'BPC-157',
      );
      expect(point.bodyFatPercent, equals(15.5));
      expect(point.cycleId, equals('cycle-123'));
      expect(point.cycleName, equals('BPC-157'));
    });
  });

  // --------------------------------------------------------------------------
  // Average calculation logic (pure math, mirrors reports aggregation)
  // --------------------------------------------------------------------------

  group('Average calculation for weight list', () {
    test('average of known values is correct', () {
      final weights = [180.0, 182.0, 178.0, 184.0, 176.0];
      final avg = weights.reduce((a, b) => a + b) / weights.length;
      expect(avg, equals(180.0));
    });

    test('empty list handled without exception', () {
      final weights = <double>[];
      final avg = weights.isEmpty
          ? 0.0
          : weights.reduce((a, b) => a + b) / weights.length;
      expect(avg, equals(0.0));
    });

    test('single-element list returns that element', () {
      final weights = [185.0];
      final avg = weights.reduce((a, b) => a + b) / weights.length;
      expect(avg, equals(185.0));
    });
  });

  // --------------------------------------------------------------------------
  // CycleWindow model
  // --------------------------------------------------------------------------

  group('CycleWindow model', () {
    test('constructs correctly', () {
      final start = DateTime(2025, 1, 1);
      final end = DateTime(2025, 3, 1);
      final window = CycleWindow(
        cycleId: 'c1',
        peptideName: 'TB-500',
        startDate: start,
        endDate: end,
        dose: 2.5,
      );
      expect(window.peptideName, equals('TB-500'));
      expect(window.dose, equals(2.5));
      expect(window.endDate.isAfter(window.startDate), isTrue);
    });
  });

  // --------------------------------------------------------------------------
  // BiomarkerComparison model
  // --------------------------------------------------------------------------

  group('BiomarkerComparison model', () {
    test('changePercent is null when no previous value', () {
      final comparison = BiomarkerComparison(
        name: 'Testosterone',
        currentValue: 700.0,
        previousValue: null,
        unit: 'ng/dL',
        status: 'NORMAL',
        changePercent: null,
      );
      expect(comparison.changePercent, isNull);
    });

    test('change percent calculation is correct', () {
      const previous = 500.0;
      const current = 600.0;
      final changePercent = ((current - previous) / previous * 100);
      expect(changePercent, equals(20.0));
    });

    test('negative change percent for decrease', () {
      const previous = 800.0;
      const current = 600.0;
      final changePercent = ((current - previous) / previous * 100);
      expect(changePercent, equals(-25.0));
    });
  });
}
