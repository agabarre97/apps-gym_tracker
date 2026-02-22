import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/presentation/screens/auth/auth_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  late FakeAuthPort authPort;
  late FakeSyncPort syncPort;
  late bool didAuthenticate;

  setUp(() {
    authPort = FakeAuthPort();
    syncPort = FakeSyncPort();
    didAuthenticate = false;
  });

  Widget buildScreen() {
    return buildTestableWidget(
      AuthScreen(
        authPort: authPort,
        syncedStorage: syncPort,
        onAuthenticated: (_) => didAuthenticate = true,
      ),
    );
  }

  group('AuthScreen', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
    });

    testWidgets('renders sign-in button by default', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Iniciar sesión'), findsWidgets);
    });

    testWidgets('toggles to sign-up mode', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Crear cuenta'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Iniciar sesión'), findsOneWidget);
    });

    testWidgets('renders Google sign-in button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Continuar con Google'), findsOneWidget);
    });

    testWidgets('shows validation error for empty email', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Campo obligatorio'), findsWidgets);
    });

    testWidgets('shows validation error for invalid email', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        'invalid-email',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'password123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Correo electrónico no válido'), findsOneWidget);
    });

    testWidgets('shows weak password error in sign-up mode', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        '123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.pumpAndSettle();

      expect(
        find.text('La contraseña debe tener al menos 6 caracteres'),
        findsOneWidget,
      );
    });

    testWidgets('successful sign-in calls onAuthenticated', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'password123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(didAuthenticate, isTrue);
      expect(syncPort.userId, equals('fake-uid'));
      expect(syncPort.pullCount, equals(1));
    });

    testWidgets('successful Google sign-in calls onAuthenticated',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuar con Google'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(didAuthenticate, isTrue);
      expect(syncPort.userId, equals('google-uid'));
    });

    testWidgets('app title is displayed', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Gym: all in one'), findsOneWidget);
    });

    testWidgets('password visibility toggle works', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('shows error snackbar on auth failure', (tester) async {
      authPort.shouldThrow = 'wrong-password';

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'password123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Contraseña incorrecta'), findsOneWidget);
      expect(didAuthenticate, isFalse);
    });

    testWidgets('shows generic error on unexpected exception', (tester) async {
      authPort.shouldThrow = 'unknown-code';

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'password123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Error de autenticación. Inténtalo de nuevo'),
          findsOneWidget);
      expect(didAuthenticate, isFalse);
    });

    testWidgets('OR divider is displayed', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('O'), findsOneWidget);
    });
  });
}
