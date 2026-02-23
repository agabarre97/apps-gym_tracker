import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/ports/custom_exercise_port.dart';
import 'package:gym_tracker/presentation/screens/routine/by_muscle_category_labels.dart';
import 'package:gym_tracker/presentation/screens/routine/create_custom_exercise_screen.dart';
import 'package:gym_tracker/presentation/screens/routine/exercise_detail_sheet.dart';
import 'package:gym_tracker/presentation/theme/app_theme.dart';

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
    this.customExercisePort,
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
  final CustomExercisePort? customExercisePort;

  @override
  State<ExerciseSelectionScreen> createState() =>
      _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  late final Set<String> _selectedCategories;
  late final Set<String> _selectedKeys;
  final Set<String> _deletedCustomExerciseKeys = <String>{};
  late List<Exercise> _filteredExercises;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Exercise> _customExercisesNewlyCreated = const [];
  List<Exercise> _allCustomExercisesLoaded = const [];
  String? _lastCreatedExerciseKey;

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
    _loadAllCustomExercises();
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
    final customPortChanged =
        oldWidget.customExercisePort != widget.customExercisePort;
    if (customPortChanged) {
      _loadAllCustomExercises();
    }
    if (exercisesChanged || categoriesChanged) {
      setState(_recomputeFilteredExercises);
    }
  }

  Future<void> _loadAllCustomExercises() async {
    final customExercisePort = widget.customExercisePort;
    if (customExercisePort == null) return;
    final loadedCustomExercises = await customExercisePort.loadExercises();
    if (!mounted) return;
    setState(() {
      _allCustomExercisesLoaded = loadedCustomExercises
          .where(
              (exercise) => !_deletedCustomExerciseKeys.contains(exercise.key))
          .toList();
      _recomputeFilteredExercises();
    });
  }

  void _recomputeFilteredExercises() {
    final mergedByKey = <String, Exercise>{
      for (final exercise in widget.allExercises) exercise.key: exercise,
      for (final exercise in _allCustomExercisesLoaded) exercise.key: exercise,
      for (final exercise in _customExercisesNewlyCreated)
        exercise.key: exercise,
    };
    _filteredExercises = mergedByKey.values
        .where((exercise) => !_deletedCustomExerciseKeys.contains(exercise.key))
        .toList(growable: false);
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

  Future<void> _openCreateCustomExercise() async {
    final customExercisePort = widget.customExercisePort;
    if (customExercisePort == null) return;
    final created = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (_) => CreateCustomExerciseScreen(
          customExercisePort: customExercisePort,
          allExercises: [
            ...widget.allExercises,
            ..._allCustomExercisesLoaded,
            ..._customExercisesNewlyCreated,
          ],
        ),
      ),
    );
    if (created == null || !mounted) return;
    setState(() {
      _customExercisesNewlyCreated = [..._customExercisesNewlyCreated, created];
      _allCustomExercisesLoaded = [..._allCustomExercisesLoaded, created];
      _selectedKeys.add(created.key);
      _lastCreatedExerciseKey = created.key;
      _recomputeFilteredExercises();
      _searchQuery = '';
      _searchController.clear();
    });
  }

  /// Exercises filtered by both category and search query.
  List<Exercise> get _displayedExercises {
    final base = _searchQuery.isEmpty
        ? List<Exercise>.from(_filteredExercises)
        : _filteredExercises
            .where((e) =>
                e.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
    final lastCreatedKey = _lastCreatedExerciseKey;
    if (lastCreatedKey == null) return base;
    final createdIndex =
        base.indexWhere((exercise) => exercise.key == lastCreatedKey);
    if (createdIndex <= 0) return base;
    final created = base.removeAt(createdIndex);
    base.insert(0, created);
    return base;
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

  bool _isCustomExercise(Exercise exercise) =>
      _allCustomExercisesLoaded.any((item) => item.key == exercise.key) ||
      _customExercisesNewlyCreated.any((item) => item.key == exercise.key);

  Future<bool?> _confirmDeleteCustomExercise() {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.customExerciseDeleteConfirmTitle),
        content: Text(l10n.customExerciseDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.customExerciseCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.customExerciseDelete),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCustomExercise(Exercise exercise) async {
    setState(() {
      _deletedCustomExerciseKeys.add(exercise.key);
      _customExercisesNewlyCreated = _customExercisesNewlyCreated
          .where((item) => item.key != exercise.key)
          .toList();
      _allCustomExercisesLoaded = _allCustomExercisesLoaded
          .where((item) => item.key != exercise.key)
          .toList();
      _selectedKeys.remove(exercise.key);
      if (_lastCreatedExerciseKey == exercise.key) {
        _lastCreatedExerciseKey = null;
      }
      _recomputeFilteredExercises();
    });
    await widget.customExercisePort?.deleteExercise(exercise.key);
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
                  style: TextStyle(color: context.textSecondary),
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
                hintStyle: TextStyle(color: context.textSubtle),
                prefixIcon: Icon(Icons.search, color: context.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: context.textSecondary),
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
          if (widget.customExercisePort != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _openCreateCustomExercise,
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(l10n.customExerciseCreate),
                ),
              ),
            ),
          Expanded(
            child: _displayedExercises.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.customExerciseNoResults,
                            style: TextStyle(color: context.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          if (widget.customExercisePort != null) ...[
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _openCreateCustomExercise,
                              icon: const Icon(Icons.add),
                              label:
                                  Text(l10n.customExerciseCreatePersonalized),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _displayedExercises.length,
                    itemBuilder: (context, index) {
                      final exercise = _displayedExercises[index];
                      final isCustom = _isCustomExercise(exercise);
                      final isSelected = _selectedKeys.contains(exercise.key);
                      final localizedDescription =
                          exercise.localizedDescriptionFor(lang);
                      final card = Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Card(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.15)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isSelected
                                ? BorderSide(color: context.textSubtle)
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
                                            : context.textSubtle,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: context.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isCustom)
                                    IconButton(
                                      key: ValueKey('delete_${exercise.key}'),
                                      onPressed: () async {
                                        final confirmed =
                                            await _confirmDeleteCustomExercise();
                                        if (confirmed == true) {
                                          await _deleteCustomExercise(exercise);
                                        }
                                      },
                                      icon: const Icon(Icons.delete_outline),
                                      color: context.textSecondary,
                                      tooltip: l10n.customExerciseDelete,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );

                      return card;
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
