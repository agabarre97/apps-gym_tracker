import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/data/datasources/profile_datasource.dart';
import 'package:gym_tracker/presentation/screens/loading_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('LoadingScreen', () {
    late FakeStoragePort storage;
    late ProfileDatasource profilePort;
    late FakeRoutinePort routinePort;
    late FakeTrainingDayPort trainingDayPort;
    late FakeWorkoutSessionPort workoutSessionPort;
    late FakeMobilitySessionPort mobilitySessionPort;

    setUp(() {
      storage = FakeStoragePort();
      profilePort = ProfileDatasource(storage);
      routinePort = FakeRoutinePort();
      trainingDayPort = FakeTrainingDayPort();
      workoutSessionPort = FakeWorkoutSessionPort();
      mobilitySessionPort = FakeMobilitySessionPort();
    });

    testWidgets('renders the motto text "Improve yourself"', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          LoadingScreen(
            profilePort: profilePort,
            storage: storage,
            routinePort: routinePort,
            trainingDayPort: trainingDayPort,
            workoutSessionPort: workoutSessionPort,
            mobilitySessionPort: mobilitySessionPort,
            onLocaleChanged: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Improve yourself'), findsOneWidget);

      // Clean up pending timers
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('contains overlay container for readability', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          LoadingScreen(
            profilePort: profilePort,
            storage: storage,
            routinePort: routinePort,
            trainingDayPort: trainingDayPort,
            workoutSessionPort: workoutSessionPort,
            mobilitySessionPort: mobilitySessionPort,
            onLocaleChanged: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Stack), findsAtLeast(1));

      // Clean up pending timers
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('navigates away after 2 seconds (no profile)', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          LoadingScreen(
            profilePort: profilePort,
            storage: storage,
            routinePort: routinePort,
            trainingDayPort: trainingDayPort,
            workoutSessionPort: workoutSessionPort,
            mobilitySessionPort: mobilitySessionPort,
            onLocaleChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Improve yourself'), findsOneWidget);

      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Improve yourself'), findsNothing);
    });
  });
}
