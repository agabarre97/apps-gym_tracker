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
  });

  final String id;
  final String name;

  /// One of: 'musculacion', 'abdominales', 'pliometricos', 'movilidad', 'hiit'.
  final String type;

  final List<RoutineDay> days;

  /// If set, this routine is a predefined mobility routine (e.g. feet_ankles_2).
  final String? recommendedRoutineKey;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'days': days.map((d) => d.toJson()).toList(),
        if (recommendedRoutineKey != null) 'recommendedRoutineKey': recommendedRoutineKey,
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
      );

  /// Creates a deep copy with optional field overrides.
  Routine copyWith({
    String? id,
    String? name,
    String? type,
    List<RoutineDay>? days,
    String? recommendedRoutineKey,
  }) =>
      Routine(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        days: days ?? this.days,
        recommendedRoutineKey: recommendedRoutineKey ?? this.recommendedRoutineKey,
      );

  static List<Routine> listFromJsonString(String source) =>
      (jsonDecode(source) as List)
          .cast<Map<String, dynamic>>()
          .map(Routine.fromJson)
          .toList();

  static String listToJsonString(List<Routine> list) =>
      jsonEncode(list.map((r) => r.toJson()).toList());
}
