import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

import 'package:gym_tracker/domain/entities/user_profile.dart';
import 'package:gym_tracker/domain/ports/storage_port.dart';

/// Profile screen that displays the saved user profile data.
/// Accessed from the landing screen via the avatar icon.
class ProfileSummaryScreen extends StatelessWidget {
  const ProfileSummaryScreen({
    super.key,
    required this.profile,
    required this.storage,
    this.email,
    this.onSignOut,
  });

  final UserProfile profile;
  final StoragePort storage;
  final String? email;

  /// If non-null, a sign-out link is shown at the bottom.
  /// The callback should return true; ProfileSummaryScreen pops with that value.
  final bool Function()? onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final na = l10n.sharedNotAvailable;

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Account email ──
          if (email != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined,
                        size: 20, color: Colors.white54),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        email!,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _SectionCard(
            title: l10n.basicInfoTitle,
            rows: [
              _Row(l10n.basicInfoBirthDate, _formatDate(profile.birthDate)),
              _Row(l10n.basicInfoSex, _sexLabel(profile.sex, l10n)),
              _Row(l10n.basicInfoWeight, '${profile.weightKg}'),
              _Row(l10n.basicInfoHeight, '${profile.heightCm}'),
              _Row(l10n.basicInfoGymExperience,
                  _experienceLabel(profile.gymExperience, l10n)),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: l10n.advancedMeasures1Title,
            rows: [
              _Row(l10n.advancedMeasures1ArmSpan, _opt(profile.armSpanCm, na)),
              _Row(l10n.advancedMeasures1BicepsPerimeter,
                  _opt(profile.bicepsPerimeterCm, na)),
              _Row(l10n.advancedMeasures1ChestPerimeter,
                  _opt(profile.chestPerimeterCm, na)),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: l10n.advancedMeasures2Title,
            rows: [
              _Row(l10n.advancedMeasures2WaistPerimeter,
                  _opt(profile.waistPerimeterCm, na)),
              _Row(l10n.advancedMeasures2QuadPerimeter,
                  _opt(profile.quadPerimeterCm, na)),
              _Row(l10n.advancedMeasures2CalfPerimeter,
                  _opt(profile.calfPerimeterCm, na)),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: l10n.goalsTitle,
            rows: [
              _Row(
                l10n.goalsWeightObjective,
                _goalLabel(profile.weightGoal, l10n),
              ),
              if (profile.targetWeightKg != null)
                _Row(l10n.goalsTargetWeight, '${profile.targetWeightKg}'),
              if (profile.kcalPerDay != null)
                _Row(
                  profile.weightGoal == 'gain'
                      ? l10n.goalsKcalToGain
                      : l10n.goalsKcalToLose,
                  '${profile.kcalPerDay}',
                ),
            ],
          ),
          // ── Sign out link ──
          if (onSignOut != null) ...[
            const SizedBox(height: 32),
            Center(
              child: GestureDetector(
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.authSignOut),
                      content: Text(l10n.authSignOutConfirm),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text(l10n.sharedCancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: Text(l10n.authSignOut),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    Navigator.of(context).pop(onSignOut!());
                  }
                },
                child: Text(
                  l10n.authSignOut,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white38,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white38,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  String _opt(double? v, String na) => v != null ? v.toString() : na;

  String _formatDate(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    return '${parts[2]}/${parts[1]}/${parts[0]}'; // dd/MM/yyyy
  }

  String _sexLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'male':
        return l10n.basicInfoSexMale;
      case 'female':
        return l10n.basicInfoSexFemale;
      default:
        return key;
    }
  }

  String _goalLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'gain':
        return l10n.sharedGain;
      case 'lose':
        return l10n.sharedLose;
      case 'maintain':
        return l10n.sharedMaintain;
      default:
        return key;
    }
  }

  String _experienceLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case '<1':
        return l10n.basicInfoExpLessThan1;
      case '1-3':
        return l10n.basicInfoExp1to3;
      case '3-5':
        return l10n.basicInfoExp3to5;
      case '>5':
        return l10n.basicInfoExpMoreThan5;
      default:
        return key;
    }
  }
}

class _Row {
  const _Row(this.label, this.value);
  final String label;
  final String value;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.rows});

  final String title;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...rows.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r.label),
                      Text(r.value,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
