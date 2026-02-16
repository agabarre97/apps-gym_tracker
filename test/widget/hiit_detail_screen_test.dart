import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/hiit_config.dart';
import 'package:gym_tracker/domain/entities/hiit_exercise.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/presentation/screens/hiit/hiit_detail_screen.dart';

import '../helpers/test_helpers.dart';

const _preloadedExercises = [
  HiitExercise(key: 'burpees', name: 'Burpees', description: 'Full body'),
  HiitExercise(
      key: 'jump_squats', name: 'Jump squats', description: 'Legs'),
  HiitExercise(
      key: 'mountain_climbers',
      name: 'Mountain climbers',
      description: 'Core'),
];

void main() {
  group('HiitDetailScreen', () {
    const hiitRoutine = Routine(
      id: 'hiit1',
      name: 'My HIIT',
      type: 'hiit',
      days: [
        RoutineDay(
          muscleGroups: [],
          exerciseKeys: ['burpees', 'jump_squats', 'mountain_climbers'],
        ),
      ],
      hiitConfig: HiitConfig(
        sets: 3,
        workSeconds: 20,
        restSeconds: 10,
        setRestSeconds: 90,
      ),
    );

    testWidgets('renders routine name in app bar', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          HiitDetailScreen(
            routine: hiitRoutine,
            allRoutines: [hiitRoutine],
            routinePort: FakeRoutinePort(),
            hiitSessionPort: FakeHiitSessionPort(),
            preloadedExercises: _preloadedExercises,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My HIIT'), findsOneWidget);
    });

    testWidgets('renders start button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          HiitDetailScreen(
            routine: hiitRoutine,
            allRoutines: [hiitRoutine],
            routinePort: FakeRoutinePort(),
            hiitSessionPort: FakeHiitSessionPort(),
            preloadedExercises: _preloadedExercises,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // "Comenzar" in Spanish
      expect(find.text('Comenzar'), findsOneWidget);
    });

    testWidgets('renders delete button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          HiitDetailScreen(
            routine: hiitRoutine,
            allRoutines: [hiitRoutine],
            routinePort: FakeRoutinePort(),
            hiitSessionPort: FakeHiitSessionPort(),
            preloadedExercises: _preloadedExercises,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // "Eliminar" in Spanish
      expect(find.text('Eliminar'), findsOneWidget);
    });

    testWidgets('renders config summary chips', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          HiitDetailScreen(
            routine: hiitRoutine,
            allRoutines: [hiitRoutine],
            routinePort: FakeRoutinePort(),
            hiitSessionPort: FakeHiitSessionPort(),
            preloadedExercises: _preloadedExercises,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show the config values as chips (20s, 10s, 90s)
      expect(find.text('20s'), findsOneWidget);
      expect(find.text('10s'), findsOneWidget);
      expect(find.text('90s'), findsOneWidget);
    });

    testWidgets('edit exercises button is visible', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          HiitDetailScreen(
            routine: hiitRoutine,
            allRoutines: [hiitRoutine],
            routinePort: FakeRoutinePort(),
            hiitSessionPort: FakeHiitSessionPort(),
            preloadedExercises: _preloadedExercises,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the edit icon button by its tooltip
      expect(find.byTooltip('Editar ejercicios'), findsOneWidget);
    });

    testWidgets('edit exercises button opens selection screen', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          HiitDetailScreen(
            routine: hiitRoutine,
            allRoutines: [hiitRoutine],
            routinePort: FakeRoutinePort(),
            hiitSessionPort: FakeHiitSessionPort(),
            preloadedExercises: _preloadedExercises,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the edit button
      await tester.tap(find.byTooltip('Editar ejercicios'));
      await tester.pumpAndSettle();

      // The exercise selection screen should appear
      expect(find.text('Selecciona ejercicios'), findsWidgets);

      // All 3 exercises should be pre-selected (check marks)
      expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
    });

    testWidgets('settings button opens config bottom sheet', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          HiitDetailScreen(
            routine: hiitRoutine,
            allRoutines: [hiitRoutine],
            routinePort: FakeRoutinePort(),
            hiitSessionPort: FakeHiitSessionPort(),
            preloadedExercises: _preloadedExercises,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap settings button ("Configuración" in Spanish)
      await tester.tap(find.text('Configuración'));
      await tester.pumpAndSettle();

      // Bottom sheet should show config options
      expect(find.text('Tiempo de trabajo'), findsOneWidget);
      expect(find.text('Descanso entre ejercicios'), findsOneWidget);
      expect(find.text('Descanso entre series'), findsOneWidget);
    });
  });
}
