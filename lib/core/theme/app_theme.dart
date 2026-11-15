import 'package:flutter/material.dart';

import '../models/accessibility_settings.dart';

abstract final class AppTheme {
  static const _seedColor = Color(0xFF1B5E7A);
  static const _surfaceColor = Color(0xFFF7F4EF);
  static const _onSurfaceColor = Color(0xFF1A1A1A);

  static ThemeData build(AppAccessibilitySettings settings) {
    if (settings.highContrast) {
      return _highContrastTheme(settings);
    }
    return _standardTheme(settings);
  }

  static ThemeData _standardTheme(AppAccessibilitySettings settings) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
      surface: _surfaceColor,
      onSurface: _onSurfaceColor,
    );

    return _baseTheme(colorScheme, settings, cardColor: Colors.white);
  }

  static ThemeData _highContrastTheme(AppAccessibilitySettings settings) {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF000000),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFFFFD600),
      onSecondary: Color(0xFF000000),
      error: Color(0xFFB00020),
      onError: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF000000),
      primaryContainer: Color(0xFF000000),
      onPrimaryContainer: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFFFD600),
      onSecondaryContainer: Color(0xFF000000),
      outline: Color(0xFF000000),
      outlineVariant: Color(0xFF000000),
    );

    return _baseTheme(colorScheme, settings, cardColor: Colors.white).copyWith(
      dividerColor: Colors.black,
      dividerTheme: const DividerThemeData(color: Colors.black, thickness: 2),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black, width: 3),
        ),
      ),
    );
  }

  static ThemeData _baseTheme(
    ColorScheme colorScheme,
    AppAccessibilitySettings settings, {
    required Color cardColor,
  }) {
    final scale = settings.textScaleFactor;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: _accessibleTextTheme(colorScheme.onSurface, scale),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        titleTextStyle: TextStyle(
          fontSize: 24 * scale,
          fontWeight: FontWeight.w700,
          color: colorScheme.onPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: settings.highContrast ? 0 : 2,
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: Size.fromHeight(56 * scale),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16 * scale),
          textStyle: TextStyle(
            fontSize: 20 * scale,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: 16 * scale,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8 * scale),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18 * scale,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static TextTheme _accessibleTextTheme(Color color, double scale) {
    final base = TextTheme(
      headlineLarge: TextStyle(fontSize: 34 * scale, fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(fontSize: 28 * scale, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(fontSize: 24 * scale, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 20 * scale, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 20 * scale, height: 1.5),
      bodyMedium: TextStyle(fontSize: 18 * scale, height: 1.5),
      labelLarge: TextStyle(fontSize: 18 * scale, fontWeight: FontWeight.w600),
    );

    return base.apply(bodyColor: color, displayColor: color);
  }
}
