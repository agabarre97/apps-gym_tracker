import 'dart:convert';

import 'package:flutter/services.dart';

/// Detailed information about a mobility exercise (instructions, tips, etc.).
class MobilityExerciseInfo {
  const MobilityExerciseInfo({
    required this.instructions,
    required this.tips,
    required this.modifications,
    required this.benefits,
  });

  /// Step-by-step instructions for performing the exercise.
  final List<String> instructions;

  /// Helpful tips for better form or execution.
  final List<String> tips;

  /// Easier alternatives or adaptations.
  final List<String> modifications;

  /// Muscle groups or body areas targeted.
  final List<String> benefits;

  factory MobilityExerciseInfo.fromJson(Map<String, dynamic> json) =>
      MobilityExerciseInfo(
        instructions: (json['instructions'] as List).cast<String>(),
        tips: (json['tips'] as List).cast<String>(),
        modifications: (json['modifications'] as List).cast<String>(),
        benefits: (json['benefits'] as List).cast<String>(),
      );

  /// Load all exercise info entries for a given language code.
  ///
  /// Returns a map from exercise key to its [MobilityExerciseInfo].
  static Future<Map<String, MobilityExerciseInfo>> loadAll(
    String langCode,
  ) async {
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
