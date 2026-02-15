import 'package:gym_tracker/domain/entities/user_profile.dart';

/// Port (interface) for profile persistence.
abstract class ProfilePort {
  Future<void> saveProfile(UserProfile profile);
  Future<UserProfile?> loadProfile();
  Future<void> markProfileCompleted();
  Future<bool> isProfileCompleted();
}
