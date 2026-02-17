/// A single exercise loaded from the JSON asset.
class Exercise {
  const Exercise({
    required this.key,
    required this.name,
    required this.description,
    required this.muscleGroups,
    required this.difficulty,
    this.muscleImage,
  });

  /// Locale-independent identifier (same in ES and EN JSON files).
  final String key;
  final String name;
  final String description;
  final List<String> muscleGroups;
  final int difficulty;
  final String? muscleImage;

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        key: json['key'] as String,
        name: json['ejercicio'] as String,
        description: json['descripcion'] as String,
        muscleGroups:
            (json['grupo_muscular'] as List).cast<String>(),
        difficulty: json['dificultad_tecnica'] as int,
        muscleImage: json['muscle_image'] as String?,
      );

  /// Resolves an exercise key to its localized display name.
  ///
  /// Falls back to the raw [key] if no match is found.
  static String nameForKey(List<Exercise> allExercises, String key) {
    for (final e in allExercises) {
      if (e.key == key) return e.name;
    }
    return key;
  }
}
