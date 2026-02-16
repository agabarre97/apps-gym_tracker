/// Shared time formatting utilities used across timer and config screens.
abstract final class TimeFormatter {
  /// Formats seconds as `MM:SS` (zero-padded, for countdown display).
  ///
  /// Example: `65` → `"01:05"`, `5` → `"00:05"`.
  static String mmss(int seconds) {
    if (seconds < 0) seconds = 0;
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Formats total seconds as a human-readable duration string.
  ///
  /// Example: `510` → `"8 min 30s"`, `120` → `"2 min"`.
  static String duration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (seconds == 0) return '$minutes min';
    return '$minutes min ${seconds}s';
  }
}
