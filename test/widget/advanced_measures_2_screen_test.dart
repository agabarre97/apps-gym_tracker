import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/presentation/screens/profile/advanced_measures_2_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('AdvancedMeasures2Screen', () {
    testWidgets('renders 3 optional text fields', (tester) async {
      final data = <String, dynamic>{};

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: AdvancedMeasures2Screen(data: data, onChanged: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(3));
    });

    testWidgets('shows Spanish labels by default', (tester) async {
      final data = <String, dynamic>{};

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: AdvancedMeasures2Screen(data: data, onChanged: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Perímetro de cintura (cm)'), findsOneWidget);
      expect(find.text('Perímetro de cuádriceps (cm)'), findsOneWidget);
      expect(find.text('Perímetro de pantorrilla (cm)'), findsOneWidget);
    });

    testWidgets('entering a value updates data map', (tester) async {
      final data = <String, dynamic>{};
      var changed = false;

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: AdvancedMeasures2Screen(
              data: data,
              onChanged: () => changed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final firstField = find.byType(TextFormField).first;
      await tester.enterText(firstField, '82.0');
      await tester.pump();

      expect(changed, isTrue);
      expect(data['waistPerimeterCm'], 82.0);
    });
  });
}
