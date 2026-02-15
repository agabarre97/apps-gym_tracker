import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/presentation/screens/profile/goals_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('GoalsScreen', () {
    testWidgets('renders gain/maintain/lose toggle and text fields',
        (tester) async {
      final data = <String, dynamic>{};

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: GoalsScreen(data: data, onChanged: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Segmented button with Gain/Maintain/Lose
      expect(find.text('Ganar'), findsOneWidget);
      expect(find.text('Mantener'), findsOneWidget);
      expect(find.text('Perder'), findsOneWidget);
      // Text fields for target weight and kcal (visible by default, goal=gain)
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('default goal is gain', (tester) async {
      final data = <String, dynamic>{};

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: GoalsScreen(data: data, onChanged: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(data['weightGoal'], 'gain');
      // Kcal label should say "Kcal/día para ganar"
      expect(find.text('Kcal/día para ganar'), findsOneWidget);
    });

    testWidgets('toggling to lose changes kcal label', (tester) async {
      final data = <String, dynamic>{};

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: GoalsScreen(data: data, onChanged: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Perder"
      await tester.tap(find.text('Perder'));
      await tester.pumpAndSettle();

      expect(data['weightGoal'], 'lose');
      expect(find.text('Kcal/día para perder'), findsOneWidget);
    });

    testWidgets('toggling to maintain hides target weight and kcal fields',
        (tester) async {
      final data = <String, dynamic>{};

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: GoalsScreen(data: data, onChanged: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially 2 text fields
      expect(find.byType(TextFormField), findsNWidgets(2));

      // Tap "Mantener"
      await tester.tap(find.text('Mantener'));
      await tester.pumpAndSettle();

      expect(data['weightGoal'], 'maintain');
      // Fields should be hidden
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets('switching from maintain back to gain shows fields again',
        (tester) async {
      final data = <String, dynamic>{};

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: GoalsScreen(data: data, onChanged: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Go to maintain
      await tester.tap(find.text('Mantener'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);

      // Back to gain
      await tester.tap(find.text('Ganar'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('shows validation error for out-of-range target weight',
        (tester) async {
      final data = <String, dynamic>{};

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: GoalsScreen(data: data, onChanged: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter invalid target weight
      final targetField = find.byType(TextFormField).first;
      await tester.enterText(targetField, '5');
      await tester.pump();

      expect(find.textContaining('30-300'), findsOneWidget);
    });
  });
}
