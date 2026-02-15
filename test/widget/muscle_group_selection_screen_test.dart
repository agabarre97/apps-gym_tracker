import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/muscle_group.dart';
import 'package:gym_tracker/presentation/screens/routine/muscle_group_selection_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('MuscleGroupSelectionScreen', () {
    testWidgets('renders all 9 muscle group chips', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          MuscleGroupSelectionScreen(
            currentDay: 1,
            totalDays: 3,
            onConfirmed: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FilterChip),
          findsNWidgets(MuscleGroupCategory.values.length));
    });

    testWidgets('next button is disabled when no group is selected',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          MuscleGroupSelectionScreen(
            currentDay: 1,
            totalDays: 3,
            onConfirmed: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('selecting a group enables the next button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          MuscleGroupSelectionScreen(
            currentDay: 1,
            totalDays: 3,
            onConfirmed: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the Pectoral chip
      await tester.tap(find.text('Pectoral'));
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('shows progress bar with correct progress', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          MuscleGroupSelectionScreen(
            currentDay: 2,
            totalDays: 4,
            onConfirmed: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final indicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator));
      expect(indicator.value, closeTo(0.5, 0.01));
    });
  });
}
