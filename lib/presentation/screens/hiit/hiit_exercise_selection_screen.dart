import 'package:flutter/material.dart';
import 'package:gym_tracker/domain/entities/hiit_exercise.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/theme/app_theme.dart';

/// Maximum recommended HIIT exercises before a warning is shown.
const int hiitMaxRecommendedExercises = 6;

/// Screen for selecting HIIT exercises.
///
/// Shows all available HIIT exercises with toggle selection.
/// Displays a warning banner when more than [hiitMaxRecommendedExercises]
/// exercises are selected.
class HiitExerciseSelectionScreen extends StatefulWidget {
  const HiitExerciseSelectionScreen({
    super.key,
    required this.exercises,
    required this.onConfirmed,
    required this.onBack,
    this.initialSelectedKeys = const [],
  });

  final List<HiitExercise> exercises;
  final ValueChanged<List<String>> onConfirmed;
  final VoidCallback onBack;
  final List<String> initialSelectedKeys;

  @override
  State<HiitExerciseSelectionScreen> createState() =>
      _HiitExerciseSelectionScreenState();
}

class _HiitExerciseSelectionScreenState
    extends State<HiitExerciseSelectionScreen> {
  late final Set<String> _selectedKeys;

  @override
  void initState() {
    super.initState();
    _selectedKeys = {...widget.initialSelectedKeys};
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showWarning = _selectedKeys.length > hiitMaxRecommendedExercises;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hiitSelectExercises),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: Column(
        children: [
          // Warning banner
          if (showWarning)
            MaterialBanner(
              backgroundColor: AppColors.warning.withAlpha(30),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              content: Text(
                l10n.hiitWarningTooMany,
                style: const TextStyle(color: AppColors.warning),
              ),
              leading:
                  const Icon(Icons.warning_amber, color: AppColors.warning),
              actions: const [SizedBox.shrink()],
            ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.hiitSelectExercises,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  l10n.routineSelected('${_selectedKeys.length}'),
                  style: TextStyle(color: context.textSecondary),
                ),
              ],
            ),
          ),

          // Exercise list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: widget.exercises.length,
              itemBuilder: (context, index) {
                final exercise = widget.exercises[index];
                final isSelected = _selectedKeys.contains(exercise.key);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Card(
                    color: isSelected ? context.selectionHighlight : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isSelected
                          ? BorderSide(color: context.textSubtle)
                          : BorderSide.none,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _toggleExercise(exercise.key),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? AppColors.success
                                  : context.textSubtle,
                            ),
                            const SizedBox(width: 12),
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
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    exercise.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.textSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Confirm button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
