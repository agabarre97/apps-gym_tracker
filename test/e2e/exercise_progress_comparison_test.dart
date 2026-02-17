import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/presentation/screens/workout/exercise_progress_screen.dart';

import '../helpers/scroll_helpers.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Exercise progress comparison E2E', () {
    late FakeWorkoutSessionPort workoutPort;

    setUp(() {
      workoutPort = FakeWorkoutSessionPort();
    });

    Future<void> seedSessions() async {
      await workoutPort.saveSessions([
        WorkoutSession(
          id: 's1',
          routineId: 'r1',
          routineDayIndex: 0,
          date: DateTime(2026, 1, 5),
          exercises: const [
            WorkoutExercise(
              exerciseKey: 'bench_press',
              sets: [ExerciseSet(reps: 12, weight: 60)],
              completed: true,
            ),
          ],
        ),
        WorkoutSession(
          id: 's2',
          routineId: 'r1',
          routineDayIndex: 0,
          date: DateTime(2026, 1, 20),
          exercises: const [
            WorkoutExercise(
              exerciseKey: 'bench_press',
              sets: [
                ExerciseSet(reps: 10, weight: 65),
                ExerciseSet(reps: 8, weight: 65)
              ],
              completed: true,
            ),
          ],
        ),
        WorkoutSession(
          id: 's3',
          routineId: 'r1',
          routineDayIndex: 0,
          date: DateTime(2026, 2, 10),
          exercises: const [
            WorkoutExercise(
              exerciseKey: 'bench_press',
              sets: [
                ExerciseSet(reps: 8, weight: 70),
                ExerciseSet(reps: 6, weight: 75)
              ],
              completed: true,
            ),
          ],
        ),
      ]);
    }

    testWidgets('changes selected day and updates comparison section',
        (tester) async {
      await seedSessions();

      await tester.pumpWidget(
        buildTestableWidget(
          ExerciseProgressScreen(
            workoutSessionPort: workoutPort,
            routineId: 'r1',
            routineDayIndex: 0,
            exerciseKey: 'bench_press',
            exerciseDisplayName: 'Press de banca',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollDownTo(find.text('Comparar días'));
      expect(find.text('Día 1'), findsOneWidget);
      expect(find.text('Día 2'), findsOneWidget);
      expect(find.byType(BarChart), findsOneWidget);

      // Open day 1 picker and select oldest date.
      await tester.tap(find.text('Día 1'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsAtLeast(3));
      await tester.tap(find.text('05/01/2026').last);
      await tester.pumpAndSettle();

      // Selector/legend should include new chosen date.
      expect(find.text('05/01/2026'), findsWidgets);
      expect(find.byType(BarChart), findsOneWidget);
    });
  });
}
