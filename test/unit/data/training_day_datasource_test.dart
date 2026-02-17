import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/data/datasources/training_day_datasource.dart';
import 'package:gym_tracker/domain/entities/training_day.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('TrainingDayDatasource', () {
    late FakeStoragePort storage;
    late TrainingDayDatasource datasource;

    setUp(() {
      storage = FakeStoragePort();
      datasource = TrainingDayDatasource(storage);
    });

    test('loadTrainingDays returns empty list when no data exists', () async {
      final days = await datasource.loadTrainingDays();
      expect(days, isEmpty);
    });

    test('saveTrainingDays persists and loadTrainingDays restores data', () async {
      final days = [
        TrainingDay(date: DateTime(2026, 2, 16)),
        TrainingDay(date: DateTime(2026, 2, 17)),
      ];

      await datasource.saveTrainingDays(days);
      final loaded = await datasource.loadTrainingDays();

      expect(loaded.length, 2);
      expect(loaded.first.key, '2026-02-16');
      expect(loaded.last.key, '2026-02-17');
    });
  });
}
