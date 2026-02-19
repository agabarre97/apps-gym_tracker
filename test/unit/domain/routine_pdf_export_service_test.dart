import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/hiit_exercise.dart';
import 'package:gym_tracker/domain/entities/hiit_session.dart';
import 'package:gym_tracker/domain/entities/mobility_routine.dart';
import 'package:gym_tracker/domain/entities/mobility_session.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/domain/services/routine_pdf_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RoutinePdfExportService', () {
    test('buildMobilityExerciseLines uses localized names when provided', () {
      const mobilityRoutine = MobilityRoutine(
        key: 'pelvic_tilt',
        nameKey: 'mobilityPelvicTilt',
        totalDurationMinutes: 7,
        exercises: [
          MobilityExercise(
            key: 'pelvic_tilt',
            durationSeconds: 30,
            bilateral: true,
          ),
          MobilityExercise(
            key: 'glute_bridge',
            durationSeconds: 30,
            bilateral: true,
          ),
        ],
      );

      final lines = RoutinePdfExportService.buildMobilityExerciseLines(
        mobilityRoutine,
        exerciseNameByKey: const {
          'pelvic_tilt': 'Inclinación pélvica',
          'glute_bridge': 'Puente de glúteo',
        },
      );

      expect(
        lines,
        equals(const [
          'Inclinación pélvica (30s)',
          'Puente de glúteo (30s)',
        ]),
      );
    });

    test('buildWorkoutRoutinePdf returns non-empty bytes', () async {
      const routine = Routine(
        id: 'r1',
        name: 'Push Pull',
        type: 'musculacion',
        days: [
          RoutineDay(muscleGroups: ['pectoral'], exerciseKeys: ['press_banca']),
        ],
      );
      const exercises = [
        Exercise(
          key: 'press_banca',
          name: 'Press banca',
          description: 'desc',
          muscleGroups: ['Pectoral'],
          difficulty: 5,
        ),
      ];

      final bytes = await RoutinePdfExportService.buildWorkoutRoutinePdf(
        routine: routine,
        allExercises: exercises,
        lastSession: WorkoutSession(
          id: 's1',
          routineId: 'r1',
          routineDayIndex: 0,
          date: DateTime(2026, 2, 18),
          exercises: const [
            WorkoutExercise(
              exerciseKey: 'press_banca',
              sets: [ExerciseSet(reps: 8, weight: 60)],
              completed: true,
            ),
          ],
        ),
        generatedAt: DateTime(2026, 2, 18),
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });

    test('buildHiitRoutinePdf returns non-empty bytes', () async {
      const routine = Routine(
        id: 'h1',
        name: 'HIIT 1',
        type: 'hiit',
        days: [
          RoutineDay(muscleGroups: [], exerciseKeys: ['burpees']),
        ],
      );

      final bytes = await RoutinePdfExportService.buildHiitRoutinePdf(
        routine: routine,
        routineExercises: const [
          HiitExercise(key: 'burpees', name: 'Burpees', description: 'desc'),
        ],
        lastSession: HiitSession(
          id: 'hs1',
          routineName: 'HIIT 1',
          date: DateTime(2026, 2, 18),
        ),
        generatedAt: DateTime(2026, 2, 18),
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(800));
    });

    test('buildMobilityRoutinePdf returns non-empty bytes', () async {
      const routine = Routine(
        id: 'm1',
        name: 'Movilidad de tobillo',
        type: 'movilidad',
        days: [],
      );
      const mobilityRoutine = MobilityRoutine(
        key: 'feet_ankles_2',
        nameKey: 'mobilityFeetAnkles2',
        totalDurationMinutes: 11,
        exercises: [
          MobilityExercise(
            key: 'ankle_roll',
            durationSeconds: 30,
            bilateral: true,
          ),
        ],
      );

      final bytes = await RoutinePdfExportService.buildMobilityRoutinePdf(
        routine: routine,
        mobilityRoutine: mobilityRoutine,
        lastSession: MobilitySession(
          id: 'ms1',
          routineKey: 'feet_ankles_2',
          date: DateTime(2026, 2, 18),
        ),
        generatedAt: DateTime(2026, 2, 18),
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(800));
    });
  });
}
