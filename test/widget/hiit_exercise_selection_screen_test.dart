import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/hiit_exercise.dart';
import 'package:gym_tracker/presentation/screens/hiit/hiit_exercise_selection_screen.dart';

import '../helpers/scroll_helpers.dart';
import '../helpers/test_helpers.dart';

const _testExercises = [
  HiitExercise(key: 'burpees', name: 'Burpees', description: 'Full body'),
  HiitExercise(key: 'jump_squats', name: 'Jump squats', description: 'Legs'),
  HiitExercise(key: 'mountain_climbers', name: 'Mountain climbers', description: 'Core'),
  HiitExercise(key: 'jumping_jacks', name: 'Jumping jacks', description: 'Cardio'),
  HiitExercise(key: 'box_jumps', name: 'Box jumps', description: 'Explosive'),
  HiitExercise(key: 'plank_jacks', name: 'Plank jacks', description: 'Core variant'),
  HiitExercise(key: 'jump_lunges', name: 'Jump lunges', description: 'Legs variant'),
  HiitExercise(key: 'sprint_in_place', name: 'Sprint in place', description: 'Speed'),
];

void main() {
  group('HiitExerciseSelectionScreen', () {
    testWidgets('renders all provided HIIT exercises', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          HiitExerciseSelectionScreen(
            exercises: _testExercises,
            onConfirmed: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ListView.builder only renders visible items, so scroll to find all
      for (final exercise in _testExercises) {
        await tester.scrollDownToInNestedList(find.text(exercise.name));
        expect(find.text(exercise.name), findsOneWidget);
      }
    });

    testWidgets('tapping an exercise toggles selection', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          HiitExerciseSelectionScreen(
            exercises: _testExercises,
            onConfirmed: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Burpees to select
      await tester.tap(find.text('Burpees'));
      await tester.pumpAndSettle();

      // Verify "1 seleccionados" (Spanish locale)
      expect(find.textContaining('1'), findsWidgets);
    });

    testWidgets('warning banner appears when more than 6 exercises selected',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          HiitExerciseSelectionScreen(
            exercises: _testExercises,
            // Pre-select 7 exercises
            initialSelectedKeys: _testExercises
                .take(7)
                .map((e) => e.key)
                .toList(),
            onConfirmed: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Warning text should be visible (Spanish locale)
      expect(
        find.textContaining('No se recomienda'),
        findsOneWidget,
      );
    });

    testWidgets('warning banner hidden when 6 or fewer selected',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          HiitExerciseSelectionScreen(
            exercises: _testExercises,
            initialSelectedKeys: _testExercises
                .take(6)
                .map((e) => e.key)
                .toList(),
            onConfirmed: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No se recomienda'),
        findsNothing,
      );
    });

    testWidgets('confirm button disabled when no exercises selected',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          HiitExerciseSelectionScreen(
            exercises: _testExercises,
            onConfirmed: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // "Confirmar" button should be present but disabled
      expect(find.text('Confirmar'), findsOneWidget);
    });

    testWidgets('confirm button enabled when at least 1 exercise selected',
        (tester) async {
      List<String>? confirmedKeys;

      await tester.pumpWidget(
        buildTestableWidget(
          HiitExerciseSelectionScreen(
            exercises: _testExercises,
            initialSelectedKeys: const ['burpees'],
            onConfirmed: (keys) => confirmedKeys = keys,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(confirmedKeys, isNotNull);
      expect(confirmedKeys, contains('burpees'));
    });
  });
}
