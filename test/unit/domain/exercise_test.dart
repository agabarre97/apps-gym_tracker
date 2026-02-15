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
}
