import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/domain/entities/muscle_group.dart';
import 'package:gym_tracker/presentation/screens/routine/by_muscle_category_labels.dart';
import 'package:gym_tracker/presentation/theme/app_theme.dart';

/// Lets the user choose which day within the selected routine to train.
class DayPickerScreen extends StatefulWidget {
  const DayPickerScreen({
    super.key,
    required this.routine,
    required this.onDaySelected,
    this.allExercises = const [],
  });

  final Routine routine;
  final List<Exercise> allExercises;

  /// Called with the selected day index (0-based).
  final void Function(int dayIndex) onDaySelected;

  @override
  State<DayPickerScreen> createState() => _DayPickerScreenState();
}

class _DayPickerScreenState extends State<DayPickerScreen> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final labels = muscleGroupLabels(lang);
    final exercisesByKey = {
      for (final exercise in widget.allExercises) exercise.key: exercise,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.workoutPickDay)),
      body: Column(
        children: [
          // Routine name
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              widget.routine.name,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),

          // Day cards
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.routine.days.length,
              itemBuilder: (context, index) {
                final day = widget.routine.days[index];
                final isSelected = _selectedIndex == index;

                // Prefer categories derived from exercise keys so every day
                // can show its real categories even if legacy muscleGroups is empty.
                final exerciseCategoryKeys = <String>{};
                for (final exerciseKey in day.exerciseKeys) {
                  final exercise = exercisesByKey[exerciseKey];
                  if (exercise == null) continue;

                  // Add all valid categories this exercise belongs to
                  for (final key in exercise.resolvedCategoryKeys) {
                    if (byMuscleCategoryOrder.contains(key)) {
                      exerciseCategoryKeys.add(key);
                    }
                  }
                }

                // Backward-compatible fallback for legacy routines.
                final chipLabels = exerciseCategoryKeys.isNotEmpty
                    ? exerciseCategoryKeys
                        .map((key) => categoryLabelForLocale(key, lang))
                        .toList()
                    : day.muscleGroups.map((key) {
                        final cat = MuscleGroupCategory.values.firstWhere(
                          (c) => c.name == key,
                          orElse: () => MuscleGroupCategory.pectoral,
                        );
                        return labels[cat] ?? key;
                      }).toList();

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isSelected
                        ? const BorderSide(color: Colors.greenAccent, width: 2)
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _selectedIndex = index),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.routineDayLabel('${index + 1}'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: chipLabels
                                .map((label) => Chip(
                                      label: Text(label,
                                          style: const TextStyle(fontSize: 11)),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${day.exerciseKeys.length} ${l10n.routineExercises}',
                            style: TextStyle(
                                fontSize: 12, color: context.textSubtle),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Start button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _selectedIndex != null
                      ? () => widget.onDaySelected(_selectedIndex!)
                      : null,
                  child: Text(l10n.workoutStart),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
