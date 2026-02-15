/// Port (interface) for local storage - domain layer defines the contract.
abstract class StoragePort {
  Future<String?> get(String key);
  Future<void> set(String key, String value);
  Future<void> remove(String key);
}
