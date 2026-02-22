import 'package:flutter/material.dart';
import 'package:gym_tracker/domain/entities/user_profile.dart';
import 'package:gym_tracker/domain/ports/profile_port.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/screens/profile/advanced_measures_screen.dart';
import 'package:gym_tracker/presentation/screens/profile/basic_info_screen.dart';
import 'package:gym_tracker/presentation/screens/profile/goals_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.profile,
    required this.profilePort,
  });

  final UserProfile profile;
  final ProfilePort profilePort;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final Map<String, dynamic> _data;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _data = {
      'birthDate': widget.profile.birthDate,
      'sex': widget.profile.sex,
      'weightKg': widget.profile.weightKg,
      'heightCm': widget.profile.heightCm,
      'armSpanCm': widget.profile.armSpanCm,
      'gymExperience': widget.profile.gymExperience,
      'bicepsPerimeterCm': widget.profile.bicepsPerimeterCm,
      'chestPerimeterCm': widget.profile.chestPerimeterCm,
      'waistPerimeterCm': widget.profile.waistPerimeterCm,
      'quadPerimeterCm': widget.profile.quadPerimeterCm,
      'calfPerimeterCm': widget.profile.calfPerimeterCm,
      'weightGoal': widget.profile.weightGoal,
      'targetWeightKg': widget.profile.targetWeightKg,
      'kcalPerDay': widget.profile.kcalPerDay,
    };
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _todayIso() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    final updatedGoal =
        _data['weightGoal'] as String? ?? widget.profile.weightGoal;
    final history = List<GoalPhase>.from(widget.profile.goalHistory);
    if (updatedGoal != widget.profile.weightGoal) {
      history.add(GoalPhase(startDate: _todayIso(), weightGoal: updatedGoal));
    }

    final updated = UserProfile(
      birthDate: _data['birthDate'] as String? ?? widget.profile.birthDate,
      sex: _data['sex'] as String? ?? widget.profile.sex,
      weightKg: _data['weightKg'] as double? ?? widget.profile.weightKg,
      heightCm: _data['heightCm'] as double? ?? widget.profile.heightCm,
      gymExperience:
          _data['gymExperience'] as String? ?? widget.profile.gymExperience,
      armSpanCm: _data['armSpanCm'] as double?,
      bicepsPerimeterCm: _data['bicepsPerimeterCm'] as double?,
      chestPerimeterCm: _data['chestPerimeterCm'] as double?,
      waistPerimeterCm: _data['waistPerimeterCm'] as double?,
      quadPerimeterCm: _data['quadPerimeterCm'] as double?,
      calfPerimeterCm: _data['calfPerimeterCm'] as double?,
      weightGoal: updatedGoal,
      targetWeightKg: _data['targetWeightKg'] as double?,
      kcalPerDay: _data['kcalPerDay'] as int?,
      goalHistory: history,
    );

    await widget.profilePort.saveProfile(updated);
    if (!mounted) return;
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileSummaryTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.basicInfoTitle),
            Tab(text: l10n.advancedMeasures1Title),
            Tab(text: l10n.goalsTitle),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          BasicInfoScreen(
            data: _data,
            onChanged: () => setState(() {}),
          ),
          AdvancedMeasuresScreen(
            data: _data,
            onChanged: () => setState(() {}),
          ),
          GoalsScreen(
            data: _data,
            onChanged: () => setState(() {}),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _save,
            child: Text(l10n.sharedSave),
          ),
        ),
      ),
    );
  }
}
