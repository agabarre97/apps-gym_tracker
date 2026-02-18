import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/domain/services/workout_session_builder.dart';

void main() {
  group('Workout reference timeline flow', () {
    const routine = Routine(
      id: 'routine-1',
      name: 'Push',
      type: 'musculacion',
      days: [
        RoutineDay(
          muscleGroups: ['pectoral'],
          exerciseKeys: ['bench_press'],
        ),
      ],
    );

    test('retroactive date uses previous calendar training, not future one',
        () {
      final day11 = WorkoutSession(
        id: 'day11',
        routineId: 'routine-1',
        routineDayIndex: 0,
        date: DateTime(2026, 2, 11),
        exercises: const [
          WorkoutExercise(
            exerciseKey: 'bench_press',
            sets: [ExerciseSet(reps: 8, weight: 72.5)],
          ),
        ],
      );
      final day16 = WorkoutSession(
        id: 'day16',
        routineId: 'routine-1',
        routineDayIndex: 0,
        date: DateTime(2026, 2, 16),
        exercises: const [
          WorkoutExercise(
            exerciseKey: 'bench_press',
            sets: [ExerciseSet(reps: 6, weight: 80)],
          ),
        ],
      );

      final sessionForDay13 = WorkoutSessionBuilder.build(
        id: 'day13',
        routine: routine,
        dayIndex: 0,
        date: DateTime(2026, 2, 13),
        trackTime: false,
        previousSessions: [day11, day16],
      );

      expect(sessionForDay13.exercises.first.sets.first.reps, 8);
      expect(sessionForDay13.exercises.first.sets.first.weight, 72.5);
    });
  });
}
