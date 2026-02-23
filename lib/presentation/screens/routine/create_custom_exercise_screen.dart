import 'package:flutter/material.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/ports/custom_exercise_port.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/components/interactive_muscle_selector.dart';
import 'package:gym_tracker/presentation/screens/routine/by_muscle_category_labels.dart';
import 'package:uuid/uuid.dart';

class CreateCustomExerciseScreen extends StatefulWidget {
  const CreateCustomExerciseScreen({
    super.key,
    required this.customExercisePort,
    required this.allExercises,
  });

  final CustomExercisePort customExercisePort;
  final List<Exercise> allExercises;

  @override
  State<CreateCustomExerciseScreen> createState() =>
      _CreateCustomExerciseScreenState();
}

class _CreateCustomExerciseScreenState
    extends State<CreateCustomExerciseScreen> {
  static const _uuid = Uuid();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Set<String> _selectedMuscles = <String>{};
  bool _saving = false;
  bool _showMuscleValidation = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMuscles.isEmpty) {
      setState(() => _showMuscleValidation = true);
      return;
    }
    setState(() {
      _showMuscleValidation = false;
      _saving = true;
    });

    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final key = _buildUniqueKey(name);
    final muscles = _selectedMuscles.toList(growable: false);

    final customExercise = Exercise(
      key: key,
      name: name,
      description: description,
      muscleGroups: muscles,
      difficulty: 2,
      muscleCategoryPriority: {
        for (var i = 0; i < muscles.length; i++) muscles[i]: i + 1,
      },
      localizedName: {'es': name, 'en': name},
      localizedShortDescription: {
        'es': description,
        'en': description,
      },
      musclesInvolved: muscles,
      musclesConfidence: 'high',
      categoryKeys: muscles,
    );

    final existing = await widget.customExercisePort.loadExercises();
    await widget.customExercisePort
        .saveExercises([...existing, customExercise]);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.customExerciseSaved)),
    );
    Navigator.of(context).pop(customExercise);
  }

  String _buildUniqueKey(String name) {
    final normalized = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final base = normalized.isEmpty ? 'custom_exercise' : normalized;
    final alreadyExists =
        widget.allExercises.any((exercise) => exercise.key == base);
    if (!alreadyExists) return base;
    return '${base}_${_uuid.v4().substring(0, 8)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final selectorTitle = lang == 'es'
        ? 'Selecciona los musculos desde este selector. El cuerpo de abajo es solo visual.'
        : 'Select muscles using this selector. The body below is visual only.';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.customExerciseCreateTitle),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.customExerciseName,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.customExerciseNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.customExerciseDescription,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.customExerciseMuscles,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              InteractiveMuscleSelector(
                selectedMuscles: _selectedMuscles.toList(growable: false),
                onChanged: (muscles) => setState(() {
                  _selectedMuscles
                    ..clear()
                    ..addAll(muscles);
                }),
                availableMuscles: byMuscleCategoryOrder,
                frontLabel: l10n.customExerciseFront,
                backLabel: l10n.customExerciseBack,
                manualAddLabel: l10n.customExerciseAddMuscleManual,
                selectorTitle: selectorTitle,
                labelBuilder: (muscle) => categoryLabelForLocale(muscle, lang),
              ),
              if (_showMuscleValidation) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.customExerciseMusclesRequired,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.customExerciseCreatePersonalized),
            ),
          ),
        ),
      ),
    );
  }
}
