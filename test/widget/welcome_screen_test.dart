import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/presentation/screens/profile/welcome_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('WelcomeScreen', () {
    testWidgets('shows gain motivational text when goal is gain',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: WelcomeScreen(
              weightGoal: 'gain',
              onStart: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Spanish motivational text for "gain"
      expect(
        find.text('Es hora de construir. Cada repetición cuenta.'),
        findsOneWidget,
      );
    });

    testWidgets('shows lose motivational text when goal is lose',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: WelcomeScreen(
              weightGoal: 'lose',
              onStart: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Más ligero, más fuerte, imparable.'),
        findsOneWidget,
      );
    });

    testWidgets('shows maintain motivational text when goal is maintain',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: WelcomeScreen(
              weightGoal: 'maintain',
              onStart: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Constancia es la clave. Sigue así.'),
        findsOneWidget,
      );
    });

    testWidgets('shows English motivational text', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: WelcomeScreen(
              weightGoal: 'gain',
              onStart: () {},
            ),
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Time to build. Every rep counts.'), findsOneWidget);
    });

    testWidgets('shows Start button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: WelcomeScreen(
              weightGoal: 'gain',
              onStart: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Comenzar'), findsOneWidget);
    });

    testWidgets('tapping Start triggers onStart callback', (tester) async {
      var started = false;

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: WelcomeScreen(
              weightGoal: 'gain',
              onStart: () => started = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Comenzar'));
      await tester.pump();

      expect(started, isTrue);
    });
  });
}
