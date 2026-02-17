import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/domain/services/exercise_progress_calculator.dart';

void main() {
  // Shared reference date for all tests.
  final now = DateTime(2026, 2, 13);

  /// Helper to build a [WorkoutSession] quickly.
  WorkoutSession makeSession({
    required DateTime date,
    String routineId = 'r1',
    int dayIndex = 0,
    required List<WorkoutExercise> exercises,
  }) =>
      WorkoutSession(
        id: 'id-${date.toIso8601String()}',
        routineId: routineId,
        routineDayIndex: dayIndex,
        date: date,
        exercises: exercises,
      );

  /// Helper to build a [WorkoutExercise].
  WorkoutExercise makeExercise({
    String key = 'bench_press',
    required List<ExerciseSet> sets,
    bool completed = true,
  }) =>
      WorkoutExercise(
        exerciseKey: key,
        sets: sets,
        completed: completed,
      );

  group('ExerciseProgressCalculator', () {
    test('returns empty result when no sessions match', () {
      final result = ExerciseProgressCalculator.compute(
        sessions: [],
        routineId: 'r1',
        routineDayIndex: 0,
        exerciseKey: 'bench_press',
        periodMonths: 3,
        metric: ProgressMetric.volume,
        now: now,
      );

      expect(result.isEmpty, isTrue);
      expect(result.points, isEmpty);
    });

    test('filters by routineId and routineDayIndex', () {
      final sessions = [
        makeSession(
          date: DateTime(2026, 1, 10),
          routineId: 'r1',
          dayIndex: 0,
          exercises: [
            makeExercise(sets: [const ExerciseSet(reps: 10, weight: 50)]),
          ],
        ),
        makeSession(
          date: DateTime(2026, 1, 15),
          routineId: 'r2', // different routine
          dayIndex: 0,
          exercises: [
            makeExercise(sets: [const ExerciseSet(reps: 10, weight: 60)]),
          ],
        ),
        makeSession(
          date: DateTime(2026, 1, 20),
          routineId: 'r1',
          dayIndex: 1, // different day
          exercises: [
            makeExercise(sets: [const ExerciseSet(reps: 10, weight: 70)]),
          ],
        ),
      ];

      final result = ExerciseProgressCalculator.compute(
        sessions: sessions,
        routineId: 'r1',
        routineDayIndex: 0,
        exerciseKey: 'bench_press',
        periodMonths: 3,
        metric: ProgressMetric.volume,
        now: now,
      );

      expect(result.points.length, 1);
      // 10 reps * 50 kg = 500
      expect(result.firstValue, 500);
    });

    test('filters by exercise key', () {
      final sessions = [
        makeSession(
          date: DateTime(2026, 1, 10),
          exercises: [
            makeExercise(
              key: 'bench_press',
              sets: [const ExerciseSet(reps: 10, weight: 50)],
            ),
            makeExercise(
              key: 'squat',
              sets: [const ExerciseSet(reps: 8, weight: 100)],
            ),
          ],
        ),
      ];

      final result = ExerciseProgressCalculator.compute(
        sessions: sessions,
        routineId: 'r1',
        routineDayIndex: 0,
        exerciseKey: 'squat',
        periodMonths: 3,
        metric: ProgressMetric.volume,
        now: now,
      );

      expect(result.points.length, 1);
      // 8 * 100 = 800
      expect(result.firstValue, 800);
    });

    test('filters by period (excludes old sessions)', () {
      final sessions = [
        makeSession(
          date: DateTime(2025, 10, 1), // >3 months ago
          exercises: [
            makeExercise(sets: [const ExerciseSet(reps: 10, weight: 50)]),
          ],
        ),
        makeSession(
          date: DateTime(2026, 1, 10), // within 3 months
          exercises: [
            makeExercise(sets: [const ExerciseSet(reps: 10, weight: 60)]),
          ],
        ),
      ];

      final result = ExerciseProgressCalculator.compute(
        sessions: sessions,
        routineId: 'r1',
        routineDayIndex: 0,
        exerciseKey: 'bench_press',
        periodMonths: 3,
        metric: ProgressMetric.volume,
        now: now,
      );

      expect(result.points.length, 1);
      expect(result.firstValue, 600); // only the Jan session
    });

    test('computes volume metric correctly (sum of reps * weight)', () {
      final sessions = [
        makeSession(
          date: DateTime(2026, 1, 5),
          exercises: [
            makeExercise(sets: [
              const ExerciseSet(reps: 10, weight: 50),
              const ExerciseSet(reps: 8, weight: 55),
              const ExerciseSet(reps: 6, weight: 60),
            ]),
          ],
        ),
      ];

      final result = ExerciseProgressCalculator.compute(
        sessions: sessions,
        routineId: 'r1',
        routineDayIndex: 0,
        exerciseKey: 'bench_press',
        periodMonths: 3,
        metric: ProgressMetric.volume,
        now: now,
      );

      // 10*50 + 8*55 + 6*60 = 500 + 440 + 360 = 1300
      expect(result.firstValue, 1300);
    });

    test('computes maxWeight metric correctly', () {
      final sessions = [
        makeSession(
          date: DateTime(2026, 1, 5),
          exercises: [
            makeExercise(sets: [
              const ExerciseSet(reps: 10, weight: 50),
              const ExerciseSet(reps: 8, weight: 55),
              const ExerciseSet(reps: 6, weight: 60),
            ]),
          ],
        ),
      ];

      final result = ExerciseProgressCalculator.compute(
        sessions: sessions,
        routineId: 'r1',
        routineDayIndex: 0,
        exerciseKey: 'bench_press',
        periodMonths: 3,
        metric: ProgressMetric.maxWeight,
        now: now,
      );

      expect(result.firstValue, 60);
    });

    test('computes totalReps metric correctly', () {
      final sessions = [
        makeSession(
          date: DateTime(2026, 1, 5),
          exercises: [
            makeExercise(sets: [
              const ExerciseSet(reps: 10, weight: 50),
              const ExerciseSet(reps: 8, weight: 55),
              const ExerciseSet(reps: 6, weight: 60),
            ]),
          ],
        ),
      ];

      final result = ExerciseProgressCalculator.compute(
        sessions: sessions,
        routineId: 'r1',
        routineDayIndex: 0,
        exerciseKey: 'bench_press',
        periodMonths: 3,
        metric: ProgressMetric.totalReps,
        now: now,
      );

      // 10 + 8 + 6 = 24
      expect(result.firstValue, 24);
    });

    test('provides correct first/last and min/max values', () {
      final sessions = [
        makeSession(
          date: DateTime(2026, 1, 5),
          exercises: [
            makeExercise(
                sets: [const ExerciseSet(reps: 10, weight: 50)]), // vol = 500
          ],
        ),
        makeSession(
          date: DateTime(2026, 1, 15),
          exercises: [
            makeExercise(
                sets: [const ExerciseSet(reps: 12, weight: 60)]), // vol = 720
          ],
        ),
        makeSession(
          date: DateTime(2026, 2, 1),
          exercises: [
            makeExercise(
                sets: [const ExerciseSet(reps: 8, weight: 55)]), // vol = 440
          ],
        ),
        makeSession(
          date: DateTime(2026, 2, 10),
          exercises: [
            makeExercise(
                sets: [const ExerciseSet(reps: 10, weight: 65)]), // vol = 650
          ],
        ),
      ];

      final result = ExerciseProgressCalculator.compute(
        sessions: sessions,
        routineId: 'r1',
        routineDayIndex: 0,
        exerciseKey: 'bench_press',
        periodMonths: 3,
        metric: ProgressMetric.volume,
        now: now,
      );

      expect(result.points.length, 4);
      expect(result.firstValue, 500);
      expect(result.lastValue, 650);
      expect(result.minValue, 440);
      expect(result.maxValue, 720);
    });

    test('aggregates multiple sessions on the same day', () {
      final sessions = [
        makeSession(
          date: DateTime(2026, 1, 10),
          exercises: [
            makeExercise(
                sets: [const ExerciseSet(reps: 10, weight: 50)]), // vol = 500
          ],
        ),
        makeSession(
          date: DateTime(2026, 1, 10), // same day
          exercises: [
            makeExercise(
                sets: [const ExerciseSet(reps: 8, weight: 55)]), // vol = 440
          ],
        ),
      ];

      // Volume → sums
      final volumeResult = ExerciseProgressCalculator.compute(
        sessions: sessions,
        routineId: 'r1',
        routineDayIndex: 0,
        exerciseKey: 'bench_press',
        periodMonths: 3,
        metric: ProgressMetric.volume,
        now: now,
      );

      expect(volumeResult.points.length, 1);
      expect(volumeResult.firstValue, 940); // 500 + 440

      // MaxWeight → takes max
      final maxResult = ExerciseProgressCalculator.compute(
        sessions: sessions,
        routineId: 'r1',
        routineDayIndex: 0,
        exerciseKey: 'bench_press',
        periodMonths: 3,
        metric: ProgressMetric.maxWeight,
        now: now,
      );

      expect(maxResult.points.length, 1);
      expect(maxResult.firstValue, 55); // max(50, 55)
    });

    test('points are sorted chronologically', () {
      final sessions = [
        makeSession(
          date: DateTime(2026, 2, 1),
          exercises: [
            makeExercise(sets: [const ExerciseSet(reps: 5, weight: 60)]),
          ],
        ),
        makeSession(
          date: DateTime(2026, 1, 1),
          exercises: [
            makeExercise(sets: [const ExerciseSet(reps: 5, weight: 50)]),
          ],
        ),
      ];

      final result = ExerciseProgressCalculator.compute(
        sessions: sessions,
        routineId: 'r1',
        routineDayIndex: 0,
        exerciseKey: 'bench_press',
        periodMonths: 3,
        metric: ProgressMetric.maxWeight,
        now: now,
      );

      expect(result.points.length, 2);
      expect(result.points[0].date, DateTime(2026, 1, 1));
      expect(result.points[1].date, DateTime(2026, 2, 1));
    });

    test('handles exercise with empty sets gracefully', () {
      final sessions = [
        makeSession(
          date: DateTime(2026, 1, 10),
          exercises: [
            makeExercise(sets: []),
          ],
        ),
      ];

      final result = ExerciseProgressCalculator.compute(
        sessions: sessions,
        routineId: 'r1',
        routineDayIndex: 0,
        exerciseKey: 'bench_press',
        periodMonths: 3,
        metric: ProgressMetric.volume,
        now: now,
      );

      expect(result.points.length, 1);
      expect(result.firstValue, 0);
    });
  });

  group('computeHeaviestSet', () {
    test('returns null when no matching sessions', () {
      final result = ExerciseProgressCalculator.computeHeaviestSet(
        sessions: [],
        routineId: 'r1',
        routineDayIndex: 0,
        exerciseKey: 'bench_press',
      );
      expect(result, isNull);
    });

    test('finds the heaviest single set across all sessions', () {
      final sessions = [
        makeSession(
          date: DateTime(2026, 1, 5),
          exercises: [
            makeExercise(sets: [
              const ExerciseSet(reps: 10, weight: 50),
              const ExerciseSet(reps: 8, weight: 70),
            ]),
          ],
        ),
        makeSession(
          date: DateTime(2026, 1, 20),
          exercises: [
            makeExercise(sets: [
              const ExerciseSet(reps: 6, weight: 80),
              const ExerciseSet(reps: 4, weight: 75),
            ]),
          ],
        ),
      ];

      final result = ExerciseProgressCalculator.computeHeaviestSet(
        sessions: sessions,
        routineId: 'r1',
        routineDayIndex: 0,
        exerciseKey: 'bench_press',
      );

      expect(result, isNotNull);
      expect(result!.weight, 80);
      expect(result.reps, 6);
      expect(result.date, DateTime(2026, 1, 20));
    });

    test('when same weight, picks the one with more reps', () {
      final sessions = [
        makeSession(
          date: DateTime(2026, 1, 5),
          exercises: [
            makeExercise(sets: [
              const ExerciseSet(reps: 8, weight: 80),
            ]),
          ],
        ),
        makeSession(
          date: DateTime(2026, 1, 20),
          exercises: [
            makeExercise(sets: [
              const ExerciseSet(reps: 10, weight: 80),
            ]),
          ],
        ),
      ];

      final result = ExerciseProgressCalculator.computeHeaviestSet(
        sessions: sessions,
        routineId: 'r1',
        routineDayIndex: 0,
        exerciseKey: 'bench_press',
      );

      expect(result!.weight, 80);
      expect(result.reps, 10);
    });

    test('filters by routine and day', () {
      final sessions = [
        makeSession(
          date: DateTime(2026, 1, 5),
          routineId: 'r2',
          exercises: [
            makeExercise(sets: [
              const ExerciseSet(reps: 5, weight: 200),
            ]),
          ],
        ),
        makeSession(
          date: DateTime(2026, 1, 10),
          routineId: 'r1',
          dayIndex: 0,
          exercises: [
            makeExercise(sets: [
              const ExerciseSet(reps: 10, weight: 60),
            ]),
          ],
        ),
      ];

      final result = ExerciseProgressCalculator.computeHeaviestSet(
        sessions: sessions,
        routineId: 'r1',
        routineDayIndex: 0,
        exerciseKey: 'bench_press',
      );

      expect(result!.weight, 60);
    });
  });

  group('availableDates', () {
    test('returns dates sorted descending (newest first)', () {
      final sessions = [
        makeSession(
          date: DateTime(2026, 1, 5),
          exercises: [
            makeExercise(sets: [const ExerciseSet(reps: 10, weight: 50)]),
          ],
        ),
        makeSession(
          date: DateTime(2026, 2, 10),
          exercises: [
            makeExercise(sets: [const ExerciseSet(reps: 10, weight: 60)]),
          ],
        ),
        makeSession(
          date: DateTime(2026, 1, 20),
          exercises: [
            makeExercise(sets: [const ExerciseSet(reps: 10, weight: 55)]),
          ],
        ),
      ];

      final dates = ExerciseProgressCalculator.availableDates(
        sessions: sessions,
        routineId: 'r1',
        routineDayIndex: 0,
        exerciseKey: 'bench_press',
      );

      expect(dates.length, 3);
      expect(dates[0], DateTime(2026, 2, 10));
      expect(dates[1], DateTime(2026, 1, 20));
      expect(dates[2], DateTime(2026, 1, 5));
    });

    test('filters by routine, day, and exercise', () {
      final sessions = [
        makeSession(
          date: DateTime(2026, 1, 5),
          routineId: 'r1',
          dayIndex: 0,
          exercises: [
            makeExercise(
              key: 'bench_press',
              sets: [const ExerciseSet(reps: 10, weight: 50)],
            ),
          ],
        ),
        makeSession(
          date: DateTime(2026, 1, 10),
          routineId: 'r2',
          dayIndex: 0,
          exercises: [
            makeExercise(
              key: 'bench_press',
              sets: [const ExerciseSet(reps: 10, weight: 50)],
            ),
          ],
        ),
      ];

      final dates = ExerciseProgressCalculator.availableDates(
        sessions: sessions,
        routineId: 'r1',
        routineDayIndex: 0,
        exerciseKey: 'bench_press',
      );

      expect(dates.length, 1);
      expect(dates[0], DateTime(2026, 1, 5));
    });
  });

  group('setsForDate', () {
    test('returns sets for matching date', () {
      final sessions = [
        makeSession(
          date: DateTime(2026, 1, 10),
          exercises: [
            makeExercise(sets: [
              const ExerciseSet(reps: 10, weight: 50),
              const ExerciseSet(reps: 8, weight: 55),
            ]),
          ],
        ),
      ];

      final result = ExerciseProgressCalculator.setsForDate(
        sessions: sessions,
        routineId: 'r1',
        routineDayIndex: 0,
        exerciseKey: 'bench_press',
        date: DateTime(2026, 1, 10),
      );

      expect(result, isNotNull);
      expect(result!.sets.length, 2);
      expect(result.sets[0].weight, 50);
      expect(result.sets[1].weight, 55);
    });

    test('returns null when no matching date', () {
      final result = ExerciseProgressCalculator.setsForDate(
        sessions: [],
        routineId: 'r1',
        routineDayIndex: 0,
        exerciseKey: 'bench_press',
        date: DateTime(2026, 1, 10),
      );

      expect(result, isNull);
    });
  });
}
