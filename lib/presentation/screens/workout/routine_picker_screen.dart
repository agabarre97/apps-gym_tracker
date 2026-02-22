import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/presentation/components/routine_type_helper.dart';
import 'package:gym_tracker/presentation/theme/app_theme.dart';

/// Lets the user choose a routine before starting a workout.
class RoutinePickerScreen extends StatelessWidget {
  const RoutinePickerScreen({
    super.key,
    required this.routines,
    required this.onRoutineSelected,
  });

  final List<Routine> routines;
  final void Function(Routine routine) onRoutineSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.workoutPickRoutine)),
      body: routines.isEmpty
          ? Center(
              child: Text(
                l10n.workoutNoRoutines,
                style: TextStyle(color: context.textSecondary),
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
                    leading: Icon(RoutineTypeHelper.iconFor(routine.type),
                        color: context.textSecondary),
                    title: Text(routine.name),
                    subtitle: routine.days.isNotEmpty
                        ? Text(
                            l10n.routineDaysCount('${routine.days.length}'),
                            style: TextStyle(
                                fontSize: 12, color: context.textSubtle),
                          )
                        : null,
                    trailing:
                        Icon(Icons.chevron_right, color: context.textSubtle),
                    onTap: () => onRoutineSelected(routine),
                  ),
                );
              },
            ),
    );
  }
}
