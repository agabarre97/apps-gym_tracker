import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/presentation/screens/workout/workout_session_screen.dart';
import 'package:gym_tracker/presentation/utils/time_formatter.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Rest stopwatch E2E', () {
    testWidgets('shows elapsed timer label in live workout mode',
        (tester) async {
      final startTime = DateTime.now();
      final session = WorkoutSession(
        id: 's1',
        routineId: 'r1',
        routineDayIndex: 0,
        date: DateTime(startTime.year, startTime.month, startTime.day),
        startTime: startTime,
        exercises: const [
          WorkoutExercise(
            exerciseKey: 'press_banca',
            sets: [ExerciseSet(reps: 8, weight: 60)],
          ),
        ],
      );
      const exercises = [
        Exercise(
          key: 'press_banca',
          name: 'Press banca',
          description: 'Pecho',
          muscleGroups: ['Pectoral'],
          difficulty: 5,
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          WorkoutSessionScreen(
            session: session,
            allExercises: exercises,
            workoutSessionPort: FakeWorkoutSessionPort(),
            routineName: 'Push',
            trackTime: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      String extractTimerLabel() {
        final textWidgets = tester.widgetList<Text>(find.byType(Text));
        for (final text in textWidgets) {
          final value = text.data;
          if (value != null && RegExp(r'^\d+[hms]').hasMatch(value)) {
            return value;
          }
        }
        return '';
      }

      final initialLabel = extractTimerLabel();
      expect(initialLabel, isNotEmpty);

      await tester.pump(const Duration(seconds: 2));

      final updatedLabel = extractTimerLabel();
      expect(updatedLabel, isNotEmpty);
      expect(RegExp(r'^\d+[hms]').hasMatch(updatedLabel), isTrue);
    });
  });
}
