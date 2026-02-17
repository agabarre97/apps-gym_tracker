import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/mobility_routine.dart';

void main() {
  group('MobilityRoutine', () {
    test('MobilityExercise.fromJson parses bilateral default true', () {
      final exercise = MobilityExercise.fromJson({
        'key': 'rag_doll',
        'duration_seconds': 30,
      });

      expect(exercise.key, 'rag_doll');
      expect(exercise.durationSeconds, 30);
      expect(exercise.bilateral, isTrue);
      expect(exercise.totalSeconds, 30);
    });

    test('MobilityExercise.totalSeconds doubles when non-bilateral', () {
      const exercise = MobilityExercise(
        key: 'hip_stretch',
        durationSeconds: 20,
        bilateral: false,
      );
      expect(exercise.totalSeconds, 40);
    });

    test('MobilityRoutine.fromJson parses exercises and computes total', () {
      final routine = MobilityRoutine.fromJson({
        'key': 'sleep',
        'name_key': 'mobility_sleep',
        'total_duration_minutes': 10,
        'exercises': [
          {'key': 'e1', 'duration_seconds': 20, 'bilateral': true},
          {'key': 'e2', 'duration_seconds': 30, 'bilateral': false},
        ],
      });

      expect(routine.key, 'sleep');
      expect(routine.exercises.length, 2);
      expect(routine.totalSeconds, 80);
    });
  });
}
