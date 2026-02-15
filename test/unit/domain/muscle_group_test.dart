import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/muscle_group.dart';

void main() {
  group('MuscleGroupCategory mapping', () {
    test('every category has entries in the mapping', () {
      for (final cat in MuscleGroupCategory.values) {
        expect(muscleGroupMapping[cat], isNotEmpty,
            reason: '$cat should have mapped muscle groups');
      }
    });

    test('every category has a Spanish label', () {
      for (final cat in MuscleGroupCategory.values) {
        expect(muscleGroupLabelEs[cat], isNotNull);
      }
    });

    test('every category has an English label', () {
      for (final cat in MuscleGroupCategory.values) {
        expect(muscleGroupLabelEn[cat], isNotNull);
      }
    });

    test('muscleGroupLabels returns correct map for language', () {
      expect(muscleGroupLabels('es'), muscleGroupLabelEs);
      expect(muscleGroupLabels('en'), muscleGroupLabelEn);
      // Default to Spanish for unknown
      expect(muscleGroupLabels('fr'), muscleGroupLabelEs);
    });
  });

  group('exercisesForCategories', () {
    final exercises = [
      const Exercise(
        key: 'press',
        name: 'Press',
        description: 'desc',
        muscleGroups: ['Pectoral mayor', 'Tríceps'],
        difficulty: 5,
      ),
      const Exercise(
        key: 'jalon',
        name: 'Jalón',
        description: 'desc',
        muscleGroups: ['Dorsal ancho', 'Bíceps'],
        difficulty: 5,
      ),
      const Exercise(
        key: 'sentadilla',
        name: 'Sentadilla',
        description: 'desc',
        muscleGroups: ['Cuádriceps', 'Glúteos'],
        difficulty: 6,
      ),
    ];

    test('filters exercises matching selected categories', () {
      final result = exercisesForCategories(
        [MuscleGroupCategory.pectoral],
        exercises,
      );
      expect(result.length, 1);
      expect(result[0].name, 'Press');
    });

    test('returns exercises for multiple categories', () {
      final result = exercisesForCategories(
        [MuscleGroupCategory.espalda, MuscleGroupCategory.cuadriceps],
        exercises,
      );
      expect(result.length, 2);
      expect(result.map((e) => e.name), containsAll(['Jalón', 'Sentadilla']));
    });

    test('returns empty when no categories match', () {
      final result = exercisesForCategories(
        [MuscleGroupCategory.gemelos],
        exercises,
      );
      expect(result, isEmpty);
    });

    test('pectoral category matches all pectoral variants', () {
      final pectoralExercises = [
        const Exercise(
          key: 'e1',
          name: 'E1',
          description: '',
          muscleGroups: ['Pectoral superior'],
          difficulty: 1,
        ),
        const Exercise(
          key: 'e2',
          name: 'E2',
          description: '',
          muscleGroups: ['Pectoral inferior'],
          difficulty: 1,
        ),
        const Exercise(
          key: 'e3',
          name: 'E3',
          description: '',
          muscleGroups: ['Pectoral'],
          difficulty: 1,
        ),
        const Exercise(
          key: 'e4',
          name: 'E4',
          description: '',
          muscleGroups: ['Pectoral mayor'],
          difficulty: 1,
        ),
      ];

      final result = exercisesForCategories(
        [MuscleGroupCategory.pectoral],
        pectoralExercises,
      );
      expect(result.length, 4);
    });

    test('espalda category matches all back + posterior deltoid variants', () {
      final backExercises = [
        const Exercise(
          key: 'e1',
          name: 'E1',
          description: '',
          muscleGroups: ['Dorsal ancho'],
          difficulty: 1,
        ),
        const Exercise(
          key: 'e2',
          name: 'E2',
          description: '',
          muscleGroups: ['Deltoide posterior'],
          difficulty: 1,
        ),
        const Exercise(
          key: 'e3',
          name: 'E3',
          description: '',
          muscleGroups: ['Romboides'],
          difficulty: 1,
        ),
        const Exercise(
          key: 'e4',
          name: 'E4',
          description: '',
          muscleGroups: ['Serrato anterior'],
          difficulty: 1,
        ),
      ];

      final result = exercisesForCategories(
        [MuscleGroupCategory.espalda],
        backExercises,
      );
      expect(result.length, 4);
    });
  });
}
