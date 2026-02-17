import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/hiit_exercise.dart';
import 'package:gym_tracker/domain/entities/mobility_exercise_info.dart';
import 'package:gym_tracker/domain/entities/mobility_routine.dart';

/// Centralized loader for JSON data stored in Flutter assets.
///
/// This keeps the domain entities free of `package:flutter/services.dart`
/// imports (`rootBundle`), preserving domain purity.
abstract final class AssetDataLoader {
  /// Loads all exercises for the given [languageCode] (`'es'` or `'en'`).
  static Future<List<Exercise>> loadExercises(String languageCode) async {
    final file = languageCode == 'en'
        ? 'assets/data/exercises_en.json'
        : 'assets/data/exercises_es.json';
    final raw = await rootBundle.loadString(file);
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>().map(Exercise.fromJson).toList();
  }

  /// Loads all HIIT exercises for the given [languageCode].
  static Future<List<HiitExercise>> loadHiitExercises(
      String languageCode) async {
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

  /// Loads a mobility routine asset by its key (e.g. `'feet_ankles_2'`).
  static Future<MobilityRoutine> loadMobilityRoutine(String assetKey) async {
    final raw = await rootBundle.loadString(
      'assets/data/mobility_routines/$assetKey.json',
    );
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return MobilityRoutine.fromJson(map);
  }

  /// Loads all mobility exercise info for the given language code.
  ///
  /// Returns a map from exercise key to its [MobilityExerciseInfo].
  static Future<Map<String, MobilityExerciseInfo>> loadMobilityExerciseInfo(
      String langCode) async {
    final raw = await rootBundle.loadString(
      'assets/data/mobility_exercises_info/$langCode.json',
    );
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map(
      (key, value) => MapEntry(
        key,
        MobilityExerciseInfo.fromJson(value as Map<String, dynamic>),
      ),
    );
  }
}
