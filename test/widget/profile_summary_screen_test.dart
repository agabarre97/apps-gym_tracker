import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/presentation/screens/profile_summary_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('ProfileSummaryScreen', () {
    final profile = sampleProfile();

    Widget buildScreen({
      String? email,
      bool Function()? onSignOut,
    }) {
      return buildTestableWidget(
        ProfileSummaryScreen(
          profile: profile,
          storage: FakeStoragePort(),
          email: email,
          onSignOut: onSignOut,
        ),
      );
    }

    testWidgets('shows email when provided', (tester) async {
      await tester.pumpWidget(buildScreen(email: 'test@example.com'));
      await tester.pumpAndSettle();

      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });

    testWidgets('hides email card when null', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.email_outlined), findsNothing);
    });

    testWidgets('shows sign-out link when onSignOut is provided',
        (tester) async {
      await tester.pumpWidget(buildScreen(onSignOut: () => true));
      await tester.pumpAndSettle();

      // Scroll to the bottom to reveal the sign-out link
      await tester.scrollUntilVisible(
        find.text('Cerrar sesión'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Cerrar sesión'), findsOneWidget);
    });

    testWidgets('hides sign-out link when onSignOut is null', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Cerrar sesión'), findsNothing);
    });

    testWidgets('sign-out link shows confirmation dialog before popping',
        (tester) async {
      bool signOutCalled = false;

      await tester.pumpWidget(buildScreen(onSignOut: () {
        signOutCalled = true;
        return true;
      }));
      await tester.pumpAndSettle();

      // Scroll to the sign-out link
      await tester.scrollUntilVisible(
        find.text('Cerrar sesión'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      // Tap the sign-out link
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear (still on profile screen)
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(ProfileSummaryScreen), findsOneWidget);
      // onSignOut not yet called
      expect(signOutCalled, isFalse);
    });

    testWidgets('cancelling dialog keeps profile screen open', (tester) async {
      bool signOutCalled = false;

      await tester.pumpWidget(buildScreen(onSignOut: () {
        signOutCalled = true;
        return true;
      }));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Cerrar sesión'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Dialog dismissed, still on profile screen
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(ProfileSummaryScreen), findsOneWidget);
      expect(signOutCalled, isFalse);
    });

    testWidgets('confirming dialog calls onSignOut and pops', (tester) async {
      bool signOutCalled = false;

      await tester.pumpWidget(buildScreen(onSignOut: () {
        signOutCalled = true;
        return true;
      }));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Cerrar sesión'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      // Tap confirm (the FilledButton "Cerrar sesión" inside the dialog)
      await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
      await tester.pumpAndSettle();

      // onSignOut should have been called
      expect(signOutCalled, isTrue);
      // Profile screen should be popped
      expect(find.byType(ProfileSummaryScreen), findsNothing);
    });
  });
}
