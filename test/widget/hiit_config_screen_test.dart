import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/presentation/components/time_wheel_picker.dart';
import 'package:gym_tracker/presentation/screens/hiit/hiit_config_screen.dart';

import '../helpers/scroll_helpers.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('HiitConfigScreen', () {
    testWidgets('renders default config values', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          HiitConfigScreen(
            exerciseCount: 4,
            onSave: ({
              required name,
              required sets,
              required workSeconds,
              required restSeconds,
              required setRestSeconds,
            }) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default sets: 3
      expect(find.text('3'), findsOneWidget);

      // Three TimeWheelPicker widgets for work, rest, and set rest
      expect(find.byType(TimeWheelPicker), findsNWidgets(3));

      // Default work (20s) and rest (10s) are visible as wheel items
      expect(find.text('20s'), findsWidgets);
      expect(find.text('10s'), findsWidgets);
    });

    testWidgets('total duration label displays correctly for defaults',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          HiitConfigScreen(
            exerciseCount: 4,
            onSave: ({
              required name,
              required sets,
              required workSeconds,
              required restSeconds,
              required setRestSeconds,
            }) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 3 sets * (4*20 + 3*10) + 2*90 = 3*(80+30) + 180 = 330 + 180 = 510s = 8 min 30s
      expect(find.textContaining('8 min 30s'), findsOneWidget);
    });

    testWidgets('routine name field accepts input', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          HiitConfigScreen(
            exerciseCount: 3,
            onSave: ({
              required name,
              required sets,
              required workSeconds,
              required restSeconds,
              required setRestSeconds,
            }) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nameField = find.byType(TextField);
      expect(nameField, findsOneWidget);

      await tester.enterText(nameField, 'My HIIT Routine');
      await tester.pumpAndSettle();

      expect(find.text('My HIIT Routine'), findsOneWidget);
    });

    testWidgets('save button disabled when name is empty', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          HiitConfigScreen(
            exerciseCount: 3,
            onSave: ({
              required name,
              required sets,
              required workSeconds,
              required restSeconds,
              required setRestSeconds,
            }) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the save button ("Guardar" in Spanish) — may be below fold
      await tester.scrollDownTo(find.widgetWithText(FilledButton, 'Guardar'));
      final saveButton = find.widgetWithText(FilledButton, 'Guardar');
      expect(saveButton, findsOneWidget);

      // It should be disabled (onPressed is null)
      final button = tester.widget<FilledButton>(saveButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('save button enabled when name is provided', (tester) async {
      String? savedName;
      int? savedSets;

      await tester.pumpWidget(
        buildTestableWidget(
          HiitConfigScreen(
            exerciseCount: 3,
            onSave: ({
              required name,
              required sets,
              required workSeconds,
              required restSeconds,
              required setRestSeconds,
            }) {
              savedName = name;
              savedSets = sets;
            },
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter a name
      await tester.enterText(find.byType(TextField), 'Tabata');
      await tester.pumpAndSettle();

      // Tap save (scroll within ListView to reach the button)
      await tester.scrollToAndTap(
          find.widgetWithText(FilledButton, 'Guardar'));

      expect(savedName, 'Tabata');
      expect(savedSets, 3); // default
    });
  });
}
