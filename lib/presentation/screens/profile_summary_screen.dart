import 'package:flutter/material.dart';
import 'package:gym_tracker/domain/ports/measurement_record_port.dart';
import 'package:gym_tracker/domain/ports/profile_port.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

import 'package:gym_tracker/domain/entities/user_profile.dart';
import 'package:gym_tracker/domain/ports/storage_port.dart';
import 'package:gym_tracker/presentation/screens/profile/body_progress_screen.dart';
import 'package:gym_tracker/presentation/screens/profile/edit_profile_screen.dart';
import 'package:gym_tracker/presentation/theme/app_theme.dart';

/// Profile screen that displays the saved user profile data.
/// Accessed from the landing screen via the avatar icon.
class ProfileSummaryScreen extends StatefulWidget {
  const ProfileSummaryScreen({
    super.key,
    required this.profile,
    required this.profilePort,
    required this.measurementRecordPort,
    required this.storage,
    this.email,
    this.onSignOut,
  });

  final UserProfile profile;
  final ProfilePort profilePort;
  final MeasurementRecordPort measurementRecordPort;
  final StoragePort storage;
  final String? email;

  /// If non-null, a sign-out link is shown at the bottom.
  /// The callback should return true; ProfileSummaryScreen pops with that value.
  final bool Function()? onSignOut;

  @override
  State<ProfileSummaryScreen> createState() => _ProfileSummaryScreenState();
}

class _ProfileSummaryScreenState extends State<ProfileSummaryScreen> {
  late UserProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  Future<void> _openBodyProgress() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BodyProgressScreen(
          measurementRecordPort: widget.measurementRecordPort,
          profilePort: widget.profilePort,
          profile: _profile,
        ),
      ),
    );
    final refreshed = await widget.profilePort.loadProfile();
    if (refreshed != null && mounted) {
      setState(() => _profile = refreshed);
    }
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          profile: _profile,
          profilePort: widget.profilePort,
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _profile = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final na = l10n.sharedNotAvailable;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: _openEditProfile,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Account email ──
          if (widget.email != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.email_outlined,
                        size: 20, color: context.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.email!,
                        style: TextStyle(
                          fontSize: 15,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Card(
            child: ListTile(
              leading: Icon(Icons.show_chart, color: context.textSecondary),
              title: Text(l10n.progressTitle),
              trailing: Icon(Icons.chevron_right, color: context.textSubtle),
              onTap: _openBodyProgress,
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: l10n.basicInfoTitle,
            rows: [
              _Row(l10n.basicInfoBirthDate, _formatDate(_profile.birthDate)),
              _Row(l10n.basicInfoSex, _sexLabel(_profile.sex, l10n)),
              _Row(l10n.basicInfoWeight, '${_profile.weightKg}'),
              _Row(l10n.basicInfoHeight, '${_profile.heightCm}'),
              _Row(l10n.advancedMeasures1ArmSpan, _opt(_profile.armSpanCm, na)),
              _Row(l10n.basicInfoGymExperience,
                  _experienceLabel(_profile.gymExperience, l10n)),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: l10n.advancedMeasures1Title,
            rows: [
              _Row(l10n.advancedMeasures1BicepsPerimeter,
                  _opt(_profile.bicepsPerimeterCm, na)),
              _Row(l10n.advancedMeasures1ChestPerimeter,
                  _opt(_profile.chestPerimeterCm, na)),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: l10n.advancedMeasures2Title,
            rows: [
              _Row(l10n.advancedMeasures2WaistPerimeter,
                  _opt(_profile.waistPerimeterCm, na)),
              _Row(l10n.advancedMeasures2QuadPerimeter,
                  _opt(_profile.quadPerimeterCm, na)),
              _Row(l10n.advancedMeasures2CalfPerimeter,
                  _opt(_profile.calfPerimeterCm, na)),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: l10n.goalsTitle,
            rows: [
              _Row(
                l10n.goalsWeightObjective,
                _goalLabel(_profile.weightGoal, l10n),
              ),
              if (_profile.targetWeightKg != null)
                _Row(l10n.goalsTargetWeight, '${_profile.targetWeightKg}'),
              if (_profile.kcalPerDay != null)
                _Row(
                  _profile.weightGoal == 'gain'
                      ? l10n.goalsKcalToGain
                      : l10n.goalsKcalToLose,
                  '${_profile.kcalPerDay}',
                ),
            ],
          ),
          // ── Sign out link ──
          if (widget.onSignOut != null) ...[
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
                    Navigator.of(context).pop(widget.onSignOut!());
                  }
                },
                child: Text(
                  l10n.authSignOut,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSubtle,
                    decoration: TextDecoration.underline,
                    decorationColor: context.textSubtle,
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
