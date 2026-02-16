import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/screens/landing_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  testWidgets(
    'LandingScreen shows snackbar when mobility asset cannot be loaded',
    (tester) async {
      final routinePort = FakeRoutinePort();
      await routinePort.saveRoutines(
        const [
          Routine(
            id: 'mob1',
            name: 'Mobility Broken',
            type: 'movilidad',
            days: [],
            recommendedRoutineKey: 'does_not_exist',
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestableWidget(
          LandingScreen(
            storage: FakeStoragePort(),
            profilePort: FakeProfilePort(),
            routinePort: routinePort,
            trainingDayPort: FakeTrainingDayPort(),
            workoutSessionPort: FakeWorkoutSessionPort(),
            mobilitySessionPort: FakeMobilitySessionPort(),
            hiitSessionPort: FakeHiitSessionPort(),
            onLocaleChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(LandingScreen)),
      )!;
      await tester.tap(find.widgetWithText(ElevatedButton, l10n.landingTrain));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mobility Broken'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(l10n.mobilityRoutineNotFound), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
