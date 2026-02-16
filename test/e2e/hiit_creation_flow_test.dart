import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/hiit_exercise.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/screens/routine/create_routine_flow.dart';

import '../helpers/scroll_helpers.dart';
import '../helpers/test_helpers.dart';

const _mockHiitExercises = [
  HiitExercise(key: 'burpees', name: 'Burpees', description: 'Full body'),
  HiitExercise(key: 'jump_squats', name: 'Jump squats', description: 'Legs'),
  HiitExercise(
      key: 'mountain_climbers',
      name: 'Mountain climbers',
      description: 'Core'),
];

Widget _buildFlowApp(FakeRoutinePort routinePort) {
  return MaterialApp(
    locale: const Locale('es'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
    home: CreateRoutineFlow(
      routinePort: routinePort,
      existingRoutines: const <Routine>[],
      preloadedHiitExercises: _mockHiitExercises,
    ),
  );
}

void main() {
  group('HIIT creation flow E2E', () {
    late FakeRoutinePort routinePort;

    setUp(() {
      routinePort = FakeRoutinePort();
    });

    testWidgets(
        'type selection → tap HIIT → exercise selection screen appears',
        (tester) async {
      await tester.pumpWidget(_buildFlowApp(routinePort));
      await tester.pumpAndSettle();

      // HIIT may be off-screen in the grid; scroll into view first
      await tester.ensureVisible(find.text('HIIT'));
      await tester.pumpAndSettle();

      // Type selection is visible
      expect(find.text('HIIT'), findsOneWidget);

      // Tap HIIT
      await tester.tap(find.text('HIIT'));
      await tester.pumpAndSettle();

      // Exercise selection screen appears
      expect(find.text('Selecciona ejercicios'), findsWidgets);
      expect(find.text('Burpees'), findsOneWidget);
      expect(find.text('Jump squats'), findsOneWidget);
      expect(find.text('Mountain climbers'), findsOneWidget);
    });

    testWidgets(
        'select 2 exercises → confirm → config screen appears',
        (tester) async {
      await tester.pumpWidget(_buildFlowApp(routinePort));
      await tester.pumpAndSettle();

      // Navigate to HIIT exercises
      await tester.ensureVisible(find.text('HIIT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('HIIT'));
      await tester.pumpAndSettle();

      // Select 2 exercises
      await tester.tap(find.text('Burpees'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jump squats'));
      await tester.pumpAndSettle();

      // Confirm
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      // Config screen should appear with name field
      expect(find.text('Configuración'), findsOneWidget);
      // Save button may be below fold in ListView; scroll to verify it exists
      await tester.scrollDownTo(find.text('Guardar'));
      expect(find.text('Guardar'), findsOneWidget);
    });

    testWidgets(
        'enter name → save → routine is saved via FakeRoutinePort',
        (tester) async {
      await tester.pumpWidget(_buildFlowApp(routinePort));
      await tester.pumpAndSettle();

      // Navigate to HIIT exercises
      await tester.ensureVisible(find.text('HIIT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('HIIT'));
      await tester.pumpAndSettle();

      // Select exercises
      await tester.tap(find.text('Burpees'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jump squats'));
      await tester.pumpAndSettle();

      // Confirm exercises
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      // Enter name
      await tester.enterText(find.byType(TextField), 'My HIIT');
      await tester.pumpAndSettle();

      // Save (scroll within ListView to find button below fold)
      await tester.scrollToAndTap(find.text('Guardar'));

      // Verify routine was saved
      final routines = await routinePort.loadRoutines();
      expect(routines.length, 1);
      expect(routines.first.name, 'My HIIT');
      expect(routines.first.type, 'hiit');
      expect(routines.first.hiitSets, 3);
      expect(routines.first.hiitWorkSeconds, 20);
      expect(routines.first.hiitRestSeconds, 10);
      expect(routines.first.hiitSetRestSeconds, 90);
      expect(routines.first.days.first.exerciseKeys.length, 2);
    });

    testWidgets(
        'back navigation: config → exercises (selection preserved)',
        (tester) async {
      await tester.pumpWidget(_buildFlowApp(routinePort));
      await tester.pumpAndSettle();

      // Navigate to HIIT exercises
      await tester.ensureVisible(find.text('HIIT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('HIIT'));
      await tester.pumpAndSettle();

      // Select Burpees
      await tester.tap(find.text('Burpees'));
      await tester.pumpAndSettle();

      // Confirm exercises
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      // We're on config screen
      expect(find.text('Configuración'), findsOneWidget);

      // Go back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Back on exercise selection, selection should be preserved
      expect(find.text('Selecciona ejercicios'), findsWidgets);
      // Check that 1 is selected
      expect(find.textContaining('1'), findsWidgets);
    });

    testWidgets(
        'back navigation: exercises → type selection',
        (tester) async {
      await tester.pumpWidget(_buildFlowApp(routinePort));
      await tester.pumpAndSettle();

      // Navigate to HIIT exercises
      await tester.ensureVisible(find.text('HIIT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('HIIT'));
      await tester.pumpAndSettle();

      // Go back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should be back on type selection
      expect(find.text('Musculación'), findsOneWidget);
      await tester.ensureVisible(find.text('HIIT'));
      await tester.pumpAndSettle();
      expect(find.text('HIIT'), findsOneWidget);
    });

    testWidgets(
        'exercises load on first HIIT selection (async asset path)',
        (tester) async {
      // Build WITHOUT preloadedHiitExercises to test real async loading
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
          home: CreateRoutineFlow(
            routinePort: routinePort,
            existingRoutines: const <Routine>[],
            // No preloadedHiitExercises — exercises load from rootBundle
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to HIIT
      await tester.ensureVisible(find.text('HIIT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('HIIT'));

      // Pump to allow async asset loading and setState rebuild
      await tester.pumpAndSettle();

      // Exercises from the asset JSON (Spanish locale) should be visible
      expect(find.text('Selecciona ejercicios'), findsWidgets);
      expect(find.text('Mountain climbers'), findsOneWidget);
      expect(find.text('Burpees'), findsOneWidget);
    });
  });
}
