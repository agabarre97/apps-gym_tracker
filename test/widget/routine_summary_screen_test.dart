import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/presentation/screens/routine/routine_summary_screen.dart';

import '../helpers/test_helpers.dart';

const _mockExercises = [
  Exercise(
      key: 'press_multipower',
      name: 'Press en multipower',
      description: '',
      muscleGroups: ['Pectoral superior'],
      difficulty: 5),
  Exercise(
      key: 'extension_triceps',
      name: 'Extensión de tríceps',
      description: '',
      muscleGroups: ['Tríceps'],
      difficulty: 4),
  Exercise(
      key: 'jalon_abierto',
      name: 'Jalón abierto',
      description: '',
      muscleGroups: ['Dorsal ancho'],
      difficulty: 5),
  Exercise(
      key: 'remo_polea',
      name: 'Remo en polea baja',
      description: '',
      muscleGroups: ['Dorsal ancho'],
      difficulty: 5),
];

void main() {
  group('RoutineSummaryScreen', () {
    testWidgets('renders name field and day summaries', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          RoutineSummaryScreen(
            type: 'musculacion',
            dayMuscleGroups: const [
              ['chest', 'triceps'],
              ['lats', 'biceps'],
            ],
            dayExerciseKeys: const [
              ['press_multipower', 'extension_triceps'],
              ['jalon_abierto', 'remo_polea'],
            ],
            dayExerciseConfigs: const [
              [
                RoutineExerciseConfig(
                    exerciseKey: 'press_multipower', sets: 4, targetReps: 8),
                RoutineExerciseConfig(
                    exerciseKey: 'extension_triceps', sets: 3, targetReps: 12),
              ],
              [
                RoutineExerciseConfig(
                    exerciseKey: 'jalon_abierto',
                    sets: 4,
                    targetReps: 10,
                    restSeconds: 90),
                RoutineExerciseConfig(
                    exerciseKey: 'remo_polea', sets: 3, targetReps: 10),
              ],
            ],
            allExercises: _mockExercises,
            onSave: (_) async {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Name field
      expect(find.byType(TextField), findsOneWidget);

      // Day labels
      expect(find.text('Día 1'), findsOneWidget);
      expect(find.text('Día 2'), findsOneWidget);

      // Exercise counts
      expect(find.text('2 ejercicios'), findsNWidgets(2));
    });

    testWidgets('save button disabled when name is empty', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          RoutineSummaryScreen(
            type: 'musculacion',
            dayMuscleGroups: const [
              ['chest'],
            ],
            dayExerciseKeys: const [
              ['press_multipower'],
            ],
            dayExerciseConfigs: const [
              [
                RoutineExerciseConfig(
                    exerciseKey: 'press_multipower', sets: 3, targetReps: 10),
              ],
            ],
            allExercises: _mockExercises,
            onSave: (_) async {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('save button enabled after entering name', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          RoutineSummaryScreen(
            type: 'musculacion',
            dayMuscleGroups: const [
              ['chest'],
            ],
            dayExerciseKeys: const [
              ['press_multipower'],
            ],
            dayExerciseConfigs: const [
              [
                RoutineExerciseConfig(
                    exerciseKey: 'press_multipower', sets: 3, targetReps: 10),
              ],
            ],
            allExercises: _mockExercises,
            onSave: (_) async {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Mi rutina');
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });
  });
}
