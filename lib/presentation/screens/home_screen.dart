import 'package:flutter/material.dart';

import 'package:gym_tracker/presentation/theme/app_theme.dart';

/// Main screen - white background, minimal placeholder.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Container(),
    );
  }
}
