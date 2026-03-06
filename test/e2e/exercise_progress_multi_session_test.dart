import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/presentation/screens/workout/exercise_progress_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Exercise progress multi-session E2E', () {
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
          date: DateTime(2026, 1, 10),
          exercises: const [
            WorkoutExercise(
              exerciseKey: 'bench_press',
              sets: [
                ExerciseSet(reps: 10, weight: 50),
                ExerciseSet(reps: 8, weight: 55)
              ],
              completed: true,
            ),
          ],
        ),
        WorkoutSession(
          id: 's2',
          routineId: 'r1',
          routineDayIndex: 0,
          date: DateTime(2026, 2, 1),
          exercises: const [
            WorkoutExercise(
              exerciseKey: 'bench_press',
              sets: [
                ExerciseSet(reps: 12, weight: 60),
                ExerciseSet(reps: 10, weight: 65)
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

    testWidgets('renders chart, summary changes with period and metric',
        (tester) async {
      await seedSessions();

      DateTime fixedNow() => DateTime(2026, 2, 20);

      await tester.pumpWidget(
        buildTestableWidget(
          ExerciseProgressScreen(
            workoutSessionPort: workoutPort,
            profile: sampleProfile(),
            routineId: 'r1',
            routineDayIndex: 0,
            exerciseKey: 'bench_press',
            exerciseDisplayName: 'Press de banca',
            clock: fixedNow,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('Serie más pesada'), findsOneWidget);
      expect(find.textContaining('75kg'), findsOneWidget);

      // Volume summary values with 3 data points.
      expect(find.text('940'), findsWidgets);
      expect(find.text('1010'), findsWidgets);
      expect(find.text('1370'), findsWidgets);

      // Period filter to 1 month should drop Jan session.
      await tester.tap(find.text('1 mes'));
      await tester.pumpAndSettle();
      expect(find.text('1370'), findsWidgets);
      expect(find.text('1010'), findsWidgets);

      // Metric switches update summary scale.
      await tester.tap(find.text('Peso máximo'));
      await tester.pumpAndSettle();
      expect(find.text('75'), findsWidgets);

      await tester.tap(find.text('Reps totales'));
      await tester.pumpAndSettle();
      expect(find.text('22'), findsWidgets);
      expect(find.text('14'), findsWidgets);
    });
  });
}
