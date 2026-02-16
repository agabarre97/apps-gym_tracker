/// Port (interface) for cloud synchronisation.
///
/// The presentation layer depends on this abstraction instead of
/// the concrete [SyncedStorageDatasource].
abstract class SyncPort {
  /// Associate the given user UID with sync operations.
  /// Pass `null` to disable sync (e.g. on sign-out).
  void setUserId(String? uid);

  /// Pull all data from the cloud into local storage.
  /// Times out after [timeout] to avoid blocking the UI.
  Future<void> pullFromCloud({Duration timeout});

  /// Push the given local keys to the cloud.
  Future<void> pushToCloud(List<String> keys);
}
