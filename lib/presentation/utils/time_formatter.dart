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

/// Convenience extension so [Duration] values can format themselves.
extension DurationFormat on Duration {
  /// Human-readable summary: `"1h 3m"`, `"12m 5s"`, `"45s"`.
  String toHumanReadable() {
    final h = inHours;
    final m = inMinutes % 60;
    final s = inSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0 && s > 0) return '${m}m ${s}s';
    if (m > 0) return '${m}m';
    return '${s}s';
  }

  /// Compact stopwatch display: `"MM:SS.cc"`.
  String toStopwatch() {
    final m = inMinutes.toString().padLeft(2, '0');
    final s = (inSeconds % 60).toString().padLeft(2, '0');
    final cs = (inMilliseconds % 1000 ~/ 10).toString().padLeft(2, '0');
    return '$m:$s.$cs';
  }

  /// Compact rest-time label: `"1m 30s"`, `"45s"`.
  String toRestLabel() {
    final totalSeconds = inSeconds;
    if (totalSeconds >= 60) {
      final m = totalSeconds ~/ 60;
      final s = totalSeconds % 60;
      return s > 0 ? '${m}m ${s}s' : '${m}m';
    }
    return '${totalSeconds}s';
  }
}
