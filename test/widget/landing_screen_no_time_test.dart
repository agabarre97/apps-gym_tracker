import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/hiit_session.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/domain/entities/training_day.dart';
import 'package:gym_tracker/presentation/screens/landing_screen.dart';
import 'package:table_calendar/table_calendar.dart';

import '../helpers/test_helpers.dart';

void main() {
  testWidgets('Session picker entries without startTime show "Sin hora"',
      (tester) async {
    final routinePort = FakeRoutinePort();
    final trainingDayPort = FakeTrainingDayPort();
    final workoutSessionPort = FakeWorkoutSessionPort();
    final mobilitySessionPort = FakeMobilitySessionPort();
    final hiitSessionPort = FakeHiitSessionPort();

    await routinePort.saveRoutines([
      const Routine(id: 'r1', name: 'Dummy', type: 'musculacion', days: []),
    ]);
    await trainingDayPort.saveTrainingDays([TrainingDay(date: DateTime(2026, 2, 16))]);
    await hiitSessionPort.saveSessions([
      HiitSession(id: 'h2', routineName: 'HIIT Evening', date: DateTime(2026, 2, 16)),
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

    final calendar = find.byType(TableCalendar<dynamic>);
    final dayFinder = find.descendant(
      of: calendar,
      matching: find.text('16'),
    );
    await tester.tap(dayFinder.first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver entrenamientos'));
    await tester.pumpAndSettle();

    expect(find.text('HIIT Evening'), findsOneWidget);
    expect(find.textContaining('Sin hora'), findsOneWidget);
  });
}
