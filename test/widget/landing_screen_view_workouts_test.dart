import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/mobility_session.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/domain/entities/training_day.dart';
import 'package:gym_tracker/presentation/screens/landing_screen.dart';
import 'package:table_calendar/table_calendar.dart';

import '../helpers/test_helpers.dart';

void main() {
  testWidgets(
      'View button shows "Ver entrenamientos" when only mobility session exists',
      (tester) async {
    final routinePort = FakeRoutinePort();
    final trainingDayPort = FakeTrainingDayPort();
    final workoutSessionPort = FakeWorkoutSessionPort();
    final mobilitySessionPort = FakeMobilitySessionPort();
    final hiitSessionPort = FakeHiitSessionPort();

    await routinePort.saveRoutines([
      const Routine(id: 'r1', name: 'Dummy', type: 'musculacion', days: []),
    ]);
    await trainingDayPort
        .saveTrainingDays([TrainingDay(date: DateTime(2026, 2, 16))]);
    await mobilitySessionPort.saveSessions([
      MobilitySession(
          id: 'm1', routineKey: 'feet_ankles_2', date: DateTime(2026, 2, 16)),
    ]);

    await tester.pumpWidget(buildTestableWidget(
      LandingScreen(
        storage: FakeStoragePort(),
        profilePort: FakeProfilePort(),
        routinePort: routinePort,
        trainingDayPort: trainingDayPort,
        workoutSessionPort: workoutSessionPort,
        mobilitySessionPort: mobilitySessionPort,
        hiitSessionPort: hiitSessionPort,
        onLocaleChanged: (_) {},
      ),
    ));
    await tester.pumpAndSettle();

    // Select today
    final calendar = find.byType(TableCalendar<dynamic>);
    final dayFinder = find.descendant(
      of: calendar,
      matching: find.text('16'),
    );
    await tester.tap(dayFinder.first);
    await tester.pumpAndSettle();

    expect(find.text('Ver entrenamientos'), findsOneWidget);
    expect(find.text('Ver detalles'), findsNothing);
  });
}
