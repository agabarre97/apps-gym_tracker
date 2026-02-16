import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/presentation/screens/workout/workout_session_screen.dart';

import '../helpers/scroll_helpers.dart';
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
        date: DateTime(2026, 2, 13),
        startTime: DateTime(2026, 2, 13, 10, 0, 0),
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

    testWidgets('expanding exercise card shows sets', (tester) async {
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

      // Tap first exercise to expand it
      await tester.tap(find.text('Press banca'));
      await tester.pumpAndSettle();

      // Should see set labels (Spanish locale: "Serie 1", "Serie 2", "Serie 3")
      expect(find.text('Serie 1'), findsOneWidget);
      expect(find.text('Serie 2'), findsOneWidget);
      expect(find.text('Serie 3'), findsOneWidget);

      // Should see Reps and Weight headers
      expect(find.text('Reps'), findsOneWidget);
      expect(find.text('Peso (kg)'), findsOneWidget);
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

      // Should show "Guardar cambios" instead of "Finalizar entrenamiento"
      expect(find.text('Guardar cambios'), findsOneWidget);
      expect(find.text('Finalizar entrenamiento'), findsNothing);

      // Button should be disabled (no changes made)
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Guardar cambios'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('saving exercise persists to port', (tester) async {
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

      // Expand first exercise
      await tester.tap(find.text('Press banca'));
      await tester.pumpAndSettle();

      // Scroll to the Save button and tap
      await tester.scrollToAndTap(find.text('Guardar'));

      // Session should have been persisted
      final saved = await port.loadSessions();
      expect(saved.length, 1);
      expect(saved[0].exercises[0].completed, true);
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

      // Timer icon should be present
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });

    testWidgets('timer is hidden when trackTime is false', (tester) async {
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

      expect(find.byIcon(Icons.timer_outlined), findsNothing);
    });

    testWidgets('+/- buttons are visible when exercise is expanded',
        (tester) async {
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

      // Expand first exercise
      await tester.tap(find.text('Press banca'));
      await tester.pumpAndSettle();

      // Should see add (+) and remove (-) step buttons (InkWell with icons)
      // Each set row has 2 pairs of +/- buttons (reps + weight) = 4 icons per row
      // 3 sets × 2 add + 2 remove = 12 total stepper icons
      expect(find.byIcon(Icons.add), findsWidgets);
      expect(find.byIcon(Icons.remove), findsWidgets);
    });

    testWidgets('tapping + reps increments the value', (tester) async {
      // Create session with a single exercise and 1 set at reps=5
      final singleSession = WorkoutSession(
        id: 'session-2',
        routineId: 'r1',
        routineDayIndex: 0,
        date: DateTime(2026, 2, 13),
        startTime: DateTime(2026, 2, 13, 10, 0, 0),
        exercises: [
          const WorkoutExercise(
            exerciseKey: 'press_banca',
            sets: [ExerciseSet(reps: 5, weight: 60)],
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestableWidget(
          WorkoutSessionScreen(
            session: singleSession,
            allExercises: exercises,
            workoutSessionPort: port,
            routineName: 'Test Routine',
            trackTime: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expand first exercise
      await tester.tap(find.text('Press banca'));
      await tester.pumpAndSettle();

      // Find all + icons (there should be 2: one for reps, one for weight)
      // Plus the add-set button icon = 3 total Icons.add
      final addIcons = find.byIcon(Icons.add);

      // The first + icon is for reps (first stepper in the row)
      await tester.tap(addIcons.first);
      await tester.pumpAndSettle();

      // After tapping, the reps field should now show 6
      // Check that a text field contains "6"
      final repsField = find.byType(TextField).first;
      final controller =
          (tester.widget<TextField>(repsField)).controller;
      expect(controller?.text, '6');
    });
  });
}
