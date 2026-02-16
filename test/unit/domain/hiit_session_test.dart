import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/hiit_session.dart';

void main() {
  group('HiitSession serialization', () {
    test('toJson and fromJson round-trip', () {
      final session = HiitSession(
        id: 'h1',
        routineName: 'Tabata',
        date: DateTime(2026, 2, 16),
        startTime: DateTime(2026, 2, 16, 10, 30),
        endTime: DateTime(2026, 2, 16, 10, 45),
      );

      final json = session.toJson();
      final restored = HiitSession.fromJson(json);

      expect(restored.id, 'h1');
      expect(restored.routineName, 'Tabata');
      expect(restored.date, DateTime(2026, 2, 16));
      expect(restored.startTime, DateTime(2026, 2, 16, 10, 30));
      expect(restored.endTime, DateTime(2026, 2, 16, 10, 45));
    });

    test('toJson and fromJson handle nullable startTime and endTime', () {
      final session = HiitSession(
        id: 'h2',
        routineName: 'Quick HIIT',
        date: DateTime(2026, 1, 5),
      );

      final json = session.toJson();
      expect(json['startTime'], isNull);
      expect(json['endTime'], isNull);

      final restored = HiitSession.fromJson(json);
      expect(restored.startTime, isNull);
      expect(restored.endTime, isNull);
    });

    test('listToJsonString and listFromJsonString round-trip', () {
      final sessions = [
        HiitSession(
          id: 'h1',
          routineName: 'Tabata',
          date: DateTime(2026, 2, 16),
          startTime: DateTime(2026, 2, 16, 10, 0),
          endTime: DateTime(2026, 2, 16, 10, 20),
        ),
        HiitSession(
          id: 'h2',
          routineName: 'Quick HIIT',
          date: DateTime(2026, 2, 17),
        ),
      ];

      final jsonStr = HiitSession.listToJsonString(sessions);
      final restored = HiitSession.listFromJsonString(jsonStr);

      expect(restored.length, 2);
      expect(restored[0].id, 'h1');
      expect(restored[0].routineName, 'Tabata');
      expect(restored[1].id, 'h2');
      expect(restored[1].startTime, isNull);
    });

    test('date serialization pads single-digit months and days', () {
      final session = HiitSession(
        id: 'h3',
        routineName: 'Test',
        date: DateTime(2026, 3, 5),
      );

      final json = session.toJson();
      expect(json['date'], '2026-03-05');
    });
  });
}
