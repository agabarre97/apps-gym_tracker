import 'package:gym_tracker/domain/entities/mobility_session.dart';
import 'package:gym_tracker/domain/ports/mobility_session_port.dart';
import 'package:gym_tracker/domain/ports/storage_port.dart';

/// Adapter implementing [MobilitySessionPort] using [StoragePort].
class MobilitySessionDatasource implements MobilitySessionPort {
  const MobilitySessionDatasource(this._storage);

  final StoragePort _storage;
  static const _key = 'mobility_sessions';

  @override
  Future<List<MobilitySession>> loadSessions() async {
    final raw = await _storage.get(_key);
    if (raw == null || raw.isEmpty) return [];
    return MobilitySession.listFromJsonString(raw);
  }

  @override
  Future<void> saveSessions(List<MobilitySession> sessions) =>
      _storage.set(_key, MobilitySession.listToJsonString(sessions));
}
