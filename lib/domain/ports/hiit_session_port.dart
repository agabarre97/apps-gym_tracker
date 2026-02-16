import 'package:gym_tracker/domain/entities/hiit_session.dart';

abstract class HiitSessionPort {
  Future<List<HiitSession>> loadSessions();
  Future<void> saveSessions(List<HiitSession> sessions);
}
