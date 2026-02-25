import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/presentation/screens/landing_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  Future<void> waitForFinder(
    WidgetTester tester,
    Finder finder, {
    int maxPumps = 40,
  }) async {
    for (var i = 0; i < maxPumps; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) return;
    }
  }

  Future<void> pumpLandingWithPendingSession(
    WidgetTester tester, {
    required FakeRoutinePort routinePort,
    required FakeWorkoutSessionPort workoutSessionPort,
  }) async {
    await tester.pumpWidget(
      buildTestableWidget(
        LandingScreen(
          storage: FakeStoragePort(),
          profilePort: FakeProfilePort(),
          routinePort: routinePort,
          trainingDayPort: FakeTrainingDayPort(),
          workoutSessionPort: workoutSessionPort,
          mobilitySessionPort: FakeMobilitySessionPort(),
          hiitSessionPort: FakeHiitSessionPort(),
          onLocaleChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    await waitForFinder(tester, find.byType(AlertDialog));
  }

  testWidgets('shows unfinished workout alert on landing load', (tester) async {
    final routinePort = FakeRoutinePort();
    final workoutSessionPort = FakeWorkoutSessionPort();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

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
    await workoutSessionPort.saveSessions([
      WorkoutSession(
        id: 'wip-1',
        routineId: 'r1',
        routineDayIndex: 0,
        date: today,
        startTime: today.add(const Duration(hours: 10)),
        exercises: const [],
      ),
    ]);

    await pumpLandingWithPendingSession(
      tester,
      routinePort: routinePort,
      workoutSessionPort: workoutSessionPort,
    );

    expect(find.text('Entrenamiento en progreso'), findsOneWidget);
    expect(
      find.text('Tienes un entrenamiento sin finalizar'),
      findsOneWidget,
    );
    expect(find.text('Nuevo'), findsNothing);
    expect(find.text('Retomar'), findsOneWidget);
  });

  testWidgets('does not show alert when session is already finished',
      (tester) async {
    final routinePort = FakeRoutinePort();
    final workoutSessionPort = FakeWorkoutSessionPort();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

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
    await workoutSessionPort.saveSessions([
      WorkoutSession(
        id: 'wip-2',
        routineId: 'r1',
        routineDayIndex: 0,
        date: today,
        startTime: today.add(const Duration(hours: 9, minutes: 30)),
        endTime: today.add(const Duration(hours: 10, minutes: 45)),
        exercises: const [],
      ),
    ]);

    await pumpLandingWithPendingSession(
      tester,
      routinePort: routinePort,
      workoutSessionPort: workoutSessionPort,
    );

    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(AlertDialog), findsNothing);
  });
}
