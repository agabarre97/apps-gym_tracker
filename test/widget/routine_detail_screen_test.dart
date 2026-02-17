import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/presentation/screens/routine/routine_detail_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
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
      description: 'Descripción',
      muscleGroups: ['pectoral'],
      difficulty: 3,
    ),
  ];

  group('RoutineDetailScreen', () {
    testWidgets('export button is visible in app bar', (tester) async {
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

      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('tapping export button shows bottom sheet with options',
        (tester) async {
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

      expect(find.text('Copiar al portapapeles'), findsOneWidget);
      expect(find.text('Compartir'), findsOneWidget);
    });

    testWidgets('copy to clipboard shows snackbar confirmation',
        (tester) async {
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

      await tester.tap(find.text('Copiar al portapapeles'));
      await tester.pumpAndSettle();

      expect(find.text('Rutina copiada al portapapeles'), findsOneWidget);
    });
  });
}
