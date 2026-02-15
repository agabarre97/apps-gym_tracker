import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/datasources/local_storage_datasource.dart';
import 'domain/ports/storage_port.dart';
import 'presentation/screens/home_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final StoragePort storage = LocalStorageDatasource(prefs);
  runApp(GymTrackerApp(storage: storage));
}

class GymTrackerApp extends StatelessWidget {
  const GymTrackerApp({super.key, required this.storage});

  final StoragePort storage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym Tracker',
      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
