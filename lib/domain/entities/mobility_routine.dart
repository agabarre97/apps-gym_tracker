/// A single exercise within a mobility routine.
class MobilityExercise {
  const MobilityExercise({
    required this.key,
    required this.durationSeconds,
    required this.bilateral,
  });

  /// Locale-independent key for i18n lookup (e.g. mobility_exercise_{key}).
  final String key;

  /// Duration per side. If bilateral=false, total = durationSeconds * 2.
  final int durationSeconds;

  /// If true, both feet/legs at once; if false, do one then the other.
  final bool bilateral;

  /// Total seconds for this exercise (bilateral ? durationSeconds : durationSeconds * 2).
  int get totalSeconds => bilateral ? durationSeconds : durationSeconds * 2;

  factory MobilityExercise.fromJson(Map<String, dynamic> json) =>
      MobilityExercise(
        key: json['key'] as String,
        durationSeconds: json['duration_seconds'] as int,
        bilateral: json['bilateral'] as bool? ?? true,
      );
}

/// A predefined mobility routine (e.g. Feet & Ankles 2 from Bend).
class MobilityRoutine {
  const MobilityRoutine({
    required this.key,
    required this.nameKey,
    required this.totalDurationMinutes,
    required this.exercises,
  });

  final String key;
  final String nameKey;
  final int totalDurationMinutes;
  final List<MobilityExercise> exercises;

  /// Total seconds across all exercises.
  int get totalSeconds => exercises.fold(0, (sum, e) => sum + e.totalSeconds);

  factory MobilityRoutine.fromJson(Map<String, dynamic> json) =>
      MobilityRoutine(
        key: json['key'] as String,
        nameKey: json['name_key'] as String,
        totalDurationMinutes: json['total_duration_minutes'] as int? ?? 11,
        exercises: (json['exercises'] as List)
            .cast<Map<String, dynamic>>()
            .map(MobilityExercise.fromJson)
            .toList(),
      );
}
