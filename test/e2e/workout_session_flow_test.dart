import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/presentation/screens/workout/workout_session_screen.dart';

import '../helpers/scroll_helpers.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Workout session E2E', () {
    late FakeWorkoutSessionPort workoutPort;
    late WorkoutSession session;
    late List<Exercise> exercises;

    setUp(() {
      workoutPort = FakeWorkoutSessionPort();
      exercises = const [
        Exercise(
          key: 'press_banca',
          name: 'Press banca',
          description: 'Pecho',
          muscleGroups: ['Pectoral'],
          difficulty: 5,
        ),
        Exercise(
          key: 'remo_barra',
          name: 'Remo barra',
          description: 'Espalda',
          muscleGroups: ['Dorsal ancho'],
          difficulty: 5,
        ),
      ];

      session = WorkoutSession(
        id: 'session-1',
        routineId: 'routine-1',
        routineDayIndex: 0,
        date: DateTime(2026, 2, 16),
        exercises: const [
          WorkoutExercise(
            exerciseKey: 'press_banca',
            sets: [
              ExerciseSet(reps: 8, weight: 60),
              ExerciseSet(reps: 8, weight: 62.5),
            ],
          ),
          WorkoutExercise(
            exerciseKey: 'remo_barra',
            sets: [
              ExerciseSet(reps: 10, weight: 40),
            ],
          ),
        ],
      );
    });

    testWidgets('fills reps and weights, then persists saved session',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          WorkoutSessionScreen(
            session: session,
            allExercises: exercises,
            workoutSessionPort: workoutPort,
            routineName: 'Push Pull',
            trackTime: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expand first exercise.
      await tester.tap(find.text('Press banca'));
      await tester.pumpAndSettle();
      expect(find.text('Serie 1'), findsOneWidget);

      // Increase reps (+1) and weight (+1.25) on first set.
      final addButtons = find.byIcon(Icons.add);
      await tester.tap(addButtons.at(0)); // reps +1
      await tester.pumpAndSettle();
      await tester.tap(addButtons.at(1)); // weight +1.25
      await tester.pumpAndSettle();

      // Complete pending sets through single CTA, then finish exercise.
      await tester.scrollToAndTap(find.text('Finalizar serie 1'));
      await tester.scrollToAndTap(find.text('Finalizar serie 2'));
      await tester.scrollToAndTap(find.text('Finalizar ejercicio'));

      // Save full session changes.
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      final savedSessions = await workoutPort.loadSessions();
      expect(savedSessions, hasLength(1));
      final firstSet = savedSessions.first.exercises.first.sets.first;
      expect(firstSet.reps, 9);
      expect(firstSet.weight, 61.25);
      expect(savedSessions.first.exercises.first.completed, isTrue);
    });
  });
}
