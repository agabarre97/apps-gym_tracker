import 'package:flutter/material.dart';
import 'package:gym_tracker/domain/entities/hiit_config.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/components/time_wheel_picker.dart';
import 'package:gym_tracker/presentation/utils/time_formatter.dart';
import 'package:gym_tracker/presentation/theme/app_theme.dart';

/// Screen for configuring HIIT routine parameters and naming the routine.
class HiitConfigScreen extends StatefulWidget {
  const HiitConfigScreen({
    super.key,
    required this.exerciseCount,
    required this.onSave,
    required this.onBack,
    this.initialName = '',
    this.initialSets = HiitConfig.defaultSets,
    this.initialWorkSeconds = HiitConfig.defaultWorkSeconds,
    this.initialRestSeconds = HiitConfig.defaultRestSeconds,
    this.initialSetRestSeconds = HiitConfig.defaultSetRestSeconds,
  });

  final int exerciseCount;
  final void Function({
    required String name,
    required int sets,
    required int workSeconds,
    required int restSeconds,
    required int setRestSeconds,
  }) onSave;
  final VoidCallback onBack;

  final String initialName;
  final int initialSets;
  final int initialWorkSeconds;
  final int initialRestSeconds;
  final int initialSetRestSeconds;

  @override
  State<HiitConfigScreen> createState() => _HiitConfigScreenState();
}

class _HiitConfigScreenState extends State<HiitConfigScreen> {
  late final TextEditingController _nameCtrl;
  late int _sets;
  late int _workSeconds;
  late int _restSeconds;
  late int _setRestSeconds;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _sets = widget.initialSets;
    _workSeconds = widget.initialWorkSeconds;
    _restSeconds = widget.initialRestSeconds;
    _setRestSeconds = widget.initialSetRestSeconds;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  /// Total duration in seconds based on current configuration.
  int get _totalDurationSeconds {
    final exerciseCount = widget.exerciseCount;
    final workPerSet = exerciseCount * _workSeconds;
    final restPerSet = (exerciseCount - 1) * _restSeconds;
    final setRest = (_sets - 1) * _setRestSeconds;
    return _sets * (workPerSet + restPerSet) + setRest;
  }

  String _formatDuration(int totalSeconds) =>
      TimeFormatter.duration(totalSeconds);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final nameEmpty = _nameCtrl.text.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hiitConfig),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Routine name
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: l10n.routineNameHint,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),

          // Sets
          _ConfigRow(
            label: l10n.hiitSets,
            value: '$_sets',
            onDecrement: _sets > 1 ? () => setState(() => _sets--) : null,
            onIncrement: _sets < 10 ? () => setState(() => _sets++) : null,
          ),
          const SizedBox(height: 16),

          // Work duration
          _buildTimeRow(
            label: l10n.hiitWorkDuration,
            value: _workSeconds,
            min: HiitConfig.minWorkSeconds,
            max: HiitConfig.maxWorkSeconds,
            onChanged: (v) => setState(() => _workSeconds = v),
          ),

          // Rest between exercises
          _buildTimeRow(
            label: l10n.hiitRestDuration,
            value: _restSeconds,
            min: HiitConfig.minRestSeconds,
            max: HiitConfig.maxRestSeconds,
            onChanged: (v) => setState(() => _restSeconds = v),
          ),

          // Rest between sets
          _buildTimeRow(
            label: l10n.hiitSetRestDuration,
            value: _setRestSeconds,
            min: HiitConfig.minSetRestSeconds,
            max: HiitConfig.maxSetRestSeconds,
            onChanged: (v) => setState(() => _setRestSeconds = v),
          ),

          const SizedBox(height: 8),

          // Total duration
          Card(
            color: Colors.white.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.hiitTotalDuration,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(
                    _formatDuration(_totalDurationSeconds),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: nameEmpty
                  ? null
                  : () => widget.onSave(
                        name: _nameCtrl.text.trim(),
                        sets: _sets,
                        workSeconds: _workSeconds,
                        restSeconds: _restSeconds,
                        setRestSeconds: _setRestSeconds,
                      ),
              child: Text(l10n.sharedSave),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 15, color: context.textSecondary),
            ),
          ),
          TimeWheelPicker(
            minSeconds: min,
            maxSeconds: max,
            stepSeconds: HiitConfig.stepSeconds,
            selectedSeconds: value,
            onChanged: onChanged,
            height: 110,
            width: 80,
          ),
        ],
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  const _ConfigRow({
    required this.label,
    required this.value,
    this.onDecrement,
    this.onIncrement,
  });

  final String label;
  final String value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: onDecrement,
              color:
                  onDecrement != null ? context.textSecondary : Colors.white24,
            ),
            SizedBox(
              width: 32,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onIncrement,
              color:
                  onIncrement != null ? context.textSecondary : Colors.white24,
            ),
          ],
        ),
      ],
    );
  }
}
