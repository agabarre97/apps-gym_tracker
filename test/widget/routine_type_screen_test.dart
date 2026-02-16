import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/presentation/screens/routine/routine_type_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('RoutineTypeScreen', () {
    testWidgets('renders routine type cards including Musculación',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          RoutineTypeScreen(
            onTypeSelected: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Musculación'), findsOneWidget);
      expect(find.text('Abdominales'), findsOneWidget);
      expect(find.text('Pliométricos'), findsOneWidget);
      expect(find.text('Movilidad'), findsOneWidget);
    });

    testWidgets('shows "Próximamente" badges on visible disabled types',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          RoutineTypeScreen(
            onTypeSelected: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Movilidad is enabled; at least 2 disabled types should show badge
      expect(find.text('Próximamente'), findsAtLeast(2));
    });

    testWidgets('tapping Musculación calls onTypeSelected', (tester) async {
      String? selectedType;

      await tester.pumpWidget(
        buildTestableWidget(
          RoutineTypeScreen(
            onTypeSelected: (type) => selectedType = type,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Musculación'));
      expect(selectedType, 'musculacion');
    });

    testWidgets('import button is shown when onImport is provided',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          RoutineTypeScreen(
            onTypeSelected: (_) {},
            onBack: () {},
            onImport: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Importar rutina'), findsOneWidget);
    });

    testWidgets('import button is hidden when onImport is null',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          RoutineTypeScreen(
            onTypeSelected: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Importar rutina'), findsNothing);
    });

    testWidgets('tapping import button calls onImport', (tester) async {
      bool importCalled = false;

      await tester.pumpWidget(
        buildTestableWidget(
          RoutineTypeScreen(
            onTypeSelected: (_) {},
            onBack: () {},
            onImport: () => importCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Importar rutina'));
      expect(importCalled, isTrue);
    });
  });
}
