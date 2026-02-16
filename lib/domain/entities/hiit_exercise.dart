/// A single HIIT exercise loaded from the JSON asset.
class HiitExercise {
  const HiitExercise({
    required this.key,
    required this.name,
    required this.description,
  });

  /// Locale-independent identifier (same in ES and EN JSON files).
  final String key;
  final String name;
  final String description;

  factory HiitExercise.fromJson(Map<String, dynamic> json) => HiitExercise(
        key: json['key'] as String,
        name: json['ejercicio'] as String,
        description: json['descripcion'] as String,
      );
}
