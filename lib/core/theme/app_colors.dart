import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand Palette - Ryzon Vibrant Blue (Matching Prototypes)
  static const Color primary = Color(0xFF0A52E2); // Vibrant Royal Blue
  static const Color primaryDark = Color(0xFF003DB8);
  static const Color primaryLight = Color(0xFFE8F0FE);
  static const Color primaryContainer = Color(0xFFF0F5FF);

  // Accent & Secondary
  static const Color secondary = Color(0xFF1E293B);
  static const Color secondaryLight = Color(0xFFF1F5F9);

  // Background & Surface
  static const Color background = Color(0xFFF6F9FD); // Soft light blue-white background
  static const Color backgroundGradientStart = Color(0xFFF4F8FF);
  static const Color backgroundGradientEnd = Color(0xFFE9F1FE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF8FAFC);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // Splash Screen Brand Blue
  static const Color splashBackground = Color(0xFF1A64F8);

  // Decorative Shapes
  static const Color shapeGlowLight = Color(0x1F0A52E2);
  static const Color shapeBorderOutline = Color(0x3D0A52E2);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFFCBD5E1);
  static const Color inputBorder = Color(0xFFEFF2F7);

  // Text Colors
  static const Color textPrimary = Color(0xFF0B1527); // Dark navy/black header text
  static const Color textSecondary = Color(0xFF475569); // Slate grey subtitle text
  static const Color textMuted = Color(0xFF94A3B8); // Light grey helper text
  static const Color textInverse = Color(0xFFFFFFFF);

  // Status Indicators
  static const Color success = Color(0xFF10B981); // Emerald green checkmark
  static const Color successBg = Color(0xFFD1FADF);
  
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFEF2F2);
  
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFFBEB);
  
  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0xFFEFF6FF);

  // Shimmer / Loading
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF8FAFC);
}
