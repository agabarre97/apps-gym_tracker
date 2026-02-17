import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';

/// Bottom sheet showing full details of an exercise with add/remove toggle.
class ExerciseDetailSheet extends StatelessWidget {
  const ExerciseDetailSheet({
    super.key,
    required this.exercise,
    required this.isSelected,
    required this.onToggle,
  });

  final Exercise exercise;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            exercise.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            exercise.description,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),

          // Muscle groups
          Text(
            l10n.routineMuscles,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: exercise.muscleGroups
                .map((g) => Chip(
                      label: Text(g, style: const TextStyle(fontSize: 12)),
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
          if (exercise.muscleImage != null) ...[
            const SizedBox(height: 16),
            Center(
              child: Image.asset(
                exercise.muscleImage!,
                height: 160,
                fit: BoxFit.contain,
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Difficulty
          Row(
            children: [
              Text(
                '${l10n.routineDifficulty}: ',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              ...List.generate(10, (i) => Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < exercise.difficulty
                          ? Colors.greenAccent
                          : Colors.white12,
                    ),
                  )),
              const SizedBox(width: 8),
              Text(
                '${exercise.difficulty}/10',
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Add / Remove button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: isSelected
                ? OutlinedButton.icon(
                    icon: const Icon(Icons.remove_circle_outline),
                    label: Text(l10n.routineRemove),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onToggle,
                  )
                : FilledButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(l10n.routineAdd),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onToggle,
                  ),
          ),
        ],
      ),
    );
  }
}
