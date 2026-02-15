import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_tracker/data/datasources/local_storage_datasource.dart';
import 'package:gym_tracker/data/datasources/profile_datasource.dart';
import 'package:gym_tracker/data/datasources/routine_datasource.dart';
import 'package:gym_tracker/data/datasources/training_day_datasource.dart';
import 'package:gym_tracker/data/datasources/workout_session_datasource.dart';
import 'package:gym_tracker/data/datasources/mobility_session_datasource.dart';
import 'package:gym_tracker/domain/ports/profile_port.dart';
import 'package:gym_tracker/domain/ports/routine_port.dart';
import 'package:gym_tracker/domain/ports/storage_port.dart';
import 'package:gym_tracker/domain/ports/training_day_port.dart';
import 'package:gym_tracker/domain/ports/workout_session_port.dart';
import 'package:gym_tracker/domain/ports/mobility_session_port.dart';
import 'package:gym_tracker/presentation/components/language_selector.dart';
import 'package:gym_tracker/presentation/screens/loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final StoragePort storage = LocalStorageDatasource(prefs);
  final ProfilePort profilePort = ProfileDatasource(storage);
  final RoutinePort routinePort = RoutineDatasource(storage);
  final TrainingDayPort trainingDayPort = TrainingDayDatasource(storage);
  final WorkoutSessionPort workoutSessionPort =
      WorkoutSessionDatasource(storage);
  final MobilitySessionPort mobilitySessionPort =
      MobilitySessionDatasource(storage);
  runApp(GymTrackerApp(
    storage: storage,
    profilePort: profilePort,
    routinePort: routinePort,
    trainingDayPort: trainingDayPort,
    workoutSessionPort: workoutSessionPort,
    mobilitySessionPort: mobilitySessionPort,
  ));
}

class GymTrackerApp extends StatefulWidget {
  const GymTrackerApp({
    super.key,
    required this.storage,
    required this.profilePort,
    required this.routinePort,
    required this.trainingDayPort,
    required this.workoutSessionPort,
    required this.mobilitySessionPort,
  });

  final StoragePort storage;
  final ProfilePort profilePort;
  final RoutinePort routinePort;
  final TrainingDayPort trainingDayPort;
  final WorkoutSessionPort workoutSessionPort;
  final MobilitySessionPort mobilitySessionPort;

  @override
  State<GymTrackerApp> createState() => _GymTrackerAppState();
}

class _GymTrackerAppState extends State<GymTrackerApp> {
  late final LocaleStorage _localeStorage;
  Locale _locale = const Locale('es');

  // App-wide color constants
  static const _scaffoldBg = Color(0xFF1C1C1E);
  static const _surfaceColor = Color(0xFF2C2C2E);
  static const _cardColor = Color(0xFF3A3A3C);

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
      // Dark gray theme — friendlier than pure black
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _scaffoldBg,
        cardColor: _cardColor,
        colorScheme: const ColorScheme.dark(
          surface: _surfaceColor,
          primary: Colors.white,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _surfaceColor,
          foregroundColor: Colors.white,
        ),
        cardTheme: const CardThemeData(color: _cardColor),
      ),
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
        profilePort: widget.profilePort,
        storage: widget.storage,
        routinePort: widget.routinePort,
        trainingDayPort: widget.trainingDayPort,
        workoutSessionPort: widget.workoutSessionPort,
        mobilitySessionPort: widget.mobilitySessionPort,
        onLocaleChanged: _setLocale,
      ),
    );
  }
}
