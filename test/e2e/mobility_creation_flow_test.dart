import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/presentation/screens/routine/create_routine_flow.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Mobility creation E2E', () {
    late FakeRoutinePort routinePort;

    setUp(() {
      routinePort = FakeRoutinePort();
    });

    testWidgets('creates a recommended mobility routine from subtype flow',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          CreateRoutineFlow(
            routinePort: routinePort,
            existingRoutines: const <Routine>[],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Movilidad'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Movilidad'));
      await tester.pumpAndSettle();

      // Select subtype with multiple recommended routines.
      await tester.tap(find.text('Cadera'));
      await tester.pumpAndSettle();

      // Choose recommended option.
      await tester.tap(find.text('Rutina recomendada'));
      await tester.pumpAndSettle();

      // Pick one of available routines and save.
      await tester.tap(find.byIcon(Icons.self_improvement).first);
      await tester.pumpAndSettle();

      final routines = await routinePort.loadRoutines();
      expect(routines, hasLength(1));
      expect(routines.first.type, 'movilidad');
      expect(routines.first.recommendedRoutineKey, isNotNull);
      expect(routines.first.recommendedRoutineKey,
          anyOf(equals('pelvic_tilt'), equals('hips')));
    });
  });
}
