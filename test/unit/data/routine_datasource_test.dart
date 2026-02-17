import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/data/datasources/routine_datasource.dart';
import 'package:gym_tracker/domain/entities/routine.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('RoutineDatasource', () {
    late FakeStoragePort storage;
    late RoutineDatasource datasource;

    setUp(() {
      storage = FakeStoragePort();
      datasource = RoutineDatasource(storage);
    });

    test('loadRoutines returns empty list when no data exists', () async {
      final routines = await datasource.loadRoutines();
      expect(routines, isEmpty);
    });

    test('saveRoutines persists and loadRoutines restores data', () async {
      final routines = [
        const Routine(
          id: 'r1',
          name: 'Push',
          type: 'musculacion',
          days: [
            RoutineDay(muscleGroups: ['pectoral'], exerciseKeys: ['press'])
          ],
        ),
      ];

      await datasource.saveRoutines(routines);
      final loaded = await datasource.loadRoutines();

      expect(loaded.length, 1);
      expect(loaded.first.id, 'r1');
      expect(loaded.first.name, 'Push');
      expect(loaded.first.days.first.exerciseKeys, ['press']);
    });
  });
}
