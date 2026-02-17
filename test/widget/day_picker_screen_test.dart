import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/presentation/screens/workout/day_picker_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('DayPickerScreen', () {
    final routine = const Routine(
      id: 'r1',
      name: 'Push Pull',
      type: 'musculacion',
      days: [
        RoutineDay(
            muscleGroups: ['pectoral', 'triceps'],
            exerciseKeys: ['press_banca', 'fondos']),
        RoutineDay(
            muscleGroups: ['espalda', 'biceps'],
            exerciseKeys: ['remo', 'curl']),
      ],
    );

    testWidgets('shows routine name and day cards', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          DayPickerScreen(
            routine: routine,
            onDaySelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Push Pull'), findsOneWidget);
      expect(find.text('Día 1'), findsOneWidget);
      expect(find.text('Día 2'), findsOneWidget);
    });

    testWidgets('start button disabled until day selected', (tester) async {
      int? selectedDay;

      await tester.pumpWidget(
        buildTestableWidget(
          DayPickerScreen(
            routine: routine,
            onDaySelected: (i) => selectedDay = i,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Button should be disabled initially
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);

      // Tap day 1 card
      await tester.tap(find.text('Día 1'));
      await tester.pumpAndSettle();

      // Now button should be enabled — tap it
      final updatedButton =
          tester.widget<FilledButton>(find.byType(FilledButton));
      expect(updatedButton.onPressed, isNotNull);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(selectedDay, 0);
    });
  });
}
