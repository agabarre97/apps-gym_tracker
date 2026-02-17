import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/mobility_session.dart';

void main() {
  group('MobilitySession', () {
    test('toJson and fromJson round-trip', () {
      final session = MobilitySession(
        id: 'm1',
        routineKey: 'sleep',
        date: DateTime(2026, 2, 16),
        startTime: DateTime(2026, 2, 16, 21, 0),
        endTime: DateTime(2026, 2, 16, 21, 15),
      );

      final json = session.toJson();
      final parsed = MobilitySession.fromJson(json);

      expect(parsed.id, 'm1');
      expect(parsed.routineKey, 'sleep');
      expect(parsed.date, DateTime(2026, 2, 16));
      expect(parsed.startTime, DateTime(2026, 2, 16, 21, 0));
      expect(parsed.endTime, DateTime(2026, 2, 16, 21, 15));
    });

    test('listToJsonString and listFromJsonString round-trip', () {
      final list = [
        MobilitySession(id: 'm1', routineKey: 'sleep', date: DateTime(2026, 2, 16)),
        MobilitySession(id: 'm2', routineKey: 'hips', date: DateTime(2026, 2, 17)),
      ];

      final json = MobilitySession.listToJsonString(list);
      final parsed = MobilitySession.listFromJsonString(json);

      expect(parsed.length, 2);
      expect(parsed.first.id, 'm1');
      expect(parsed.last.id, 'm2');
    });
  });
}
