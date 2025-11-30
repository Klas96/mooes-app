import 'package:flutter/material.dart';

class AppColors {
  // Primary green colors
  static const Color primaryGreen = Color(0xFF2E7D32); // Dark green
  static const Color primaryGreenLight = Color(0xFF4CAF50); // Medium green
  static const Color primaryGreenLighter = Color(0xFF66BB6A); // Light green
  static const Color primaryGreenLightest = Color(0xFF81C784); // Very light green
  
  // Accent green colors
  static const Color accentGreen = Color(0xFF00C853); // Bright green
  static const Color accentGreenLight = Color(0xFF69F0AE); // Light accent
  static const Color accentGreenDark = Color(0xFF00E676); // Dark accent
  
  // Pink/Red colors for likes and favorites
  static const Color accentPink = Color(0xFFE91E63); // Pink for likes
  static const Color accentPinkLight = Color(0xFFF48FB1); // Light pink
  
  // Gold color for premium features
  static const Color accentGold = Color(0xFFFFD700); // Gold
  
  // Yellow color for active navigation tab
  static const Color activeTabYellow = Color(0xFFFF8F00); // Darker orange-yellow for better contrast
  
  // Background and surface colors
  static const Color backgroundLight = Color(0xFFF1F8E9); // Very light green background
  static const Color backgroundDark = Color(0xFF1B5E20); // Dark green background
  static const Color surfaceLight = Color(0xFFE8F5E8); // Light green surface
  static const Color surfaceDark = Color(0xFF2E7D32); // Dark green surface
  
  // Text colors - Updated for better contrast
  static const Color textPrimaryLight = Color(0xFF0D4F14); // Darker green text for better contrast
  static const Color textSecondaryLight = Color(0xFF2E7D32); // Medium green text
  static const Color textPrimaryDark = Color(0xFFFFFFFF); // White text for maximum contrast
  static const Color textSecondaryDark = Color(0xFFE8F5E8); // Light green text
  
  // Legacy support
  static const Color tintColorLight = primaryGreen;
  static const Color tintColorDark = primaryGreenLight;
  static const Color greenLight = primaryGreenLight;
  static const Color greenDark = primaryGreen;
  static const Color greenAccent = accentGreen;

  static const Map<String, Map<String, Color>> colors = {
    'light': {
      'text': textPrimaryLight,
      'background': backgroundLight,
      'tint': primaryGreen,
      'icon': textSecondaryLight,
      'tabIconDefault': textSecondaryLight,
      'tabIconSelected': primaryGreen,
      'surface': surfaceLight,
      'primary': primaryGreen,
      'secondary': accentGreen,
    },
    'dark': {
      'text': textPrimaryDark,
      'background': backgroundDark,
      'tint': primaryGreenLight,
      'icon': textSecondaryDark,
      'tabIconDefault': textSecondaryDark,
      'tabIconSelected': primaryGreenLight,
      'surface': surfaceDark,
      'primary': primaryGreenLight,
      'secondary': accentGreenLight,
    },
  };

  static ColorScheme getColorScheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorMap = colors[isDark ? 'dark' : 'light']!;
    
    return ColorScheme(
      brightness: brightness,
      primary: colorMap['primary']!,
      onPrimary: Colors.white,
      secondary: colorMap['secondary']!,
      onSecondary: Colors.white,
      error: Colors.red,
      onError: Colors.white,
      background: colorMap['background']!,
      onBackground: colorMap['text']!,
      surface: colorMap['surface']!,
      onSurface: colorMap['text']!,
      tertiary: accentGreen,
      onTertiary: Colors.white,
    );
  }
}
