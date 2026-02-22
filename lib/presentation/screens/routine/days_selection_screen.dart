import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/theme/app_theme.dart';

/// Screen to choose how many days per week the routine will have.
class DaysSelectionScreen extends StatefulWidget {
  const DaysSelectionScreen({
    super.key,
    required this.initialDays,
    required this.onConfirmed,
    required this.onBack,
  });

  final int initialDays;
  final ValueChanged<int> onConfirmed;
  final VoidCallback onBack;

  @override
  State<DaysSelectionScreen> createState() => _DaysSelectionScreenState();
}

class _DaysSelectionScreenState extends State<DaysSelectionScreen> {
  late double _days;

  @override
  void initState() {
    super.initState();
    _days = widget.initialDays.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.routineSelectDays),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${_days.round()}',
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.routineDaysCount('${_days.round()}'),
              style: TextStyle(fontSize: 18, color: context.textSecondary),
            ),
            const SizedBox(height: 32),
            Slider(
              value: _days,
              min: 1,
              max: 7,
              divisions: 6,
              label: '${_days.round()}',
              activeColor: Colors.white,
              inactiveColor: Colors.white24,
              onChanged: (v) => setState(() => _days = v),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => widget.onConfirmed(_days.round()),
                child: Text(l10n.sharedNext),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
