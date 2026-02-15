import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/components/routine_type_helper.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('RoutineTypeHelper', () {
    testWidgets('returns localized labels for known routine types', (
      tester,
    ) async {
      late AppLocalizations l10n;

      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        RoutineTypeHelper.labelFor('musculacion', l10n),
        'Musculación',
      );
      expect(
        RoutineTypeHelper.labelFor('movilidad', l10n),
        'Movilidad',
      );
    });

    test('returns expected icons and fallback icon', () {
      expect(RoutineTypeHelper.iconFor('musculacion'), Icons.fitness_center);
      expect(RoutineTypeHelper.iconFor('movilidad'), Icons.accessibility_new);
      expect(RoutineTypeHelper.iconFor('unknown_type'), Icons.fitness_center);
    });
  });
}
