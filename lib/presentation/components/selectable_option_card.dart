import 'package:flutter/material.dart';

/// Data model for a selectable option used in grid/list selection screens.
class SelectableOption {
  const SelectableOption({
    required this.key,
    required this.label,
    required this.icon,
    required this.enabled,
  });

  final String key;
  final String label;
  final IconData icon;
  final bool enabled;
}

/// A grid-style card for an option with icon, label, enabled/disabled state,
/// and optional "coming soon" badge.
class SelectableOptionGridCard extends StatelessWidget {
  const SelectableOptionGridCard({
    super.key,
    required this.option,
    required this.comingSoonLabel,
    this.onTap,
  });

  final SelectableOption option;
  final String comingSoonLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: option.enabled ? 1.0 : 0.4,
      child: Card(
        elevation: option.enabled ? 4 : 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(option.icon, size: 48, color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      option.label,
                      style: Theme.of(context).textTheme.titleSmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (!option.enabled)
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        comingSoonLabel,
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white54),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A list-style card for an option with icon, label, enabled/disabled state,
/// and optional "coming soon" trailing text.
class SelectableOptionListCard extends StatelessWidget {
  const SelectableOptionListCard({
    super.key,
    required this.option,
    required this.comingSoonLabel,
    this.onTap,
  });

  final SelectableOption option;
  final String comingSoonLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: option.enabled ? 1.0 : 0.4,
      child: Card(
        elevation: option.enabled ? 4 : 1,
        child: ListTile(
          leading: Icon(option.icon, color: Colors.white),
          title: Text(option.label),
          trailing: option.enabled
              ? const Icon(Icons.chevron_right, color: Colors.white54)
              : Text(
                  comingSoonLabel,
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
          onTap: onTap,
        ),
      ),
    );
  }
}
