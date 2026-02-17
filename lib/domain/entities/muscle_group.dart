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
  if (selected.isEmpty) return const [];

  final matchingRaw = <String>{};
  for (final cat in selected) {
    matchingRaw.addAll(muscleGroupMapping[cat]!);
  }
  final filtered = all
      .where((e) => e.muscleGroups.any(matchingRaw.contains))
      .toList();

  int priorityForCategory(Exercise exercise, MuscleGroupCategory category) {
    final categoryKey = category.name;
    final explicitPriority = exercise.muscleCategoryPriority[categoryKey];
    if (explicitPriority != null) return explicitPriority;

    // Backward-compatible fallback for entries without explicit JSON priority:
    // infer from the first matching muscle-group position.
    final rawNames = muscleGroupMapping[category]!;
    for (var index = 0; index < exercise.muscleGroups.length; index++) {
      if (rawNames.contains(exercise.muscleGroups[index])) {
        return index + 1;
      }
    }
    return 999;
  }

  filtered.sort((a, b) {
    final aBest =
        selected.map((cat) => priorityForCategory(a, cat)).reduce((x, y) => x < y ? x : y);
    final bBest =
        selected.map((cat) => priorityForCategory(b, cat)).reduce((x, y) => x < y ? x : y);

    if (aBest != bBest) return aBest.compareTo(bBest);

    if (a.muscleGroups.length != b.muscleGroups.length) {
      return a.muscleGroups.length.compareTo(b.muscleGroups.length);
    }

    return a.name.compareTo(b.name);
  });

  return filtered;
}
