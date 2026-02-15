import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

/// Screen 5 — motivational welcome message and "Start" button.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.weightGoal,
    required this.onStart,
  });

  /// 'gain', 'lose', or 'maintain'.
  final String weightGoal;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final String motto;
    switch (weightGoal) {
      case 'gain':
        motto = l10n.welcomeMotivationalGain;
      case 'lose':
        motto = l10n.welcomeMotivationalLose;
      case 'maintain':
        motto = l10n.welcomeMotivationalMaintain;
      default:
        motto = l10n.welcomeMotivationalGain;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.welcomeTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 32),
          Text(
            motto,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.fitness_center),
            label: Text(l10n.sharedStart),
          ),
        ],
      ),
    );
  }
}
