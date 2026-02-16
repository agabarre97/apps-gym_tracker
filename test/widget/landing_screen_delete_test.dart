import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/hiit_session.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/domain/entities/training_day.dart';
import 'package:gym_tracker/presentation/screens/landing_screen.dart';
import 'package:table_calendar/table_calendar.dart';

import '../helpers/test_helpers.dart';

final _today = DateTime(2026, 2, 16);

void main() {
  testWidgets('Delete training confirmation dialog removes session',
      (tester) async {
    final routinePort = FakeRoutinePort();
    final trainingDayPort = FakeTrainingDayPort();
    final workoutSessionPort = FakeWorkoutSessionPort();
    final mobilitySessionPort = FakeMobilitySessionPort();
    final hiitSessionPort = FakeHiitSessionPort();

    await routinePort.saveRoutines([
      const Routine(id: 'r1', name: 'Dummy', type: 'musculacion', days: []),
    ]);
    await trainingDayPort.saveTrainingDays([TrainingDay(date: _today)]);
    await hiitSessionPort.saveSessions([
      HiitSession(id: 'h1', routineName: 'HIIT Cardio', date: _today),
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

    // Open session picker
    await tester.tap(find.text('Ver entrenamientos'));
    await tester.pumpAndSettle();

    // Tap delete button
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    // Confirmation dialog should appear
    expect(find.text('Eliminar entrenamiento'), findsOneWidget);
    expect(find.textContaining('HIIT Cardio'), findsWidgets);

    // Confirm deletion
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    // Session should be removed
    final remaining = await hiitSessionPort.loadSessions();
    expect(remaining, isEmpty);
  });
}
