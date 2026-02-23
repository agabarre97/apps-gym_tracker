import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

/// Screen 4 — weight goal (gain / lose / maintain), target weight, daily kcal.
///
/// When the goal is "maintain", target weight and kcal fields are hidden
/// because they are not relevant.
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final Map<String, dynamic> data;
  final VoidCallback onChanged;

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late final TextEditingController _targetWeightCtrl;
  late final TextEditingController _kcalCtrl;

  @override
  void initState() {
    super.initState();
    _targetWeightCtrl =
        TextEditingController(text: _str(widget.data['targetWeightKg']));
    _kcalCtrl = TextEditingController(text: _str(widget.data['kcalPerDay']));
    widget.data['weightGoal'] ??= 'gain';
  }

  String _str(dynamic v) => v == null ? '' : v.toString();

  bool get _isMaintain => widget.data['weightGoal'] == 'maintain';

  @override
  void dispose() {
    _targetWeightCtrl.dispose();
    _kcalCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_isMaintain) {
      widget.data['targetWeightKg'] = null;
      widget.data['kcalPerDay'] = null;
    } else {
      widget.data['targetWeightKg'] = double.tryParse(_targetWeightCtrl.text);
      widget.data['kcalPerDay'] = int.tryParse(_kcalCtrl.text);
    }
    widget.onChanged();
  }

  String? _validateTargetWeight(String? v) {
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.isEmpty) return l10n.sharedFieldRequired;
    final n = double.tryParse(v);
    if (n == null || n < 30 || n > 300) {
      return l10n.sharedFieldInvalidRange('30', '300');
    }
    return null;
  }

  String? _validateKcal(String? v) {
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.isEmpty) return l10n.sharedFieldRequired;
    if (int.tryParse(v) == null) return l10n.sharedFieldRequired;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final goal = widget.data['weightGoal'] as String;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.goalsTitle,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),

          // Gain / Maintain / Lose toggle
          Text(l10n.goalsWeightObjective,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'gain', label: Text(l10n.sharedGain)),
              ButtonSegment(
                  value: 'maintain', label: Text(l10n.sharedMaintain)),
              ButtonSegment(value: 'lose', label: Text(l10n.sharedLose)),
            ],
            selected: {goal},
            onSelectionChanged: (value) {
              setState(() {
                widget.data['weightGoal'] = value.first;
              });
              _save();
            },
          ),

          // Only show target weight and kcal when NOT maintaining
          if (!_isMaintain) ...[
            const SizedBox(height: 24),
            // Target weight
            TextFormField(
              controller: _targetWeightCtrl,
              decoration: InputDecoration(labelText: l10n.goalsTargetWeight),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: _validateTargetWeight,
              onChanged: (_) => _save(),
            ),
            const SizedBox(height: 16),
            // Kcal per day
            TextFormField(
              controller: _kcalCtrl,
              decoration: InputDecoration(
                labelText: goal == 'gain'
                    ? l10n.goalsKcalToGain
                    : l10n.goalsKcalToLose,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: _validateKcal,
              onChanged: (_) => _save(),
            ),
          ],
        ],
      ),
    );
  }
}
