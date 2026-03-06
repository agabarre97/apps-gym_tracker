import 'package:flutter/material.dart';
import 'package:gym_tracker/domain/entities/mobility_exercise_info.dart';
import 'package:gym_tracker/domain/entities/mobility_routine.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/components/mobility_exercise_tile.dart';
import 'package:gym_tracker/presentation/theme/app_theme.dart';

/// Shows a modal bottom sheet with detailed exercise information.
Future<void> showMobilityExerciseDetailSheet(
  BuildContext context, {
  required MobilityExercise exercise,
  required MobilityExerciseInfo info,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.darkSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _MobilityExerciseDetailContent(
      exercise: exercise,
      info: info,
    ),
  );
}

class _MobilityExerciseDetailContent extends StatelessWidget {
  const _MobilityExerciseDetailContent({
    required this.exercise,
    required this.info,
  });

  final MobilityExercise exercise;
  final MobilityExerciseInfo info;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = mobilityExerciseDisplayName(exercise.key, l10n);
    final sideLabel = exercise.bilateral
        ? l10n.mobilityBothSides
        : '${l10n.mobilityLeftSide} + ${l10n.mobilityRightSide}';
    final duration = exercise.bilateral
        ? '${exercise.durationSeconds}s'
        : '${exercise.durationSeconds}s × 2';

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ListView(
          controller: scrollController,
          children: [
            const SizedBox(height: 12),

            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.dividerSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 6),

            // Subtitle: duration + side info
            Text(
              '$duration  ·  $sideLabel',
              style: TextStyle(fontSize: 13, color: context.textSecondary),
            ),
            const Divider(height: 28),

            // Instructions
            if (info.instructions.isNotEmpty) ...[
              _SectionHeader(label: l10n.mobilityInfoInstructions),
              const SizedBox(height: 8),
              ...info.instructions.asMap().entries.map(
                    (e) => _NumberedItem(index: e.key + 1, text: e.value),
                  ),
              const SizedBox(height: 16),
            ],

            // Tips
            if (info.tips.isNotEmpty) ...[
              _SectionHeader(label: l10n.mobilityInfoTips),
              const SizedBox(height: 8),
              ...info.tips.map((t) => _BulletItem(text: t)),
              const SizedBox(height: 16),
            ],

            // Modifications
            if (info.modifications.isNotEmpty) ...[
              _SectionHeader(label: l10n.mobilityInfoModifications),
              const SizedBox(height: 8),
              ...info.modifications.map((m) => _BulletItem(text: m)),
              const SizedBox(height: 16),
            ],

            // Benefits
            if (info.benefits.isNotEmpty) ...[
              _SectionHeader(label: l10n.mobilityInfoBenefits),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: info.benefits
                    .map((b) => Chip(
                          label: Text(b, style: const TextStyle(fontSize: 12)),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.success,
      ),
    );
  }
}

class _NumberedItem extends StatelessWidget {
  const _NumberedItem({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$index.',
              style: TextStyle(
                fontSize: 13,
                color: context.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: context.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '•',
              style: TextStyle(
                fontSize: 13,
                color: context.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: context.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
