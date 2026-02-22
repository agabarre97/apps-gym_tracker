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
            profilePort: FakeProfilePort(),
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
            profilePort: FakeProfilePort(),
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
            profilePort: FakeProfilePort(),
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

    testWidgets('reordering a day exercises persists new exerciseKeys order',
        (tester) async {
      final routinePort = FakeRoutinePort();
      const reorderRoutine = Routine(
        id: 'r-reorder',
        name: 'Pull day',
        type: 'musculacion',
        days: [
          RoutineDay(
            muscleGroups: ['espalda'],
            exerciseKeys: ['jalon_abierto', 'remo_barra'],
          ),
        ],
      );
      const reorderExercises = [
        Exercise(
          key: 'jalon_abierto',
          name: 'Jalón abierto',
          description: 'Descripción',
          muscleGroups: ['espalda'],
          difficulty: 3,
        ),
        Exercise(
          key: 'remo_barra',
          name: 'Remo barra',
          description: 'Descripción',
          muscleGroups: ['espalda'],
          difficulty: 3,
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          RoutineDetailScreen(
            routine: reorderRoutine,
            allRoutines: const [reorderRoutine],
            routinePort: routinePort,
            allExercises: reorderExercises,
            workoutSessionPort: FakeWorkoutSessionPort(),
            profilePort: FakeProfilePort(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final jalonBefore = tester.getTopLeft(find.text('Jalón abierto')).dy;
      final remoBefore = tester.getTopLeft(find.text('Remo barra')).dy;
      expect(jalonBefore, lessThan(remoBefore));

      await tester.drag(
        find.byKey(const ValueKey('routine-day-0-drag-handle-jalon_abierto')),
        const Offset(0, 160),
      );
      await tester.pumpAndSettle();

      final jalonAfter = tester.getTopLeft(find.text('Jalón abierto')).dy;
      final remoAfter = tester.getTopLeft(find.text('Remo barra')).dy;
      expect(jalonAfter, greaterThan(remoAfter));

      final saved = await routinePort.loadRoutines();
      expect(saved, hasLength(1));
      expect(
          saved.first.days.first.exerciseKeys, ['remo_barra', 'jalon_abierto']);
    });
  });
}
