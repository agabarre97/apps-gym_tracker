import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/data/datasources/mobility_session_datasource.dart';
import 'package:gym_tracker/domain/entities/mobility_session.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('MobilitySessionDatasource', () {
    late FakeStoragePort storage;
    late MobilitySessionDatasource datasource;

    setUp(() {
      storage = FakeStoragePort();
      datasource = MobilitySessionDatasource(storage);
    });

    test('loadSessions returns empty list when no data exists', () async {
      final sessions = await datasource.loadSessions();
      expect(sessions, isEmpty);
    });

    test('loadSessions returns empty list for empty raw string', () async {
      await storage.set('mobility_sessions', '');
      final sessions = await datasource.loadSessions();
      expect(sessions, isEmpty);
    });

    test('saveSessions persists and loadSessions restores data', () async {
      final sessions = [
        MobilitySession(
          id: 'm1',
          routineKey: 'sleep',
          date: DateTime(2026, 2, 16),
          startTime: DateTime(2026, 2, 16, 21, 0),
          endTime: DateTime(2026, 2, 16, 21, 15),
        ),
      ];

      await datasource.saveSessions(sessions);
      final loaded = await datasource.loadSessions();

      expect(loaded.length, 1);
      expect(loaded.first.id, 'm1');
      expect(loaded.first.routineKey, 'sleep');
    });
  });
}
