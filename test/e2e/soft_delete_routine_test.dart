import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/domain/entities/training_day.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/presentation/screens/landing_screen.dart';
import 'package:table_calendar/table_calendar.dart';

import '../helpers/test_helpers.dart';

final _date = DateTime(2026, 2, 16);

void main() {
  group('Soft delete routine E2E', () {
    testWidgets('archives routine and keeps historical calendar visibility',
        (tester) async {
      final routinePort = FakeRoutinePort();
      final workoutPort = FakeWorkoutSessionPort();
      final trainingDayPort = FakeTrainingDayPort();
      const archivedRoutine = Routine(
        id: 'r1',
        name: 'Old Push',
        type: 'musculacion',
        days: [
          RoutineDay(muscleGroups: ['pectoral'], exerciseKeys: ['press_banca'])
        ],
        isArchived: true,
      );
      await routinePort.saveRoutines([archivedRoutine]);
      final updated = await routinePort.loadRoutines();
      expect(updated.first.isArchived, isTrue);

      // Historical session still shows routine name in calendar.
      await trainingDayPort.saveTrainingDays([TrainingDay(date: _date)]);
      await workoutPort.saveSessions([
        WorkoutSession(
          id: 'w1',
          routineId: 'r1',
          routineDayIndex: 0,
          date: _date,
          startTime: _date.add(const Duration(hours: 8)),
          endTime: _date.add(const Duration(hours: 9)),
          exercises: const [],
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
            mobilitySessionPort: FakeMobilitySessionPort(),
            hiitSessionPort: FakeHiitSessionPort(),
            onLocaleChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Archived routine must not appear in active routines list.
      expect(find.text('Old Push'), findsNothing);

      final calendar = find.byType(TableCalendar<dynamic>);
      final dayFinder =
          find.descendant(of: calendar, matching: find.text('16')).first;
      await tester.tap(dayFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver entrenamientos'));
      await tester.pumpAndSettle();

      // Historical entry still resolves routine name.
      expect(find.text('Old Push'), findsWidgets);
    });
  });
}
