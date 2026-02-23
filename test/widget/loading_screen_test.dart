import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/data/datasources/profile_datasource.dart';
import 'package:gym_tracker/domain/ports/auth_port.dart';
import 'package:gym_tracker/presentation/screens/auth/auth_screen.dart';
import 'package:gym_tracker/presentation/screens/loading_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('LoadingScreen', () {
    late FakeStoragePort storage;
    late ProfileDatasource profilePort;
    late FakeRoutinePort routinePort;
    late FakeTrainingDayPort trainingDayPort;
    late FakeWorkoutSessionPort workoutSessionPort;
    late FakeMobilitySessionPort mobilitySessionPort;
    late FakeHiitSessionPort hiitSessionPort;

    setUp(() {
      storage = FakeStoragePort();
      profilePort = ProfileDatasource(storage);
      routinePort = FakeRoutinePort();
      trainingDayPort = FakeTrainingDayPort();
      workoutSessionPort = FakeWorkoutSessionPort();
      mobilitySessionPort = FakeMobilitySessionPort();
      hiitSessionPort = FakeHiitSessionPort();
    });

    Widget buildScreen({
      FakeAuthPort? authPort,
      FakeSyncPort? syncPort,
    }) {
      return buildTestableWidget(
        LoadingScreen(
          authPort: authPort,
          syncedStorage: syncPort,
          profilePort: profilePort,
          storage: storage,
          routinePort: routinePort,
          trainingDayPort: trainingDayPort,
          workoutSessionPort: workoutSessionPort,
          mobilitySessionPort: mobilitySessionPort,
          hiitSessionPort: hiitSessionPort,
          onLocaleChanged: (_) {},
        ),
      );
    }

    // ── Navigation without auth (authPort == null) ──────────────

    testWidgets('navigates to onboarding when no auth and no profile',
        (tester) async {
      await tester.pumpWidget(buildScreen());

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LoadingScreen), findsNothing);
    });

    testWidgets('navigates to landing when no auth but profile completed',
        (tester) async {
      await profilePort.saveProfile(sampleProfile());
      await profilePort.markProfileCompleted();

      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LoadingScreen), findsNothing);
    });

    // ── Navigation with auth (unauthenticated) ──────────────────

    testWidgets('navigates to AuthScreen when user is not signed in',
        (tester) async {
      final authPort = FakeAuthPort();
      final syncPort = FakeSyncPort();

      await tester.pumpWidget(
        buildScreen(authPort: authPort, syncPort: syncPort),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AuthScreen), findsOneWidget);
    });

    // ── Navigation with auth (authenticated, no profile) ────────

    testWidgets('navigates to onboarding when user is signed in but no profile',
        (tester) async {
      final authPort = FakeAuthPort(
        simulatedUser: const AuthUser(uid: 'u1', email: 'a@b.com'),
      );
      final syncPort = FakeSyncPort();

      await tester.pumpWidget(
        buildScreen(authPort: authPort, syncPort: syncPort),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AuthScreen), findsNothing);
    });

    // ── Navigation with auth (authenticated, profile complete) ──

    testWidgets('navigates to landing when user signed in and profile complete',
        (tester) async {
      final authPort = FakeAuthPort(
        simulatedUser: const AuthUser(uid: 'u1', email: 'a@b.com'),
      );
      final syncPort = FakeSyncPort();

      await profilePort.saveProfile(sampleProfile());
      await profilePort.markProfileCompleted();

      await tester.pumpWidget(
        buildScreen(authPort: authPort, syncPort: syncPort),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AuthScreen), findsNothing);
      expect(find.byType(LoadingScreen), findsNothing);
    });

    // ── Auth → onboarding transition ────────────────────────────

    testWidgets('AuthScreen sign-in navigates to onboarding when no profile',
        (tester) async {
      final authPort = FakeAuthPort();
      final syncPort = FakeSyncPort();

      await tester.pumpWidget(
        buildScreen(authPort: authPort, syncPort: syncPort),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AuthScreen), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'password123',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AuthScreen), findsNothing);
    });

    testWidgets('AuthScreen sign-in navigates to landing when profile exists',
        (tester) async {
      final authPort = FakeAuthPort();
      final syncPort = FakeSyncPort();

      await profilePort.saveProfile(sampleProfile());
      await profilePort.markProfileCompleted();

      await tester.pumpWidget(
        buildScreen(authPort: authPort, syncPort: syncPort),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AuthScreen), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'password123',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AuthScreen), findsNothing);
      expect(find.byType(LoadingScreen), findsNothing);
    });

    // ── Auth state timeout → auth screen ────────────────────────

    testWidgets('shows AuthScreen when auth state stream times out',
        (tester) async {
      final authPort = _NeverEmitAuthPort();
      final syncPort = FakeSyncPort();

      await tester.pumpWidget(
        buildTestableWidget(
          LoadingScreen(
            authPort: authPort,
            syncedStorage: syncPort,
            profilePort: profilePort,
            storage: storage,
            routinePort: routinePort,
            trainingDayPort: trainingDayPort,
            workoutSessionPort: workoutSessionPort,
            mobilitySessionPort: mobilitySessionPort,
            hiitSessionPort: hiitSessionPort,
            onLocaleChanged: (_) {},
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 6));
      await tester.pump();

      expect(find.byType(AuthScreen), findsOneWidget);
    });
  });
}

/// AuthPort whose [authStateChanges] stream never emits,
/// simulating a broken or very slow session restore.
class _NeverEmitAuthPort implements AuthPort {
  @override
  AuthUser? get currentUser => null;

  @override
  Stream<AuthUser?> get authStateChanges => const Stream<AuthUser?>.empty();

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async =>
      const AuthUser(uid: 'fake', email: 'test@test.com');

  @override
  Future<AuthUser> signUpWithEmail(String email, String password) async =>
      const AuthUser(uid: 'fake', email: 'test@test.com');

  @override
  Future<AuthUser> signInWithGoogle() async =>
      const AuthUser(uid: 'fake', email: 'test@test.com');

  @override
  Future<void> signOut() async {}
}
