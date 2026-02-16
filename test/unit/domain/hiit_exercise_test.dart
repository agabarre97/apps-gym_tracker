import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/hiit_exercise.dart';

void main() {
  group('HiitExercise', () {
    test('fromJson parses key, name, and description', () {
      final json = {
        'key': 'burpees',
        'ejercicio': 'Burpees',
        'descripcion': 'Full body explosive movement.',
      };

      final exercise = HiitExercise.fromJson(json);

      expect(exercise.key, 'burpees');
      expect(exercise.name, 'Burpees');
      expect(exercise.description, 'Full body explosive movement.');
    });

    test('fromJson handles all 18 exercises consistently', () {
      final jsonList = [
        {'key': 'mountain_climbers', 'ejercicio': 'Mountain climbers', 'descripcion': 'desc1'},
        {'key': 'jumping_jacks', 'ejercicio': 'Jumping jacks', 'descripcion': 'desc2'},
        {'key': 'burpees', 'ejercicio': 'Burpees', 'descripcion': 'desc3'},
      ];

      final exercises = jsonList.map(HiitExercise.fromJson).toList();

      expect(exercises.length, 3);
      expect(exercises[0].key, 'mountain_climbers');
      expect(exercises[1].key, 'jumping_jacks');
      expect(exercises[2].key, 'burpees');
    });

    test('fromJson preserves Spanish characters in description', () {
      final json = {
        'key': 'high_knee_sprints',
        'ejercicio': 'High knee sprints',
        'descripcion': 'Corre en el sitio elevando las rodillas lo más alto posible.',
      };

      final exercise = HiitExercise.fromJson(json);

      expect(exercise.description, contains('más'));
    });
  });
}
