import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/data/datasources/profile_datasource.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/screens/landing_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Language switch E2E', () {
    testWidgets(
      'toggle language from Spanish to English and back on landing screen',
      (tester) async {
        final storage = FakeStoragePort();
        final profilePort = ProfileDatasource(storage);
        final routinePort = FakeRoutinePort();
        final trainingDayPort = FakeTrainingDayPort();
        final workoutSessionPort = FakeWorkoutSessionPort();
        var currentLocale = const Locale('es');

        // Save a profile so landing can load it
        await profilePort.saveProfile(sampleProfile());
        await profilePort.markProfileCompleted();

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return MaterialApp(
                locale: currentLocale,
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
                ),
                home: LandingScreen(
                  storage: storage,
                  profilePort: profilePort,
                  routinePort: routinePort,
                  trainingDayPort: trainingDayPort,
                  workoutSessionPort: workoutSessionPort,
                  mobilitySessionPort: FakeMobilitySessionPort(),
                  hiitSessionPort: FakeHiitSessionPort(),
                  onLocaleChanged: (locale) {
                    setState(() => currentLocale = locale);
                  },
                ),
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        // --- Spanish by default ---
        expect(find.text('Entrenar'), findsOneWidget);
        expect(find.text('Mis rutinas'), findsOneWidget);

        // Tap language toggle (globe icon)
        await tester.tap(find.byIcon(Icons.language));
        await tester.pumpAndSettle();

        // --- Now English ---
        expect(find.text('Train'), findsOneWidget);
        expect(find.text('My routines'), findsOneWidget);

        // Toggle back to Spanish
        await tester.tap(find.byIcon(Icons.language));
        await tester.pumpAndSettle();

        // --- Spanish again ---
        expect(find.text('Entrenar'), findsOneWidget);
        expect(find.text('Mis rutinas'), findsOneWidget);
      },
    );
  });
}
