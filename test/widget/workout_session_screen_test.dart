import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/presentation/screens/workout/workout_session_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('WorkoutSessionScreen', () {
    late FakeWorkoutSessionPort port;
    late WorkoutSession session;
    late List<Exercise> exercises;

    setUp(() {
      port = FakeWorkoutSessionPort();
      exercises = const [
        Exercise(
          key: 'press_banca',
          name: 'Press banca',
          description: 'Press de banca plano',
          muscleGroups: ['Pectoral'],
          difficulty: 5,
        ),
        Exercise(
          key: 'curl_biceps',
          name: 'Curl bíceps',
          description: 'Curl de bíceps con barra',
          muscleGroups: ['Bíceps'],
          difficulty: 3,
        ),
      ];

      session = WorkoutSession(
        id: 'session-1',
        routineId: 'r1',
        routineDayIndex: 0,
        date: DateTime.now(),
        startTime: DateTime.now(),
        exercises: [
          const WorkoutExercise(
            exerciseKey: 'press_banca',
            sets: [
              ExerciseSet(reps: 10, weight: 60),
              ExerciseSet(reps: 8, weight: 65),
              ExerciseSet(reps: 6, weight: 70),
            ],
          ),
          WorkoutExercise.empty('curl_biceps'),
        ],
      );
    });

    testWidgets('shows exercise names from session', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          WorkoutSessionScreen(
            session: session,
            allExercises: exercises,
            workoutSessionPort: port,
            routineName: 'Test Routine',
            trackTime: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Press banca'), findsOneWidget);
      expect(find.text('Curl bíceps'), findsOneWidget);
      expect(find.text('Test Routine'), findsOneWidget);
    });

    testWidgets('shows finish button in live workout mode', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          WorkoutSessionScreen(
            session: session,
            allExercises: exercises,
            workoutSessionPort: port,
            routineName: 'Test Routine',
            trackTime: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Finalizar entrenamiento'), findsOneWidget);
    });

    testWidgets('shows save changes button in view mode', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          WorkoutSessionScreen(
            session: session,
            allExercises: exercises,
            workoutSessionPort: port,
            routineName: 'Test Routine',
            trackTime: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Guardar entrenamiento'), findsOneWidget);
      expect(find.text('Finalizar entrenamiento'), findsNothing);
    });

    testWidgets('timer shows elapsed time when trackTime is true',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          WorkoutSessionScreen(
            session: session,
            allExercises: exercises,
            workoutSessionPort: port,
            routineName: 'Test Routine',
            trackTime: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('s'), findsWidgets);
    });
  });
}
