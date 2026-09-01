import 'package:flutter/material.dart';

class AppColors {
  // Primary Blue System
  static const Color primary = Color(0xFF1E40AF); // Deep Royal Blue
  static const Color primaryDark = Color(0xFF1E3A8A); // Midnight Navy Blue
  static const Color primaryLight = Color(0xFF2563EB); // Vibrant Royal Blue
  static const Color primaryAccent = Color(0xFF3B82F6); // Electric Blue
  static const Color primarySky = Color(0xFF0284C7); // Sky Blue Accent
  
  // Soft Blue Tints & Highlights
  static const Color softBlue = Color(0xFFEFF6FF); // Ultra-light Blue Tint
  static const Color softBlueHover = Color(0xFFDBEAFE); // Light Blue Hover
  static const Color blueBorder = Color(0xFFBFDBFE); // Soft Blue Border
  static const Color blueBadgeBg = Color(0xFFE0F2FE); // Cyan-Blue Badge
  static const Color blueBadgeText = Color(0xFF0369A1); // Deep Cyan-Blue Badge Text

  // Neutrals & Surfaces
  static const Color background = Color(0xFFF8FAFC); // Clean Canvas Background
  static const Color surface = Color(0xFFFFFFFF); // Pitch White Surface
  static const Color cardBorder = Color(0xFFE2E8F0); // Subtle Slate Border
  static const Color cardBorderDarker = Color(0xFFCBD5E1); // Defined Border
  static const Color divider = Color(0xFFE2E8F0);

  // Text Hierarchy
  static const Color textPrimary = Color(0xFF0F172A); // High Contrast Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color textLight = Color(0xFF94A3B8); // Slate 400
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White on Blue

  // Status & Utility Colors (Harmonized)
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFEFF6FF);

  // Premium Blue Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
  );

  static const LinearGradient vibrantBlueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D4ED8), Color(0xFF38BDF8)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF), Color(0xFF2563EB)],
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF0F5FF)],
  );
}
