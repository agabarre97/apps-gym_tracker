import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/presentation/screens/routine/routine_detail_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Routine PDF export E2E', () {
    testWidgets('share sheet includes Exportar PDF option', (tester) async {
      const routine = Routine(
        id: 'r1',
        name: 'Push day',
        type: 'musculacion',
        days: [
          RoutineDay(
            muscleGroups: ['pectoral'],
            exerciseKeys: ['press_banca'],
          ),
        ],
      );
      const exercises = [
        Exercise(
          key: 'press_banca',
          name: 'Press banca',
          description: 'desc',
          muscleGroups: ['Pectoral'],
          difficulty: 4,
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          RoutineDetailScreen(
            routine: routine,
            allRoutines: const [routine],
            routinePort: FakeRoutinePort(),
            allExercises: exercises,
            workoutSessionPort: FakeWorkoutSessionPort(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();
      expect(find.text('Exportar PDF'), findsOneWidget);

      await tester.tap(find.text('Exportar PDF'));
      await tester.pumpAndSettle();
    });
  });
}
