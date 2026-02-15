import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/components/selectable_option_card.dart';

/// Screen to choose: Crear rutina personalizada or Rutina recomendada.
class MobilityOptionScreen extends StatelessWidget {
  const MobilityOptionScreen({
    super.key,
    required this.subType,
    required this.customEnabled,
    required this.recommendedEnabled,
    required this.onOptionSelected,
    required this.onBack,
  });

  final String subType;
  final bool customEnabled;
  final bool recommendedEnabled;
  final ValueChanged<String> onOptionSelected;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final options = <SelectableOption>[
      SelectableOption(
        key: 'custom',
        label: l10n.mobilityCustomRoutine,
        icon: Icons.edit_note,
        enabled: customEnabled,
      ),
      SelectableOption(
        key: 'recommended',
        label: l10n.mobilityRecommendedRoutine,
        icon: Icons.star,
        enabled: recommendedEnabled,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.mobilityChooseOption,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            ...options.map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SelectableOptionListCard(
                    option: o,
                    comingSoonLabel: l10n.routineComingSoon,
                    onTap:
                        o.enabled ? () => onOptionSelected(o.key) : null,
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
