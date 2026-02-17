import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/presentation/screens/workout/workout_session_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Rest stopwatch E2E', () {
    testWidgets('opens from session timer and supports play/pause/reset',
        (tester) async {
      final session = WorkoutSession(
        id: 's1',
        routineId: 'r1',
        routineDayIndex: 0,
        date: DateTime(2026, 2, 16),
        startTime: DateTime(2026, 2, 16, 10, 0, 0),
        exercises: const [
          WorkoutExercise(
            exerciseKey: 'press_banca',
            sets: [ExerciseSet(reps: 8, weight: 60)],
          ),
        ],
      );
      const exercises = [
        Exercise(
          key: 'press_banca',
          name: 'Press banca',
          description: 'Pecho',
          muscleGroups: ['Pectoral'],
          difficulty: 5,
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          WorkoutSessionScreen(
            session: session,
            allExercises: exercises,
            workoutSessionPort: FakeWorkoutSessionPort(),
            routineName: 'Push',
            trackTime: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.timer_outlined));
      await tester.pumpAndSettle();

      expect(find.text('00:00.00'), findsOneWidget);

      // Play
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump(const Duration(milliseconds: 250));

      // Pause
      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pumpAndSettle();

      expect(find.text('00:00.00'), findsNothing);

      // Reset
      await tester.tap(find.byIcon(Icons.stop_rounded));
      await tester.pumpAndSettle();
      expect(find.text('00:00.00'), findsOneWidget);
    });
  });
}
