import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/presentation/screens/workout/exercise_progress_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  late FakeWorkoutSessionPort fakePort;

  setUp(() {
    fakePort = FakeWorkoutSessionPort();
  });

  Widget buildScreen() {
    return buildTestableWidget(
      ExerciseProgressScreen(
        workoutSessionPort: fakePort,
        routineId: 'r1',
        routineDayIndex: 0,
        exerciseKey: 'bench_press',
        exerciseDisplayName: 'Press de banca',
      ),
    );
  }

  /// Seeds the fake port with sessions covering different dates.
  Future<void> seedSessions() async {
    await fakePort.saveSessions([
      WorkoutSession(
        id: 's1',
        routineId: 'r1',
        routineDayIndex: 0,
        date: DateTime(2026, 1, 10),
        exercises: [
          const WorkoutExercise(
            exerciseKey: 'bench_press',
            sets: [
              ExerciseSet(reps: 10, weight: 50),
              ExerciseSet(reps: 8, weight: 55),
            ],
            completed: true,
          ),
        ],
      ),
      WorkoutSession(
        id: 's2',
        routineId: 'r1',
        routineDayIndex: 0,
        date: DateTime(2026, 2, 5),
        exercises: [
          const WorkoutExercise(
            exerciseKey: 'bench_press',
            sets: [
              ExerciseSet(reps: 10, weight: 60),
              ExerciseSet(reps: 8, weight: 65),
            ],
            completed: true,
          ),
        ],
      ),
    ]);
  }

  group('ExerciseProgressScreen', () {
    testWidgets('shows exercise display name in app bar', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Press de banca'), findsOneWidget);
    });

    testWidgets('shows period chips', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('1 mes'), findsOneWidget);
      expect(find.text('3 meses'), findsOneWidget);
      expect(find.text('6 meses'), findsOneWidget);
      expect(find.text('12 meses'), findsOneWidget);
    });

    testWidgets('shows metric segment buttons', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Volumen (kg)'), findsOneWidget);
      expect(find.text('Peso máximo'), findsOneWidget);
      expect(find.text('Reps totales'), findsOneWidget);
    });

    testWidgets('shows empty state when no data', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('No hay datos en este periodo'), findsOneWidget);
    });

    testWidgets('shows chart and summary when data exists', (tester) async {
      await seedSessions();
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Summary labels
      expect(find.text('Primer registro'), findsOneWidget);
      expect(find.text('Último registro'), findsOneWidget);
      expect(find.text('Mínimo'), findsOneWidget);
      expect(find.text('Máximo'), findsOneWidget);

      // No empty state
      expect(find.text('No hay datos en este periodo'), findsNothing);
    });

    testWidgets('changing period chip updates view', (tester) async {
      await seedSessions();
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Default is 3 months which includes both sessions.
      // Switch to 1 month → only Feb session should remain.
      await tester.tap(find.text('1 mes'));
      await tester.pumpAndSettle();

      // Summary should still appear (there is 1 data point).
      expect(find.text('Primer registro'), findsOneWidget);
    });

    testWidgets('changing metric updates view', (tester) async {
      await seedSessions();
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Tap on "Peso máximo" metric
      await tester.tap(find.text('Peso máximo'));
      await tester.pumpAndSettle();

      // Summary should still be visible with data.
      expect(find.text('Primer registro'), findsOneWidget);
      expect(find.text('Último registro'), findsOneWidget);
    });

    testWidgets('empty state shown when period has no data', (tester) async {
      // Seed a session far in the past (>12 months ago)
      await fakePort.saveSessions([
        WorkoutSession(
          id: 's-old',
          routineId: 'r1',
          routineDayIndex: 0,
          date: DateTime(2024, 1, 1),
          exercises: [
            const WorkoutExercise(
              exerciseKey: 'bench_press',
              sets: [ExerciseSet(reps: 10, weight: 50)],
              completed: true,
            ),
          ],
        ),
      ]);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('No hay datos en este periodo'), findsOneWidget);
    });
  });
}
