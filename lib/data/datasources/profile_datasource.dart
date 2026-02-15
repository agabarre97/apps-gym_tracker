import 'package:gym_tracker/domain/entities/user_profile.dart';
import 'package:gym_tracker/domain/ports/profile_port.dart';
import 'package:gym_tracker/domain/ports/storage_port.dart';

/// Adapter implementing [ProfilePort] using [StoragePort].
///
/// Stores the profile as a JSON string under a fixed key.
class ProfileDatasource implements ProfilePort {
  const ProfileDatasource(this._storage);

  final StoragePort _storage;

  static const _profileKey = 'user_profile';
  static const _completedKey = 'profile_completed';

  @override
  Future<void> saveProfile(UserProfile profile) =>
      _storage.set(_profileKey, profile.toJsonString());

  @override
  Future<UserProfile?> loadProfile() async {
    final raw = await _storage.get(_profileKey);
    if (raw == null) return null;
    return UserProfile.fromJsonString(raw);
  }

  @override
  Future<void> markProfileCompleted() =>
      _storage.set(_completedKey, 'true');

  @override
  Future<bool> isProfileCompleted() async {
    final value = await _storage.get(_completedKey);
    return value == 'true';
  }
}
