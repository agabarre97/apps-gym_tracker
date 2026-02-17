import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/presentation/screens/routine/exercise_detail_sheet.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('ExerciseDetailSheet', () {
    testWidgets('shows muscle image when muscleImage is provided',
        (tester) async {
      const exercise = Exercise(
        key: 'press_banca',
        name: 'Press banca',
        description: 'Descripcion',
        muscleGroups: ['Pectoral', 'Triceps'],
        difficulty: 4,
        muscleImage: 'assets/images/muscles/pectoralis_major.png',
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

      expect(find.byType(Image), findsOneWidget);
      final imageWidget = tester.widget<Image>(find.byType(Image));
      final imageProvider = imageWidget.image;
      expect(imageProvider, isA<AssetImage>());
      expect((imageProvider as AssetImage).assetName,
          'assets/images/muscles/pectoralis_major.png');
    });

    testWidgets('does not show muscle image when muscleImage is null',
        (tester) async {
      const exercise = Exercise(
        key: 'press_banca',
        name: 'Press banca',
        description: 'Descripcion',
        muscleGroups: ['Pectoral', 'Triceps'],
        difficulty: 4,
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

      expect(find.byType(Image), findsNothing);
    });
  });
}
