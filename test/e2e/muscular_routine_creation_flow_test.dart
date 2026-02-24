import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/presentation/screens/routine/create_routine_flow.dart';

import '../helpers/test_helpers.dart';

const _preloadedExercises = [
  Exercise(
    key: 'press_banca',
    name: 'Press banca',
    description: 'Pecho',
    muscleGroups: ['Pectoral'],
    difficulty: 5,
    muscleCategoryPriority: {'chest': 1},
    categoryKeys: ['chest'],
  ),
  Exercise(
    key: 'press_inclinado',
    name: 'Press inclinado',
    description: 'Pecho superior',
    muscleGroups: ['Pectoral superior', 'Tríceps'],
    difficulty: 6,
    muscleCategoryPriority: {'chest': 1, 'triceps': 2},
    categoryKeys: ['chest', 'triceps'],
  ),
  Exercise(
    key: 'jalon_pecho',
    name: 'Jalón al pecho',
    description: 'Espalda',
    muscleGroups: ['Dorsal ancho'],
    difficulty: 5,
    muscleCategoryPriority: {'lats': 1},
    categoryKeys: ['lats'],
  ),
  Exercise(
    key: 'remo_mancuerna',
    name: 'Remo mancuerna',
    description: 'Espalda media',
    muscleGroups: ['Dorsal ancho', 'Romboides'],
    difficulty: 5,
    muscleCategoryPriority: {'lats': 1},
    categoryKeys: ['lats'],
  ),
  Exercise(
    key: 'curl_barra',
    name: 'Curl barra',
    description: 'Bíceps',
    muscleGroups: ['Bíceps braquial'],
    difficulty: 4,
    muscleCategoryPriority: {'biceps': 1},
    categoryKeys: ['biceps'],
  ),
  Exercise(
    key: 'extension_triceps',
    name: 'Extensión tríceps',
    description: 'Tríceps',
    muscleGroups: ['Tríceps braquial'],
    difficulty: 4,
    muscleCategoryPriority: {'triceps': 1},
    categoryKeys: ['triceps'],
  ),
];

void main() {
  group('Muscular routine creation E2E', () {
    late FakeRoutinePort routinePort;

    setUp(() {
      routinePort = FakeRoutinePort();
    });

    testWidgets('creates 3-day muscular routine using search each day',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          CreateRoutineFlow(
            routinePort: routinePort,
            existingRoutines: const <Routine>[],
            preloadedExercises: _preloadedExercises,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Musculación'));
      await tester.tap(find.text('Musculación'));
      await tester.pumpAndSettle();

      // Days screen defaults to 3, confirm directly.
      expect(find.text('3'), findsOneWidget);
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      // Day 1: chest (Pecho) + search "press".
      await tester.tap(find.text('Pecho'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'press');
      await tester.pumpAndSettle();
      expect(find.text('Press banca'), findsOneWidget);
      expect(find.text('Jalón al pecho'), findsNothing);
      await tester.tap(find.byIcon(Icons.radio_button_unchecked).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      // Day 2: lats (Dorsales) + search "jalón".
      await tester.tap(find.text('Dorsales'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'jalón');
      await tester.pumpAndSettle();
      expect(find.text('Jalón al pecho'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.radio_button_unchecked).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      // Day 3: select any muscle group and one exercise.
      await tester.tap(find.byType(FilterChip).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.radio_button_unchecked).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      // Summary + save.
      await tester.enterText(find.byType(TextField).first, 'Rutina 3 dias');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar rutina'));
      await tester.pumpAndSettle();

      final saved = await routinePort.loadRoutines();
      expect(saved, hasLength(1));
      expect(saved.first.type, 'musculacion');
      expect(saved.first.days, hasLength(3));
      expect(saved.first.days[0].exerciseKeys, contains('press_banca'));
      expect(saved.first.days[1].exerciseKeys, contains('jalon_pecho'));
      expect(saved.first.days[2].exerciseKeys.length, 1);
      expect(saved.first.days[0].exerciseConfigs, isNotEmpty);
      expect(saved.first.days[0].exerciseConfigs.first.sets, greaterThan(0));
    });
  });
}
