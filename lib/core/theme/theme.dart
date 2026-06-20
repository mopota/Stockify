import 'package:flutter/material.dart';
import 'colors.dart';
import 'text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: ColorsManager.primary,
      brightness: Brightness.light,
      primary: ColorsManager.primary,
      onPrimary: ColorsManager.onPrimary,
      primaryContainer: ColorsManager.primaryContainer,
      onPrimaryContainer: ColorsManager.onPrimaryContainer,
      secondary: ColorsManager.secondary,
      onSecondary: ColorsManager.onSecondary,
      secondaryContainer: ColorsManager.secondaryContainer,
      onSecondaryContainer: ColorsManager.onSecondaryContainer,
      tertiary: ColorsManager.tertiary,
      onTertiary: ColorsManager.onTertiary,
      tertiaryContainer: ColorsManager.tertiaryContainer,
      onTertiaryContainer: ColorsManager.onTertiaryContainer,
      error: ColorsManager.error,
      onError: ColorsManager.onError,
      errorContainer: ColorsManager.errorContainer,
      onErrorContainer: ColorsManager.onErrorContainer,
      surface: ColorsManager.backgroundLight,
      onSurface: ColorsManager.onSurfaceLight,
      surfaceContainerHighest: ColorsManager.surfaceVariantLight,
      onSurfaceVariant: ColorsManager.onSurfaceVariantLight,
      outline: ColorsManager.outline,
    ),

    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: ColorsManager.backgroundLight,
      foregroundColor: ColorsManager.onSurfaceLight,
      titleTextStyle: TextStylesManager.bold22.copyWith(
        color: ColorsManager.onSurfaceLight,
        fontSize: 20,
      ),
    ),

    cardTheme: CardThemeData(
      color: ColorsManager.surfaceLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: ColorsManager.outline.withValues(alpha: 0.1)),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorsManager.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ColorsManager.surfaceVariantLight.withValues(alpha: 0.3),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: ColorsManager.primary,
          width: 1.5,
        ),
      ),
      hintStyle: TextStyle(color: ColorsManager.onSurfaceVariantLight.withValues(alpha: 0.6)),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: ColorsManager.backgroundLight,
      indicatorColor: ColorsManager.primaryContainer,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: ColorsManager.onPrimaryContainer);
        }
        return const IconThemeData(color: ColorsManager.onSurfaceVariantLight);
      }),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: ColorsManager.primary,
      brightness: Brightness.dark,
      primary: ColorsManager.primary,
      onPrimary: ColorsManager.onPrimary,
      primaryContainer: const Color(0xFF333CB3),
      onPrimaryContainer: const Color(0xFFE0E0FF),
      secondary: ColorsManager.secondary,
      onSecondary: ColorsManager.onSecondary,
      secondaryContainer: const Color(0xFF4C42CC),
      onSecondaryContainer: const Color(0xFFE0E0FF),
      tertiary: ColorsManager.tertiary,
      onTertiary: ColorsManager.onTertiary,
      tertiaryContainer: const Color(0xFF7A5900),
      onTertiaryContainer: const Color(0xFFFFE082),
      error: ColorsManager.error,
      onError: ColorsManager.onError,
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),
      surface: ColorsManager.backgroundDark,
      onSurface: ColorsManager.onSurfaceDark,
      surfaceContainerHighest: ColorsManager.surfaceVariantDark,
      onSurfaceVariant: ColorsManager.onSurfaceVariantDark,
      outline: ColorsManager.outline,
    ),

    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: ColorsManager.backgroundDark,
      foregroundColor: ColorsManager.onSurfaceDark,
      titleTextStyle: TextStylesManager.bold22.copyWith(
        color: ColorsManager.onSurfaceDark,
        fontSize: 20,
      ),
    ),

    cardTheme: CardThemeData(
      color: ColorsManager.surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: ColorsManager.outline.withValues(alpha: 0.1)),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorsManager.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ColorsManager.surfaceVariantDark.withValues(alpha: 0.2),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: ColorsManager.primary,
          width: 1.5,
        ),
      ),
      hintStyle: TextStyle(color: ColorsManager.onSurfaceVariantDark.withValues(alpha: 0.6)),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: ColorsManager.backgroundDark,
      indicatorColor: const Color(0xFF333CB3),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: Color(0xFFE0E0FF));
        }
        return const IconThemeData(color: ColorsManager.onSurfaceVariantDark);
      }),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ),
  );
}
