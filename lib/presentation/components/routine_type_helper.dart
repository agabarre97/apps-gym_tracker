import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

/// Centralized resolution of routine type keys to labels and icons.
abstract final class RoutineTypeHelper {
  /// Returns the localized label for a given routine type key.
  static String labelFor(String type, AppLocalizations l10n) {
    switch (type) {
      case 'musculacion':
        return l10n.routineMusculacion;
      case 'pliometricos':
        return l10n.routinePliometricos;
      case 'movilidad':
        return l10n.routineMovilidad;
      case 'hiit':
        return l10n.routineHiit;
      default:
        return type;
    }
  }

  /// Returns the corresponding icon for a given routine type key.
  static IconData iconFor(String type) {
    switch (type) {
      case 'musculacion':
        return Icons.fitness_center;
      case 'pliometricos':
        return Icons.directions_run;
      case 'movilidad':
        return Icons.accessibility_new;
      case 'hiit':
        return Icons.timer;
      default:
        return Icons.fitness_center;
    }
  }
}
