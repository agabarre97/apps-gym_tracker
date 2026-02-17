import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/services/rest_time_calculator.dart';

void main() {
  group('RestTimeCalculator', () {
    test('returns null when previous edit is missing', () {
      final result = RestTimeCalculator.fromEditTimes(
        previousSetLastEdit: null,
        currentSetFirstEdit: DateTime(2026, 2, 16, 10, 0, 10),
      );
      expect(result, isNull);
    });

    test('returns null for negative differences', () {
      final result = RestTimeCalculator.fromEditTimes(
        previousSetLastEdit: DateTime(2026, 2, 16, 10, 0, 10),
        currentSetFirstEdit: DateTime(2026, 2, 16, 10, 0, 5),
      );
      expect(result, isNull);
    });

    test('returns elapsed seconds when valid', () {
      final result = RestTimeCalculator.fromEditTimes(
        previousSetLastEdit: DateTime(2026, 2, 16, 10, 0, 10),
        currentSetFirstEdit: DateTime(2026, 2, 16, 10, 0, 25),
      );
      expect(result, 15);
    });
  });
}
