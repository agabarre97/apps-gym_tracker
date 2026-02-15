import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/presentation/screens/routine/days_selection_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('DaysSelectionScreen', () {
    testWidgets('renders initial day count and slider', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          DaysSelectionScreen(
            initialDays: 4,
            onConfirmed: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('4'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('tapping next calls onConfirmed with correct value',
        (tester) async {
      int? confirmedDays;

      await tester.pumpWidget(
        buildTestableWidget(
          DaysSelectionScreen(
            initialDays: 3,
            onConfirmed: (d) => confirmedDays = d,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Siguiente'));
      expect(confirmedDays, 3);
    });
  });
}
