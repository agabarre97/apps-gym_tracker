import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/data/datasources/measurement_datasource.dart';
import 'package:gym_tracker/domain/entities/measurement_record.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('MeasurementDatasource', () {
    late FakeStoragePort storage;
    late MeasurementDatasource datasource;

    setUp(() {
      storage = FakeStoragePort();
      datasource = MeasurementDatasource(storage);
    });

    test('loadRecords() returns empty list when no records are saved',
        () async {
      expect(await datasource.loadRecords(), isEmpty);
    });

    test('saveRecords() then loadRecords() returns persisted values', () async {
      final list = [
        MeasurementRecord(
          id: 'm1',
          date: DateTime(2026, 1, 10),
          weightKg: 80,
          chestPerimeterCm: 100,
        ),
      ];

      await datasource.saveRecords(list);
      final loaded = await datasource.loadRecords();

      expect(loaded, hasLength(1));
      expect(loaded.first.id, 'm1');
      expect(loaded.first.weightKg, 80);
      expect(loaded.first.chestPerimeterCm, 100);
    });

    test('addRecord() appends new record to stored list', () async {
      await datasource.saveRecords([
        MeasurementRecord(
          id: 'm1',
          date: DateTime(2026, 1, 10),
          weightKg: 80,
        ),
      ]);

      await datasource.addRecord(
        MeasurementRecord(
          id: 'm2',
          date: DateTime(2026, 1, 20),
          weightKg: 79.4,
        ),
      );

      final loaded = await datasource.loadRecords();
      expect(loaded, hasLength(2));
      expect(loaded.last.id, 'm2');
      expect(loaded.last.weightKg, 79.4);
    });
  });
}
