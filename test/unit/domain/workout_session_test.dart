import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';

void main() {
  group('ExerciseSet', () {
    test('JSON round-trip', () {
      const set = ExerciseSet(reps: 10, weight: 60.5);
      final json = set.toJson();
      final restored = ExerciseSet.fromJson(json);
      expect(restored.reps, 10);
      expect(restored.weight, 60.5);
    });

    test('copyWith', () {
      const set = ExerciseSet(reps: 10, weight: 60);
      final updated = set.copyWith(reps: 12);
      expect(updated.reps, 12);
      expect(updated.weight, 60);
    });

    test('JSON round-trip with estimatedRestSeconds', () {
      const set = ExerciseSet(reps: 10, weight: 60, estimatedRestSeconds: 90);
      final json = set.toJson();
      expect(json['estimatedRestSeconds'], 90);
      final restored = ExerciseSet.fromJson(json);
      expect(restored.estimatedRestSeconds, 90);
    });

    test('backward compatibility: JSON without estimatedRestSeconds', () {
      final json = {'reps': 8, 'weight': 55.0};
      final restored = ExerciseSet.fromJson(json);
      expect(restored.reps, 8);
      expect(restored.weight, 55.0);
      expect(restored.estimatedRestSeconds, isNull);
    });

    test('estimatedRestSeconds omitted from JSON when null', () {
      const set = ExerciseSet(reps: 10, weight: 60);
      final json = set.toJson();
      expect(json.containsKey('estimatedRestSeconds'), isFalse);
    });

    test('copyWith clearRest sets estimatedRestSeconds to null', () {
      const set = ExerciseSet(reps: 10, weight: 60, estimatedRestSeconds: 45);
      final cleared = set.copyWith(clearRest: true);
      expect(cleared.estimatedRestSeconds, isNull);
    });

    test('copyWith preserves estimatedRestSeconds when not cleared', () {
      const set = ExerciseSet(reps: 10, weight: 60, estimatedRestSeconds: 45);
      final updated = set.copyWith(reps: 12);
      expect(updated.estimatedRestSeconds, 45);
    });
  });

  group('WorkoutExercise', () {
    test('JSON round-trip', () {
      const ex = WorkoutExercise(
        exerciseKey: 'press_banca',
        sets: [
          ExerciseSet(reps: 10, weight: 60),
          ExerciseSet(reps: 8, weight: 65),
        ],
        notes: 'buena forma',
        completed: true,
      );
      final json = ex.toJson();
      final restored = WorkoutExercise.fromJson(json);
      expect(restored.exerciseKey, 'press_banca');
      expect(restored.sets.length, 2);
      expect(restored.sets[0].reps, 10);
      expect(restored.sets[1].weight, 65);
      expect(restored.notes, 'buena forma');
      expect(restored.completed, true);
    });

    test('empty factory creates 3 sets with 0 values', () {
      final ex = WorkoutExercise.empty('curl_biceps');
      expect(ex.exerciseKey, 'curl_biceps');
      expect(ex.sets.length, 3);
      expect(ex.sets.every((s) => s.reps == 0 && s.weight == 0), true);
      expect(ex.notes, '');
      expect(ex.completed, false);
    });

    test('copyWith', () {
      final ex = WorkoutExercise.empty('curl_biceps');
      final updated = ex.copyWith(completed: true, notes: 'test');
      expect(updated.completed, true);
      expect(updated.notes, 'test');
      expect(updated.sets.length, 3);
    });
  });

  group('WorkoutSession', () {
    late WorkoutSession session;

    setUp(() {
      session = WorkoutSession(
        id: 'sess-1',
        routineId: 'routine-1',
        routineDayIndex: 0,
        date: DateTime(2026, 2, 13),
        startTime: DateTime(2026, 2, 13, 10, 0, 0),
        endTime: DateTime(2026, 2, 13, 11, 30, 0),
        exercises: [
          const WorkoutExercise(
            exerciseKey: 'press_banca',
            sets: [
              ExerciseSet(reps: 10, weight: 60),
              ExerciseSet(reps: 8, weight: 65.5),
            ],
            notes: 'notes here',
            completed: true,
          ),
          WorkoutExercise.empty('curl_biceps'),
        ],
      );
    });

    test('JSON round-trip', () {
      final json = session.toJson();
      final restored = WorkoutSession.fromJson(json);
      expect(restored.id, 'sess-1');
      expect(restored.routineId, 'routine-1');
      expect(restored.routineDayIndex, 0);
      expect(restored.date, DateTime(2026, 2, 13));
      expect(restored.startTime, DateTime(2026, 2, 13, 10, 0, 0));
      expect(restored.endTime, DateTime(2026, 2, 13, 11, 30, 0));
      expect(restored.exercises.length, 2);
      expect(restored.exercises[0].exerciseKey, 'press_banca');
      expect(restored.exercises[0].completed, true);
      expect(restored.exercises[1].exerciseKey, 'curl_biceps');
    });

    test('JSON round-trip with null times', () {
      final noTime = session.copyWith(
        clearStartTime: true,
        clearEndTime: true,
      );
      final json = noTime.toJson();
      final restored = WorkoutSession.fromJson(json);
      expect(restored.startTime, isNull);
      expect(restored.endTime, isNull);
    });

    test('listFromJsonString / listToJsonString', () {
      final list = [session];
      final jsonStr = WorkoutSession.listToJsonString(list);
      final decoded = WorkoutSession.listFromJsonString(jsonStr);
      expect(decoded.length, 1);
      expect(decoded[0].id, 'sess-1');
      expect(decoded[0].exercises.length, 2);
    });

    test('date serializes as yyyy-MM-dd', () {
      final json = session.toJson();
      expect(json['date'], '2026-02-13');
    });

    test('copyWith', () {
      final updated =
          session.copyWith(endTime: DateTime(2026, 2, 13, 12, 0, 0));
      expect(updated.endTime, DateTime(2026, 2, 13, 12, 0, 0));
      expect(updated.startTime, session.startTime);
    });
  });

  group('auto-complete logic', () {
    test('copies sets from previous session for matching exercise', () {
      final previousSets = [
        const ExerciseSet(reps: 10, weight: 60),
        const ExerciseSet(reps: 8, weight: 65),
        const ExerciseSet(reps: 6, weight: 70),
      ];

      final previousSession = WorkoutSession(
        id: 'prev-1',
        routineId: 'r1',
        routineDayIndex: 0,
        date: DateTime(2026, 2, 10),
        exercises: [
          WorkoutExercise(
            exerciseKey: 'press_banca',
            sets: previousSets,
            notes: 'prev notes',
            completed: true,
          ),
        ],
      );

      // Simulate auto-complete: for exercise 'press_banca', use previous data
      final prevEx = previousSession.exercises
          .where((e) => e.exerciseKey == 'press_banca')
          .toList();

      expect(prevEx.isNotEmpty, true);
      final autoFilledSets = prevEx.first.sets
          .map((s) => ExerciseSet(reps: s.reps, weight: s.weight))
          .toList();

      expect(autoFilledSets.length, 3);
      expect(autoFilledSets[0].reps, 10);
      expect(autoFilledSets[0].weight, 60);
      expect(autoFilledSets[2].weight, 70);
    });
  });
}
