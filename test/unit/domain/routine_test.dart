import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/routine.dart';

void main() {
  group('Routine serialization', () {
    test('toJson and fromJson round-trip', () {
      const routine = Routine(
        id: 'r1',
        name: 'Push day',
        type: 'musculacion',
        days: [
          RoutineDay(
            muscleGroups: ['pectoral', 'triceps'],
            exerciseKeys: ['press_en_multipower', 'extension_de_triceps'],
          ),
        ],
      );

      final json = routine.toJson();
      final restored = Routine.fromJson(json);

      expect(restored.id, 'r1');
      expect(restored.name, 'Push day');
      expect(restored.type, 'musculacion');
      expect(restored.days.length, 1);
      expect(restored.days[0].muscleGroups, ['pectoral', 'triceps']);
      expect(restored.days[0].exerciseKeys.length, 2);
    });

    test('listToJsonString and listFromJsonString round-trip', () {
      final routines = [
        const Routine(
          id: 'r1',
          name: 'Push',
          type: 'musculacion',
          days: [],
        ),
        const Routine(
          id: 'r2',
          name: 'Pull',
          type: 'musculacion',
          days: [
            RoutineDay(
              muscleGroups: ['espalda'],
              exerciseKeys: ['jalon_abierto'],
            ),
          ],
        ),
      ];

      final jsonStr = Routine.listToJsonString(routines);
      final restored = Routine.listFromJsonString(jsonStr);

      expect(restored.length, 2);
      expect(restored[0].name, 'Push');
      expect(restored[1].days.length, 1);
    });

    test('fromJson handles missing type gracefully', () {
      final json = {'id': 'r1', 'name': 'Old routine'};
      final routine = Routine.fromJson(json);

      expect(routine.type, 'musculacion');
      expect(routine.days, isEmpty);
    });

    test('fromJson backward compat: reads exerciseNames as exerciseKeys', () {
      final json = {
        'muscleGroups': ['pectoral'],
        'exerciseNames': ['Press', 'Curl'],
      };
      final day = RoutineDay.fromJson(json);
      expect(day.exerciseKeys, ['Press', 'Curl']);
    });
  });

  group('RoutineDay serialization', () {
    test('toJson and fromJson round-trip', () {
      const day = RoutineDay(
        muscleGroups: ['pectoral', 'hombro'],
        exerciseKeys: ['press_en_multipower', 'press_para_hombros'],
      );

      final json = day.toJson();
      final restored = RoutineDay.fromJson(json);

      expect(restored.muscleGroups, ['pectoral', 'hombro']);
      expect(restored.exerciseKeys.length, 2);
    });
  });

  group('Routine copyWith', () {
    test('creates a copy with overridden fields', () {
      const routine = Routine(
        id: 'r1',
        name: 'Old name',
        type: 'musculacion',
        days: [],
      );

      final copy = routine.copyWith(name: 'New name');
      expect(copy.id, 'r1');
      expect(copy.name, 'New name');
      expect(copy.type, 'musculacion');
    });
  });
}
