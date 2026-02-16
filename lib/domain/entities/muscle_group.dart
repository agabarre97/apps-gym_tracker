import 'package:gym_tracker/domain/entities/exercise.dart';

/// High-level muscle group categories used in the UI.
enum MuscleGroupCategory {
  pectoral,
  espalda,
  hombro,
  triceps,
  biceps,
  cuadriceps,
  gluteos,
  isquiotibiales,
  gemelos,
  abdominales,
}

/// Maps each category to the raw JSON muscle-group strings it covers.
const Map<MuscleGroupCategory, List<String>> muscleGroupMapping = {
  MuscleGroupCategory.pectoral: [
    'Pectoral',
    'Pectoral superior',
    'Pectoral inferior',
    'Pectoral mayor',
  ],
  MuscleGroupCategory.espalda: [
    'Dorsal ancho',
    'Romboides',
    'Trapecio medio',
    'Erectores espinales',
    'Deltoide posterior',
    'Serrato anterior',
  ],
  MuscleGroupCategory.hombro: [
    'Deltoide anterior',
    'Deltoide medio',
  ],
  MuscleGroupCategory.triceps: [
    'Tríceps',
    'Tríceps (porción larga)',
  ],
  MuscleGroupCategory.biceps: [
    'Bíceps',
    'Bíceps braquial',
  ],
  MuscleGroupCategory.cuadriceps: [
    'Cuádriceps',
  ],
  MuscleGroupCategory.gluteos: [
    'Glúteos',
  ],
  MuscleGroupCategory.isquiotibiales: [
    'Isquiotibiales',
  ],
  MuscleGroupCategory.gemelos: [
    'Gemelos',
    'Sóleo',
  ],
  MuscleGroupCategory.abdominales: [
    'Abdominales',
    'Recto abdominal',
    'Recto abdominal inferior',
    'Core profundo',
    'Oblicuos',
  ],
};

/// Display names for each category (Spanish — default).
const Map<MuscleGroupCategory, String> muscleGroupLabelEs = {
  MuscleGroupCategory.pectoral: 'Pectoral',
  MuscleGroupCategory.espalda: 'Espalda',
  MuscleGroupCategory.hombro: 'Hombro',
  MuscleGroupCategory.triceps: 'Tríceps',
  MuscleGroupCategory.biceps: 'Bíceps',
  MuscleGroupCategory.cuadriceps: 'Cuádriceps',
  MuscleGroupCategory.gluteos: 'Glúteos',
  MuscleGroupCategory.isquiotibiales: 'Isquiotibiales',
  MuscleGroupCategory.gemelos: 'Gemelos',
  MuscleGroupCategory.abdominales: 'Abdominales',
};

/// Display names for each category (English).
const Map<MuscleGroupCategory, String> muscleGroupLabelEn = {
  MuscleGroupCategory.pectoral: 'Chest',
  MuscleGroupCategory.espalda: 'Back',
  MuscleGroupCategory.hombro: 'Shoulders',
  MuscleGroupCategory.triceps: 'Triceps',
  MuscleGroupCategory.biceps: 'Biceps',
  MuscleGroupCategory.cuadriceps: 'Quadriceps',
  MuscleGroupCategory.gluteos: 'Glutes',
  MuscleGroupCategory.isquiotibiales: 'Hamstrings',
  MuscleGroupCategory.gemelos: 'Calves',
  MuscleGroupCategory.abdominales: 'Abs',
};

/// Returns the localised label map for a given language code.
Map<MuscleGroupCategory, String> muscleGroupLabels(String languageCode) =>
    languageCode == 'en' ? muscleGroupLabelEn : muscleGroupLabelEs;

/// Filters exercises that have at least one muscle group matching
/// any of the selected categories.
List<Exercise> exercisesForCategories(
  List<MuscleGroupCategory> selected,
  List<Exercise> all,
) {
  final matchingRaw = <String>{};
  for (final cat in selected) {
    matchingRaw.addAll(muscleGroupMapping[cat]!);
  }
  return all
      .where((e) => e.muscleGroups.any(matchingRaw.contains))
      .toList();
}
