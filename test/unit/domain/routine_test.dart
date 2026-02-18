import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/hiit_config.dart';
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

  group('Routine export', () {
    test('toExportJson excludes id', () {
      const routine = Routine(
        id: 'r1',
        name: 'Push day',
        type: 'musculacion',
        days: [
          RoutineDay(
            muscleGroups: ['pectoral', 'triceps'],
            exerciseKeys: ['press_banca', 'fondos'],
          ),
        ],
      );

      final export = routine.toExportJson();
      expect(export.containsKey('id'), isFalse);
      expect(export['version'], Routine.exportVersion);
      expect(export['name'], 'Push day');
      expect(export['type'], 'musculacion');
      expect((export['days'] as List).length, 1);
    });

    test('toExportJson includes recommendedRoutineKey when set', () {
      const routine = Routine(
        id: 'r1',
        name: 'Mobility',
        type: 'movilidad',
        days: [],
        recommendedRoutineKey: 'feet_ankles_2',
      );

      final export = routine.toExportJson();
      expect(export.containsKey('id'), isFalse);
      expect(export['recommendedRoutineKey'], 'feet_ankles_2');
    });

    test('toExportJsonString produces valid parseable JSON', () {
      const routine = Routine(
        id: 'r1',
        name: 'Test',
        type: 'musculacion',
        days: [
          RoutineDay(muscleGroups: ['espalda'], exerciseKeys: ['dominadas']),
        ],
      );

      final jsonStr = routine.toExportJsonString();
      final restored = Routine.fromImportJsonString(jsonStr, id: 'new-id');
      expect(restored.id, 'new-id');
      expect(restored.name, 'Test');
      expect(restored.type, 'musculacion');
      expect(restored.days.length, 1);
      expect(restored.days[0].exerciseKeys, ['dominadas']);
    });

    test('export → import round-trip preserves all days and does not throw',
        () {
      const routine = Routine(
        id: 'full-routine',
        name: 'Full body',
        type: 'musculacion',
        days: [
          RoutineDay(
            muscleGroups: ['chest', 'triceps'],
            exerciseKeys: ['press_banca', 'fondos', 'press_inclinado'],
          ),
          RoutineDay(
            muscleGroups: ['lats', 'biceps'],
            exerciseKeys: ['dominadas', 'curl_barra'],
          ),
          RoutineDay(
            muscleGroups: ['quads', 'hamstrings', 'glutes'],
            exerciseKeys: ['sentadilla', 'peso_muerto'],
          ),
        ],
      );

      // Must not throw.
      final jsonStr = routine.toExportJsonString();
      final restored = Routine.fromImportJsonString(jsonStr, id: 'imported-id');

      expect(restored.id, 'imported-id');
      expect(restored.name, routine.name);
      expect(restored.type, routine.type);
      expect(restored.days.length, routine.days.length);

      for (var i = 0; i < routine.days.length; i++) {
        expect(
          restored.days[i].muscleGroups,
          routine.days[i].muscleGroups,
          reason: 'muscleGroups mismatch on day $i',
        );
        expect(
          restored.days[i].exerciseKeys,
          routine.days[i].exerciseKeys,
          reason: 'exerciseKeys mismatch on day $i',
        );
      }
    });
  });

  group('Routine import', () {
    test('fromImportJsonString parses valid export JSON', () {
      const json = '{"name":"Push","type":"musculacion","days":'
          '[{"muscleGroups":["pectoral"],"exerciseKeys":["press_banca"]}]}';

      final routine = Routine.fromImportJsonString(json, id: 'abc');
      expect(routine.id, 'abc');
      expect(routine.name, 'Push');
      expect(routine.type, 'musculacion');
      expect(routine.days.length, 1);
    });

    test('fromImportJsonString throws on invalid JSON', () {
      expect(
        () => Routine.fromImportJsonString('not json', id: 'x'),
        throwsFormatException,
      );
    });

    test('fromImportJsonString throws on non-object JSON', () {
      expect(
        () => Routine.fromImportJsonString('[1,2]', id: 'x'),
        throwsFormatException,
      );
    });

    test('fromImportJsonString throws when name is missing', () {
      expect(
        () => Routine.fromImportJsonString(
          '{"type":"musculacion","days":[]}',
          id: 'x',
        ),
        throwsFormatException,
      );
    });

    test('fromImportJsonString throws when type is missing', () {
      expect(
        () => Routine.fromImportJsonString(
          '{"name":"Test","days":[]}',
          id: 'x',
        ),
        throwsFormatException,
      );
    });

    test('fromImportJsonString throws when days is empty list', () {
      expect(
        () => Routine.fromImportJsonString(
          '{"name":"Test","type":"musculacion","days":[]}',
          id: 'x',
        ),
        throwsFormatException,
      );
    });

    test('fromImportJsonString preserves recommendedRoutineKey', () {
      const json = '{"name":"Mob","type":"movilidad","days":'
          '[{"muscleGroups":[],"exerciseKeys":[]}],'
          '"recommendedRoutineKey":"feet_ankles_2"}';

      final routine = Routine.fromImportJsonString(json, id: 'abc');
      expect(routine.recommendedRoutineKey, 'feet_ankles_2');
    });
  });

  // ── isArchived (soft delete) ────────────────────────────────

  group('isArchived soft delete', () {
    test('defaults to false when not present in JSON', () {
      final json = {
        'id': 'r1',
        'name': 'Push',
        'type': 'musculacion',
        'days': <Map<String, dynamic>>[],
      };
      final routine = Routine.fromJson(json);
      expect(routine.isArchived, isFalse);
    });

    test('toJson omits isArchived when false', () {
      const routine = Routine(
        id: 'r1',
        name: 'Push',
        type: 'musculacion',
        days: [],
      );
      final json = routine.toJson();
      expect(json.containsKey('isArchived'), isFalse);
    });

    test('toJson includes isArchived when true', () {
      const routine = Routine(
        id: 'r1',
        name: 'Push',
        type: 'musculacion',
        days: [],
        isArchived: true,
      );
      final json = routine.toJson();
      expect(json['isArchived'], isTrue);
    });

    test('round-trip preserves isArchived true', () {
      const routine = Routine(
        id: 'r1',
        name: 'Archived',
        type: 'musculacion',
        days: [],
        isArchived: true,
      );
      final json = routine.toJson();
      final restored = Routine.fromJson(json);
      expect(restored.isArchived, isTrue);
    });

    test('copyWith can set isArchived to true', () {
      const routine = Routine(
        id: 'r1',
        name: 'Push',
        type: 'musculacion',
        days: [],
      );
      final archived = routine.copyWith(isArchived: true);
      expect(archived.isArchived, isTrue);
      expect(archived.name, 'Push');
    });

    test('listToJsonString preserves isArchived in list round-trip', () {
      final routines = [
        const Routine(
          id: 'r1',
          name: 'Active',
          type: 'musculacion',
          days: [],
        ),
        const Routine(
          id: 'r2',
          name: 'Deleted',
          type: 'musculacion',
          days: [],
          isArchived: true,
        ),
      ];
      final jsonStr = Routine.listToJsonString(routines);
      final restored = Routine.listFromJsonString(jsonStr);
      expect(restored[0].isArchived, isFalse);
      expect(restored[1].isArchived, isTrue);
    });
  });

  // ── HIIT config fields ──────────────────────────────────────

  group('HIIT config fields', () {
    test('toJson and fromJson round-trip preserves HIIT config', () {
      const routine = Routine(
        id: 'hiit1',
        name: 'My HIIT',
        type: 'hiit',
        days: [
          RoutineDay(
              muscleGroups: [], exerciseKeys: ['burpees', 'jump_squats']),
        ],
        hiitConfig: HiitConfig(
          sets: 4,
          workSeconds: 30,
          restSeconds: 15,
          setRestSeconds: 120,
        ),
      );

      final json = routine.toJson();
      final restored = Routine.fromJson(json);

      expect(restored.hiitSets, 4);
      expect(restored.hiitWorkSeconds, 30);
      expect(restored.hiitRestSeconds, 15);
      expect(restored.hiitSetRestSeconds, 120);
      expect(restored.type, 'hiit');
      expect(restored.days.first.exerciseKeys, ['burpees', 'jump_squats']);
    });

    test('fromJson defaults to null for HIIT fields when absent', () {
      final json = {
        'id': 'r1',
        'name': 'Strength',
        'type': 'musculacion',
        'days': <Map<String, dynamic>>[],
      };

      final routine = Routine.fromJson(json);

      expect(routine.hiitSets, isNull);
      expect(routine.hiitWorkSeconds, isNull);
      expect(routine.hiitRestSeconds, isNull);
      expect(routine.hiitSetRestSeconds, isNull);
    });

    test('copyWith overrides HIIT config', () {
      const routine = Routine(
        id: 'hiit1',
        name: 'My HIIT',
        type: 'hiit',
        days: [],
        hiitConfig: HiitConfig(
          sets: 3,
          workSeconds: 20,
          restSeconds: 10,
          setRestSeconds: 90,
        ),
      );

      final updated = routine.copyWith(
        hiitConfig: routine.hiitConfig!.copyWith(
          sets: 5,
          workSeconds: 40,
        ),
      );

      expect(updated.hiitSets, 5);
      expect(updated.hiitWorkSeconds, 40);
      expect(updated.hiitRestSeconds, 10);
      expect(updated.hiitSetRestSeconds, 90);
    });

    test('export and import round-trip preserves HIIT fields', () {
      const routine = Routine(
        id: 'hiit1',
        name: 'My HIIT',
        type: 'hiit',
        days: [
          RoutineDay(muscleGroups: [], exerciseKeys: ['burpees']),
        ],
        hiitConfig: HiitConfig(
          sets: 4,
          workSeconds: 30,
          restSeconds: 15,
          setRestSeconds: 120,
        ),
      );

      final jsonString = routine.toExportJsonString();
      final restored = Routine.fromImportJsonString(jsonString, id: 'new_id');

      expect(restored.hiitSets, 4);
      expect(restored.hiitWorkSeconds, 30);
      expect(restored.hiitRestSeconds, 15);
      expect(restored.hiitSetRestSeconds, 120);
      expect(restored.name, 'My HIIT');
      expect(restored.type, 'hiit');
    });
  });
}
