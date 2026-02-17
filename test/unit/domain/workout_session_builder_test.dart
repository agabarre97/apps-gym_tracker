import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/domain/services/workout_session_builder.dart';

void main() {
  group('WorkoutSessionBuilder', () {
    const routine = Routine(
      id: 'r1',
      name: 'Push',
      type: 'musculacion',
      days: [
        RoutineDay(
          muscleGroups: ['pectoral'],
          exerciseKeys: ['bench_press', 'incline_press'],
        ),
      ],
    );

    test('builds empty sets when no previous sessions exist', () {
      final session = WorkoutSessionBuilder.build(
        id: 'session1',
        routine: routine,
        dayIndex: 0,
        date: DateTime(2026, 2, 16),
        trackTime: false,
        previousSessions: [],
      );

      expect(session.id, 'session1');
      expect(session.routineId, 'r1');
      expect(session.routineDayIndex, 0);
      expect(session.startTime, isNull);
      expect(session.exercises.length, 2);
      expect(session.exercises[0].exerciseKey, 'bench_press');
      expect(session.exercises[0].sets.length, 3); // default empty sets
      expect(session.exercises[1].exerciseKey, 'incline_press');
    });

    test('records startTime when trackTime is true', () {
      final before = DateTime.now();
      final session = WorkoutSessionBuilder.build(
        id: 'session2',
        routine: routine,
        dayIndex: 0,
        date: DateTime(2026, 2, 16),
        trackTime: true,
        previousSessions: [],
      );
      final after = DateTime.now();

      expect(session.startTime, isNotNull);
      expect(
          session.startTime!
              .isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue);
      expect(session.startTime!.isBefore(after.add(const Duration(seconds: 1))),
          isTrue);
    });

    test('auto-fills sets from most recent matching session', () {
      final previous = WorkoutSession(
        id: 'prev1',
        routineId: 'r1',
        routineDayIndex: 0,
        date: DateTime(2026, 2, 14),
        exercises: [
          const WorkoutExercise(
            exerciseKey: 'bench_press',
            sets: [
              ExerciseSet(reps: 10, weight: 80),
              ExerciseSet(reps: 8, weight: 85),
            ],
            notes: 'Good form',
            completed: true,
          ),
        ],
      );

      final session = WorkoutSessionBuilder.build(
        id: 'session3',
        routine: routine,
        dayIndex: 0,
        date: DateTime(2026, 2, 16),
        trackTime: false,
        previousSessions: [previous],
      );

      // bench_press should be pre-filled from previous session
      final benchSets = session.exercises[0].sets;
      expect(benchSets.length, 2);
      expect(benchSets[0].reps, 10);
      expect(benchSets[0].weight, 80);
      expect(benchSets[1].reps, 8);
      expect(benchSets[1].weight, 85);
      // Notes and completed should NOT carry over
      expect(session.exercises[0].notes, '');
      expect(session.exercises[0].completed, false);

      // incline_press has no previous data — should be empty default
      expect(session.exercises[1].exerciseKey, 'incline_press');
      expect(session.exercises[1].sets.length, 3);
    });

    test('picks the latest previous session when multiple exist', () {
      final older = WorkoutSession(
        id: 'older',
        routineId: 'r1',
        routineDayIndex: 0,
        date: DateTime(2026, 2, 10),
        exercises: [
          const WorkoutExercise(
            exerciseKey: 'bench_press',
            sets: [ExerciseSet(reps: 5, weight: 50)],
            notes: '',
            completed: true,
          ),
        ],
      );
      final newer = WorkoutSession(
        id: 'newer',
        routineId: 'r1',
        routineDayIndex: 0,
        date: DateTime(2026, 2, 14),
        exercises: [
          const WorkoutExercise(
            exerciseKey: 'bench_press',
            sets: [ExerciseSet(reps: 12, weight: 100)],
            notes: '',
            completed: true,
          ),
        ],
      );

      final session = WorkoutSessionBuilder.build(
        id: 'session4',
        routine: routine,
        dayIndex: 0,
        date: DateTime(2026, 2, 16),
        trackTime: false,
        previousSessions: [older, newer],
      );

      // Should pick the newer session
      expect(session.exercises[0].sets[0].weight, 100);
      expect(session.exercises[0].sets[0].reps, 12);
    });

    test('ignores previous sessions for different routine or day', () {
      final differentRoutine = WorkoutSession(
        id: 'diff',
        routineId: 'r_other',
        routineDayIndex: 0,
        date: DateTime(2026, 2, 14),
        exercises: [
          const WorkoutExercise(
            exerciseKey: 'bench_press',
            sets: [ExerciseSet(reps: 99, weight: 999)],
            notes: '',
            completed: true,
          ),
        ],
      );

      final session = WorkoutSessionBuilder.build(
        id: 'session5',
        routine: routine,
        dayIndex: 0,
        date: DateTime(2026, 2, 16),
        trackTime: false,
        previousSessions: [differentRoutine],
      );

      // Should be empty sets since the previous session is for a different routine
      expect(session.exercises[0].sets.length, 3);
      expect(session.exercises[0].sets[0].reps, 0);
    });
  });
}
