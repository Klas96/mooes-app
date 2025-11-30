import 'package:flutter/material.dart';

class AppColors {
  // Core palette inspired by the new Mooves mockups
  static const Color primaryPurple = Color(0xFF5A3BFF);
  static const Color primaryPurpleLight = Color(0xFF7A5CFF);
  static const Color accentCoral = Color(0xFFFF9B8B);
  static const Color accentCoralDark = Color(0xFFE57373);
  
  // Pink color variations for backgrounds - very light for maximum contrast with dark text
  static const Color pinkLight = Color(0xFFFFF8F6); // Very light pink
  static const Color pinkMedium = Color(0xFFFFF0ED); // Medium pink
  static const Color pinkBackground = Color(0xFFFFFCFA); // Extremely light pink background for best contrast
  static const Color pinkAccent = Color(0xFFFFD4D0); // Accent pink
  static const Color pinkCard = Color(0xFFFFFAF8); // Very light pink for cards for better contrast
  
  static const Color backgroundPeach = Color(0xFFF7DCCB);
  static const Color backgroundPink = pinkBackground; // Use pink as main background
  static const Color backgroundDeep = Color(0xFF1F1630);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceTinted = Color(0xFFFFF1E8);
  static const Color surfacePink = pinkCard; // Pink surface for cards
  static const Color surfaceDark = Color(0xFF2A1F3C);
  // Darker text colors for better contrast on pink backgrounds
  static const Color textPrimary = Color(0xFF0A0508); // Very dark text for excellent contrast
  static const Color textSecondary = Color(0xFF4A2D35); // Darker secondary text
  static const Color textOnDark = Colors.white;
  static const Color textOnPink = Color(0xFF0A0508); // Very dark text for pink backgrounds

  // Legacy aliases (until all references migrate)
  static const Color primaryGreen = primaryPurple;
  static const Color primaryGreenLight = primaryPurpleLight;
  static const Color primaryGreenLightest = surfaceTinted;
  static const Color accentGreen = accentCoral;
  static const Color accentGreenLight = accentCoral;
  static const Color textPrimaryLight = textPrimary;
  static const Color textSecondaryLight = textSecondary;
  static const Color textPrimaryDark = textOnDark;
  static const Color textSecondaryDark = Colors.white70;
  static const Color surfaceAltLight = surfaceTinted;
  static const Color backgroundLight = backgroundPeach;
  static const Color backgroundDark = backgroundDeep;
  static const Color tintColorLight = primaryPurple;
  static const Color tintColorDark = primaryPurpleLight;
  static const Color activeTabYellow = accentCoral;

  static const Map<String, Map<String, Color>> colors = {
    'light': {
      'text': textPrimary,
      'textSecondary': textSecondary,
      'background': backgroundPink, // Use pink as main background
      'surface': surfacePink, // Use pink for surfaces
      'surfaceAlt': pinkMedium, // Medium pink for alternate surfaces
      'primary': primaryPurple,
      'primaryVariant': primaryPurpleLight,
      'secondary': accentCoral,
      'secondaryVariant': accentCoralDark,
      'tint': primaryPurple,
    },
    'dark': {
      'text': textOnDark,
      'textSecondary': Colors.white70,
      'background': backgroundDeep,
      'surface': surfaceDark,
      'surfaceAlt': Color(0xFF36284C),
      'primary': primaryPurpleLight,
      'primaryVariant': Color(0xFF9C7CFF),
      'secondary': accentCoral,
      'secondaryVariant': accentCoralDark,
      'tint': primaryPurpleLight,
    },
  };

  static ColorScheme getColorScheme(Brightness brightness) {
    final scheme = colors[brightness == Brightness.dark ? 'dark' : 'light']!;
    return ColorScheme(
      brightness: brightness,
      primary: scheme['primary']!,
      onPrimary: Colors.white,
      secondary: scheme['secondary']!,
      onSecondary: Colors.white,
      error: Colors.red.shade400,
      onError: Colors.white,
      background: scheme['background']!,
      onBackground: scheme['text']!,
      surface: scheme['surface']!,
      onSurface: scheme['text']!,
      tertiary: scheme['secondaryVariant']!,
      onTertiary: Colors.white,
    );
  }

  static Color textColor(Brightness brightness) =>
      colors[brightness == Brightness.dark ? 'dark' : 'light']!['text']!;

  static Color textSecondaryColor(Brightness brightness) => colors[
      brightness == Brightness.dark ? 'dark' : 'light']!['textSecondary']!;

  static Color surfaceAlt(Brightness brightness) =>
      colors[brightness == Brightness.dark ? 'dark' : 'light']!['surfaceAlt']!;
}
