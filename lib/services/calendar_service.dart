import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CalendarEvent {
  final DateTime date;
  final List<CycleEvent> cycles;
  final List<ProtocolEvent> protocols;
  final List<LabEvent> labs;
  final WeightEvent? weight;
  final List<DoseEvent> doses;
  final List<SideEffectEvent> sideEffects;

  CalendarEvent({
    required this.date,
    this.cycles = const [],
    this.protocols = const [],
    this.labs = const [],
    this.weight,
    this.doses = const [],
    this.sideEffects = const [],
  });

  bool get hasEvents =>
      cycles.isNotEmpty ||
      protocols.isNotEmpty ||
      labs.isNotEmpty ||
      weight != null ||
      doses.isNotEmpty ||
      sideEffects.isNotEmpty;
}

class CycleEvent {
  final String id;
  final String peptideName;
  final double dose;
  final String route;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  CycleEvent({
    required this.id,
    required this.peptideName,
    required this.dose,
    required this.route,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });
}

class ProtocolEvent {
  final String id;
  final String name;
  final String category;
  final bool isActive;

  ProtocolEvent({
    required this.id,
    required this.name,
    required this.category,
    required this.isActive,
  });
}

class LabEvent {
  final String id;
  final DateTime uploadDate;
  final Map<String, dynamic> extractedData;

  LabEvent({
    required this.id,
    required this.uploadDate,
    required this.extractedData,
  });
}

class WeightEvent {
  final double weightLbs;
  final double? bodyFatPercent;
  final String? notes;

  WeightEvent({
    required this.weightLbs,
    this.bodyFatPercent,
    this.notes,
  });
}

class DoseEvent {
  final String peptideName;
  final double amount;
  final String? route;
  final DateTime loggedAt;

  DoseEvent({
    required this.peptideName,
    required this.amount,
    this.route,
    required this.loggedAt,
  });
}

class SideEffectEvent {
  final String symptom;
  final int severity;
  final String? notes;

  SideEffectEvent({
    required this.symptom,
    required this.severity,
    this.notes,
  });
}

class CalendarService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Get all events for a specific month
  Future<Map<DateTime, CalendarEvent>> getMonthEvents(
      int year, int month) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      final Map<DateTime, CalendarEvent> events = {};

      // Initialize all days in the month
      for (int day = 1; day <= endDate.day; day++) {
        final date = DateTime(year, month, day);
        events[date] = CalendarEvent(date: date);
      }

      // Fetch cycles that overlap with this month
      final cyclesResponse = await supabase
          .from('cycles')
          .select()
          .eq('user_id', user.id)
          .or('and(start_date.lte.${endDate.toIso8601String()},end_date.gte.${startDate.toIso8601String()})');

      final cycles = cyclesResponse as List;

      for (var cycle in cycles) {
        final cycleStart = DateTime.parse(cycle['start_date']);
        final cycleEnd = DateTime.parse(cycle['end_date']);
        final isActive = cycle['is_active'] as bool? ?? true;

        final cycleEvent = CycleEvent(
          id: cycle['id'],
          peptideName: cycle['peptide_name'],
          dose: (cycle['dose'] as num).toDouble(),
          route: cycle['route'],
          startDate: cycleStart,
          endDate: cycleEnd,
          isActive: isActive,
        );

        // Add cycle to all days it spans within the month
        for (int day = 1; day <= endDate.day; day++) {
          final date = DateTime(year, month, day);
          if (date.isAfter(cycleStart.subtract(const Duration(days: 1))) &&
              date.isBefore(cycleEnd.add(const Duration(days: 1)))) {
            final existing = events[date] ?? CalendarEvent(date: date);
            events[date] = CalendarEvent(
              date: date,
              cycles: [...existing.cycles, cycleEvent],
              protocols: existing.protocols,
              labs: existing.labs,
              weight: existing.weight,
              doses: existing.doses,
              sideEffects: existing.sideEffects,
            );
          }
        }
      }

      // Fetch protocols (assuming they have start/end dates or are just active)
      final protocolsResponse = await supabase
          .from('protocol_templates')
          .select()
          .eq('user_id', user.id)
          .eq('is_active', true);

      final protocols = protocolsResponse as List;

      // Add protocols to all days (they're always active if is_active=true)
      if (protocols.isNotEmpty) {
        for (int day = 1; day <= endDate.day; day++) {
          final date = DateTime(year, month, day);
          final protocolEvents = protocols.map((p) => ProtocolEvent(
            id: p['id'],
            name: p['protocol_name'],
            category: p['category'] ?? 'General',
            isActive: true,
          )).toList();

          final existing = events[date] ?? CalendarEvent(date: date);
          events[date] = CalendarEvent(
            date: date,
            cycles: existing.cycles,
            protocols: protocolEvents,
            labs: existing.labs,
            weight: existing.weight,
            doses: existing.doses,
            sideEffects: existing.sideEffects,
          );
        }
      }

      // Fetch lab results uploaded in this month
      final labsResponse = await supabase
          .from('labs_results')
          .select()
          .eq('user_id', user.id)
          .gte('upload_date', startDate.toIso8601String())
          .lte('upload_date', endDate.toIso8601String());

      final labs = labsResponse as List;

      for (var lab in labs) {
        final uploadDate = DateTime.parse(lab['upload_date']);
        final dayKey = DateTime(uploadDate.year, uploadDate.month, uploadDate.day);

        if (events.containsKey(dayKey)) {
          final labEvent = LabEvent(
            id: lab['id'],
            uploadDate: uploadDate,
            extractedData: lab['extracted_data'] ?? {},
          );

          final existing = events[dayKey] ?? CalendarEvent(date: dayKey);
          events[dayKey] = CalendarEvent(
            date: dayKey,
            cycles: existing.cycles,
            protocols: existing.protocols,
            labs: [...existing.labs, labEvent],
            weight: existing.weight,
            doses: existing.doses,
            sideEffects: existing.sideEffects,
          );
        }
      }

      // Fetch weight logs for this month
      final weightsResponse = await supabase
          .from('weight_logs')
          .select()
          .eq('user_id', user.id)
          .gte('logged_at', startDate.toIso8601String())
          .lte('logged_at', endDate.toIso8601String());

      final weights = weightsResponse as List;

      for (var weight in weights) {
        final loggedAt = DateTime.parse(weight['logged_at']);
        final dayKey = DateTime(loggedAt.year, loggedAt.month, loggedAt.day);

        if (events.containsKey(dayKey)) {
          final weightEvent = WeightEvent(
            weightLbs: (weight['weight_lbs'] as num).toDouble(),
            bodyFatPercent: weight['body_fat_percent'] != null
                ? (weight['body_fat_percent'] as num).toDouble()
                : null,
            notes: weight['notes'],
          );

          final existing = events[dayKey] ?? CalendarEvent(date: dayKey);
          events[dayKey] = CalendarEvent(
            date: dayKey,
            cycles: existing.cycles,
            protocols: existing.protocols,
            labs: existing.labs,
            weight: weightEvent,
            doses: existing.doses,
            sideEffects: existing.sideEffects,
          );
        }
      }

      // Fetch doses for this month
      final dosesResponse = await supabase
          .from('dose_logs')
          .select('*, cycles!inner(peptide_name)')
          .eq('user_id', user.id)
          .gte('logged_at', startDate.toIso8601String())
          .lte('logged_at', endDate.toIso8601String());

      final doses = dosesResponse as List;

      for (var dose in doses) {
        final loggedAt = DateTime.parse(dose['logged_at']);
        final dayKey = DateTime(loggedAt.year, loggedAt.month, loggedAt.day);

        if (events.containsKey(dayKey)) {
          final doseEvent = DoseEvent(
            peptideName: dose['cycles']['peptide_name'],
            amount: (dose['dose_amount'] as num).toDouble(),
            route: dose['route'],
            loggedAt: loggedAt,
          );

          final existing = events[dayKey] ?? CalendarEvent(date: dayKey);
          events[dayKey] = CalendarEvent(
            date: dayKey,
            cycles: existing.cycles,
            protocols: existing.protocols,
            labs: existing.labs,
            weight: existing.weight,
            doses: [...existing.doses, doseEvent],
            sideEffects: existing.sideEffects,
          );
        }
      }

      // Fetch side effects for this month
      final sideEffectsResponse = await supabase
          .from('side_effects_log')
          .select()
          .eq('user_id', user.id)
          .gte('logged_at', startDate.toIso8601String())
          .lte('logged_at', endDate.toIso8601String());

      final sideEffects = sideEffectsResponse as List;

      for (var effect in sideEffects) {
        final loggedAt = DateTime.parse(effect['logged_at']);
        final dayKey = DateTime(loggedAt.year, loggedAt.month, loggedAt.day);

        if (events.containsKey(dayKey)) {
          final sideEffectEvent = SideEffectEvent(
            symptom: effect['symptom'],
            severity: effect['severity'],
            notes: effect['notes'],
          );

          final existing = events[dayKey] ?? CalendarEvent(date: dayKey);
          events[dayKey] = CalendarEvent(
            date: dayKey,
            cycles: existing.cycles,
            protocols: existing.protocols,
            labs: existing.labs,
            weight: existing.weight,
            doses: existing.doses,
            sideEffects: [...existing.sideEffects, sideEffectEvent],
          );
        }
      }

      return events;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[CalendarService] Error fetching calendar events: $e');
        print('[CalendarService] Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  // Get week events for a specific week (7 days starting from date)
  Future<Map<DateTime, CalendarEvent>> getWeekEvents(DateTime startDate) async {
    try {
      final endDate = startDate.add(const Duration(days: 6));

      // Use the same logic as getMonthEvents but for a week
      return getMonthEvents(startDate.year, startDate.month);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[CalendarService] Error fetching week events: $e');
        print('[CalendarService] Stack trace: $stackTrace');
      }
      rethrow;
    }
  }
}
