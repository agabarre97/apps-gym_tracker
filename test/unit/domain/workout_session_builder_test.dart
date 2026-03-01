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
          exerciseConfigs: [
            RoutineExerciseConfig(
              exerciseKey: 'bench_press',
              restSeconds: 120,
              setConfigs: [
                RoutineSetConfig(targetReps: 8),
                RoutineSetConfig(targetReps: 8),
                RoutineSetConfig(targetReps: 8),
                RoutineSetConfig(targetReps: 8),
              ],
            ),
            RoutineExerciseConfig(
              exerciseKey: 'incline_press',
              setConfigs: [
                RoutineSetConfig(targetReps: 12),
                RoutineSetConfig(targetReps: 12),
              ],
            ),
          ],
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
      expect(session.exercises[0].sets.length, 4);
      expect(session.exercises[0].sets.first.reps, 8);
      expect(session.exercises[0].sets.first.plannedRestSeconds, 120);
      expect(session.exercises[0].restSeconds, 120);
      expect(session.exercises[1].exerciseKey, 'incline_press');
      expect(session.exercises[1].sets.length, 2);
      expect(session.exercises[1].sets.first.reps, 12);
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
      expect(benchSets.length, 4);
      expect(benchSets[0].reps, 10);
      expect(benchSets[0].weight, 80);
      expect(benchSets[1].reps, 8);
      expect(benchSets[1].weight, 85);
      expect(benchSets[2].reps, 8);
      expect(benchSets[3].reps, 8);
      expect(benchSets[0].plannedRestSeconds, 120);
      // Notes and completed should NOT carry over
      expect(session.exercises[0].notes, '');
      expect(session.exercises[0].completed, false);

      // incline_press has no previous data — should use routine defaults
      expect(session.exercises[1].exerciseKey, 'incline_press');
      expect(session.exercises[1].sets.length, 2);
      expect(session.exercises[1].sets.first.reps, 12);
      expect(session.exercises[0].restSeconds, 120);
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

      // Should use routine defaults since previous is for another routine.
      expect(session.exercises[0].sets.length, 4);
      expect(session.exercises[0].sets[0].reps, 8);
    });

    test('trims previous sets to configured set count', () {
      final previous = WorkoutSession(
        id: 'prev-many',
        routineId: 'r1',
        routineDayIndex: 0,
        date: DateTime(2026, 2, 14),
        exercises: [
          const WorkoutExercise(
            exerciseKey: 'incline_press',
            sets: [
              ExerciseSet(reps: 12, weight: 30),
              ExerciseSet(reps: 10, weight: 32.5),
              ExerciseSet(reps: 8, weight: 35),
            ],
          ),
        ],
      );

      final session = WorkoutSessionBuilder.build(
        id: 'session-trim',
        routine: routine,
        dayIndex: 0,
        date: DateTime(2026, 2, 16),
        trackTime: false,
        previousSessions: [previous],
      );

      final incline = session.exercises[1];
      expect(incline.sets.length, 2);
      expect(incline.sets[0].weight, 30);
      expect(incline.sets[1].weight, 32.5);
    });

    test('uses day 16 as reference when creating on day 18', () {
      final day11 = WorkoutSession(
        id: 'day11',
        routineId: 'r1',
        routineDayIndex: 0,
        date: DateTime(2026, 2, 11),
        exercises: [
          const WorkoutExercise(
            exerciseKey: 'bench_press',
            sets: [ExerciseSet(reps: 8, weight: 70)],
            notes: '',
            completed: true,
          ),
        ],
      );
      final day16 = WorkoutSession(
        id: 'day16',
        routineId: 'r1',
        routineDayIndex: 0,
        date: DateTime(2026, 2, 16),
        exercises: [
          const WorkoutExercise(
            exerciseKey: 'bench_press',
            sets: [ExerciseSet(reps: 6, weight: 80)],
            notes: '',
            completed: true,
          ),
        ],
      );

      final session = WorkoutSessionBuilder.build(
        id: 'day18',
        routine: routine,
        dayIndex: 0,
        date: DateTime(2026, 2, 18),
        trackTime: false,
        previousSessions: [day11, day16],
      );

      expect(session.exercises.first.sets.first.reps, 6);
      expect(session.exercises.first.sets.first.weight, 80);
    });

    test('uses day 11 as reference when creating retroactively on day 13', () {
      final day11 = WorkoutSession(
        id: 'day11',
        routineId: 'r1',
        routineDayIndex: 0,
        date: DateTime(2026, 2, 11),
        exercises: [
          const WorkoutExercise(
            exerciseKey: 'bench_press',
            sets: [ExerciseSet(reps: 8, weight: 70)],
            notes: '',
            completed: true,
          ),
        ],
      );
      final day16 = WorkoutSession(
        id: 'day16',
        routineId: 'r1',
        routineDayIndex: 0,
        date: DateTime(2026, 2, 16),
        exercises: [
          const WorkoutExercise(
            exerciseKey: 'bench_press',
            sets: [ExerciseSet(reps: 6, weight: 80)],
            notes: '',
            completed: true,
          ),
        ],
      );

      final session = WorkoutSessionBuilder.build(
        id: 'day13',
        routine: routine,
        dayIndex: 0,
        date: DateTime(2026, 2, 13),
        trackTime: false,
        previousSessions: [day11, day16],
      );

      expect(session.exercises.first.sets.first.reps, 8);
      expect(session.exercises.first.sets.first.weight, 70);
    });

    test('does not use future sessions as reference', () {
      final day11 = WorkoutSession(
        id: 'day11',
        routineId: 'r1',
        routineDayIndex: 0,
        date: DateTime(2026, 2, 11),
        exercises: [
          const WorkoutExercise(
            exerciseKey: 'bench_press',
            sets: [ExerciseSet(reps: 8, weight: 70)],
            notes: '',
            completed: true,
          ),
        ],
      );
      final day18 = WorkoutSession(
        id: 'day18',
        routineId: 'r1',
        routineDayIndex: 0,
        date: DateTime(2026, 2, 18),
        exercises: [
          const WorkoutExercise(
            exerciseKey: 'bench_press',
            sets: [ExerciseSet(reps: 4, weight: 90)],
            notes: '',
            completed: true,
          ),
        ],
      );

      final session = WorkoutSessionBuilder.build(
        id: 'day16',
        routine: routine,
        dayIndex: 0,
        date: DateTime(2026, 2, 16),
        trackTime: false,
        previousSessions: [day11, day18],
      );

      expect(session.exercises.first.sets.first.reps, 8);
      expect(session.exercises.first.sets.first.weight, 70);
    });

    test('for same day, picks immediately previous session by startTime', () {
      final morning = WorkoutSession(
        id: 'morning',
        routineId: 'r1',
        routineDayIndex: 0,
        date: DateTime(2026, 2, 16),
        startTime: DateTime(2026, 2, 16, 9, 0),
        exercises: [
          const WorkoutExercise(
            exerciseKey: 'bench_press',
            sets: [ExerciseSet(reps: 9, weight: 72.5)],
            notes: '',
            completed: true,
          ),
        ],
      );
      final noon = WorkoutSession(
        id: 'noon',
        routineId: 'r1',
        routineDayIndex: 0,
        date: DateTime(2026, 2, 16),
        startTime: DateTime(2026, 2, 16, 12, 0),
        exercises: [
          const WorkoutExercise(
            exerciseKey: 'bench_press',
            sets: [ExerciseSet(reps: 7, weight: 77.5)],
            notes: '',
            completed: true,
          ),
        ],
      );

      final session = WorkoutSessionBuilder.build(
        id: 'afternoon',
        routine: routine,
        dayIndex: 0,
        date: DateTime(2026, 2, 16),
        trackTime: false,
        previousSessions: [morning, noon],
        overrideStartTime: DateTime(2026, 2, 16, 15, 0),
      );

      expect(session.exercises.first.sets.first.reps, 7);
      expect(session.exercises.first.sets.first.weight, 77.5);
    });
  });
}
