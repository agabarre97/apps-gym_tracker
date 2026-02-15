import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

import 'package:gym_tracker/domain/ports/profile_port.dart';
import 'package:gym_tracker/domain/ports/routine_port.dart';
import 'package:gym_tracker/domain/ports/storage_port.dart';
import 'package:gym_tracker/domain/ports/training_day_port.dart';
import 'package:gym_tracker/domain/ports/workout_session_port.dart';
import 'package:gym_tracker/domain/ports/mobility_session_port.dart';
import 'package:gym_tracker/presentation/screens/get_profile_flow.dart';
import 'package:gym_tracker/presentation/screens/landing_screen.dart';

/// Splash / loading screen shown on app launch.
///
/// Displays a gym background image with a motivational motto, waits 2 seconds,
/// then routes to the onboarding flow or the landing screen.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({
    super.key,
    required this.profilePort,
    required this.storage,
    required this.routinePort,
    required this.trainingDayPort,
    required this.workoutSessionPort,
    required this.mobilitySessionPort,
    required this.onLocaleChanged,
  });

  final ProfilePort profilePort;
  final StoragePort storage;
  final RoutinePort routinePort;
  final TrainingDayPort trainingDayPort;
  final WorkoutSessionPort workoutSessionPort;
  final MobilitySessionPort mobilitySessionPort;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final completed = await widget.profilePort.isProfileCompleted();

    if (!mounted) return;

    if (completed) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LandingScreen(
            storage: widget.storage,
            profilePort: widget.profilePort,
            routinePort: widget.routinePort,
            trainingDayPort: widget.trainingDayPort,
            workoutSessionPort: widget.workoutSessionPort,
            mobilitySessionPort: widget.mobilitySessionPort,
            onLocaleChanged: widget.onLocaleChanged,
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GetProfileFlow(
            profilePort: widget.profilePort,
            storage: widget.storage,
            routinePort: widget.routinePort,
            trainingDayPort: widget.trainingDayPort,
            workoutSessionPort: widget.workoutSessionPort,
            mobilitySessionPort: widget.mobilitySessionPort,
            onLocaleChanged: widget.onLocaleChanged,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Gym background image
          Image.asset(
            'assets/images/gym_background.png',
            fit: BoxFit.cover,
          ),
          // Dark overlay for readability
          Container(color: Colors.black.withValues(alpha: 0.55)),
          // Motto text
          Center(
            child: Text(
              l10n.loadingMotto,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
