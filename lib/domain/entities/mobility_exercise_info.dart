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
}
