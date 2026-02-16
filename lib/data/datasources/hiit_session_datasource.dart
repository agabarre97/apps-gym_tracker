import 'package:gym_tracker/domain/entities/hiit_session.dart';
import 'package:gym_tracker/domain/ports/hiit_session_port.dart';
import 'package:gym_tracker/domain/ports/storage_port.dart';

/// Adapter implementing [HiitSessionPort] using [StoragePort].
class HiitSessionDatasource implements HiitSessionPort {
  const HiitSessionDatasource(this._storage);

  final StoragePort _storage;
  static const _key = 'hiit_sessions';

  @override
  Future<List<HiitSession>> loadSessions() async {
    final raw = await _storage.get(_key);
    if (raw == null || raw.isEmpty) return [];
    return HiitSession.listFromJsonString(raw);
  }

  @override
  Future<void> saveSessions(List<HiitSession> sessions) =>
      _storage.set(_key, HiitSession.listToJsonString(sessions));
}
