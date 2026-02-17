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

    test('orders by explicit category priority and favors specific exercises', () {
      final orderedExercises = [
        const Exercise(
          key: 'multi_first',
          name: 'Multi primero',
          description: '',
          muscleGroups: ['Espalda', 'Bíceps'],
          difficulty: 1,
          muscleCategoryPriority: {'biceps': 2, 'espalda': 1},
        ),
        const Exercise(
          key: 'single_biceps',
          name: 'Solo bíceps',
          description: '',
          muscleGroups: ['Bíceps braquial'],
          difficulty: 1,
          muscleCategoryPriority: {'biceps': 1},
        ),
        const Exercise(
          key: 'multi_same_priority',
          name: 'Multi misma prioridad',
          description: '',
          muscleGroups: ['Bíceps', 'Tríceps'],
          difficulty: 1,
          muscleCategoryPriority: {'biceps': 1, 'triceps': 2},
        ),
      ];

      final result = exercisesForCategories(
        [MuscleGroupCategory.biceps],
        orderedExercises,
      );

      expect(result.map((e) => e.key).toList(), [
        'single_biceps',
        'multi_same_priority',
        'multi_first',
      ]);
    });

    test('uses best any match when multiple categories are selected', () {
      final exercises = [
        const Exercise(
          key: 'back_focus',
          name: 'Back focus',
          description: '',
          muscleGroups: ['Dorsal ancho', 'Bíceps'],
          difficulty: 1,
          muscleCategoryPriority: {'espalda': 1, 'biceps': 2},
        ),
        const Exercise(
          key: 'biceps_focus',
          name: 'Biceps focus',
          description: '',
          muscleGroups: ['Bíceps', 'Dorsal ancho'],
          difficulty: 1,
          muscleCategoryPriority: {'biceps': 1, 'espalda': 2},
        ),
        const Exercise(
          key: 'secondary',
          name: 'Secondary',
          description: '',
          muscleGroups: ['Pectoral', 'Tríceps'],
          difficulty: 1,
          muscleCategoryPriority: {'pectoral': 2, 'triceps': 3},
        ),
      ];

      final result = exercisesForCategories(
        [MuscleGroupCategory.biceps, MuscleGroupCategory.espalda],
        exercises,
      );

      expect(result.map((e) => e.key).toList(), [
        'back_focus',
        'biceps_focus',
      ]);
    });

    test('falls back to muscleGroups order when explicit priority is missing', () {
      final result = exercisesForCategories(
        [MuscleGroupCategory.biceps],
        const [
          Exercise(
            key: 'biceps_second',
            name: 'Biceps second',
            description: '',
            muscleGroups: ['Dorsal ancho', 'Bíceps'],
            difficulty: 1,
          ),
          Exercise(
            key: 'biceps_first',
            name: 'Biceps first',
            description: '',
            muscleGroups: ['Bíceps', 'Dorsal ancho'],
            difficulty: 1,
          ),
        ],
      );

      expect(result.map((e) => e.key).toList(), ['biceps_first', 'biceps_second']);
    });
  });
}
