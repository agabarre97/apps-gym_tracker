import 'dart:convert';

/// A single day within a routine.
class RoutineDay {
  const RoutineDay({
    required this.muscleGroups,
    required this.exerciseKeys,
  });

  /// Category keys (e.g. 'pectoral', 'espalda').
  final List<String> muscleGroups;

  /// Locale-independent exercise keys selected for this day.
  final List<String> exerciseKeys;

  Map<String, dynamic> toJson() => {
        'muscleGroups': muscleGroups,
        'exerciseKeys': exerciseKeys,
      };

  factory RoutineDay.fromJson(Map<String, dynamic> json) => RoutineDay(
        muscleGroups: (json['muscleGroups'] as List).cast<String>(),
        // Backward compat: read old 'exerciseNames' if 'exerciseKeys' absent
        exerciseKeys: json['exerciseKeys'] != null
            ? (json['exerciseKeys'] as List).cast<String>()
            : (json['exerciseNames'] as List?)?.cast<String>() ?? [],
      );
}

/// A named workout routine with type and per-day exercise selection.
class Routine {
  const Routine({
    required this.id,
    required this.name,
    required this.type,
    required this.days,
    this.recommendedRoutineKey,
    this.hiitSets,
    this.hiitWorkSeconds,
    this.hiitRestSeconds,
    this.hiitSetRestSeconds,
  });

  final String id;
  final String name;

  /// One of: 'musculacion', 'pliometricos', 'movilidad', 'hiit'.
  final String type;

  final List<RoutineDay> days;

  /// If set, this routine is a predefined mobility routine (e.g. feet_ankles_2).
  final String? recommendedRoutineKey;

  /// HIIT configuration (only populated when [type] == 'hiit').
  final int? hiitSets;
  final int? hiitWorkSeconds;
  final int? hiitRestSeconds;
  final int? hiitSetRestSeconds;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'days': days.map((d) => d.toJson()).toList(),
        if (recommendedRoutineKey != null) 'recommendedRoutineKey': recommendedRoutineKey,
        if (hiitSets != null) 'hiitSets': hiitSets,
        if (hiitWorkSeconds != null) 'hiitWorkSeconds': hiitWorkSeconds,
        if (hiitRestSeconds != null) 'hiitRestSeconds': hiitRestSeconds,
        if (hiitSetRestSeconds != null) 'hiitSetRestSeconds': hiitSetRestSeconds,
      };

  factory Routine.fromJson(Map<String, dynamic> json) => Routine(
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
        hiitSets: json['hiitSets'] as int?,
        hiitWorkSeconds: json['hiitWorkSeconds'] as int?,
        hiitRestSeconds: json['hiitRestSeconds'] as int?,
        hiitSetRestSeconds: json['hiitSetRestSeconds'] as int?,
      );

  /// Creates a deep copy with optional field overrides.
  Routine copyWith({
    String? id,
    String? name,
    String? type,
    List<RoutineDay>? days,
    String? recommendedRoutineKey,
    int? hiitSets,
    int? hiitWorkSeconds,
    int? hiitRestSeconds,
    int? hiitSetRestSeconds,
  }) =>
      Routine(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        days: days ?? this.days,
        recommendedRoutineKey: recommendedRoutineKey ?? this.recommendedRoutineKey,
        hiitSets: hiitSets ?? this.hiitSets,
        hiitWorkSeconds: hiitWorkSeconds ?? this.hiitWorkSeconds,
        hiitRestSeconds: hiitRestSeconds ?? this.hiitRestSeconds,
        hiitSetRestSeconds: hiitSetRestSeconds ?? this.hiitSetRestSeconds,
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
        if (hiitSets != null) 'hiitSets': hiitSets,
        if (hiitWorkSeconds != null) 'hiitWorkSeconds': hiitWorkSeconds,
        if (hiitRestSeconds != null) 'hiitRestSeconds': hiitRestSeconds,
        if (hiitSetRestSeconds != null) 'hiitSetRestSeconds': hiitSetRestSeconds,
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
    return Routine(
      id: id,
      name: name,
      type: type,
      days: days
          .cast<Map<String, dynamic>>()
          .map(RoutineDay.fromJson)
          .toList(),
      recommendedRoutineKey: decoded['recommendedRoutineKey'] as String?,
      hiitSets: decoded['hiitSets'] as int?,
      hiitWorkSeconds: decoded['hiitWorkSeconds'] as int?,
      hiitRestSeconds: decoded['hiitRestSeconds'] as int?,
      hiitSetRestSeconds: decoded['hiitSetRestSeconds'] as int?,
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
