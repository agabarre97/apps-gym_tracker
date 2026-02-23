import 'package:flutter/material.dart';
import 'package:gym_tracker/domain/entities/mobility_routine.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/theme/app_theme.dart';

/// Data-driven map from exercise keys to l10n getters.
///
/// Adding a new exercise requires only adding an entry here and in the ARB
/// files — no switch-case maintenance.
final Map<String, String Function(AppLocalizations)>
    _mobilityExerciseNameGetters = {
  'single_leg_stand': (l) => l.mobilitySingleLegStand,
  'ankle_circles': (l) => l.mobilityAnkleCircles,
  'heel_to_toe_rocks': (l) => l.mobilityHeelToToeRocks,
  'lateral_foot_rocks': (l) => l.mobilityLateralFootRocks,
  'knee_circles': (l) => l.mobilityKneeCircles,
  'soleus_stretch': (l) => l.mobilitySoleusStretch,
  'leaning_calf': (l) => l.mobilityLeaningCalf,
  'toe_to_wall': (l) => l.mobilityToeToWall,
  'standing_quad': (l) => l.mobilityStandingQuad,
  'single_leg_calf_stretch': (l) => l.mobilitySingleLegCalfStretch,
  'single_leg_shin_stretch': (l) => l.mobilitySingleLegShinStretch,
  'toe_stretch': (l) => l.mobilityToeStretch,
  'thunderbolt': (l) => l.mobilityThunderbolt,
  'toe_squat': (l) => l.mobilityToeSquat,
  // Pelvic Tilt routine
  'pelvic_tilt': (l) => l.mobilityPelvicTiltExercise,
  'glute_bridge': (l) => l.mobilityGluteBridge,
  'knees_to_chest': (l) => l.mobilityKneesToChest,
  'single_knee_to_chest': (l) => l.mobilitySingleKneeToChest,
  'lying_quad_stretch': (l) => l.mobilityLyingQuadStretch,
  'kneeling_hip_flexor': (l) => l.mobilityKneelingHipFlexor,
  'cat_cow': (l) => l.mobilityCatCow,
  'seated_butterfly': (l) => l.mobilitySeatedButterfly,
  'lying_figure_four': (l) => l.mobilityLyingFigureFour,
  // Hips routine
  'lizard_pose': (l) => l.mobilityLizardPose,
  'pigeon': (l) => l.mobilityPigeon,
  'folded_butterfly': (l) => l.mobilityFoldedButterfly,
  'happy_baby': (l) => l.mobilityHappyBaby,
  'frog_pose': (l) => l.mobilityFrogPose,
  'squat_stretch': (l) => l.mobilitySquatStretch,
  'double_pigeon': (l) => l.mobilityDoublePigeon,
  'reclined_butterfly': (l) => l.mobilityReclinedButterfly,
  // Sleep routine
  'rag_doll': (l) => l.mobilityRagDoll,
  'upward_dog': (l) => l.mobilityUpwardDog,
  'childs_pose': (l) => l.mobilityChildsPose,
  'spinal_twist': (l) => l.mobilitySpinalTwist,
  'quad_stretch': (l) => l.mobilityQuadStretch,
  'legs_up_wall': (l) => l.mobilityLegsUpWall,
};

/// Returns the localized display name for a mobility exercise key.
String mobilityExerciseDisplayName(String key, AppLocalizations l10n) {
  final getter = _mobilityExerciseNameGetters[key];
  return getter != null ? getter(l10n) : key.replaceAll('_', ' ');
}

/// Variant style for [MobilityExerciseTile].
enum MobilityExerciseTileVariant {
  /// Detailed card with CircleAvatar and duration badge — used in the
  /// routine detail screen.
  detailed,

  /// Compact ListTile — used in the timer preview screen.
  compact,
}

/// A reusable widget that displays a single mobility exercise with its index,
/// name, side label, and duration.
class MobilityExerciseTile extends StatelessWidget {
  const MobilityExerciseTile({
    super.key,
    required this.exercise,
    required this.index,
    required this.l10n,
    this.variant = MobilityExerciseTileVariant.detailed,
    this.onTap,
  });

  final MobilityExercise exercise;
  final int index;
  final AppLocalizations l10n;
  final MobilityExerciseTileVariant variant;

  /// Optional tap handler — used in the detail screen to show exercise info.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = mobilityExerciseDisplayName(exercise.key, l10n);
    final sideLabel = exercise.bilateral
        ? l10n.mobilityBothSides
        : '${l10n.mobilityLeftSide} + ${l10n.mobilityRightSide}';
    final duration = exercise.bilateral
        ? '${exercise.durationSeconds}s'
        : '${exercise.durationSeconds}s × 2';

    return switch (variant) {
      MobilityExerciseTileVariant.detailed =>
        _buildDetailed(context, name, sideLabel, duration),
      MobilityExerciseTileVariant.compact =>
        _buildCompact(context, name, sideLabel, duration),
    };
  }

  Widget _buildDetailed(
    BuildContext context,
    String name,
    String sideLabel,
    String duration,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.greenAccent.withAlpha(30),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sideLabel,
                      style:
                          TextStyle(fontSize: 11, color: context.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  duration,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(
    BuildContext context,
    String name,
    String sideLabel,
    String duration,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: Colors.white12,
          child: Text(
            '${index + 1}',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: context.textSecondary),
          ),
        ),
        title: Text(name, style: const TextStyle(fontSize: 14)),
        subtitle: Text(
          sideLabel,
          style: TextStyle(fontSize: 11, color: context.textSecondary),
        ),
        trailing: Text(
          duration,
          style: const TextStyle(fontSize: 13, color: Colors.greenAccent),
        ),
      ),
    );
  }
}
