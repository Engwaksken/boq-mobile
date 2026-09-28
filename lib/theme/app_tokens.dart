import 'package:flutter/widgets.dart';

/// Spacing scale (4dp grid).
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Standard page padding for scrollable screens.
  static const EdgeInsets page = EdgeInsets.fromLTRB(16, 12, 16, 24);

  /// Padding inside cards.
  static const EdgeInsets card = EdgeInsets.all(16);

  /// Gap between stacked cards / sections.
  static const double sectionGap = 20;
  static const double itemGap = 12;
}

/// Corner radii.
abstract final class AppRadii {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
  static const BorderRadius input = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius button = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}

/// Minimum interactive sizes.
abstract final class AppSizes {
  static const double minTap = 48;
  static const double buttonHeight = 52;
  static const double iconBadge = 40;
}
