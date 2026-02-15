import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/presentation/screens/workout/routine_picker_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('RoutinePickerScreen', () {
    testWidgets('shows routine list and selects one', (tester) async {
      final routines = [
        const Routine(
          id: 'r1',
          name: 'Push Pull Legs',
          type: 'musculacion',
          days: [
            RoutineDay(muscleGroups: ['pectoral'], exerciseKeys: ['press_banca']),
            RoutineDay(muscleGroups: ['espalda'], exerciseKeys: ['remo']),
          ],
        ),
        const Routine(
          id: 'r2',
          name: 'Full Body',
          type: 'musculacion',
          days: [
            RoutineDay(muscleGroups: ['pectoral'], exerciseKeys: ['press_banca']),
          ],
        ),
      ];

      Routine? selected;

      await tester.pumpWidget(
        buildTestableWidget(
          RoutinePickerScreen(
            routines: routines,
            onRoutineSelected: (r) => selected = r,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both routines should appear
      expect(find.text('Push Pull Legs'), findsOneWidget);
      expect(find.text('Full Body'), findsOneWidget);

      // Tap the first
      await tester.tap(find.text('Push Pull Legs'));
      await tester.pumpAndSettle();

      expect(selected?.id, 'r1');
    });

    testWidgets('shows empty message when no routines', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          RoutinePickerScreen(
            routines: const [],
            onRoutineSelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Crea una rutina primero'), findsOneWidget);
    });
  });
}
