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

  group('Exercise serialization', () {
    test('round-trips with toJson and list serializers', () {
      const original = Exercise(
        key: 'custom_press',
        name: 'Custom Press',
        description: 'Custom description',
        muscleGroups: ['chest', 'triceps'],
        difficulty: 2,
        localizedName: {'es': 'Press custom', 'en': 'Custom press'},
        localizedShortDescription: {'es': 'Desc ES', 'en': 'Desc EN'},
        musclesInvolved: ['chest', 'triceps'],
        musclesConfidence: 'high',
        categoryKeys: ['chest', 'triceps'],
      );

      final encoded = Exercise.listToJsonString(const [original]);
      final decoded = Exercise.listFromJsonString(encoded);

      expect(decoded, hasLength(1));
      expect(decoded.first.key, original.key);
      expect(decoded.first.localizedNameFor('es'), 'Press custom');
      expect(decoded.first.localizedDescriptionFor('en'), 'Desc EN');
      expect(decoded.first.categoryKeys, ['chest', 'triceps']);
    });
  });
}
