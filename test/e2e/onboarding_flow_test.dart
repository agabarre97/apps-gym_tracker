import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/data/datasources/profile_datasource.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/screens/loading_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Onboarding flow E2E', () {
    late FakeStoragePort storage;
    late ProfileDatasource profilePort;
    late FakeRoutinePort routinePort;
    late FakeTrainingDayPort trainingDayPort;
    late FakeWorkoutSessionPort workoutSessionPort;
    late FakeMobilitySessionPort mobilitySessionPort;

    setUp(() {
      storage = FakeStoragePort();
      profilePort = ProfileDatasource(storage);
      routinePort = FakeRoutinePort();
      trainingDayPort = FakeTrainingDayPort();
      workoutSessionPort = FakeWorkoutSessionPort();
      mobilitySessionPort = FakeMobilitySessionPort();
    });

    Widget buildApp() {
      return MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF1C1C1E),
          colorScheme: const ColorScheme.dark(
            surface: Color(0xFF2C2C2E),
            primary: Colors.white,
            onSurface: Colors.white,
          ),
        ),
        home: LoadingScreen(
          profilePort: profilePort,
          storage: storage,
          routinePort: routinePort,
          trainingDayPort: trainingDayPort,
          workoutSessionPort: workoutSessionPort,
          mobilitySessionPort: mobilitySessionPort,
          onLocaleChanged: (_) {},
        ),
      );
    }

    testWidgets(
      'full flow: loading -> basic info -> skip advanced -> goals -> welcome -> landing',
      (tester) async {
        await tester.pumpWidget(buildApp());

        // --- Loading screen ---
        expect(find.text('Improve yourself'), findsOneWidget);

        // Wait for 2s delay + navigation
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // --- Basic Info screen (Step 1 of 5) ---
        expect(find.text('Información básica'), findsOneWidget);

        // Select birth date via date picker
        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();
        // Confirm default date in the date picker dialog.
        final dialogButtons = find.byType(TextButton);
        await tester.tap(dialogButtons.last);
        await tester.pumpAndSettle();

        // Select sex
        await tester.tap(find.text('Hombre'));
        await tester.pump();

        // Fill required numeric fields (weight & height)
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.at(0), '80'); // Weight
        await tester.enterText(textFields.at(1), '180'); // Height
        await tester.pump();

        // Scroll down to reveal gym experience chips
        await tester.drag(
            find.byType(SingleChildScrollView), const Offset(0, -200));
        await tester.pumpAndSettle();

        // Select gym experience
        await tester.tap(find.text('1-3 años'));
        await tester.pump();

        // Tap Next (at the bottom of the page, outside the scroll)
        await tester.tap(find.text('Siguiente'));
        await tester.pumpAndSettle();

        // --- Advanced Measures 1 (Step 2 of 5) ---
        expect(find.text('Medidas avanzadas 1'), findsOneWidget);

        // Skip
        await tester.tap(find.text('Omitir'));
        await tester.pumpAndSettle();

        // --- Advanced Measures 2 (Step 3 of 5) ---
        expect(find.text('Medidas avanzadas 2'), findsOneWidget);

        // Skip
        await tester.tap(find.text('Omitir'));
        await tester.pumpAndSettle();

        // --- Goals (Step 4 of 5) ---
        expect(find.text('Objetivos'), findsOneWidget);

        // Fill target weight and kcal
        final goalFields = find.byType(TextFormField);
        await tester.enterText(goalFields.at(0), '85'); // Target weight
        await tester.enterText(goalFields.at(1), '2500'); // Kcal
        await tester.pump();

        // Tap Next
        await tester.tap(find.text('Siguiente'));
        await tester.pumpAndSettle();

        // --- Welcome (Step 5 of 5) ---
        expect(find.text('Bienvenido'), findsOneWidget);
        expect(
          find.text('Es hora de construir. Cada repetición cuenta.'),
          findsOneWidget,
        );

        // Tap Start
        await tester.tap(find.text('Comenzar'));
        await tester.pumpAndSettle();

        // --- Landing screen (redirected after onboarding) ---
        // Should see the Train button
        expect(find.text('Entrenar'), findsOneWidget);

        // Verify profile was persisted
        expect(await profilePort.isProfileCompleted(), isTrue);
        final saved = await profilePort.loadProfile();
        expect(saved, isNotNull);
        expect(saved!.birthDate, isNotEmpty);
        expect(saved.sex, 'male');
      },
    );
  });
}
