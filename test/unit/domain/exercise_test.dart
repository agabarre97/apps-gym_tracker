import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';

void main() {
  group('Exercise.nameForKey', () {
    test('returns localized name when key exists', () {
      const all = [
        Exercise(
          key: 'push_up',
          name: 'Flexiones',
          description: '...',
          muscleGroups: ['pectoral'],
          difficulty: 2,
        ),
      ];

      final result = Exercise.nameForKey(all, 'push_up');
      expect(result, 'Flexiones');
    });

    test('falls back to the key when key does not exist', () {
      const all = <Exercise>[];
      final result = Exercise.nameForKey(all, 'unknown_key');
      expect(result, 'unknown_key');
    });
  });

  group('Exercise.fromJson by_muscle', () {
    test('parses bilingual fields and confidence difficulty', () {
      final exercise = Exercise.fromJson({
        'key': 'barbell-curl',
        'name': {'es': 'Curl con barra', 'en': 'Barbell Curl'},
        'short_description': {'es': 'Descripcion ES', 'en': 'Description EN'},
        'muscles_involved': ['biceps', 'forearms'],
        'muscles_confidence': 'high',
      });

      expect(exercise.localizedNameFor('es'), 'Curl con barra');
      expect(exercise.localizedNameFor('en'), 'Barbell Curl');
      expect(exercise.localizedDescriptionFor('es'), 'Descripcion ES');
      expect(exercise.localizedDescriptionFor('en'), 'Description EN');
      expect(exercise.resolvedMusclesInvolved, ['biceps', 'forearms']);
      expect(exercise.difficulty, 3);
    });
  });
}
