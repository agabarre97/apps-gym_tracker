import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

import 'package:gym_tracker/domain/entities/routine.dart';

/// Lets the user choose a routine before starting a workout.
class RoutinePickerScreen extends StatelessWidget {
  const RoutinePickerScreen({
    super.key,
    required this.routines,
    required this.onRoutineSelected,
  });

  final List<Routine> routines;
  final void Function(Routine routine) onRoutineSelected;

  IconData _iconForType(String type) {
    switch (type) {
      case 'musculacion':
        return Icons.fitness_center;
      case 'abdominales':
        return Icons.self_improvement;
      case 'pliometricos':
        return Icons.directions_run;
      case 'movilidad':
        return Icons.accessibility_new;
      case 'hiit':
        return Icons.timer;
      default:
        return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.workoutPickRoutine)),
      body: routines.isEmpty
          ? Center(
              child: Text(
                l10n.workoutNoRoutines,
                style: const TextStyle(color: Colors.white54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: routines.length,
              itemBuilder: (context, index) {
                final routine = routines[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(_iconForType(routine.type),
                        color: Colors.white70),
                    title: Text(routine.name),
                    subtitle: routine.days.isNotEmpty
                        ? Text(
                            l10n.routineDaysCount('${routine.days.length}'),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white38),
                          )
                        : null,
                    trailing: const Icon(Icons.chevron_right,
                        color: Colors.white38),
                    onTap: () => onRoutineSelected(routine),
                  ),
                );
              },
            ),
    );
  }
}
