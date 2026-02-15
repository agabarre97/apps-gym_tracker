import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/ports/storage_port.dart';

/// Adapter implementing [StoragePort] using SharedPreferences.
class LocalStorageDatasource implements StoragePort {
  LocalStorageDatasource(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<String?> get(String key) => Future.value(_prefs.getString(key));

  @override
  Future<void> set(String key, String value) => _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}
