/// Stateless helper to compute rest duration between sets.
abstract final class RestTimeCalculator {
  /// Returns rest in seconds between the previous set's last edit and
  /// current set's first edit. Returns null when unavailable or negative.
  static int? fromEditTimes({
    required DateTime? previousSetLastEdit,
    required DateTime? currentSetFirstEdit,
  }) {
    if (previousSetLastEdit == null || currentSetFirstEdit == null) {
      return null;
    }
    final seconds = currentSetFirstEdit.difference(previousSetLastEdit).inSeconds;
    return seconds < 0 ? null : seconds;
  }
}
