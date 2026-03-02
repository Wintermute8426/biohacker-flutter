// Advanced dosing calculator for ramping/tapering schedules

class DosingSchedule {
  final double startDose; // Week 1 dose
  final double midDose;   // Middle weeks dose
  final double endDose;   // Last week dose
  final int totalWeeks;
  final String frequency; // 1x weekly, 2x weekly, etc.

  DosingSchedule({
    required this.startDose,
    required this.midDose,
    required this.endDose,
    required this.totalWeeks,
    required this.frequency,
  });

  // Get dose for a specific week
  double getDoseForWeek(int week) {
    if (week <= 0 || week > totalWeeks) return midDose;

    // If only 1-2 weeks, return start dose
    if (totalWeeks <= 2) return startDose;

    // Linear ramp up from start to mid (first half)
    final midPoint = totalWeeks / 2;
    if (week <= midPoint) {
      final progress = (week - 1) / (midPoint - 1);
      return startDose + (midDose - startDose) * progress;
    }

    // Linear ramp down from mid to end (second half)
    final secondHalfWeeks = totalWeeks - midPoint;
    final weekInSecondHalf = week - midPoint;
    final progress = weekInSecondHalf / secondHalfWeeks;
    return midDose + (endDose - midDose) * progress;
  }

  // Get weekly schedule as map
  Map<int, double> getWeeklySchedule() {
    final schedule = <int, double>{};
    for (int week = 1; week <= totalWeeks; week++) {
      schedule[week] = getDoseForWeek(week);
    }
    return schedule;
  }

  // Get total doses per week based on frequency
  int dosesPerWeek() {
    if (frequency.contains('Daily')) return 7;
    if (frequency.contains('2x daily')) return 14;
    if (frequency.contains('3x')) return 3;
    if (frequency.contains('2x')) return 2;
    return 1; // 1x weekly
  }

  // Get daily dose
  double getDailyDose(int week) {
    final weekDose = getDoseForWeek(week);
    return weekDose / dosesPerWeek();
  }

  // Format as readable string
  String formatSchedule() {
    final schedule = getWeeklySchedule();
    return schedule.entries
        .map((e) => 'Week ${e.key}: ${e.value.toStringAsFixed(2)}mg')
        .join('\n');
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'start_dose': startDose,
    'mid_dose': midDose,
    'end_dose': endDose,
    'total_weeks': totalWeeks,
    'frequency': frequency,
  };

  factory DosingSchedule.fromJson(Map<String, dynamic> json) {
    return DosingSchedule(
      startDose: (json['start_dose'] as num).toDouble(),
      midDose: (json['mid_dose'] as num).toDouble(),
      endDose: (json['end_dose'] as num).toDouble(),
      totalWeeks: json['total_weeks'] as int,
      frequency: json['frequency'] as String,
    );
  }
}

// Helper: Standard dosing profiles
class DosingProfiles {
  static DosingSchedule flatDose({
    required double dose,
    required int weeks,
    required String frequency,
  }) {
    return DosingSchedule(
      startDose: dose,
      midDose: dose,
      endDose: dose,
      totalWeeks: weeks,
      frequency: frequency,
    );
  }

  static DosingSchedule rampUp({
    required double startDose,
    required double endDose,
    required int weeks,
    required String frequency,
  }) {
    return DosingSchedule(
      startDose: startDose,
      midDose: endDose,
      endDose: endDose,
      totalWeeks: weeks,
      frequency: frequency,
    );
  }

  static DosingSchedule rampDown({
    required double startDose,
    required double endDose,
    required int weeks,
    required String frequency,
  }) {
    return DosingSchedule(
      startDose: startDose,
      midDose: startDose,
      endDose: endDose,
      totalWeeks: weeks,
      frequency: frequency,
    );
  }

  static DosingSchedule rampUpAndDown({
    required double startDose,
    required double peakDose,
    required double endDose,
    required int weeks,
    required String frequency,
  }) {
    return DosingSchedule(
      startDose: startDose,
      midDose: peakDose,
      endDose: endDose,
      totalWeeks: weeks,
      frequency: frequency,
    );
  }
}
