import 'package:flutter/material.dart';

/// Centralized design tokens for the Gym Tracker app.
///
/// All hardcoded colours, spacings and sizes used across screens
/// are collected here so changes propagate consistently.
abstract final class AppColors {
  // Shared colors
  static const success = Color(0xFF34C759);
  static const destructive = Color(0xFFFF3B30);
  static const restTimer = Color(0xFF007AFF);

  // Dark Theme Colors
  static const darkScaffoldBg = Color(0xFF1C1C1E);
  static const darkSurface = Color(0xFF2C2C2E);
  static const darkCard = Color(0xFF3A3A3C);
  static const darkPrimary = Colors.white;
  static const darkTextPrimary = Colors.white;
  static const darkTextSecondary = Colors.white70;
  static const darkTextSubtle = Colors.white38;
  static const darkBorder = Color(0xFF3A3A3C);

  // Light Theme Colors
  static const lightScaffoldBg = Color(0xFFF2F2F7);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightPrimary = Color(0xFF1C1C1E);
  static const lightTextPrimary = Color(0xFF000000);
  static const lightTextSecondary = Color(0xFF3C3C43); // ~60% opacity
  static const lightTextSubtle = Color(0x4D3C3C43); // ~30% opacity
  static const lightBorder = Color(0xFFE5E5EA);

  // Legacy aliases (deprecated, to be migrated)
  static const scaffoldBg = darkScaffoldBg;
  static const surface = darkSurface;
  static const card = darkCard;
  static const subtleText = darkTextSubtle;
  static const secondaryText = darkTextSecondary;
  static const bodyText = darkTextPrimary;
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

/// Extensions for easy theme color access
extension ThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get scaffoldBg => Theme.of(this).scaffoldBackgroundColor;
  Color get surface => Theme.of(this).colorScheme.surface;
  Color get card => Theme.of(this).cardColor;
  Color get primary => Theme.of(this).colorScheme.primary;

  Color get textPrimary =>
      isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  Color get textSecondary =>
      isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get textSubtle =>
      isDarkMode ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;
  Color get border => isDarkMode ? AppColors.darkBorder : AppColors.lightBorder;
}

/// Builds the app's dark theme using the centralized design tokens.
ThemeData buildDarkTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkScaffoldBg,
      cardColor: AppColors.darkCard,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.darkSurface,
        primary: AppColors.darkPrimary,
        onSurface: AppColors.darkTextPrimary,
        onPrimary: AppColors.darkScaffoldBg,
        error: AppColors.destructive,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(AppSizes.borderRadius)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        space: 1,
      ),
    );

/// Builds the app's light theme using the centralized design tokens.
ThemeData buildLightTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightScaffoldBg,
      cardColor: AppColors.lightCard,
      colorScheme: const ColorScheme.light(
        surface: AppColors.lightSurface,
        primary: AppColors.lightPrimary,
        onSurface: AppColors.lightTextPrimary,
        onPrimary: AppColors.lightScaffoldBg,
        error: AppColors.destructive,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 1, // Slight shadow in light mode
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(AppSizes.borderRadius)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        space: 1,
      ),
    );

// Legacy method pointing to dark theme for backward compatibility during migration
ThemeData buildAppTheme() => buildDarkTheme();
