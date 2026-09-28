import 'package:flutter/material.dart';

/// Brand and neutral palette for the BOQ app.
///
/// Screens should prefer `Theme.of(context).colorScheme` roles; these raw
/// values exist for the theme itself and for semantic status colours that
/// Material's scheme has no role for (success, warning, info).
abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF05645B);
  static const primaryDark = Color(0xFF044F48);
  static const primaryContainer = Color(0xFFD3EEEA);
  static const onPrimaryContainer = Color(0xFF00201C);
  static const accent = Color(0xFFD7DF21);
  static const onAccent = Color(0xFF2A2C00);
  static const navy = Color(0xFF102A43);

  // Slate neutrals
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1E293B);
  static const slate900 = Color(0xFF0F172A);

  // Surfaces
  static const background = Color(0xFFF4F7F6);
  static const surface = Colors.white;

  // Semantic
  static const success = Color(0xFF15803D);
  static const successContainer = Color(0xFFDCFCE7);
  static const warning = Color(0xFFB45309);
  static const warningContainer = Color(0xFFFEF3C7);
  static const danger = Color(0xFFBE123C);
  static const dangerContainer = Color(0xFFFFE4E6);
  static const info = Color(0xFF1D4ED8);
  static const infoContainer = Color(0xFFDBEAFE);

  // Dark theme surfaces
  static const darkBackground = Color(0xFF0B1514);
  static const darkSurface = Color(0xFF12201E);
  static const darkSurfaceHigh = Color(0xFF1A2B29);
  static const darkOutline = Color(0xFF2C3E3B);
}
