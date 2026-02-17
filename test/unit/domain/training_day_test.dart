import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/training_day.dart';

void main() {
  group('TrainingDay', () {
    test('key formats date as yyyy-MM-dd', () {
      final day = TrainingDay(date: DateTime(2026, 2, 6));
      expect(day.key, '2026-02-06');
    });

    test('fromKey parses key correctly', () {
      final day = TrainingDay.fromKey('2026-02-16');
      expect(day.date, DateTime(2026, 2, 16));
    });

    test('listToJsonString and listFromJsonString round-trip', () {
      final days = [
        TrainingDay(date: DateTime(2026, 2, 16)),
        TrainingDay(date: DateTime(2026, 2, 17)),
      ];
      final json = TrainingDay.listToJsonString(days);
      final parsed = TrainingDay.listFromJsonString(json);

      expect(parsed.length, 2);
      expect(parsed.first.key, '2026-02-16');
      expect(parsed.last.key, '2026-02-17');
    });
  });
}
