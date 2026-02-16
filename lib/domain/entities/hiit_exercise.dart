import 'dart:convert';

import 'package:flutter/services.dart';

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

  /// Loads all HIIT exercises from the appropriate locale asset.
  static Future<List<HiitExercise>> loadFromAsset(String languageCode) async {
    final file = languageCode == 'en'
        ? 'assets/data/hiit_exercises_en.json'
        : 'assets/data/hiit_exercises_es.json';
    final raw = await rootBundle.loadString(file);
    final list = jsonDecode(raw) as List;
    return list
        .cast<Map<String, dynamic>>()
        .map(HiitExercise.fromJson)
        .toList();
  }
}
