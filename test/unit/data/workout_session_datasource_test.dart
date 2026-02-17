import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/data/datasources/workout_session_datasource.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('WorkoutSessionDatasource', () {
    late FakeStoragePort storage;
    late WorkoutSessionDatasource datasource;

    setUp(() {
      storage = FakeStoragePort();
      datasource = WorkoutSessionDatasource(storage);
    });

    test('loadSessions returns empty list when no data exists', () async {
      final sessions = await datasource.loadSessions();
      expect(sessions, isEmpty);
    });

    test('loadSessions returns empty list for empty raw string', () async {
      await storage.set('workout_sessions', '');
      final sessions = await datasource.loadSessions();
      expect(sessions, isEmpty);
    });

    test('saveSessions persists and loadSessions restores data', () async {
      final sessions = [
        WorkoutSession(
          id: 's1',
          routineId: 'r1',
          routineDayIndex: 0,
          date: DateTime(2026, 2, 16),
          exercises: const [
            WorkoutExercise(
              exerciseKey: 'press',
              sets: [ExerciseSet(reps: 8, weight: 60)],
            ),
          ],
        ),
      ];

      await datasource.saveSessions(sessions);
      final loaded = await datasource.loadSessions();

      expect(loaded.length, 1);
      expect(loaded.first.id, 's1');
      expect(loaded.first.exercises.first.exerciseKey, 'press');
    });
  });
}
