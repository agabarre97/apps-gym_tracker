import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/presentation/screens/workout/focused_exercise_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  testWidgets(
      'renders drop sets as mini cards and shows inline rest after finishing set',
      (tester) async {
    const exercise = WorkoutExercise(
      exerciseKey: 'press_banca',
      restSeconds: 90,
      sets: [
        ExerciseSet(reps: 8, weight: 60, targetReps: 10),
        ExerciseSet(
          reps: 6,
          weight: 45,
          targetReps: 8,
          isDropSet: true,
          dropParentSetNumber: 1,
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestableWidget(
        const FocusedExerciseScreen(
          exerciseName: 'Press banca',
          exercise: exercise,
          enableTimer: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Serie 1'), findsOneWidget);
    expect(find.text('Drop set'), findsOneWidget);

    await tester.tap(find.text('Finalizar serie 1'));
    await tester.pump();

    expect(find.text('Omitir'), findsOneWidget);
  });
}
