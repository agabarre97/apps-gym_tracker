import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/presentation/screens/profile/advanced_measures_1_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('AdvancedMeasures1Screen', () {
    testWidgets('renders 3 optional text fields', (tester) async {
      final data = <String, dynamic>{};

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: AdvancedMeasures1Screen(data: data, onChanged: () {}),
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
            body: AdvancedMeasures1Screen(data: data, onChanged: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Envergadura brazo a brazo (cm)'), findsOneWidget);
      expect(find.text('Perímetro de bíceps (cm)'), findsOneWidget);
      expect(find.text('Perímetro de pecho (cm)'), findsOneWidget);
    });

    testWidgets('entering a value updates data map', (tester) async {
      final data = <String, dynamic>{};
      var changed = false;

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: AdvancedMeasures1Screen(
              data: data,
              onChanged: () => changed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final firstField = find.byType(TextFormField).first;
      await tester.enterText(firstField, '185.5');
      await tester.pump();

      expect(changed, isTrue);
      expect(data['armSpanCm'], 185.5);
    });

    testWidgets('fields remain empty by default (optional)', (tester) async {
      final data = <String, dynamic>{};

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: AdvancedMeasures1Screen(data: data, onChanged: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No data should be set for empty fields
      expect(data['armSpanCm'], isNull);
      expect(data['bicepsPerimeterCm'], isNull);
      expect(data['chestPerimeterCm'], isNull);
    });
  });
}
