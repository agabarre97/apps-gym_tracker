import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/presentation/screens/profile_summary_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('ProfileSummaryScreen', () {
    testWidgets('displays basic profile data', (tester) async {
      final profile = sampleProfile();
      final storage = FakeStoragePort();

      await tester.pumpWidget(
        buildTestableWidget(
          ProfileSummaryScreen(
            profile: profile,
            storage: storage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Birth date formatted as dd/MM/yyyy
      expect(find.text('15/03/2001'), findsOneWidget);
      // Sex label in Spanish
      expect(find.text('Hombre'), findsOneWidget);
      // Height
      expect(find.text('180.0'), findsOneWidget);
    });

    testWidgets('displays experience label in Spanish', (tester) async {
      final profile = sampleProfile();
      final storage = FakeStoragePort();

      await tester.pumpWidget(
        buildTestableWidget(
          ProfileSummaryScreen(
            profile: profile,
            storage: storage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1-3 años'), findsOneWidget);
    });

    testWidgets('displays N/D for null optional fields', (tester) async {
      final profile = sampleProfile().copyWithNulls();
      final storage = FakeStoragePort();

      await tester.pumpWidget(
        buildTestableWidget(
          ProfileSummaryScreen(
            profile: profile,
            storage: storage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('N/D'), findsNWidgets(6));
    });

    testWidgets('displays goal section correctly for lose', (tester) async {
      final profile = sampleProfile(weightGoal: 'lose');
      final storage = FakeStoragePort();

      await tester.pumpWidget(
        buildTestableWidget(
          ProfileSummaryScreen(
            profile: profile,
            storage: storage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('Perder'), findsOneWidget);
      expect(find.text('2500'), findsOneWidget);
    });

    testWidgets('displays maintain goal without weight/kcal rows',
        (tester) async {
      final profile = sampleProfile(weightGoal: 'maintain');
      final storage = FakeStoragePort();

      await tester.pumpWidget(
        buildTestableWidget(
          ProfileSummaryScreen(
            profile: profile,
            storage: storage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('Mantener'), findsOneWidget);
      // Target weight and kcal should not be shown
      expect(find.text('Peso objetivo (kg)'), findsNothing);
    });

    testWidgets('does not show title text in app bar', (tester) async {
      final profile = sampleProfile();
      final storage = FakeStoragePort();

      await tester.pumpWidget(
        buildTestableWidget(
          ProfileSummaryScreen(
            profile: profile,
            storage: storage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title should NOT appear
      expect(find.text('Tu perfil'), findsNothing);
      // Language selector should NOT appear
      expect(find.byIcon(Icons.language), findsNothing);
    });
  });
}
