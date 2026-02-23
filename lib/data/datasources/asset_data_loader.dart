import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/hiit_exercise.dart';
import 'package:gym_tracker/domain/entities/mobility_exercise_info.dart';
import 'package:gym_tracker/domain/entities/mobility_routine.dart';

class ByMuscleCatalog {
  const ByMuscleCatalog({
    required this.categories,
    required this.exercises,
  });

  final List<String> categories;
  final List<Exercise> exercises;
}

/// Centralized loader for JSON data stored in Flutter assets.
///
/// This keeps the domain entities free of `package:flutter/services.dart`
/// imports (`rootBundle`), preserving domain purity.
abstract final class AssetDataLoader {
  static const String _byMuscleBasePath = 'assets/data/musclewiki/by_muscle';

  /// Loads `by_muscle` categories + exercises with de-dup by exercise key.
  static Future<ByMuscleCatalog> loadByMuscleCatalog(
      String languageCode) async {
    final categoryNames = await _loadByMuscleCategoryIndex();
    final exercisesByKey = <String, Exercise>{};

    for (final category in categoryNames) {
      final file = '$_byMuscleBasePath/$category.json';
      final raw = await rootBundle.loadString(file);
      final decoded = jsonDecode(raw);

      List<dynamic> list;
      if (decoded is Map<String, dynamic> && decoded.containsKey('exercises')) {
        list = decoded['exercises'] as List<dynamic>;
      } else if (decoded is List) {
        list = decoded;
      } else {
        continue;
      }

      for (final item in list.cast<Map<String, dynamic>>()) {
        final parsed = Exercise.fromJson(item);
        final existing = exercisesByKey[parsed.key];
        if (existing == null) {
          exercisesByKey[parsed.key] = parsed.copyWith(
            name: parsed.localizedNameFor(languageCode),
            description: parsed.localizedDescriptionFor(languageCode),
            categoryKeys: [category],
          );
          continue;
        }

        final mergedCategories = {
          ...existing.categoryKeys,
          category,
        }.toList()
          ..sort();
        final mergedMuscles = {
          ...existing.resolvedMusclesInvolved,
          ...parsed.resolvedMusclesInvolved,
        }.toList();

        exercisesByKey[parsed.key] = existing.copyWith(
          categoryKeys: mergedCategories,
          musclesInvolved: mergedMuscles,
          muscleGroups: mergedMuscles,
          name: existing.localizedNameFor(languageCode),
          description: existing.localizedDescriptionFor(languageCode),
        );
      }
    }

    final exercises = exercisesByKey.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return ByMuscleCatalog(
      categories: categoryNames,
      exercises: exercises,
    );
  }

  static Future<List<String>> _loadByMuscleCategoryIndex() async {
    const indexFile = '$_byMuscleBasePath/index.json';
    final raw = await rootBundle.loadString(indexFile);
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded.whereType<String>().toList()..sort();
    }
    if (decoded is Map<String, dynamic>) {
      final categories =
          (decoded['categories'] as List?)?.whereType<String>().toList() ??
              const <String>[];
      categories.sort();
      return categories;
    }
    return const [];
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
