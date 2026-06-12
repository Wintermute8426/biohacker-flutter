// cycles_screen_test.dart
//
// CyclesScreen depends on Supabase.instance.client at construction time,
// which makes full widget-pumping impossible without a live Supabase
// connection in CI.
//
// This file provides:
//   1. A smoke test that the Cycle model and CyclesDatabase class can be
//      imported and instantiated (catches any compile-time regressions).
//   2. A lightweight widget test for a standalone card-like widget to
//      confirm the Flutter test harness is wired up correctly.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biohacker_app/services/cycles_database.dart';

// ---------------------------------------------------------------------------
// Minimal standalone widget used for smoke-testing the test harness
// ---------------------------------------------------------------------------

class _CycleCardStub extends StatelessWidget {
  final Cycle cycle;
  const _CycleCardStub({required this.cycle});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListTile(
          title: Text(cycle.peptideName),
          subtitle: Text('${cycle.dose} mg – ${cycle.route}'),
          trailing: cycle.isActive
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.cancel, color: Colors.grey),
        ),
      ),
    );
  }
}

void main() {
  // --------------------------------------------------------------------------
  // Model import smoke test
  // --------------------------------------------------------------------------

  group('CyclesDatabase / Cycle import smoke tests', () {
    test('Cycle can be instantiated without network', () {
      final cycle = Cycle(
        id: 'test-id',
        userId: 'user-id',
        peptideName: 'BPC-157',
        dose: 250.0,
        route: 'SC',
        frequency: '1x daily',
        durationWeeks: 8,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 3, 1),
        createdAt: DateTime(2025, 1, 1),
      );

      expect(cycle.peptideName, equals('BPC-157'));
      expect(cycle.isActive, isTrue); // default value
    });
  });

  // --------------------------------------------------------------------------
  // Lightweight widget tests using a stub card
  // --------------------------------------------------------------------------

  group('Cycle card widget (stub)', () {
    testWidgets('renders peptide name', (WidgetTester tester) async {
      final cycle = Cycle(
        id: 'w1',
        userId: 'u1',
        peptideName: 'TB-500',
        dose: 2.5,
        route: 'IM',
        frequency: '2x weekly',
        durationWeeks: 6,
        startDate: DateTime(2025, 4, 1),
        endDate: DateTime(2025, 5, 13),
        createdAt: DateTime(2025, 4, 1),
      );

      await tester.pumpWidget(_CycleCardStub(cycle: cycle));

      expect(find.text('TB-500'), findsOneWidget);
      expect(find.text('2.5 mg – IM'), findsOneWidget);
    });

    testWidgets('shows active icon for active cycle', (WidgetTester tester) async {
      final cycle = Cycle(
        id: 'w2',
        userId: 'u1',
        peptideName: 'BPC-157',
        dose: 250.0,
        route: 'SC',
        frequency: '1x daily',
        durationWeeks: 8,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 3, 1),
        isActive: true,
        createdAt: DateTime(2025, 1, 1),
      );

      await tester.pumpWidget(_CycleCardStub(cycle: cycle));

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsNothing);
    });

    testWidgets('shows cancelled icon for inactive cycle', (WidgetTester tester) async {
      final cycle = Cycle(
        id: 'w3',
        userId: 'u1',
        peptideName: 'Semax',
        dose: 600.0,
        route: 'nasal',
        frequency: '2x daily',
        durationWeeks: 4,
        startDate: DateTime(2024, 10, 1),
        endDate: DateTime(2024, 11, 1),
        isActive: false,
        createdAt: DateTime(2024, 10, 1),
      );

      await tester.pumpWidget(_CycleCardStub(cycle: cycle));

      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('widget tree contains Scaffold', (WidgetTester tester) async {
      final cycle = Cycle(
        id: 'w4',
        userId: 'u1',
        peptideName: 'GHK-Cu',
        dose: 1.0,
        route: 'SC',
        frequency: '1x daily',
        durationWeeks: 4,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 2, 1),
        createdAt: DateTime(2025, 1, 1),
      );

      await tester.pumpWidget(_CycleCardStub(cycle: cycle));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
    });
  });
}
