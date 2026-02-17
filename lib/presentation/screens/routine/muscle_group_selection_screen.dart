import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/domain/entities/muscle_group.dart';

/// Icon for each muscle group (presentation-layer concern).
const Map<MuscleGroupCategory, IconData> muscleGroupIcons = {
  MuscleGroupCategory.pectoral: Icons.expand,
  MuscleGroupCategory.espalda: Icons.airline_seat_flat,
  MuscleGroupCategory.hombro: Icons.accessibility_new,
  MuscleGroupCategory.triceps: Icons.back_hand,
  MuscleGroupCategory.biceps: Icons.front_hand,
  MuscleGroupCategory.cuadriceps: Icons.directions_walk,
  MuscleGroupCategory.gluteos: Icons.event_seat,
  MuscleGroupCategory.isquiotibiales: Icons.directions_run,
  MuscleGroupCategory.gemelos: Icons.do_not_step,
  MuscleGroupCategory.abdominales: Icons.self_improvement,
};

/// Screen for selecting which muscle groups to train on a given day.
class MuscleGroupSelectionScreen extends StatefulWidget {
  const MuscleGroupSelectionScreen({
    super.key,
    required this.currentDay,
    required this.totalDays,
    required this.onConfirmed,
    required this.onBack,
    this.initialSelection = const [],
  });

  final int currentDay;
  final int totalDays;
  final ValueChanged<List<MuscleGroupCategory>> onConfirmed;
  final VoidCallback onBack;

  /// Pre-selected groups (used when navigating back).
  final List<MuscleGroupCategory> initialSelection;

  @override
  State<MuscleGroupSelectionScreen> createState() =>
      _MuscleGroupSelectionScreenState();
}

class _MuscleGroupSelectionScreenState
    extends State<MuscleGroupSelectionScreen> {
  late final Set<MuscleGroupCategory> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initialSelection};
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final labels = muscleGroupLabels(lang);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.routineDayOf(
          '${widget.currentDay}',
          '${widget.totalDays}',
        )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: widget.currentDay / widget.totalDays,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.routineSelectMuscleGroups,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: MuscleGroupCategory.values.map((cat) {
                  final isSelected = _selected.contains(cat);
                  return FilterChip(
                    avatar: Icon(
                      muscleGroupIcons[cat],
                      size: 18,
                      color: isSelected ? Colors.black : Colors.white70,
                    ),
                    label: Text(labels[cat]!),
                    selected: isSelected,
                    selectedColor: Colors.white,
                    checkmarkColor: Colors.black,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                    backgroundColor: Colors.white12,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selected.add(cat);
                        } else {
                          _selected.remove(cat);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _selected.isNotEmpty
                      ? () => widget.onConfirmed(_selected.toList())
                      : null,
                  child: Text(l10n.sharedNext),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
