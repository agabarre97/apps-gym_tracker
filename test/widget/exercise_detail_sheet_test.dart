import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/presentation/components/musclewiki_svg_preview.dart';
import 'package:gym_tracker/presentation/screens/routine/exercise_detail_sheet.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('ExerciseDetailSheet', () {
    testWidgets('shows SVG body preview for involved muscles', (tester) async {
      const exercise = Exercise(
        key: 'press_banca',
        name: 'Press banca',
        description: 'Descripcion',
        muscleGroups: ['chest', 'triceps'],
        musclesInvolved: ['chest', 'triceps'],
        difficulty: 3,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: ExerciseDetailSheet(
              exercise: exercise,
              isSelected: false,
              onToggle: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MuscleWikiSvgPreview), findsOneWidget);
      expect(find.text('3/3'), findsOneWidget);
    });

    testWidgets('shows translated description from bilingual payload',
        (tester) async {
      const exercise = Exercise(
        key: 'press_banca',
        name: 'Press banca',
        description: 'Descripcion ES',
        localizedShortDescription: {'es': 'Descripcion ES', 'en': 'EN Desc'},
        muscleGroups: ['chest', 'triceps'],
        difficulty: 2,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: ExerciseDetailSheet(
              exercise: exercise,
              isSelected: false,
              onToggle: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Descripcion ES'), findsOneWidget);
    });
  });
}
