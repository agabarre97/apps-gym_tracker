import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

import 'package:gym_tracker/domain/entities/user_profile.dart';
import 'package:gym_tracker/domain/ports/auth_port.dart';
import 'package:gym_tracker/domain/ports/sync_port.dart';
import 'package:gym_tracker/domain/ports/profile_port.dart';
import 'package:gym_tracker/domain/ports/routine_port.dart';
import 'package:gym_tracker/domain/ports/storage_port.dart';
import 'package:gym_tracker/domain/ports/training_day_port.dart';
import 'package:gym_tracker/domain/ports/workout_session_port.dart';
import 'package:gym_tracker/domain/ports/measurement_record_port.dart';
import 'package:gym_tracker/domain/ports/mobility_session_port.dart';
import 'package:gym_tracker/domain/ports/hiit_session_port.dart';
import 'package:gym_tracker/presentation/components/language_selector.dart';
import 'package:gym_tracker/presentation/screens/landing_screen.dart';
import 'package:gym_tracker/presentation/screens/profile/advanced_measures_screen.dart';
import 'package:gym_tracker/presentation/screens/profile/basic_info_screen.dart';
import 'package:gym_tracker/presentation/screens/profile/goals_screen.dart';
import 'package:gym_tracker/presentation/screens/profile/welcome_screen.dart';

/// Manages the 5-step onboarding wizard using a [PageController].
class GetProfileFlow extends StatefulWidget {
  const GetProfileFlow({
    super.key,
    required this.profilePort,
    required this.storage,
    required this.routinePort,
    required this.trainingDayPort,
    required this.workoutSessionPort,
    this.measurementRecordPort,
    required this.mobilitySessionPort,
    required this.hiitSessionPort,
    required this.onLocaleChanged,
    this.authPort,
    this.syncedStorage,
  });

  final ProfilePort profilePort;
  final StoragePort storage;
  final RoutinePort routinePort;
  final TrainingDayPort trainingDayPort;
  final WorkoutSessionPort workoutSessionPort;
  final MeasurementRecordPort? measurementRecordPort;
  final MobilitySessionPort mobilitySessionPort;
  final HiitSessionPort hiitSessionPort;
  final ValueChanged<Locale> onLocaleChanged;
  final AuthPort? authPort;
  final SyncPort? syncedStorage;

  @override
  State<GetProfileFlow> createState() => _GetProfileFlowState();
}

class _GetProfileFlowState extends State<GetProfileFlow> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  static const _totalPages = 4;

  /// Shared mutable data map populated by each page.
  final Map<String, dynamic> _data = {};

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) => setState(() => _currentPage = index);

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _isBasicInfoValid() {
    final birthDate = _data['birthDate'];
    final sex = _data['sex'];
    final weight = _data['weightKg'];
    final height = _data['heightCm'];
    final exp = _data['gymExperience'];
    if (birthDate == null || birthDate is! String || birthDate.isEmpty) {
      return false;
    }
    if (sex == null || sex is! String || sex.isEmpty) return false;
    if (weight == null || weight is! double || weight < 30 || weight > 300) {
      return false;
    }
    if (height == null || height is! double || height < 100 || height > 250) {
      return false;
    }
    final armSpan = _data['armSpanCm'];
    if (armSpan == null ||
        armSpan is! double ||
        armSpan < 100 ||
        armSpan > 300) {
      return false;
    }
    if (exp == null || exp is! String || exp.isEmpty) return false;
    return true;
  }

  bool _isGoalsValid() {
    final goal = _data['weightGoal'];
    if (goal == null) return false;

    // "maintain" doesn't need target weight or kcal
    if (goal == 'maintain') return true;

    final target = _data['targetWeightKg'];
    final kcal = _data['kcalPerDay'];
    if (target == null || target is! double || target < 30 || target > 300) {
      return false;
    }
    if (kcal == null || kcal is! int) return false;
    return true;
  }

  Future<void> _onStart() async {
    final now = DateTime.now();
    final todayIso =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final goal = _data['weightGoal'] as String;
    final profile = UserProfile(
      birthDate: _data['birthDate'] as String,
      sex: _data['sex'] as String,
      weightKg: _data['weightKg'] as double,
      heightCm: _data['heightCm'] as double,
      gymExperience: _data['gymExperience'] as String,
      armSpanCm: _data['armSpanCm'] as double?,
      bicepsPerimeterCm: _data['bicepsPerimeterCm'] as double?,
      chestPerimeterCm: _data['chestPerimeterCm'] as double?,
      waistPerimeterCm: _data['waistPerimeterCm'] as double?,
      quadPerimeterCm: _data['quadPerimeterCm'] as double?,
      calfPerimeterCm: _data['calfPerimeterCm'] as double?,
      weightGoal: goal,
      targetWeightKg: _data['targetWeightKg'] as double?,
      kcalPerDay: _data['kcalPerDay'] as int?,
      goalHistory: [GoalPhase(startDate: todayIso, weightGoal: goal)],
    );

    await widget.profilePort.saveProfile(profile);
    await widget.profilePort.markProfileCompleted();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LandingScreen(
          storage: widget.storage,
          profilePort: widget.profilePort,
          routinePort: widget.routinePort,
          trainingDayPort: widget.trainingDayPort,
          workoutSessionPort: widget.workoutSessionPort,
          measurementRecordPort: widget.measurementRecordPort,
          mobilitySessionPort: widget.mobilitySessionPort,
          hiitSessionPort: widget.hiitSessionPort,
          onLocaleChanged: widget.onLocaleChanged,
          authPort: widget.authPort,
          syncedStorage: widget.syncedStorage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sharedStepOf(
          '${_currentPage + 1}',
          '$_totalPages',
        )),
        actions: [
          LanguageSelector(
            onLocaleChanged: widget.onLocaleChanged,
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentPage + 1) / _totalPages,
          ),
          // Pages
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              onPageChanged: _onPageChanged,
              physics: const NeverScrollableScrollPhysics(),
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
                WelcomeScreen(
                  weightGoal: (_data['weightGoal'] as String?) ?? 'gain',
                  onStart: _onStart,
                ),
              ],
            ),
          ),
          // Navigation buttons
          if (_currentPage < _totalPages - 1)
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back
                    if (_currentPage > 0)
                      OutlinedButton(
                        onPressed: _back,
                        child: Text(l10n.sharedBack),
                      )
                    else
                      const SizedBox.shrink(),
                    // Skip (on advanced measure pages)
                    if (_currentPage == 1)
                      TextButton(
                        onPressed: _next,
                        child: Text(l10n.sharedSkip),
                      ),
                    // Next
                    FilledButton(
                      onPressed: _canAdvance() ? _next : null,
                      child: Text(l10n.sharedNext),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _canAdvance() {
    switch (_currentPage) {
      case 0:
        return _isBasicInfoValid();
      case 1:
        return true; // optional screens
      case 2:
        return _isGoalsValid();
      default:
        return false;
    }
  }
}
