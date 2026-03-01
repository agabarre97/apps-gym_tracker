import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/hiit_session.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/domain/entities/training_day.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/presentation/screens/landing_screen.dart';
import 'package:table_calendar/table_calendar.dart';

import '../helpers/test_helpers.dart';

final _now = DateTime.now();
final _day = DateTime(_now.year, _now.month, 1);

void main() {
  group('Calendar session management E2E', () {
    testWidgets('views day sessions and removes all entries from calendar day',
        (tester) async {
      final routinePort = FakeRoutinePort();
      final trainingDayPort = FakeTrainingDayPort();
      final workoutPort = FakeWorkoutSessionPort();
      final mobilityPort = FakeMobilitySessionPort();
      final hiitPort = FakeHiitSessionPort();

      await routinePort.saveRoutines([
        const Routine(
          id: 'r1',
          name: 'Push Pull',
          type: 'musculacion',
          days: [
            RoutineDay(muscleGroups: ['pectoral'], exerciseKeys: ['bench'])
          ],
        ),
      ]);
      await trainingDayPort.saveTrainingDays([TrainingDay(date: _day)]);
      await workoutPort.saveSessions([
        WorkoutSession(
          id: 'w1',
          routineId: 'r1',
          routineDayIndex: 0,
          date: _day,
          startTime: _day.add(const Duration(hours: 10)),
          endTime: _day.add(const Duration(hours: 11)),
          exercises: const [],
        ),
      ]);
      await hiitPort.saveSessions([
        HiitSession(
          id: 'h1',
          routineName: 'HIIT Cardio',
          date: _day,
          startTime: _day.add(const Duration(hours: 12)),
          endTime: _day.add(const Duration(hours: 12, minutes: 25)),
        ),
      ]);

      await tester.pumpWidget(
        buildTestableWidget(
          LandingScreen(
            storage: FakeStoragePort(),
            profilePort: FakeProfilePort(),
            routinePort: routinePort,
            trainingDayPort: trainingDayPort,
            workoutSessionPort: workoutPort,
            mobilitySessionPort: mobilityPort,
            hiitSessionPort: hiitPort,
            onLocaleChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final calendar = find.byType(TableCalendar<dynamic>);
      final dayFinder =
          find.descendant(of: calendar, matching: find.text('1')).first;
      await tester.tap(dayFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ver entrenamientos'));
      await tester.pumpAndSettle();
      expect(find.text('Push Pull'), findsWidgets);
      expect(find.text('HIIT Cardio'), findsOneWidget);

      // Delete first entry (workout).
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();
      expect(await workoutPort.loadSessions(), isEmpty);

      // Re-open and delete HIIT entry.
      await tester.tap(find.text('Ver entrenamientos'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();
      expect(await hiitPort.loadSessions(), isEmpty);

      // No entries left for this day.
      final days = await trainingDayPort.loadTrainingDays();
      expect(days, isEmpty);
      expect(find.text('Ver entrenamientos'), findsNothing);
    });
  });
}
