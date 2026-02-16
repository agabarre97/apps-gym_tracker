import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/data/datasources/hiit_session_datasource.dart';
import 'package:gym_tracker/domain/entities/hiit_session.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('HiitSessionDatasource', () {
    late FakeStoragePort storage;
    late HiitSessionDatasource datasource;

    setUp(() {
      storage = FakeStoragePort();
      datasource = HiitSessionDatasource(storage);
    });

    test('loadSessions returns empty list when no data saved', () async {
      final sessions = await datasource.loadSessions();
      expect(sessions, isEmpty);
    });

    test('saveSessions persists and loadSessions retrieves correctly',
        () async {
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

      await datasource.saveSessions(sessions);

      final loaded = await datasource.loadSessions();
      expect(loaded.length, 2);
      expect(loaded[0].id, 'h1');
      expect(loaded[0].routineName, 'Tabata');
      expect(loaded[1].id, 'h2');
      expect(loaded[1].routineName, 'Quick HIIT');
    });

    test('loadSessions returns empty list for empty string in storage',
        () async {
      await storage.set('hiit_sessions', '');
      final sessions = await datasource.loadSessions();
      expect(sessions, isEmpty);
    });

    test('overwriting sessions replaces previous data', () async {
      await datasource.saveSessions([
        HiitSession(
          id: 'h1',
          routineName: 'Old',
          date: DateTime(2026, 1, 1),
        ),
      ]);

      await datasource.saveSessions([
        HiitSession(
          id: 'h2',
          routineName: 'New',
          date: DateTime(2026, 2, 1),
        ),
      ]);

      final loaded = await datasource.loadSessions();
      expect(loaded.length, 1);
      expect(loaded[0].id, 'h2');
      expect(loaded[0].routineName, 'New');
    });
  });
}
