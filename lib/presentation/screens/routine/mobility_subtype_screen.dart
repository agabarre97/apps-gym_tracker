import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/components/selectable_option_card.dart';

/// Screen to select mobility sub-type: Cadera or Tobillos.
class MobilitySubTypeScreen extends StatelessWidget {
  const MobilitySubTypeScreen({
    super.key,
    required this.onSubTypeSelected,
    required this.onBack,
  });

  final ValueChanged<String> onSubTypeSelected;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final options = <SelectableOption>[
      SelectableOption(
        key: 'cadera',
        label: l10n.mobilityCadera,
        icon: Icons.accessibility_new,
        enabled: true,
      ),
      SelectableOption(
        key: 'tobillos',
        label: l10n.mobilityTobillos,
        icon: Icons.directions_walk,
        enabled: true,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.routineMovilidad),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: options
              .map((o) => SelectableOptionGridCard(
                    option: o,
                    comingSoonLabel: l10n.routineComingSoon,
                    onTap:
                        o.enabled ? () => onSubTypeSelected(o.key) : null,
                  ))
              .toList(),
        ),
      ),
    );
  }
}
