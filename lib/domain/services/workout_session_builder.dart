import 'dart:math' as math;

import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';

/// Pure-domain helper that builds a new [WorkoutSession] for a given routine
/// day, optionally pre-filling sets from the most recent matching session.
///
/// This was extracted from `LandingScreen` to keep the screen focused on
/// navigation and UI, while the session-creation logic stays in the domain.
class WorkoutSessionBuilder {
  const WorkoutSessionBuilder._();

  static DateTime _effectiveSessionTime(WorkoutSession session) {
    return session.startTime ?? session.date;
  }

  /// Splits [previousSets] into ordered main sets and drops grouped by parent
  /// main-set number (1-based).
  static ({
    List<ExerciseSet> mainSets,
    Map<int, List<ExerciseSet>> dropsByParent,
  }) _partitionPreviousSets(List<ExerciseSet> previousSets) {
    final mainSets = <ExerciseSet>[];
    final dropsByParent = <int, List<ExerciseSet>>{};
    for (final set in previousSets) {
      if (set.isDropSet) {
        final parent = set.dropParentSetNumber;
        if (parent != null) {
          dropsByParent.putIfAbsent(parent, () => []).add(set);
        }
      } else {
        mainSets.add(set);
      }
    }
    return (mainSets: mainSets, dropsByParent: dropsByParent);
  }

  static List<ExerciseSet> _buildSetsFromConfig({
    required RoutineExerciseConfig config,
    required List<ExerciseSet> previousSets,
  }) {
    final partitioned = _partitionPreviousSets(previousSets);
    final prevMainSets = partitioned.mainSets;
    final prevDropsByParent = partitioned.dropsByParent;

    final setConfigs = config.setConfigs.isEmpty
        ? const [
            RoutineSetConfig(),
            RoutineSetConfig(),
            RoutineSetConfig(),
          ]
        : config.setConfigs;

    final result = <ExerciseSet>[];

    for (var setIndex = 0; setIndex < setConfigs.length; setIndex++) {
      final setConfig = setConfigs[setIndex];
      final parentNumber = setIndex + 1;

      final prevMain =
          setIndex < prevMainSets.length ? prevMainSets[setIndex] : null;
      result.add(
        ExerciseSet(
          reps: prevMain?.reps ?? setConfig.targetReps,
          weight: prevMain?.weight ?? 0,
          targetReps: setConfig.targetReps,
          plannedRestSeconds: config.restSeconds ?? setConfig.restSeconds,
          isDropSet: false,
          notes: prevMain?.notes ?? '',
        ),
      );

      final prevDrops = prevDropsByParent[parentNumber] ?? const [];
      final dropCount = math.max(setConfig.dropSetCount, prevDrops.length);

      for (var dropIndex = 0; dropIndex < dropCount; dropIndex++) {
        final dropTarget = setConfig.copyWith(
          targetReps: setConfig.dropSetReps ?? setConfig.targetReps,
          clearRestSeconds: true,
        );
        final prevDrop =
            dropIndex < prevDrops.length ? prevDrops[dropIndex] : null;
        result.add(
          ExerciseSet(
            reps: prevDrop?.reps ?? dropTarget.targetReps,
            weight: prevDrop?.weight ?? 0,
            targetReps: dropTarget.targetReps,
            plannedRestSeconds: config.restSeconds ?? dropTarget.restSeconds,
            isDropSet: true,
            dropParentSetNumber: parentNumber,
            notes: prevDrop?.notes ?? '',
          ),
        );
      }
    }

    return result;
  }

  /// Finds the most recent [WorkoutExercise] for [exerciseKey] in [matching]
  /// sessions (already sorted newest-first) that has at least one set.
  static WorkoutExercise? _findLatestExerciseWithSets(
    List<WorkoutSession> matchingNewestFirst,
    String exerciseKey,
  ) {
    for (final session in matchingNewestFirst) {
      for (final ex in session.exercises) {
        if (ex.exerciseKey == exerciseKey && ex.sets.isNotEmpty) {
          return ex;
        }
      }
    }
    return null;
  }

  /// Builds a [WorkoutSession] for the given [routine] and [dayIndex],
  /// auto-filling exercise sets from the latest matching session in
  /// [previousSessions] that is not later than the target session time.
  ///
  /// For each exercise, reference data is taken from the most recent matching
  /// session that actually contains that exercise (not necessarily the same
  /// session for every exercise).
  ///
  /// - [id]: unique session identifier (typically a UUID).
  /// - [date]: calendar date for the session.
  /// - [trackTime]: if true, records the current time as [startTime].
  static WorkoutSession build({
    required String id,
    required Routine routine,
    required int dayIndex,
    required DateTime date,
    required bool trackTime,
    required List<WorkoutSession> previousSessions,
    DateTime? overrideStartTime,
    DateTime? overrideEndTime,
  }) {
    final day = routine.days[dayIndex];
    final targetSessionTime = overrideStartTime ?? date;

    // Sessions for same routine + day, not after target time; newest first.
    final matching = previousSessions
        .where((session) =>
            session.routineId == routine.id &&
            session.routineDayIndex == dayIndex &&
            !_effectiveSessionTime(session).isAfter(targetSessionTime))
        .toList()
      ..sort((a, b) =>
          _effectiveSessionTime(b).compareTo(_effectiveSessionTime(a)));

    // Build exercise list
    final exercises = day.exerciseKeys.map((key) {
      final config =
          day.configForExercise(key) ?? RoutineExerciseConfig(exerciseKey: key);
      final prevEx = _findLatestExerciseWithSets(matching, key);
      final previousSets = prevEx?.sets ?? const <ExerciseSet>[];

      return WorkoutExercise(
        exerciseKey: key,
        sets: _buildSetsFromConfig(
          config: config,
          previousSets: previousSets,
        ),
        notes: '',
        completed: false,
        restSeconds: config.restSeconds,
      );
    }).toList();

    return WorkoutSession(
      id: id,
      routineId: routine.id,
      routineDayIndex: dayIndex,
      date: date,
      startTime: overrideStartTime ?? (trackTime ? DateTime.now() : null),
      endTime: overrideEndTime,
      exercises: exercises,
    );
  }
}
