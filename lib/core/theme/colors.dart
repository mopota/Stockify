import 'package:flutter/material.dart';

class ColorsManager {
  // Material 3 Color Palette
  static const Color primary = Color(0xFF4A56E2);
  static const Color onPrimary = Colors.white;
  static const Color primaryContainer = Color(0xFFE0E0FF);
  static const Color onPrimaryContainer = Color(0xFF00006E);

  static const Color secondary = Color(0xFF6C63FF);
  static const Color onSecondary = Colors.white;
  static const Color secondaryContainer = Color(0xFFE0E0FF);
  static const Color onSecondaryContainer = Color(0xFF00006E);

  static const Color tertiary = Color(0xFFFFB800);
  static const Color onTertiary = Colors.white;
  static const Color tertiaryContainer = Color(0xFFFFE082);
  static const Color onTertiaryContainer = Color(0xFF261900);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Colors.white;
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  static const Color backgroundLight = Color(0xFFFEFBFF);
  static const Color onBackgroundLight = Color(0xFF1B1B1D);
  
  static const Color surfaceLight = Color(0xFFFEFBFF);
  static const Color onSurfaceLight = Color(0xFF1B1B1D);
  static const Color surfaceVariantLight = Color(0xFFE1E2EC);
  static const Color onSurfaceVariantLight = Color(0xFF44474F);

  static const Color backgroundDark = Color(0xFF1B1B1D);
  static const Color onBackgroundDark = Color(0xFFE3E2E6);
  
  static const Color surfaceDark = Color(0xFF1B1B1D);
  static const Color onSurfaceDark = Color(0xFFE3E2E6);
  static const Color surfaceVariantDark = Color(0xFF44474F);
  static const Color onSurfaceVariantDark = Color(0xFFC4C6D0);

  static const Color outline = Color(0xFF74777F);

  // For backward compatibility if needed, but we should use M3 names
  static const Color lightBackground = backgroundLight;
  static const Color lightCard = surfaceLight;
  static const Color lightTextPrimary = onSurfaceLight;
  static const Color lightTextSecondary = onSurfaceVariantLight;
  static const Color lightInputBackground = Color(0xFFF0F1F5);
  static const Color lightInputBorder = Color(0xFFDADCE3);

  static const Color darkBackground = backgroundDark;
  static const Color darkCard = surfaceDark;
  static const Color darkTextPrimary = onSurfaceDark;
  static const Color darkTextSecondary = onSurfaceVariantDark;
  static const Color darkInputBackground = Color(0xFF1A1A1A);
  static const Color darkInputBorder = Color(0xFF2A2A2A);
  
  // Legacy chat/bubble colors preserved
  static const Color bubbleMeLight = primary;
  static const Color bubbleMeLightText = Colors.white;
  static const Color bubbleOtherLight = Color(0xFFF0F1F5);
  static const Color bubbleOtherLightText = onSurfaceLight;

  static const Color bubbleMeDark = primary;
  static const Color bubbleMeDarkText = Colors.white;
  static const Color bubbleOtherDark = surfaceDark;
  static const Color bubbleOtherDarkText = onSurfaceDark;
}
