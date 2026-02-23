import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

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
import 'package:gym_tracker/domain/ports/custom_exercise_port.dart';
import 'package:gym_tracker/presentation/screens/auth/auth_screen.dart';
import 'package:gym_tracker/presentation/screens/get_profile_flow.dart';
import 'package:gym_tracker/presentation/screens/landing_screen.dart';

/// Splash / loading screen shown on app launch.
///
/// Displays a gym background image with a motivational motto, waits 2 seconds,
/// then routes to auth (if not signed in) or to the main flow.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({
    super.key,
    this.authPort,
    this.syncedStorage,
    required this.profilePort,
    required this.storage,
    required this.routinePort,
    required this.trainingDayPort,
    required this.workoutSessionPort,
    this.measurementRecordPort,
    required this.mobilitySessionPort,
    required this.hiitSessionPort,
    this.customExercisePort,
    required this.onLocaleChanged,
  });

  final AuthPort? authPort;
  final SyncPort? syncedStorage;
  final ProfilePort profilePort;
  final StoragePort storage;
  final RoutinePort routinePort;
  final TrainingDayPort trainingDayPort;
  final WorkoutSessionPort workoutSessionPort;
  final MeasurementRecordPort? measurementRecordPort;
  final MobilitySessionPort mobilitySessionPort;
  final HiitSessionPort hiitSessionPort;
  final CustomExercisePort? customExercisePort;
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
    // Yield to let the widget mount
    await Future.microtask(() {});

    // If auth is not configured (e.g. in tests), skip auth check
    final authPort = widget.authPort;
    if (authPort == null) {
      _goToMainFlow();
      return;
    }

    // Wait for Firebase to restore the persisted session.
    // On web, currentUser is null until the auth state is hydrated.
    AuthUser? user;
    try {
      user = await authPort.authStateChanges.first
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
    } catch (_) {
      // Stream completed without emitting (e.g. empty stream) or other error
      user = null;
    }

    if (!mounted) return;

    if (user == null) {
      _goToAuth();
    } else {
      // Ensure synced storage is linked to the persisted user
      widget.syncedStorage?.setUserId(user.uid);
      _goToMainFlow();
    }
  }

  void _goToAuth() {
    FlutterNativeSplash.remove();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AuthScreen(
          authPort: widget.authPort!,
          syncedStorage: widget.syncedStorage!,
          onAuthenticated: (authContext) {
            Navigator.of(authContext).pushReplacement(
              MaterialPageRoute(
                builder: (_) => _PostAuthRouter(
                  profilePort: widget.profilePort,
                  storage: widget.storage,
                  routinePort: widget.routinePort,
                  trainingDayPort: widget.trainingDayPort,
                  workoutSessionPort: widget.workoutSessionPort,
                  measurementRecordPort: widget.measurementRecordPort,
                  mobilitySessionPort: widget.mobilitySessionPort,
                  hiitSessionPort: widget.hiitSessionPort,
                  customExercisePort: widget.customExercisePort,
                  onLocaleChanged: widget.onLocaleChanged,
                  authPort: widget.authPort!,
                  syncedStorage: widget.syncedStorage!,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _goToMainFlow() => _routeByProfile(
        context: context,
        profilePort: widget.profilePort,
        storage: widget.storage,
        routinePort: widget.routinePort,
        trainingDayPort: widget.trainingDayPort,
        workoutSessionPort: widget.workoutSessionPort,
        measurementRecordPort: widget.measurementRecordPort,
        mobilitySessionPort: widget.mobilitySessionPort,
        hiitSessionPort: widget.hiitSessionPort,
        customExercisePort: widget.customExercisePort,
        onLocaleChanged: widget.onLocaleChanged,
        authPort: widget.authPort,
        syncedStorage: widget.syncedStorage,
        mounted: () => mounted,
      );

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      body: SizedBox.shrink(),
    );
  }
}

// ── Shared routing helper ──────────────────────────────────────

/// Checks profile completion and routes to [LandingScreen] or
/// [GetProfileFlow]. Used by both [LoadingScreen] and [_PostAuthRouter]
/// to avoid duplicating the routing logic.
Future<void> _routeByProfile({
  required BuildContext context,
  required ProfilePort profilePort,
  required StoragePort storage,
  required RoutinePort routinePort,
  required TrainingDayPort trainingDayPort,
  required WorkoutSessionPort workoutSessionPort,
  required MeasurementRecordPort? measurementRecordPort,
  required MobilitySessionPort mobilitySessionPort,
  required HiitSessionPort hiitSessionPort,
  CustomExercisePort? customExercisePort,
  required ValueChanged<Locale> onLocaleChanged,
  required bool Function() mounted,
  AuthPort? authPort,
  SyncPort? syncedStorage,
}) async {
  final navigator = Navigator.of(context);
  final completed = await profilePort.isProfileCompleted();
  if (!mounted()) return;

  final Widget destination = completed
      ? LandingScreen(
          storage: storage,
          profilePort: profilePort,
          routinePort: routinePort,
          trainingDayPort: trainingDayPort,
          workoutSessionPort: workoutSessionPort,
          measurementRecordPort: measurementRecordPort,
          mobilitySessionPort: mobilitySessionPort,
          hiitSessionPort: hiitSessionPort,
          customExercisePort: customExercisePort,
          onLocaleChanged: onLocaleChanged,
          authPort: authPort,
          syncedStorage: syncedStorage,
        )
      : GetProfileFlow(
          profilePort: profilePort,
          storage: storage,
          routinePort: routinePort,
          trainingDayPort: trainingDayPort,
          workoutSessionPort: workoutSessionPort,
          measurementRecordPort: measurementRecordPort,
          mobilitySessionPort: mobilitySessionPort,
          hiitSessionPort: hiitSessionPort,
          customExercisePort: customExercisePort,
          onLocaleChanged: onLocaleChanged,
          authPort: authPort,
          syncedStorage: syncedStorage,
        );

  if (!navigator.mounted) return;
  FlutterNativeSplash.remove();
  navigator.pushReplacement(
    MaterialPageRoute(builder: (_) => destination),
  );
}

/// Intermediate widget that checks profile completion after auth success
/// and routes accordingly. This avoids the auth screen having to know
/// about the profile flow.
class _PostAuthRouter extends StatefulWidget {
  const _PostAuthRouter({
    required this.profilePort,
    required this.storage,
    required this.routinePort,
    required this.trainingDayPort,
    required this.workoutSessionPort,
    required this.measurementRecordPort,
    required this.mobilitySessionPort,
    required this.hiitSessionPort,
    this.customExercisePort,
    required this.onLocaleChanged,
    required this.authPort,
    required this.syncedStorage,
  });

  final ProfilePort profilePort;
  final StoragePort storage;
  final RoutinePort routinePort;
  final TrainingDayPort trainingDayPort;
  final WorkoutSessionPort workoutSessionPort;
  final MeasurementRecordPort? measurementRecordPort;
  final MobilitySessionPort mobilitySessionPort;
  final HiitSessionPort hiitSessionPort;
  final CustomExercisePort? customExercisePort;
  final ValueChanged<Locale> onLocaleChanged;
  final AuthPort authPort;
  final SyncPort syncedStorage;

  @override
  State<_PostAuthRouter> createState() => _PostAuthRouterState();
}

class _PostAuthRouterState extends State<_PostAuthRouter> {
  @override
  void initState() {
    super.initState();
    _routeByProfile(
      context: context,
      profilePort: widget.profilePort,
      storage: widget.storage,
      routinePort: widget.routinePort,
      trainingDayPort: widget.trainingDayPort,
      workoutSessionPort: widget.workoutSessionPort,
      measurementRecordPort: widget.measurementRecordPort,
      mobilitySessionPort: widget.mobilitySessionPort,
      hiitSessionPort: widget.hiitSessionPort,
      customExercisePort: widget.customExercisePort,
      onLocaleChanged: widget.onLocaleChanged,
      authPort: widget.authPort,
      syncedStorage: widget.syncedStorage,
      mounted: () => mounted,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
