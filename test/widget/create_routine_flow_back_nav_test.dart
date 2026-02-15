import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/screens/routine/create_routine_flow.dart';

import '../helpers/test_helpers.dart';

/// Mock exercises used for all back-navigation tests.
const _mockExercises = [
  Exercise(
    key: 'press_banca',
    name: 'Press de Banca',
    description: 'Press de pecho en banco plano.',
    muscleGroups: ['Pectoral', 'Tríceps'],
    difficulty: 5,
  ),
  Exercise(
    key: 'cruce_poleas',
    name: 'Cruce de poleas',
    description: 'Apertura en poleas.',
    muscleGroups: ['Pectoral mayor'],
    difficulty: 4,
  ),
  Exercise(
    key: 'curl_biceps',
    name: 'Curl de bíceps',
    description: 'Curl con mancuernas.',
    muscleGroups: ['Bíceps'],
    difficulty: 3,
  ),
  Exercise(
    key: 'jalon_pecho',
    name: 'Jalón al pecho',
    description: 'Tirón vertical al pecho.',
    muscleGroups: ['Dorsal ancho', 'Bíceps'],
    difficulty: 5,
  ),
];

/// Builds the CreateRoutineFlow inside a MaterialApp with localization
/// and pre-loaded mock exercises (to avoid asset loading in tests).
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
      preloadedExercises: _mockExercises,
    ),
  );
}

void main() {
  group('CreateRoutineFlow back navigation', () {
    late FakeRoutinePort routinePort;

    setUp(() {
      routinePort = FakeRoutinePort();
    });

    testWidgets('back from days returns to type selection', (tester) async {
      await tester.pumpWidget(_buildFlowApp(routinePort));
      await tester.pumpAndSettle();

      // We start on type selection
      expect(find.text('Musculación'), findsOneWidget);

      // Select Musculación → days screen
      await tester.tap(find.text('Musculación'));
      await tester.pumpAndSettle();
      expect(find.byType(Slider), findsOneWidget);

      // Tap back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Back on type selection
      expect(find.text('Musculación'), findsOneWidget);
      expect(find.byType(Slider), findsNothing);
    });

    testWidgets('back from muscle groups (day 1) returns to days',
        (tester) async {
      await tester.pumpWidget(_buildFlowApp(routinePort));
      await tester.pumpAndSettle();

      // Type → Musculación
      await tester.tap(find.text('Musculación'));
      await tester.pumpAndSettle();

      // Days → confirm with default (3 days)
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      // On muscle groups for day 1
      expect(find.text('Grupos musculares'), findsOneWidget);

      // Tap back → should return to days
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets(
        'back from exercises returns to muscle groups with chips selected',
        (tester) async {
      await tester.pumpWidget(_buildFlowApp(routinePort));
      await tester.pumpAndSettle();

      // Type → Musculación
      await tester.tap(find.text('Musculación'));
      await tester.pumpAndSettle();

      // Days → confirm
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      // On muscle groups day 1: select Pectoral
      await tester.tap(find.text('Pectoral'));
      await tester.pump();

      // Confirm muscle groups → exercises
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      // Now on exercise selection
      expect(find.text('Selecciona ejercicios'), findsOneWidget);

      // Tap back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Back on muscle groups — Pectoral should still be selected
      expect(find.text('Grupos musculares'), findsOneWidget);
      final pectoralChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Pectoral'),
      );
      expect(pectoralChip.selected, isTrue);
    });

    testWidgets(
        'back from day 2 muscle groups restores day 1 exercise selection',
        (tester) async {
      await tester.pumpWidget(_buildFlowApp(routinePort));
      await tester.pumpAndSettle();

      // ── Day 1 setup ──

      // Type → Musculación
      await tester.tap(find.text('Musculación'));
      await tester.pumpAndSettle();

      // Days → confirm with default
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      // Muscle groups day 1: select Pectoral
      await tester.tap(find.text('Pectoral'));
      await tester.pump();
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      // Exercises day 1: select "Press de Banca" via the checkbox icon
      expect(find.text('Press de Banca'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.radio_button_unchecked).first);
      await tester.pump();

      // Verify it's selected (icon changed to check_circle)
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Confirm exercises → moves to day 2 muscle groups
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      // ── Now on Day 2 muscle groups ──
      expect(find.text('Grupos musculares'), findsOneWidget);

      // Tap back → should return to day 1 exercise selection
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Day 1 exercises should show with "Press de Banca" still selected
      expect(find.text('Selecciona ejercicios'), findsOneWidget);
      expect(find.text('Press de Banca'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}
