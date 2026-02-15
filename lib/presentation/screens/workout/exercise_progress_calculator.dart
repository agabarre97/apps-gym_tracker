import 'dart:math' as math;

import 'package:gym_tracker/domain/entities/workout_session.dart';

/// Available metrics for the exercise progress chart.
enum ProgressMetric {
  /// Sum of (reps * weight) across all sets.
  volume,

  /// Maximum weight lifted in any single set.
  maxWeight,

  /// Sum of reps across all sets.
  totalReps,
}

/// A single data point for the progress chart.
class ProgressDataPoint {
  const ProgressDataPoint({required this.date, required this.value});

  final DateTime date;
  final double value;
}

/// Result of computing progress for an exercise over a period.
class ProgressResult {
  const ProgressResult({
    required this.points,
    required this.firstValue,
    required this.lastValue,
    required this.minValue,
    required this.maxValue,
  });

  /// Chronologically ordered data points.
  final List<ProgressDataPoint> points;

  /// First data point value in the period.
  final double firstValue;

  /// Last data point value in the period.
  final double lastValue;

  /// Minimum value across the period.
  final double minValue;

  /// Maximum value across the period.
  final double maxValue;

  /// Whether there is any data.
  bool get isEmpty => points.isEmpty;

  /// Convenience factory for an empty result.
  static const empty = ProgressResult(
    points: [],
    firstValue: 0,
    lastValue: 0,
    minValue: 0,
    maxValue: 0,
  );
}

/// Computes exercise progress from workout session history.
class ExerciseProgressCalculator {
  const ExerciseProgressCalculator._();

  /// Computes progress for a specific exercise within a routine + day,
  /// filtered to the given period and metric.
  ///
  /// - [sessions]: all workout sessions.
  /// - [routineId]: the routine to filter by.
  /// - [routineDayIndex]: the day index (0-based) to filter by.
  /// - [exerciseKey]: the exercise to track.
  /// - [periodMonths]: how many months back from [now] to include.
  /// - [metric]: which metric to compute.
  /// - [now]: current date (injectable for testing).
  static ProgressResult compute({
    required List<WorkoutSession> sessions,
    required String routineId,
    required int routineDayIndex,
    required String exerciseKey,
    required int periodMonths,
    required ProgressMetric metric,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final cutoff = DateTime(today.year, today.month - periodMonths, today.day);

    // 1. Filter sessions by routine + day + date range
    final filtered = sessions.where((s) =>
        s.routineId == routineId &&
        s.routineDayIndex == routineDayIndex &&
        !s.date.isBefore(cutoff) &&
        !s.date.isAfter(today));

    // 2. For each session, extract the exercise and compute the metric
    final Map<DateTime, List<double>> byDate = {};
    for (final session in filtered) {
      final matches =
          session.exercises.where((e) => e.exerciseKey == exerciseKey);
      if (matches.isEmpty) continue;

      final norm = DateTime(session.date.year, session.date.month, session.date.day);
      final value = _computeMetric(matches.first, metric);
      byDate.putIfAbsent(norm, () => []).add(value);
    }

    if (byDate.isEmpty) return ProgressResult.empty;

    // 3. Aggregate multiple sessions on the same date
    //    volume / totalReps → sum; maxWeight → max
    final points = <ProgressDataPoint>[];
    final sortedDates = byDate.keys.toList()..sort();

    for (final date in sortedDates) {
      final values = byDate[date]!;
      final aggregated = metric == ProgressMetric.maxWeight
          ? values.reduce(math.max)
          : values.reduce((a, b) => a + b);
      points.add(ProgressDataPoint(date: date, value: aggregated));
    }

    final allValues = points.map((p) => p.value);

    return ProgressResult(
      points: points,
      firstValue: points.first.value,
      lastValue: points.last.value,
      minValue: allValues.reduce(math.min),
      maxValue: allValues.reduce(math.max),
    );
  }

  static double _computeMetric(WorkoutExercise ex, ProgressMetric metric) {
    if (ex.sets.isEmpty) return 0;
    switch (metric) {
      case ProgressMetric.volume:
        return ex.sets.fold<double>(0, (sum, s) => sum + s.reps * s.weight);
      case ProgressMetric.maxWeight:
        return ex.sets.map((s) => s.weight).reduce(math.max);
      case ProgressMetric.totalReps:
        return ex.sets.fold<double>(0, (sum, s) => sum + s.reps);
    }
  }
}
