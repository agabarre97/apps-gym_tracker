import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_tracker/data/datasources/firebase_auth_datasource.dart';
import 'package:gym_tracker/data/datasources/local_storage_datasource.dart';
import 'package:gym_tracker/data/datasources/profile_datasource.dart';
import 'package:gym_tracker/data/datasources/routine_datasource.dart';
import 'package:gym_tracker/data/datasources/synced_storage_datasource.dart';
import 'package:gym_tracker/data/datasources/training_day_datasource.dart';
import 'package:gym_tracker/domain/ports/sync_port.dart';
import 'package:gym_tracker/data/datasources/workout_session_datasource.dart';
import 'package:gym_tracker/data/datasources/mobility_session_datasource.dart';
import 'package:gym_tracker/data/datasources/hiit_session_datasource.dart';
import 'package:gym_tracker/domain/ports/auth_port.dart';
import 'package:gym_tracker/domain/ports/profile_port.dart';
import 'package:gym_tracker/domain/ports/routine_port.dart';
import 'package:gym_tracker/domain/ports/storage_port.dart';
import 'package:gym_tracker/domain/ports/training_day_port.dart';
import 'package:gym_tracker/domain/ports/workout_session_port.dart';
import 'package:gym_tracker/domain/ports/mobility_session_port.dart';
import 'package:gym_tracker/domain/ports/hiit_session_port.dart';
import 'package:gym_tracker/firebase_options.dart';
import 'package:gym_tracker/presentation/components/language_selector.dart';
import 'package:gym_tracker/presentation/screens/loading_screen.dart';
import 'package:gym_tracker/presentation/theme/app_theme.dart';

/// Returns true if the current platform supports Firebase (Android, iOS, web).
bool get _firebaseSupported {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final localStorage = LocalStorageDatasource(prefs);

  AuthPort? authPort;
  SyncedStorageDatasource? syncedStorage;
  StoragePort storage = localStorage;

  if (_firebaseSupported) {
    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);

      authPort = FirebaseAuthDatasource();
      syncedStorage = SyncedStorageDatasource(
        local: localStorage,
        firestore: FirebaseFirestore.instance,
      );

      if (authPort.currentUser != null) {
        syncedStorage.setUserId(authPort.currentUser!.uid);
      }

      storage = syncedStorage;
    } catch (e) {
      dev.log('Firebase init failed, falling back to local-only: $e');
    }
  } else {
    dev.log('Firebase not supported on this platform, using local storage');
  }

  final ProfilePort profilePort = ProfileDatasource(storage);
  final RoutinePort routinePort = RoutineDatasource(storage);
  final TrainingDayPort trainingDayPort = TrainingDayDatasource(storage);
  final WorkoutSessionPort workoutSessionPort =
      WorkoutSessionDatasource(storage);
  final MobilitySessionPort mobilitySessionPort =
      MobilitySessionDatasource(storage);
  final HiitSessionPort hiitSessionPort =
      HiitSessionDatasource(storage);

  runApp(GymTrackerApp(
    storage: storage,
    syncedStorage: syncedStorage,
    authPort: authPort,
    profilePort: profilePort,
    routinePort: routinePort,
    trainingDayPort: trainingDayPort,
    workoutSessionPort: workoutSessionPort,
    mobilitySessionPort: mobilitySessionPort,
    hiitSessionPort: hiitSessionPort,
  ));
}

class GymTrackerApp extends StatefulWidget {
  const GymTrackerApp({
    super.key,
    required this.storage,
    this.syncedStorage,
    this.authPort,
    required this.profilePort,
    required this.routinePort,
    required this.trainingDayPort,
    required this.workoutSessionPort,
    required this.mobilitySessionPort,
    required this.hiitSessionPort,
  });

  final StoragePort storage;
  final SyncPort? syncedStorage;
  final AuthPort? authPort;
  final ProfilePort profilePort;
  final RoutinePort routinePort;
  final TrainingDayPort trainingDayPort;
  final WorkoutSessionPort workoutSessionPort;
  final MobilitySessionPort mobilitySessionPort;
  final HiitSessionPort hiitSessionPort;

  @override
  State<GymTrackerApp> createState() => _GymTrackerAppState();
}

class _GymTrackerAppState extends State<GymTrackerApp> {
  late final LocaleStorage _localeStorage;
  Locale _locale = const Locale('es');

  @override
  void initState() {
    super.initState();
    _localeStorage = LocaleStorage(widget.storage);
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final saved = await _localeStorage.load();
    setState(() => _locale = saved);
  }

  void _setLocale(Locale locale) {
    setState(() => _locale = locale);
    _localeStorage.save(locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym Tracker',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // i18n
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: LoadingScreen(
        authPort: widget.authPort,
        syncedStorage: widget.syncedStorage,
        profilePort: widget.profilePort,
        storage: widget.storage,
        routinePort: widget.routinePort,
        trainingDayPort: widget.trainingDayPort,
        workoutSessionPort: widget.workoutSessionPort,
        mobilitySessionPort: widget.mobilitySessionPort,
        hiitSessionPort: widget.hiitSessionPort,
        onLocaleChanged: _setLocale,
      ),
    );
  }
}
