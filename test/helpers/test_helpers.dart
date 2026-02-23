import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gym_tracker/domain/entities/routine.dart';
import 'package:gym_tracker/domain/entities/training_day.dart';
import 'package:gym_tracker/domain/entities/user_profile.dart';
import 'package:gym_tracker/domain/ports/auth_port.dart';
import 'package:gym_tracker/domain/ports/profile_port.dart';
import 'package:gym_tracker/domain/ports/routine_port.dart';
import 'package:gym_tracker/domain/ports/storage_port.dart';
import 'package:gym_tracker/domain/ports/sync_port.dart';
import 'package:gym_tracker/domain/entities/workout_session.dart';
import 'package:gym_tracker/domain/ports/training_day_port.dart';
import 'package:gym_tracker/domain/entities/measurement_record.dart';
import 'package:gym_tracker/domain/entities/mobility_session.dart';
import 'package:gym_tracker/domain/ports/mobility_session_port.dart';
import 'package:gym_tracker/domain/entities/hiit_session.dart';
import 'package:gym_tracker/domain/entities/exercise.dart';
import 'package:gym_tracker/domain/ports/hiit_session_port.dart';
import 'package:gym_tracker/domain/ports/custom_exercise_port.dart';
import 'package:gym_tracker/domain/ports/measurement_record_port.dart';
import 'package:gym_tracker/domain/ports/workout_session_port.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/presentation/theme/app_theme.dart';

/// In-memory implementation of [StoragePort] for testing.
class FakeStoragePort implements StoragePort {
  final Map<String, String> _store = {};

  @override
  Future<String?> get(String key) async => _store[key];

  @override
  Future<void> set(String key, String value) async => _store[key] = value;

  @override
  Future<void> remove(String key) async => _store.remove(key);

  /// Expose underlying map for assertions.
  Map<String, String> get store => _store;
}

/// In-memory implementation of [RoutinePort] for testing.
class FakeRoutinePort implements RoutinePort {
  List<Routine> _routines = [];

  @override
  Future<List<Routine>> loadRoutines() async => List.of(_routines);

  @override
  Future<void> saveRoutines(List<Routine> routines) async =>
      _routines = List.of(routines);
}

/// In-memory implementation of [TrainingDayPort] for testing.
class FakeTrainingDayPort implements TrainingDayPort {
  List<TrainingDay> _days = [];

  @override
  Future<List<TrainingDay>> loadTrainingDays() async => List.of(_days);

  @override
  Future<void> saveTrainingDays(List<TrainingDay> days) async =>
      _days = List.of(days);
}

/// In-memory implementation of [WorkoutSessionPort] for testing.
class FakeWorkoutSessionPort implements WorkoutSessionPort {
  List<WorkoutSession> _sessions = [];

  @override
  Future<List<WorkoutSession>> loadSessions() async => List.of(_sessions);

  @override
  Future<void> saveSessions(List<WorkoutSession> sessions) async =>
      _sessions = List.of(sessions);

  @override
  Future<void> upsertSession(WorkoutSession session) async {
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index >= 0) {
      _sessions[index] = session;
    } else {
      _sessions.add(session);
    }
  }
}

/// In-memory implementation of [MobilitySessionPort] for testing.
class FakeMobilitySessionPort implements MobilitySessionPort {
  List<MobilitySession> _sessions = [];

  @override
  Future<List<MobilitySession>> loadSessions() async => List.of(_sessions);

  @override
  Future<void> saveSessions(List<MobilitySession> sessions) async =>
      _sessions = List.of(sessions);
}

/// In-memory implementation of [HiitSessionPort] for testing.
class FakeHiitSessionPort implements HiitSessionPort {
  List<HiitSession> _sessions = [];

  @override
  Future<List<HiitSession>> loadSessions() async => List.of(_sessions);

  @override
  Future<void> saveSessions(List<HiitSession> sessions) async =>
      _sessions = List.of(sessions);
}

/// In-memory implementation of [CustomExercisePort] for testing.
class FakeCustomExercisePort implements CustomExercisePort {
  List<Exercise> _exercises = [];

  @override
  Future<List<Exercise>> loadExercises() async => List.of(_exercises);

  @override
  Future<void> saveExercises(List<Exercise> exercises) async {
    _exercises = List.of(exercises);
  }

  @override
  Future<void> deleteExercise(String key) async {
    _exercises = _exercises.where((exercise) => exercise.key != key).toList();
  }
}

/// In-memory implementation of [MeasurementRecordPort] for testing.
class FakeMeasurementRecordPort implements MeasurementRecordPort {
  List<MeasurementRecord> _records = [];

  @override
  Future<List<MeasurementRecord>> loadRecords() async => List.of(_records);

  @override
  Future<void> saveRecords(List<MeasurementRecord> records) async =>
      _records = List.of(records);

  @override
  Future<void> addRecord(MeasurementRecord record) async {
    _records = [..._records, record];
  }
}

/// In-memory implementation of [ProfilePort] for testing.
class FakeProfilePort implements ProfilePort {
  UserProfile? _profile;
  bool _completed = false;

  @override
  Future<void> saveProfile(UserProfile profile) async {
    _profile = profile;
  }

  @override
  Future<UserProfile?> loadProfile() async => _profile;

  @override
  Future<void> markProfileCompleted() async {
    _completed = true;
  }

  @override
  Future<bool> isProfileCompleted() async => _completed;
}

/// In-memory implementation of [AuthPort] for testing.
///
/// Set [simulatedUser] to simulate an authenticated state at construction
/// or call [signInWithEmail] / [signOut] to change state dynamically.
///
/// Set [shouldThrow] to a code string to make sign-in/sign-up methods
/// throw an [AuthException] with that code (simulates auth errors).
class FakeAuthPort implements AuthPort {
  FakeAuthPort({this.simulatedUser});

  AuthUser? simulatedUser;
  String? shouldThrow;

  @override
  AuthUser? get currentUser => simulatedUser;

  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(simulatedUser);

  void _throwIfNeeded() {
    if (shouldThrow != null) {
      throw AuthException(code: shouldThrow!);
    }
  }

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    _throwIfNeeded();
    final user = AuthUser(uid: 'fake-uid', email: email);
    simulatedUser = user;
    return user;
  }

  @override
  Future<AuthUser> signUpWithEmail(String email, String password) async {
    _throwIfNeeded();
    final user = AuthUser(uid: 'fake-uid', email: email);
    simulatedUser = user;
    return user;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    _throwIfNeeded();
    const user = AuthUser(uid: 'google-uid', email: 'test@gmail.com');
    simulatedUser = user;
    return user;
  }

  @override
  Future<void> signOut() async {
    simulatedUser = null;
  }
}

/// In-memory no-op implementation of [SyncPort] for testing.
class FakeSyncPort implements SyncPort {
  String? userId;
  int pullCount = 0;
  int pushCount = 0;
  List<String> lastPushedKeys = [];

  @override
  void setUserId(String? uid) => userId = uid;

  @override
  Future<void> pullFromCloud(
      {Duration timeout = const Duration(seconds: 10)}) async {
    pullCount++;
  }

  @override
  Future<void> pushToCloud(List<String> keys) async {
    pushCount++;
    lastPushedKeys = keys;
  }
}

/// Wraps a widget with MaterialApp and localization support for widget tests.
Widget buildTestableWidget(
  Widget child, {
  Locale locale = const Locale('es'),
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: buildAppTheme(),
    home: child,
  );
}

/// Creates a sample [UserProfile] for tests.
UserProfile sampleProfile({
  String weightGoal = 'gain',
  bool withOptional = true,
}) =>
    UserProfile(
      birthDate: '2001-03-15',
      sex: 'male',
      weightKg: 80.0,
      heightCm: 180.0,
      gymExperience: '1-3',
      armSpanCm: withOptional ? 182.0 : null,
      bicepsPerimeterCm: withOptional ? 35.0 : null,
      chestPerimeterCm: withOptional ? 100.0 : null,
      waistPerimeterCm: withOptional ? 80.0 : null,
      quadPerimeterCm: withOptional ? 55.0 : null,
      calfPerimeterCm: withOptional ? 38.0 : null,
      weightGoal: weightGoal,
      targetWeightKg: weightGoal == 'maintain' ? null : 85.0,
      kcalPerDay: weightGoal == 'maintain' ? null : 2500,
      goalHistory: [GoalPhase(startDate: '2026-01-01', weightGoal: weightGoal)],
    );

/// Extension to create a profile with null optional fields.
extension UserProfileTestX on UserProfile {
  UserProfile copyWithNulls() => UserProfile(
        birthDate: birthDate,
        sex: sex,
        weightKg: weightKg,
        heightCm: heightCm,
        gymExperience: gymExperience,
        weightGoal: weightGoal,
        targetWeightKg: targetWeightKg,
        kcalPerDay: kcalPerDay,
        goalHistory: goalHistory,
      );
}
