import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/entities/muscle_group.dart';
import 'package:gym_tracker/presentation/screens/routine/exercise_detail_sheet.dart';

/// Screen for selecting exercises for a given day.
///
/// Selection is tracked by exercise **key** (locale-independent).
/// Tapping the check icon toggles selection; tapping the card body opens detail.
class ExerciseSelectionScreen extends StatefulWidget {
  const ExerciseSelectionScreen({
    super.key,
    required this.currentDay,
    required this.totalDays,
    required this.selectedCategories,
    required this.allExercises,
    required this.onConfirmed,
    required this.onBack,
    this.initialSelectedKeys = const [],
  });

  final int currentDay;
  final int totalDays;
  final List<MuscleGroupCategory> selectedCategories;
  final List<Exercise> allExercises;

  /// Returns a list of **exercise keys**.
  final ValueChanged<List<String>> onConfirmed;
  final VoidCallback onBack;

  /// Pre-selected exercise keys (used when navigating back or editing).
  final List<String> initialSelectedKeys;

  @override
  State<ExerciseSelectionScreen> createState() =>
      _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  late final Set<String> _selectedKeys;
  late final List<Exercise> _filteredExercises;

  @override
  void initState() {
    super.initState();
    _selectedKeys = {...widget.initialSelectedKeys};
    _filteredExercises = exercisesForCategories(
      widget.selectedCategories,
      widget.allExercises,
    );
  }

  void _toggleExercise(String key) {
    setState(() {
      if (_selectedKeys.contains(key)) {
        _selectedKeys.remove(key);
      } else {
        _selectedKeys.add(key);
      }
    });
  }

  void _showDetail(Exercise exercise) {
    final isSelected = _selectedKeys.contains(exercise.key);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2C2C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ExerciseDetailSheet(
        exercise: exercise,
        isSelected: isSelected,
        onToggle: () {
          _toggleExercise(exercise.key);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
          LinearProgressIndicator(
            value: widget.currentDay / widget.totalDays,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.routineSelectExercises,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  l10n.routineSelected('${_selectedKeys.length}'),
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _filteredExercises.length,
              itemBuilder: (context, index) {
                final exercise = _filteredExercises[index];
                final isSelected = _selectedKeys.contains(exercise.key);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Card(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.15)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isSelected
                          ? const BorderSide(color: Colors.white38)
                          : BorderSide.none,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showDetail(exercise),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            // Checkbox — toggles selection directly
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _toggleExercise(exercise.key),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? Colors.greenAccent
                                      : Colors.white38,
                                ),
                              ),
                            ),
                            // Exercise info — shows detail
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exercise.name,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    exercise.muscleGroups.join(' · '),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Difficulty dots
                            _DifficultyIndicator(
                                difficulty: exercise.difficulty),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Bottom bar
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _selectedKeys.isNotEmpty
                      ? () => widget.onConfirmed(_selectedKeys.toList())
                      : null,
                  child: Text(l10n.sharedConfirm),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyIndicator extends StatelessWidget {
  const _DifficultyIndicator({required this.difficulty});

  final int difficulty;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(10, (i) {
        return Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < difficulty ? Colors.greenAccent : Colors.white12,
          ),
        );
      }),
    );
  }
}
