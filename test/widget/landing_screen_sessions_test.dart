import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/hiit_session.dart';
import 'package:gym_tracker/domain/entities/mobility_session.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/domain/entities/training_day.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/presentation/screens/landing_screen.dart';
import 'package:table_calendar/table_calendar.dart';

import '../helpers/test_helpers.dart';

Widget buildLandingScreenWidget({
  required FakeRoutinePort routinePort,
  required FakeTrainingDayPort trainingDayPort,
  required FakeWorkoutSessionPort workoutSessionPort,
  required FakeMobilitySessionPort mobilitySessionPort,
  required FakeHiitSessionPort hiitSessionPort,
}) {
  return buildTestableWidget(
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
  );
}

final _now = DateTime.now();
final today = DateTime(_now.year, _now.month, 1);

Future<void> selectToday(WidgetTester tester) async {
  await tester.pumpAndSettle();

  final calendar = find.byType(TableCalendar<dynamic>);
  final dayFinder = find.descendant(
    of: calendar,
    matching: find.text('1'),
  );
  await tester.tap(dayFinder.first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Session picker shows all 3 session types with correct icons',
      (tester) async {
    final routinePort = FakeRoutinePort();
    final trainingDayPort = FakeTrainingDayPort();
    final workoutSessionPort = FakeWorkoutSessionPort();
    final mobilitySessionPort = FakeMobilitySessionPort();
    final hiitSessionPort = FakeHiitSessionPort();

    await routinePort.saveRoutines([
      const Routine(
        id: 'r1',
        name: 'Push Pull',
        type: 'musculacion',
        days: [
          RoutineDay(muscleGroups: ['chest'], exerciseKeys: ['bench'])
        ],
      ),
    ]);
    await trainingDayPort.saveTrainingDays([TrainingDay(date: today)]);
    await workoutSessionPort.saveSessions([
      WorkoutSession(
        id: 'w1',
        routineId: 'r1',
        routineDayIndex: 0,
        date: today,
        startTime: today.add(const Duration(hours: 10)),
        endTime: today.add(const Duration(hours: 11)),
        exercises: const [],
      ),
    ]);
    await mobilitySessionPort.saveSessions([
      MobilitySession(
        id: 'm1',
        routineKey: 'feet_ankles_2',
        date: today,
        startTime: today.add(const Duration(hours: 8)),
        endTime: today.add(const Duration(hours: 8, minutes: 30)),
      ),
    ]);
    await hiitSessionPort.saveSessions([
      HiitSession(
        id: 'h1',
        routineName: 'HIIT Cardio',
        date: today,
        startTime: today.add(const Duration(hours: 9)),
      ),
    ]);

    await tester.pumpWidget(buildLandingScreenWidget(
      routinePort: routinePort,
      trainingDayPort: trainingDayPort,
      workoutSessionPort: workoutSessionPort,
      mobilitySessionPort: mobilitySessionPort,
      hiitSessionPort: hiitSessionPort,
    ));
    await selectToday(tester);

    await tester.tap(find.text('Ver entrenamientos'));
    await tester.pumpAndSettle();

    // Bottom sheet should show all 3 entries
    expect(find.text('Entrenamientos del día'), findsOneWidget);
    expect(find.text('Push Pull'), findsWidgets);
    expect(find.text('HIIT Cardio'), findsOneWidget);

    // Check type-specific icons
    expect(find.byIcon(Icons.fitness_center), findsWidgets);
    expect(find.byIcon(Icons.self_improvement), findsOneWidget);
    expect(find.byIcon(Icons.timer), findsOneWidget);

    // Type labels in subtitles
    expect(find.textContaining('Movilidad'), findsWidgets);
    expect(find.textContaining('HIIT'), findsWidgets);
    expect(find.textContaining('Musculación'), findsWidgets);
  });
}
