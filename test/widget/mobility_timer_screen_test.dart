import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/mobility_routine.dart';
import 'package:gym_tracker/presentation/screens/mobility/mobility_timer_screen.dart';

import '../helpers/test_helpers.dart';

const _testRoutine = MobilityRoutine(
  key: 'test_routine',
  nameKey: 'test',
  totalDurationMinutes: 5,
  exercises: [
    MobilityExercise(key: 'stretch_a', durationSeconds: 30, bilateral: true),
    MobilityExercise(key: 'stretch_b', durationSeconds: 20, bilateral: false),
  ],
);

void main() {
  group('MobilityTimerScreen', () {
    testWidgets('without autoStart shows preview with Comenzar button',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          MobilityTimerScreen(
            routine: _testRoutine,
            mobilitySessionPort: FakeMobilitySessionPort(),
            routineName: 'Test Mobility',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Preview phase: start button visible
      expect(find.text('Comenzar'), findsOneWidget);
    });

    testWidgets('with autoStart skips preview and enters countdown',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          MobilityTimerScreen(
            routine: _testRoutine,
            mobilitySessionPort: FakeMobilitySessionPort(),
            routineName: 'Test Mobility',
            autoStart: true,
          ),
        ),
      );

      // After first frame, autoStart triggers the countdown
      await tester.pump();
      await tester.pump();

      // Countdown phase: "¡Prepárate!" (Spanish) — no manual tap needed
      expect(find.text('¡Prepárate!'), findsOneWidget);

      // The preview "Comenzar" button should no longer be visible
      expect(find.text('Comenzar'), findsNothing);
    });
  });
}
