import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/domain/entities/training_day.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/presentation/screens/landing_screen.dart';
import 'package:table_calendar/table_calendar.dart';

import '../helpers/test_helpers.dart';

final _today = DateTime(2026, 2, 16);

Widget _buildWidget({
  required FakeRoutinePort routinePort,
  required FakeTrainingDayPort trainingDayPort,
  required FakeWorkoutSessionPort workoutSessionPort,
}) {
  return buildTestableWidget(
    LandingScreen(
      storage: FakeStoragePort(),
      profilePort: FakeProfilePort(),
      routinePort: routinePort,
      trainingDayPort: trainingDayPort,
      workoutSessionPort: workoutSessionPort,
      mobilitySessionPort: FakeMobilitySessionPort(),
      hiitSessionPort: FakeHiitSessionPort(),
      onLocaleChanged: (_) {},
    ),
  );
}

Future<void> _selectToday(WidgetTester tester) async {
  await tester.pumpAndSettle();
  final calendar = find.byType(TableCalendar<dynamic>);
  final dayFinder = find.descendant(
    of: calendar,
    matching: find.text('16'),
  );
  await tester.tap(dayFinder.first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Archived routine is hidden from Mis rutinas but session still shows name in calendar',
    (tester) async {
      final routinePort = FakeRoutinePort();
      final trainingDayPort = FakeTrainingDayPort();
      final workoutSessionPort = FakeWorkoutSessionPort();

      // Routine is archived (soft-deleted)
      await routinePort.saveRoutines([
        const Routine(
          id: 'r1',
          name: 'Old Push',
          type: 'musculacion',
          days: [
            RoutineDay(muscleGroups: ['chest'], exerciseKeys: ['bench'])
          ],
          isArchived: true,
        ),
      ]);

      // Historical session referencing the archived routine
      await trainingDayPort.saveTrainingDays([TrainingDay(date: _today)]);
      await workoutSessionPort.saveSessions([
        WorkoutSession(
          id: 'w1',
          routineId: 'r1',
          routineDayIndex: 0,
          date: _today,
          startTime: _today.add(const Duration(hours: 10)),
          endTime: _today.add(const Duration(hours: 11)),
          exercises: const [],
        ),
      ]);

      await tester.pumpWidget(_buildWidget(
        routinePort: routinePort,
        trainingDayPort: trainingDayPort,
        workoutSessionPort: workoutSessionPort,
      ));
      await tester.pumpAndSettle();

      // "Mis rutinas" section should NOT show the archived routine
      expect(find.text('Old Push'), findsNothing);

      // Select today in the calendar to see historical sessions
      await _selectToday(tester);

      // Tap the view button to open the session picker
      await tester.tap(find.text('Ver entrenamientos'));
      await tester.pumpAndSettle();

      // The session should still show the routine name (not the raw ID)
      expect(find.text('Old Push'), findsWidgets);
    },
  );
}
