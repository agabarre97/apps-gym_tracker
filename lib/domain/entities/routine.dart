import 'dart:convert';

import 'package:gym_tracker/domain/entities/hiit_config.dart';

/// Strongly-typed discriminator for [Routine.type].
///
/// The underlying JSON representation stays as its [value] string so
/// existing stored data requires no migration.
enum RoutineType {
  musculacion('musculacion'),
  pliometricos('pliometricos'),
  movilidad('movilidad'),
  hiit('hiit');

  const RoutineType(this.value);

  /// Serialised string stored in JSON / shared-prefs.
  final String value;

  /// Parses [raw] into a [RoutineType]; returns [musculacion] for unknown values.
  static RoutineType fromString(String raw) => RoutineType.values.firstWhere(
        (t) => t.value == raw,
        orElse: () => RoutineType.musculacion,
      );
}

/// A single day within a routine.
class RoutineSetConfig {
  const RoutineSetConfig({
    this.targetReps = 10,
    this.restSeconds,
    this.dropSetCount = 0,
    this.dropSetReps,
  });

  final int targetReps;
  final int? restSeconds;
  final int dropSetCount;
  final int? dropSetReps;

  bool get hasDropSet => dropSetCount > 0;

  Map<String, dynamic> toJson() => {
        'targetReps': targetReps,
        if (restSeconds != null) 'restSeconds': restSeconds,
        if (dropSetCount > 0) 'dropSetCount': dropSetCount,
        if (dropSetReps != null) 'dropSetReps': dropSetReps,
      };

  factory RoutineSetConfig.fromJson(Map<String, dynamic> json) =>
      RoutineSetConfig(
        targetReps: json['targetReps'] as int? ?? 10,
        restSeconds: json['restSeconds'] as int?,
        dropSetCount: json['dropSetCount'] as int? ?? 0,
        dropSetReps: json['dropSetReps'] as int?,
      );

  RoutineSetConfig copyWith({
    int? targetReps,
    int? restSeconds,
    int? dropSetCount,
    int? dropSetReps,
    bool clearRestSeconds = false,
    bool clearDropSetReps = false,
  }) =>
      RoutineSetConfig(
        targetReps: targetReps ?? this.targetReps,
        restSeconds:
            clearRestSeconds ? null : (restSeconds ?? this.restSeconds),
        dropSetCount: dropSetCount ?? this.dropSetCount,
        dropSetReps:
            clearDropSetReps ? null : (dropSetReps ?? this.dropSetReps),
      );
}

/// A single exercise configuration within a routine day.
class RoutineExerciseConfig {
  const RoutineExerciseConfig({
    required this.exerciseKey,
    this.setConfigs = const [],
    this.restSeconds,
  });

  final String exerciseKey;
  final List<RoutineSetConfig> setConfigs;
  final int? restSeconds;

  /// Backward-compatible aggregate getters used by legacy UI summaries.
  int get sets => setConfigs.length;
  int get targetReps => setConfigs.isEmpty ? 10 : setConfigs.first.targetReps;
  Map<String, dynamic> toJson() => {
        'exerciseKey': exerciseKey,
        if (restSeconds != null) 'restSeconds': restSeconds,
        if (setConfigs.isNotEmpty)
          'setConfigs': setConfigs.map((c) => c.toJson()).toList(),
      };

  factory RoutineExerciseConfig.fromJson(Map<String, dynamic> json) {
    final rawSetConfigs = (json['setConfigs'] as List?)
            ?.cast<Map<String, dynamic>>()
            .map(RoutineSetConfig.fromJson)
            .toList() ??
        const <RoutineSetConfig>[];
    if (rawSetConfigs.isNotEmpty) {
      return RoutineExerciseConfig(
        exerciseKey: json['exerciseKey'] as String,
        setConfigs: rawSetConfigs,
        restSeconds:
            json['restSeconds'] as int? ?? rawSetConfigs.first.restSeconds,
      );
    }

    // Backward compatibility for previous schema.
    final sets = json['sets'] as int? ?? 3;
    final targetReps = json['targetReps'] as int? ?? 10;
    final restSeconds = json['restSeconds'] as int?;
    return RoutineExerciseConfig(
      exerciseKey: json['exerciseKey'] as String,
      restSeconds: restSeconds,
      setConfigs: List<RoutineSetConfig>.generate(
        sets,
        (_) => RoutineSetConfig(
          targetReps: targetReps,
        ),
        growable: false,
      ),
    );
  }

  RoutineExerciseConfig copyWith({
    String? exerciseKey,
    List<RoutineSetConfig>? setConfigs,
    int? restSeconds,
    bool clearRestSeconds = false,
  }) =>
      RoutineExerciseConfig(
        exerciseKey: exerciseKey ?? this.exerciseKey,
        setConfigs: setConfigs ?? this.setConfigs,
        restSeconds:
            clearRestSeconds ? null : (restSeconds ?? this.restSeconds),
      );
}

/// A single day within a routine.
class RoutineDay {
  const RoutineDay({
    required this.muscleGroups,
    required this.exerciseKeys,
    this.exerciseConfigs = const [],
  });

  /// Category keys (e.g. 'pectoral', 'espalda').
  final List<String> muscleGroups;

  /// Locale-independent exercise keys selected for this day.
  final List<String> exerciseKeys;

  /// Per-exercise default setup for workouts generated from this routine day.
  final List<RoutineExerciseConfig> exerciseConfigs;

  Map<String, dynamic> toJson() => {
        'muscleGroups': muscleGroups,
        'exerciseKeys': exerciseKeys,
        if (exerciseConfigs.isNotEmpty)
          'exerciseConfigs': exerciseConfigs.map((c) => c.toJson()).toList(),
      };

  factory RoutineDay.fromJson(Map<String, dynamic> json) {
    final exerciseKeys = json['exerciseKeys'] != null
        ? (json['exerciseKeys'] as List).cast<String>()
        : (json['exerciseNames'] as List?)?.cast<String>() ?? [];
    final rawConfigs = (json['exerciseConfigs'] as List?)
            ?.cast<Map<String, dynamic>>()
            .map(RoutineExerciseConfig.fromJson)
            .toList() ??
        const <RoutineExerciseConfig>[];
    final mergedConfigs = _normalizeExerciseConfigs(
      exerciseKeys: exerciseKeys,
      provided: rawConfigs,
    );

    return RoutineDay(
      muscleGroups: (json['muscleGroups'] as List).cast<String>(),
      // Backward compat: read old 'exerciseNames' if 'exerciseKeys' absent
      exerciseKeys: exerciseKeys,
      exerciseConfigs: mergedConfigs,
    );
  }

  RoutineDay copyWith({
    List<String>? muscleGroups,
    List<String>? exerciseKeys,
    List<RoutineExerciseConfig>? exerciseConfigs,
  }) {
    final nextExerciseKeys = exerciseKeys ?? this.exerciseKeys;
    final nextConfigs = _normalizeExerciseConfigs(
      exerciseKeys: nextExerciseKeys,
      provided: exerciseConfigs ?? this.exerciseConfigs,
    );
    return RoutineDay(
      muscleGroups: muscleGroups ?? this.muscleGroups,
      exerciseKeys: nextExerciseKeys,
      exerciseConfigs: nextConfigs,
    );
  }

  RoutineExerciseConfig? configForExercise(String exerciseKey) {
    for (final config in exerciseConfigs) {
      if (config.exerciseKey == exerciseKey) return config;
    }
    return null;
  }

  static List<RoutineExerciseConfig> _normalizeExerciseConfigs({
    required List<String> exerciseKeys,
    required List<RoutineExerciseConfig> provided,
  }) {
    final byKey = <String, RoutineExerciseConfig>{
      for (final config in provided) config.exerciseKey: config,
    };
    return exerciseKeys
        .map(
          (key) =>
              byKey[key] ??
              RoutineExerciseConfig(
                exerciseKey: key,
                setConfigs: const [
                  RoutineSetConfig(),
                  RoutineSetConfig(),
                  RoutineSetConfig(),
                ],
              ),
        )
        .toList(growable: false);
  }
}

/// A named workout routine with type and per-day exercise selection.
class Routine {
  const Routine({
    required this.id,
    required this.name,
    required this.type,
    required this.days,
    this.recommendedRoutineKey,
    this.hiitConfig,
    this.isArchived = false,
  });

  final String id;
  final String name;

  /// One of: 'musculacion', 'pliometricos', 'movilidad', 'hiit'.
  final String type;

  /// Typed accessor for [type]. Prefer this over raw string comparisons.
  RoutineType get routineType => RoutineType.fromString(type);

  final List<RoutineDay> days;

  /// If set, this routine is a predefined mobility routine (e.g. feet_ankles_2).
  final String? recommendedRoutineKey;

  /// HIIT configuration (only populated when [type] == 'hiit').
  final HiitConfig? hiitConfig;

  /// Soft-delete flag. Archived routines are hidden from the active list
  /// but remain in storage so historical sessions can still resolve their name.
  final bool isArchived;

  // ── Backward-compatible convenience getters ────────────────────

  int? get hiitSets => hiitConfig?.sets;
  int? get hiitWorkSeconds => hiitConfig?.workSeconds;
  int? get hiitRestSeconds => hiitConfig?.restSeconds;
  int? get hiitSetRestSeconds => hiitConfig?.setRestSeconds;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'days': days.map((d) => d.toJson()).toList(),
        if (recommendedRoutineKey != null)
          'recommendedRoutineKey': recommendedRoutineKey,
        if (hiitConfig != null) ...{
          'hiitSets': hiitConfig!.sets,
          'hiitWorkSeconds': hiitConfig!.workSeconds,
          'hiitRestSeconds': hiitConfig!.restSeconds,
          'hiitSetRestSeconds': hiitConfig!.setRestSeconds,
        },
        if (isArchived) 'isArchived': true,
      };

  factory Routine.fromJson(Map<String, dynamic> json) {
    // Backward-compatible: reconstruct HiitConfig from flat fields
    final hiitSets = json['hiitSets'] as int?;
    final hiitWork = json['hiitWorkSeconds'] as int?;
    final hiitRest = json['hiitRestSeconds'] as int?;
    final hiitSetRest = json['hiitSetRestSeconds'] as int?;
    final hasHiitFields = hiitSets != null ||
        hiitWork != null ||
        hiitRest != null ||
        hiitSetRest != null;

    return Routine(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'musculacion',
      days: json['days'] != null
          ? (json['days'] as List)
              .cast<Map<String, dynamic>>()
              .map(RoutineDay.fromJson)
              .toList()
          : [],
      recommendedRoutineKey: json['recommendedRoutineKey'] as String?,
      hiitConfig: hasHiitFields
          ? HiitConfig(
              sets: hiitSets ?? HiitConfig.defaultSets,
              workSeconds: hiitWork ?? HiitConfig.defaultWorkSeconds,
              restSeconds: hiitRest ?? HiitConfig.defaultRestSeconds,
              setRestSeconds: hiitSetRest ?? HiitConfig.defaultSetRestSeconds,
            )
          : null,
      isArchived: json['isArchived'] as bool? ?? false,
    );
  }

  /// Creates a deep copy with optional field overrides.
  Routine copyWith({
    String? id,
    String? name,
    String? type,
    List<RoutineDay>? days,
    String? recommendedRoutineKey,
    HiitConfig? hiitConfig,
    bool? isArchived,
  }) =>
      Routine(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        days: days ?? this.days,
        recommendedRoutineKey:
            recommendedRoutineKey ?? this.recommendedRoutineKey,
        hiitConfig: hiitConfig ?? this.hiitConfig,
        isArchived: isArchived ?? this.isArchived,
      );

  /// Current export format version — bump when the schema changes.
  static const int exportVersion = 1;

  /// Generates a portable JSON map for export (excludes `id`).
  Map<String, dynamic> toExportJson() => {
        'version': exportVersion,
        'name': name,
        'type': type,
        'days': days.map((d) => d.toJson()).toList(),
        if (recommendedRoutineKey != null)
          'recommendedRoutineKey': recommendedRoutineKey,
        if (hiitConfig != null) ...{
          'hiitSets': hiitConfig!.sets,
          'hiitWorkSeconds': hiitConfig!.workSeconds,
          'hiitRestSeconds': hiitConfig!.restSeconds,
          'hiitSetRestSeconds': hiitConfig!.setRestSeconds,
        },
      };

  /// Generates a portable JSON string for export (excludes `id`).
  String toExportJsonString() =>
      const JsonEncoder.withIndent('  ').convert(toExportJson());

  /// Parses a portable export JSON string and returns a [Routine] with the
  /// given [id]. Throws [FormatException] if the JSON is invalid or missing
  /// required fields.
  static Routine fromImportJsonString(String source, {required String id}) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(source);
    } catch (_) {
      throw const FormatException('Invalid JSON');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object');
    }
    final name = decoded['name'];
    final type = decoded['type'];
    final days = decoded['days'];
    if (name is! String || name.isEmpty) {
      throw const FormatException('Missing or empty "name"');
    }
    if (type is! String || type.isEmpty) {
      throw const FormatException('Missing or empty "type"');
    }
    if (days is! List || days.isEmpty) {
      throw const FormatException('Missing or empty "days"');
    }

    final hiitSets = decoded['hiitSets'] as int?;
    final hiitWork = decoded['hiitWorkSeconds'] as int?;
    final hiitRest = decoded['hiitRestSeconds'] as int?;
    final hiitSetRest = decoded['hiitSetRestSeconds'] as int?;
    final hasHiitFields = hiitSets != null ||
        hiitWork != null ||
        hiitRest != null ||
        hiitSetRest != null;

    return Routine(
      id: id,
      name: name,
      type: type,
      days: days.cast<Map<String, dynamic>>().map(RoutineDay.fromJson).toList(),
      recommendedRoutineKey: decoded['recommendedRoutineKey'] as String?,
      hiitConfig: hasHiitFields
          ? HiitConfig(
              sets: hiitSets ?? HiitConfig.defaultSets,
              workSeconds: hiitWork ?? HiitConfig.defaultWorkSeconds,
              restSeconds: hiitRest ?? HiitConfig.defaultRestSeconds,
              setRestSeconds: hiitSetRest ?? HiitConfig.defaultSetRestSeconds,
            )
          : null,
    );
  }

  static List<Routine> listFromJsonString(String source) =>
      (jsonDecode(source) as List)
          .cast<Map<String, dynamic>>()
          .map(Routine.fromJson)
          .toList();

  static String listToJsonString(List<Routine> list) =>
      jsonEncode(list.map((r) => r.toJson()).toList());
}
