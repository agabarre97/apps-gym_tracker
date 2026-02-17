import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/mobility_exercise_info.dart';

void main() {
  group('MobilityExerciseInfo', () {
    test('fromJson parses all list fields', () {
      final info = MobilityExerciseInfo.fromJson({
        'instructions': ['A', 'B'],
        'tips': ['Tip 1'],
        'modifications': ['Mod 1'],
        'benefits': ['Glutes', 'Hamstrings'],
      });

      expect(info.instructions, ['A', 'B']);
      expect(info.tips, ['Tip 1']);
      expect(info.modifications, ['Mod 1']);
      expect(info.benefits, ['Glutes', 'Hamstrings']);
    });
  });
}
