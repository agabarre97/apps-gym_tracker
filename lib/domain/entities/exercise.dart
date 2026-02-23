import 'dart:convert';

/// A single exercise loaded from the JSON asset.
class Exercise {
  const Exercise({
    required this.key,
    required this.name,
    required this.description,
    required this.muscleGroups,
    required this.difficulty,
    this.muscleImage,
    this.muscleCategoryPriority = const {},
    this.localizedName = const {},
    this.localizedShortDescription = const {},
    this.musclesInvolved = const [],
    this.musclesConfidence = 'medium',
    this.categoryKeys = const [],
  });

  /// Locale-independent identifier (same in ES and EN JSON files).
  final String key;
  final String name;
  final String description;
  final List<String> muscleGroups;
  final int difficulty;
  final String? muscleImage;
  final Map<String, int> muscleCategoryPriority;
  final Map<String, String> localizedName;
  final Map<String, String> localizedShortDescription;
  final List<String> musclesInvolved;
  final String musclesConfidence;
  final List<String> categoryKeys;

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final localizedName =
        _readLocaleMap(json['name'], fallback: json['ejercicio'] as String?);
    final localizedDescription = _readLocaleMap(
      json['short_description'],
      fallback: json['descripcion'] as String?,
    );
    final parsedMusclesInvolved =
        (json['muscles_involved'] as List?)?.whereType<String>().toList() ??
            const <String>[];
    final parsedMuscleGroups =
        (json['grupo_muscular'] as List?)?.whereType<String>().toList() ??
            parsedMusclesInvolved;
    final musclesConfidence = json['muscles_confidence'] as String? ?? 'medium';

    return Exercise(
      key: json['key'] as String,
      name: localizedName['es'] ??
          localizedName['en'] ??
          (json['ejercicio'] as String? ?? json['key'] as String),
      description: localizedDescription['es'] ??
          localizedDescription['en'] ??
          (json['descripcion'] as String? ?? ''),
      muscleGroups: parsedMuscleGroups,
      difficulty: _parseDifficulty(json, musclesConfidence),
      muscleImage: json['muscle_image'] as String?,
      muscleCategoryPriority:
          ((json['muscle_category_priority'] as Map<String, dynamic>?) ??
                  const {})
              .map((key, value) => MapEntry(key, value as int)),
      localizedName: localizedName,
      localizedShortDescription: localizedDescription,
      musclesInvolved: parsedMusclesInvolved,
      musclesConfidence: musclesConfidence,
      categoryKeys:
          (json['category_keys'] as List?)?.whereType<String>().toList() ??
              const <String>[],
    );
  }

  Exercise copyWith({
    String? key,
    String? name,
    String? description,
    List<String>? muscleGroups,
    int? difficulty,
    String? muscleImage,
    Map<String, int>? muscleCategoryPriority,
    Map<String, String>? localizedName,
    Map<String, String>? localizedShortDescription,
    List<String>? musclesInvolved,
    String? musclesConfidence,
    List<String>? categoryKeys,
  }) {
    return Exercise(
      key: key ?? this.key,
      name: name ?? this.name,
      description: description ?? this.description,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      difficulty: difficulty ?? this.difficulty,
      muscleImage: muscleImage ?? this.muscleImage,
      muscleCategoryPriority:
          muscleCategoryPriority ?? this.muscleCategoryPriority,
      localizedName: localizedName ?? this.localizedName,
      localizedShortDescription:
          localizedShortDescription ?? this.localizedShortDescription,
      musclesInvolved: musclesInvolved ?? this.musclesInvolved,
      musclesConfidence: musclesConfidence ?? this.musclesConfidence,
      categoryKeys: categoryKeys ?? this.categoryKeys,
    );
  }

  String localizedNameFor(String languageCode) =>
      localizedName[languageCode] ?? name;

  String localizedDescriptionFor(String languageCode) =>
      localizedShortDescription[languageCode] ?? description;

  List<String> get resolvedMusclesInvolved =>
      musclesInvolved.isNotEmpty ? musclesInvolved : muscleGroups;

  List<String> get resolvedCategoryKeys {
    if (categoryKeys.isNotEmpty) return categoryKeys;
    // Map muscle groups to category keys safely
    final mapped = <String>{};
    for (final group in muscleGroups) {
      final key = _mapMuscleGroupToCategoryKey(group);
      if (key != null) mapped.add(key);
    }
    if (mapped.isNotEmpty) return mapped.toList();
    return muscleGroups
        .map((group) => group.toLowerCase().replaceAll(' ', '-'))
        .toSet()
        .toList();
  }

  static String? _mapMuscleGroupToCategoryKey(String group) {
    final g = group.toLowerCase();
    if (g.contains('pectoral')) return 'chest';
    if (g.contains('hombro') || g.contains('deltoide')) {
      if (g.contains('posterior')) return 'rear-shoulders';
      return 'front-shoulders'; // default shoulder to front
    }
    if (g.contains('tríceps') || g.contains('triceps')) return 'triceps';
    if (g.contains('bíceps') || g.contains('biceps')) return 'biceps';
    if (g.contains('antebrazo')) return 'forearms';
    if (g.contains('dorsal') || g.contains('espalda')) return 'lats';
    if (g.contains('cuádriceps') || g.contains('cuadriceps')) return 'quads';
    if (g.contains('isquio') || g.contains('femoral')) return 'hamstrings';
    if (g.contains('glúteo') || g.contains('gluteo')) return 'glutes';
    return null;
  }

  /// Resolves an exercise key to its localized display name.
  ///
  /// Falls back to the raw [key] if no match is found.
  static String nameForKey(List<Exercise> allExercises, String key) {
    for (final e in allExercises) {
      if (e.key == key) return e.name;
    }
    return key;
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'name':
            localizedName.isNotEmpty ? localizedName : {'es': name, 'en': name},
        'short_description': localizedShortDescription.isNotEmpty
            ? localizedShortDescription
            : {'es': description, 'en': description},
        'grupo_muscular': muscleGroups,
        'muscle_image': muscleImage,
        'muscle_category_priority': muscleCategoryPriority,
        'muscles_involved': musclesInvolved,
        'muscles_confidence': musclesConfidence,
        'category_keys': categoryKeys,
      };

  static String listToJsonString(List<Exercise> exercises) =>
      jsonEncode(exercises.map((exercise) => exercise.toJson()).toList());

  static List<Exercise> listFromJsonString(String jsonString) {
    final raw = jsonDecode(jsonString);
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(Exercise.fromJson)
        .toList();
  }
}

Map<String, String> _readLocaleMap(
  Object? raw, {
  required String? fallback,
}) {
  if (raw is Map<String, dynamic>) {
    return raw.map(
      (key, value) => MapEntry(key, (value ?? '').toString()),
    );
  }
  if (raw is String && raw.isNotEmpty) {
    return {'es': raw, 'en': raw};
  }
  if (fallback != null && fallback.isNotEmpty) {
    return {'es': fallback, 'en': fallback};
  }
  return const {};
}

int _parseDifficulty(Map<String, dynamic> json, String musclesConfidence) {
  final oldDifficulty = json['dificultad_tecnica'];
  if (oldDifficulty is int) {
    return oldDifficulty.clamp(1, 10);
  }
  switch (musclesConfidence.toLowerCase()) {
    case 'low':
      return 1;
    case 'high':
      return 3;
    case 'medium':
    default:
      return 2;
  }
}
