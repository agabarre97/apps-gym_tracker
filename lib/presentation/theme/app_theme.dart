import 'package:flutter/material.dart';

/// Centralized design tokens for the Gym Tracker app.
///
/// All hardcoded colours, spacings and sizes used across screens
/// are collected here so changes propagate consistently.
abstract final class AppColors {
  static const scaffoldBg = Color(0xFF1C1C1E);
  static const surface = Color(0xFF2C2C2E);
  static const card = Color(0xFF3A3A3C);
  static const subtleText = Colors.white38;
  static const secondaryText = Colors.white54;
  static const bodyText = Colors.white70;
}

abstract final class AppSizes {
  static const double iconSmall = 18;
  static const double iconMedium = 20;
  static const double iconLarge = 28;
  static const double iconXLarge = 64;
  static const double borderRadius = 12;
  static const double borderRadiusLarge = 16;
  static const double buttonHeight = 52;
  static const double buttonHeightSmall = 44;
  static const double buttonHeightLarge = 56;
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
}

/// Builds the app's dark theme using the centralized design tokens.
ThemeData buildAppTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.scaffoldBg,
      cardColor: AppColors.card,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: Colors.white,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
      ),
      cardTheme: const CardThemeData(color: AppColors.card),
    );
