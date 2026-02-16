import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/components/selectable_option_card.dart';

/// Screen to pick a specific recommended routine when a mobility subtype
/// has more than one available routine.
class MobilityRoutineSelectionScreen extends StatelessWidget {
  const MobilityRoutineSelectionScreen({
    super.key,
    required this.routineKeys,
    required this.routineNameGetters,
    required this.onRoutineSelected,
    required this.onBack,
  });

  final List<String> routineKeys;
  final Map<String, String Function(AppLocalizations)> routineNameGetters;
  final ValueChanged<String> onRoutineSelected;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final options = routineKeys.map((key) {
      final nameGetter = routineNameGetters[key];
      final label = nameGetter != null ? nameGetter(l10n) : key;
      return SelectableOption(
        key: key,
        label: label,
        icon: Icons.self_improvement,
        enabled: true,
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mobilityChooseOption),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: options
              .map((o) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SelectableOptionListCard(
                      option: o,
                      comingSoonLabel: l10n.routineComingSoon,
                      onTap: () => onRoutineSelected(o.key),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
