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

/// The heaviest single set recorded for an exercise (nullable for no-data).
class HeaviestSet {
  const HeaviestSet({
    required this.weight,
    required this.reps,
    required this.date,
  });

  final double weight;
  final int reps;
  final DateTime date;
}

/// Data for comparing sets between two training days.
class DayComparisonData {
  const DayComparisonData({
    required this.date,
    required this.sets,
  });

  final DateTime date;
  final List<ExerciseSet> sets;
}

/// Computes exercise progress from workout session history.
class ExerciseProgressCalculator {
  const ExerciseProgressCalculator._();

  /// Computes progress for a specific exercise within a routine + day,
  /// filtered to the given period and metric.
  static ProgressResult compute({
    required List<WorkoutSession> sessions,
    required String routineId,
    required int routineDayIndex,
    required String exerciseKey,
    required int periodMonths,
    required ProgressMetric metric,
    DateTime? cutoffDate,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final cutoff = cutoffDate ??
        DateTime(today.year, today.month - periodMonths, today.day);

    final filtered = sessions.where((s) =>
        s.routineId == routineId &&
        s.routineDayIndex == routineDayIndex &&
        !s.date.isBefore(cutoff) &&
        !s.date.isAfter(today));

    final Map<DateTime, List<double>> byDate = {};
    for (final session in filtered) {
      final matches =
          session.exercises.where((e) => e.exerciseKey == exerciseKey);
      if (matches.isEmpty) continue;

      final norm =
          DateTime(session.date.year, session.date.month, session.date.day);
      final value = _computeMetric(matches.first, metric);
      byDate.putIfAbsent(norm, () => []).add(value);
    }

    if (byDate.isEmpty) return ProgressResult.empty;

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

  /// Finds the heaviest single set across ALL sessions for this exercise
  /// (regardless of period filter).
  static HeaviestSet? computeHeaviestSet({
    required List<WorkoutSession> sessions,
    required String routineId,
    required int routineDayIndex,
    required String exerciseKey,
  }) {
    double maxWeight = -1;
    int maxReps = 0;
    DateTime? maxDate;

    for (final session in sessions) {
      if (session.routineId != routineId ||
          session.routineDayIndex != routineDayIndex) {
        continue;
      }
      for (final ex in session.exercises) {
        if (ex.exerciseKey != exerciseKey) continue;
        for (final s in ex.sets) {
          if (s.weight > maxWeight ||
              (s.weight == maxWeight && s.reps > maxReps)) {
            maxWeight = s.weight;
            maxReps = s.reps;
            maxDate = session.date;
          }
        }
      }
    }

    if (maxDate == null || maxWeight <= 0) return null;
    return HeaviestSet(weight: maxWeight, reps: maxReps, date: maxDate);
  }

  /// Returns the list of unique training dates for this exercise
  /// (sorted descending, newest first).
  static List<DateTime> availableDates({
    required List<WorkoutSession> sessions,
    required String routineId,
    required int routineDayIndex,
    required String exerciseKey,
  }) {
    final dates = <DateTime>{};
    for (final session in sessions) {
      if (session.routineId != routineId ||
          session.routineDayIndex != routineDayIndex) {
        continue;
      }
      final hasExercise =
          session.exercises.any((e) => e.exerciseKey == exerciseKey);
      if (hasExercise) {
        dates.add(
            DateTime(session.date.year, session.date.month, session.date.day));
      }
    }
    final sorted = dates.toList()..sort((a, b) => b.compareTo(a));
    return sorted;
  }

  /// Returns the sets for a specific exercise on a specific date.
  static DayComparisonData? setsForDate({
    required List<WorkoutSession> sessions,
    required String routineId,
    required int routineDayIndex,
    required String exerciseKey,
    required DateTime date,
  }) {
    final norm = DateTime(date.year, date.month, date.day);
    for (final session in sessions) {
      if (session.routineId != routineId ||
          session.routineDayIndex != routineDayIndex) {
        continue;
      }
      final sessionDate =
          DateTime(session.date.year, session.date.month, session.date.day);
      if (sessionDate != norm) continue;
      for (final ex in session.exercises) {
        if (ex.exerciseKey == exerciseKey) {
          return DayComparisonData(date: norm, sets: ex.sets);
        }
      }
    }
    return null;
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
