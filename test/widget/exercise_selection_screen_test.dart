import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/muscle_group.dart';
import 'package:gym_tracker/presentation/screens/routine/exercise_selection_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('ExerciseSelectionScreen', () {
    final exercises = [
      const Exercise(
        key: 'press_multipower',
        name: 'Press en multipower',
        description: 'Press de pecho en multipower.',
        muscleGroups: ['Pectoral superior', 'Tríceps'],
        difficulty: 6,
      ),
      const Exercise(
        key: 'cruce_poleas',
        name: 'Cruce de poleas',
        description: 'Apertura en poleas.',
        muscleGroups: ['Pectoral mayor'],
        difficulty: 5,
      ),
      const Exercise(
        key: 'jalon_abierto',
        name: 'Jalón abierto',
        description: 'Tirón vertical.',
        muscleGroups: ['Dorsal ancho', 'Bíceps'],
        difficulty: 5,
      ),
    ];

    testWidgets('shows only exercises matching selected categories',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          ExerciseSelectionScreen(
            currentDay: 1,
            totalDays: 3,
            allExercises: exercises,
            initialSelectedCategories: const [MuscleGroupCategory.pectoral],
            onConfirmed: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 2 pectoral exercises should show
      expect(find.text('Press en multipower'), findsOneWidget);
      expect(find.text('Cruce de poleas'), findsOneWidget);
      // Back exercise should not show
      expect(find.text('Jalón abierto'), findsNothing);
    });

    testWidgets('confirm button is disabled when no exercises selected',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          ExerciseSelectionScreen(
            currentDay: 1,
            totalDays: 1,
            allExercises: exercises,
            initialSelectedCategories: const [MuscleGroupCategory.pectoral],
            onConfirmed: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('tapping exercise name opens detail bottom sheet',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          ExerciseSelectionScreen(
            currentDay: 1,
            totalDays: 1,
            allExercises: exercises,
            initialSelectedCategories: const [MuscleGroupCategory.pectoral],
            onConfirmed: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the exercise text (card body), not the checkbox icon
      await tester.tap(find.text('Press en multipower'));
      await tester.pumpAndSettle();

      // Bottom sheet should show the description
      expect(find.text('Press de pecho en multipower.'), findsOneWidget);
      expect(find.text('Añadir'), findsOneWidget);
    });

    testWidgets('tapping checkbox icon toggles selection without opening detail',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          ExerciseSelectionScreen(
            currentDay: 1,
            totalDays: 1,
            allExercises: exercises,
            initialSelectedCategories: const [MuscleGroupCategory.pectoral],
            onConfirmed: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially all unchecked
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(2));
      expect(find.byIcon(Icons.check_circle), findsNothing);

      // Tap the first checkbox icon
      await tester.tap(find.byIcon(Icons.radio_button_unchecked).first);
      await tester.pumpAndSettle();

      // One exercise is now selected (icon changed)
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Detail bottom sheet should NOT have opened
      expect(find.text('Press de pecho en multipower.'), findsNothing);
      expect(find.text('Añadir'), findsNothing);
    });

    testWidgets('initialSelectedKeys pre-populates selected exercises',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          ExerciseSelectionScreen(
            currentDay: 1,
            totalDays: 1,
            allExercises: exercises,
            initialSelectedCategories: const [MuscleGroupCategory.pectoral],
            initialSelectedKeys: const ['press_multipower'],
            onConfirmed: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // "Press en multipower" should already be selected
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Confirm button should be enabled
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('orders exercises by category priority for selected muscle group',
        (tester) async {
      final prioritizedExercises = const [
        Exercise(
          key: 'biceps_multi',
          name: 'Curl multi',
          description: 'desc',
          muscleGroups: ['Dorsal ancho', 'Bíceps'],
          difficulty: 5,
          muscleCategoryPriority: {'biceps': 2, 'espalda': 1},
        ),
        Exercise(
          key: 'biceps_only',
          name: 'Curl bíceps',
          description: 'desc',
          muscleGroups: ['Bíceps braquial'],
          difficulty: 5,
          muscleCategoryPriority: {'biceps': 1},
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          ExerciseSelectionScreen(
            currentDay: 1,
            totalDays: 1,
            allExercises: prioritizedExercises,
            initialSelectedCategories: const [MuscleGroupCategory.biceps],
            onConfirmed: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bicepsOnlyY = tester.getTopLeft(find.text('Curl bíceps')).dy;
      final bicepsMultiY = tester.getTopLeft(find.text('Curl multi')).dy;

      expect(bicepsOnlyY, lessThan(bicepsMultiY));
    });
  });
}
