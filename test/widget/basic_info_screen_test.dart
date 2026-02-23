import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/presentation/screens/profile/basic_info_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('BasicInfoScreen', () {
    testWidgets('renders weight/height text fields and choice chips',
        (tester) async {
      final data = <String, dynamic>{};

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: BasicInfoScreen(data: data, onChanged: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Three TextFormFields: birth date, weight, height
      expect(find.byType(TextFormField), findsNWidgets(3));
      // 4 experience chips + 2 sex chips = 6 ChoiceChips
      expect(find.byType(ChoiceChip), findsNWidgets(6));
    });

    testWidgets('shows label texts in Spanish (default)', (tester) async {
      final data = <String, dynamic>{};

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: BasicInfoScreen(data: data, onChanged: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fecha de nacimiento'), findsOneWidget);
      expect(find.text('Sexo'), findsOneWidget);
      expect(find.text('Hombre'), findsOneWidget);
      expect(find.text('Mujer'), findsOneWidget);
      expect(find.text('Peso (kg)'), findsOneWidget);
      expect(find.text('Altura (cm)'), findsOneWidget);
      expect(find.text('Experiencia en gimnasio'), findsOneWidget);
    });

    testWidgets('shows labels in English', (tester) async {
      final data = <String, dynamic>{};

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: BasicInfoScreen(data: data, onChanged: () {}),
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Date of birth'), findsOneWidget);
      expect(find.text('Sex'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('Weight (kg)'), findsOneWidget);
      expect(find.text('Height (cm)'), findsOneWidget);
      expect(find.text('Gym experience'), findsOneWidget);
    });

    testWidgets('selecting sex chip updates data', (tester) async {
      final data = <String, dynamic>{};
      var changed = false;

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: BasicInfoScreen(
              data: data,
              onChanged: () => changed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hombre'));
      await tester.pump();

      expect(changed, isTrue);
      expect(data['sex'], 'male');
    });

    testWidgets('selecting experience chip updates data', (tester) async {
      final data = <String, dynamic>{};
      var changed = false;

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: BasicInfoScreen(
              data: data,
              onChanged: () => changed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('1-3 años'));
      await tester.pump();

      expect(changed, isTrue);
      expect(data['gymExperience'], '1-3');
    });

    testWidgets('entering weight updates data map', (tester) async {
      final data = <String, dynamic>{};
      var changed = false;

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: BasicInfoScreen(
              data: data,
              onChanged: () => changed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // First TextFormField is weight
      final weightField = find.byType(TextFormField).first;
      await tester.enterText(weightField, '80');
      await tester.pump();

      expect(changed, isTrue);
      expect(data['weightKg'], 80.0);
    });

    testWidgets('birth date picker hint is shown initially', (tester) async {
      final data = <String, dynamic>{};

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: BasicInfoScreen(data: data, onChanged: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pulsa para seleccionar'), findsAtLeast(1));
    });
  });
}
