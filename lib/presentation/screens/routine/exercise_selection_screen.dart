import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/presentation/screens/routine/by_muscle_category_labels.dart';
import 'package:gym_tracker/presentation/screens/routine/exercise_detail_sheet.dart';

/// Combined output of the unified category+exercise selection screen.
class ExerciseSelectionResult {
  const ExerciseSelectionResult({
    required this.selectedCategories,
    required this.selectedExerciseKeys,
  });

  final List<String> selectedCategories;
  final List<String> selectedExerciseKeys;
}

/// Screen for selecting exercises for a given day.
///
/// Selection is tracked by exercise **key** (locale-independent).
/// Tapping the check icon toggles selection; tapping the card body opens detail.
class ExerciseSelectionScreen extends StatefulWidget {
  const ExerciseSelectionScreen({
    super.key,
    required this.currentDay,
    required this.totalDays,
    required this.allExercises,
    required this.availableCategories,
    required this.onConfirmed,
    required this.onBack,
    this.showDayProgress = true,
    this.titleOverride,
    this.initialSelectedCategories = const [],
    this.initialSelectedKeys = const [],
  });

  final int currentDay;
  final int totalDays;
  final List<Exercise> allExercises;
  final List<String> availableCategories;

  /// Returns categories + exercise keys in a single result.
  final ValueChanged<ExerciseSelectionResult> onConfirmed;
  final VoidCallback onBack;
  final bool showDayProgress;
  final String? titleOverride;
  final List<String> initialSelectedCategories;

  /// Pre-selected exercise keys (used when navigating back or editing).
  final List<String> initialSelectedKeys;

  @override
  State<ExerciseSelectionScreen> createState() =>
      _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  late final Set<String> _selectedCategories;
  late final Set<String> _selectedKeys;
  late List<Exercise> _filteredExercises;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<String> get _displayCategories {
    final incoming = widget.availableCategories.toSet();
    final ordered =
        byMuscleCategoryOrder.where(incoming.contains).toList(growable: false);
    if (ordered.isNotEmpty) return ordered;
    return byMuscleCategoryOrder;
  }

  @override
  void initState() {
    super.initState();
    _selectedCategories = {...widget.initialSelectedCategories};
    _selectedKeys = {...widget.initialSelectedKeys};
    _recomputeFilteredExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ExerciseSelectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final exercisesChanged = oldWidget.allExercises != widget.allExercises;
    final categoriesChanged =
        oldWidget.availableCategories != widget.availableCategories;
    if (exercisesChanged || categoriesChanged) {
      setState(_recomputeFilteredExercises);
    }
  }

  void _recomputeFilteredExercises() {
    _filteredExercises = List<Exercise>.from(widget.allExercises);
    if (_selectedCategories.isNotEmpty) {
      _filteredExercises = _filteredExercises.where((exercise) {
        return exercise.resolvedCategoryKeys.any(_selectedCategories.contains);
      }).toList();
    }

    _filteredExercises.sort((a, b) {
      if (_selectedCategories.isNotEmpty) {
        final aPriority = _bestPriorityFor(a, _selectedCategories);
        final bPriority = _bestPriorityFor(b, _selectedCategories);
        if (aPriority != bPriority) {
          return aPriority.compareTo(bPriority);
        }
      }
      return a.name.compareTo(b.name);
    });
  }

  /// Exercises filtered by both category and search query.
  List<Exercise> get _displayedExercises {
    if (_searchQuery.isEmpty) return _filteredExercises;
    final query = _searchQuery.toLowerCase();
    return _filteredExercises
        .where((e) => e.name.toLowerCase().contains(query))
        .toList();
  }

  void _toggleCategory(String category, bool selected) {
    setState(() {
      if (selected) {
        _selectedCategories.add(category);
      } else {
        _selectedCategories.remove(category);
      }
      _recomputeFilteredExercises();
    });
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
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.titleOverride ??
              l10n.routineDayOf(
                '${widget.currentDay}',
                '${widget.totalDays}',
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: Column(
        children: [
          if (widget.showDayProgress) ...[
            LinearProgressIndicator(
              value: widget.currentDay / widget.totalDays,
            ),
            const SizedBox(height: 8),
          ],
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _displayCategories.map((category) {
                final isSelected = _selectedCategories.contains(category);
                return FilterChip(
                  label: Text(categoryLabelForLocale(category, lang)),
                  selected: isSelected,
                  selectedColor: Colors.white,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                  ),
                  backgroundColor: Colors.white12,
                  onSelected: (selected) => _toggleCategory(category, selected),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.exerciseSearchHint,
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _displayedExercises.length,
              itemBuilder: (context, index) {
                final exercise = _displayedExercises[index];
                final isSelected = _selectedKeys.contains(exercise.key);
                final localizedDescription =
                    exercise.localizedDescriptionFor(lang);

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
                                    exercise.localizedNameFor(lang),
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    localizedDescription,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // TODO(difficulty): re-enable once difficulty data is reliable
                            // _DifficultyIndicator(difficulty: exercise.difficulty),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _selectedKeys.isNotEmpty
                      ? () => widget.onConfirmed(
                            ExerciseSelectionResult(
                              selectedCategories: _selectedCategories.toList(),
                              selectedExerciseKeys: _selectedKeys.toList(),
                            ),
                          )
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
      children: List.generate(3, (i) {
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

int _bestPriorityFor(Exercise exercise, Set<String> selectedCategories) {
  var best = 999;
  for (final category in selectedCategories) {
    final priority = exercise.muscleCategoryPriority[category] ?? 999;
    if (priority < best) {
      best = priority;
    }
  }
  return best;
}
