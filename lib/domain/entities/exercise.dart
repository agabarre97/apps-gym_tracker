import 'dart:convert';

import 'package:flutter/services.dart';

/// A single exercise loaded from the JSON asset.
class Exercise {
  const Exercise({
    required this.key,
    required this.name,
    required this.description,
    required this.muscleGroups,
    required this.difficulty,
  });

  /// Locale-independent identifier (same in ES and EN JSON files).
  final String key;
  final String name;
  final String description;
  final List<String> muscleGroups;
  final int difficulty;

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        key: json['key'] as String,
        name: json['ejercicio'] as String,
        description: json['descripcion'] as String,
        muscleGroups:
            (json['grupo_muscular'] as List).cast<String>(),
        difficulty: json['dificultad_tecnica'] as int,
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

  /// Loads all exercises from the appropriate locale asset.
  static Future<List<Exercise>> loadFromAsset(String languageCode) async {
    final file = languageCode == 'en'
        ? 'assets/data/exercises_en.json'
        : 'assets/data/exercises_es.json';
    final raw = await rootBundle.loadString(file);
    final list = jsonDecode(raw) as List;
    return list
        .cast<Map<String, dynamic>>()
        .map(Exercise.fromJson)
        .toList();
  }
}
