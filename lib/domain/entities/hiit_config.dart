/// Configuration for a HIIT routine (sets, work/rest durations).
///
/// This is a pure domain value object — no Flutter dependencies.
class HiitConfig {
  const HiitConfig({
    this.sets = defaultSets,
    this.workSeconds = defaultWorkSeconds,
    this.restSeconds = defaultRestSeconds,
    this.setRestSeconds = defaultSetRestSeconds,
  });

  final int sets;
  final int workSeconds;
  final int restSeconds;
  final int setRestSeconds;

  // ── Default values ─────────────────────────────────────────────

  static const int defaultSets = 3;
  static const int defaultWorkSeconds = 20;
  static const int defaultRestSeconds = 10;
  static const int defaultSetRestSeconds = 90;

  // ── Range limits (for UI pickers) ──────────────────────────────

  static const int minWorkSeconds = 5;
  static const int maxWorkSeconds = 120;
  static const int minRestSeconds = 5;
  static const int maxRestSeconds = 60;
  static const int minSetRestSeconds = 10;
  static const int maxSetRestSeconds = 300;

  /// Picker increment step in seconds.
  static const int stepSeconds = 5;

  // ── Serialization ──────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'sets': sets,
        'workSeconds': workSeconds,
        'restSeconds': restSeconds,
        'setRestSeconds': setRestSeconds,
      };

  factory HiitConfig.fromJson(Map<String, dynamic> json) => HiitConfig(
        sets: json['sets'] as int? ?? defaultSets,
        workSeconds: json['workSeconds'] as int? ?? defaultWorkSeconds,
        restSeconds: json['restSeconds'] as int? ?? defaultRestSeconds,
        setRestSeconds: json['setRestSeconds'] as int? ?? defaultSetRestSeconds,
      );

  /// Creates a copy with optional overrides.
  HiitConfig copyWith({
    int? sets,
    int? workSeconds,
    int? restSeconds,
    int? setRestSeconds,
  }) =>
      HiitConfig(
        sets: sets ?? this.sets,
        workSeconds: workSeconds ?? this.workSeconds,
        restSeconds: restSeconds ?? this.restSeconds,
        setRestSeconds: setRestSeconds ?? this.setRestSeconds,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiitConfig &&
          sets == other.sets &&
          workSeconds == other.workSeconds &&
          restSeconds == other.restSeconds &&
          setRestSeconds == other.setRestSeconds;

  @override
  int get hashCode =>
      Object.hash(sets, workSeconds, restSeconds, setRestSeconds);

  @override
  String toString() =>
      'HiitConfig(sets: $sets, work: ${workSeconds}s, rest: ${restSeconds}s, setRest: ${setRestSeconds}s)';
}
