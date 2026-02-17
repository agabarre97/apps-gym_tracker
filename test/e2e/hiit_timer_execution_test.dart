import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/hiit_exercise.dart';
import 'package:gym_tracker/presentation/screens/hiit/hiit_timer_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('HIIT timer execution E2E', () {
    testWidgets('runs countdown to completion with pause and resume',
        (tester) async {
      final hiitPort = FakeHiitSessionPort();

      await tester.pumpWidget(
        buildTestableWidget(
          HiitTimerScreen(
            exercises: const [
              HiitExercise(
                  key: 'burpees', name: 'Burpees', description: 'Full body'),
              HiitExercise(
                  key: 'jump_squats', name: 'Jump squats', description: 'Legs'),
            ],
            routineName: 'Quick HIIT',
            sets: 1,
            workSeconds: 1,
            restSeconds: 1,
            setRestSeconds: 1,
            hiitSessionPort: hiitPort,
            autoStart: true,
          ),
        ),
      );

      // Auto-start enters countdown.
      await tester.pump();
      expect(find.text('¡Prepárate!'), findsOneWidget);

      // Wait countdown (5s) -> first exercise phase.
      await tester.pump(const Duration(seconds: 6));
      expect(find.byIcon(Icons.pause), findsOneWidget);

      // Pause then resume.
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Advance through rest + second exercise to completion.
      await tester.pump(const Duration(seconds: 7));
      expect(find.textContaining('Complet'), findsWidgets);

      final sessions = await hiitPort.loadSessions();
      expect(sessions, hasLength(1));
      expect(sessions.first.routineName, 'Quick HIIT');
    });
  });
}
