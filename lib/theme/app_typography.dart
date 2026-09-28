import 'package:flutter/material.dart';

/// Type scale tuned for a dense business app: tighter headings, semi-bold
/// titles and comfortable body text.
abstract final class AppTypography {
  static TextTheme textTheme(TextTheme base, Color onSurface, Color muted) {
    final t = base.apply(bodyColor: onSurface, displayColor: onSurface);
    return t.copyWith(
      displaySmall: t.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineLarge: t.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: t.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      headlineSmall: t.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleLarge: t.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: t.bodyLarge?.copyWith(height: 1.45),
      bodyMedium: t.bodyMedium?.copyWith(height: 1.4),
      bodySmall: t.bodySmall?.copyWith(color: muted, height: 1.35),
      labelLarge: t.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: t.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: muted,
      ),
      labelSmall: t.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: muted,
      ),
    );
  }
}
