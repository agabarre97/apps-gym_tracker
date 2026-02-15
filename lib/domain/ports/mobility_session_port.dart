import 'package:gym_tracker/domain/entities/mobility_session.dart';

abstract class MobilitySessionPort {
  Future<List<MobilitySession>> loadSessions();
  Future<void> saveSessions(List<MobilitySession> sessions);
}
