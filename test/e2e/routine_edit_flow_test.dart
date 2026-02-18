import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/domain/services/workout_session_builder.dart';
import 'package:gym_tracker/presentation/screens/routine/routine_detail_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Routine edit E2E', () {
    late FakeRoutinePort routinePort;
    late Routine routine;
    late List<Exercise> allExercises;

    setUp(() {
      routinePort = FakeRoutinePort();
      routine = const Routine(
        id: 'r1',
        name: 'Push day',
        type: 'musculacion',
        days: [
          RoutineDay(
            muscleGroups: ['pectoral', 'triceps'],
            exerciseKeys: ['press_banca', 'fondos'],
          ),
        ],
      );
      allExercises = const [
        Exercise(
          key: 'press_banca',
          name: 'Press banca',
          description: 'Pecho',
          muscleGroups: ['Pectoral'],
          difficulty: 5,
        ),
        Exercise(
          key: 'fondos',
          name: 'Fondos',
          description: 'Tríceps',
          muscleGroups: ['Tríceps braquial'],
          difficulty: 5,
        ),
        Exercise(
          key: 'press_inclinado',
          name: 'Press inclinado',
          description: 'Pecho superior',
          muscleGroups: ['Pectoral superior'],
          difficulty: 6,
        ),
      ];
    });

    testWidgets('can remove one exercise and add another from edit flow',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          RoutineDetailScreen(
            routine: routine,
            allRoutines: const [
              Routine(
                id: 'r1',
                name: 'Push day',
                type: 'musculacion',
                days: [
                  RoutineDay(
                    muscleGroups: ['pectoral', 'triceps'],
                    exerciseKeys: ['press_banca', 'fondos'],
                  ),
                ],
              )
            ],
            routinePort: routinePort,
            allExercises: allExercises,
            workoutSessionPort: FakeWorkoutSessionPort(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Press banca'), findsOneWidget);
      expect(find.text('Fondos'), findsOneWidget);

      // Enter day edit.
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();
      expect(find.text('Selecciona ejercicios'), findsWidgets);

      // Deselect one pre-selected exercise.
      await tester.tap(find.byIcon(Icons.check_circle).first);
      await tester.pumpAndSettle();

      // Search and add a new exercise.
      await tester.enterText(find.byType(TextField), 'inclinado');
      await tester.pumpAndSettle();
      expect(find.text('Press inclinado'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.radio_button_unchecked).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      // Updated routine detail should reflect replacement.
      expect(find.text('Press inclinado'), findsOneWidget);

      final saved = await routinePort.loadRoutines();
      expect(saved, hasLength(1));
      expect(saved.first.days.first.exerciseKeys, contains('press_inclinado'));
      expect(saved.first.days.first.exerciseKeys.length, 2);
    });

    testWidgets('reordered day exercises are used for future workout sessions',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          RoutineDetailScreen(
            routine: routine,
            allRoutines: const [
              Routine(
                id: 'r1',
                name: 'Push day',
                type: 'musculacion',
                days: [
                  RoutineDay(
                    muscleGroups: ['pectoral', 'triceps'],
                    exerciseKeys: ['press_banca', 'fondos'],
                  ),
                ],
              )
            ],
            routinePort: routinePort,
            allExercises: allExercises,
            workoutSessionPort: FakeWorkoutSessionPort(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const ValueKey('routine-day-0-drag-handle-press_banca')),
        const Offset(0, 160),
      );
      await tester.pumpAndSettle();

      final savedRoutines = await routinePort.loadRoutines();
      expect(savedRoutines, hasLength(1));
      expect(savedRoutines.first.days.first.exerciseKeys,
          ['fondos', 'press_banca']);

      final nextWorkoutSession = WorkoutSessionBuilder.build(
        id: 'next-session',
        routine: savedRoutines.first,
        dayIndex: 0,
        date: DateTime(2026, 2, 20),
        trackTime: false,
        previousSessions: const [],
      );
      expect(
        nextWorkoutSession.exercises
            .map((exercise) => exercise.exerciseKey)
            .toList(),
        ['fondos', 'press_banca'],
      );
    });
  });
}
