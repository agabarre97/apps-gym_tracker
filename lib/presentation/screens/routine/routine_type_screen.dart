import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/components/routine_type_helper.dart';
import 'package:gym_tracker/presentation/components/selectable_option_card.dart';

/// Screen to select the routine type.
class RoutineTypeScreen extends StatelessWidget {
  const RoutineTypeScreen({
    super.key,
    required this.onTypeSelected,
    required this.onBack,
    this.onImport,
  });

  final ValueChanged<String> onTypeSelected;
  final VoidCallback onBack;
  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const typeConfigs = <(String, bool)>[
      ('musculacion', true),
      ('abdominales', false),
      ('pliometricos', false),
      ('movilidad', true),
      ('hiit', false),
    ];
    final types = typeConfigs
        .map(
          (cfg) => SelectableOption(
            key: cfg.$1,
            label: RoutineTypeHelper.labelFor(cfg.$1, l10n),
            icon: RoutineTypeHelper.iconFor(cfg.$1),
            enabled: cfg.$2,
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.routineSelectType),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: types
                    .map((t) => SelectableOptionGridCard(
                          option: t,
                          comingSoonLabel: l10n.routineComingSoon,
                          onTap:
                              t.enabled ? () => onTypeSelected(t.key) : null,
                        ))
                    .toList(),
              ),
            ),
          ),
          if (onImport != null)
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.file_download_outlined),
                    label: Text(l10n.routineImport),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onImport,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
