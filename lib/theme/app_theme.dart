import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

export 'app_colors.dart';
export 'app_tokens.dart';

/// Central Material 3 theme for the BOQ app.
abstract final class AppTheme {
  static ThemeData get light => _build(_lightScheme);
  static ThemeData get dark => _build(_darkScheme);

  static final ColorScheme _lightScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.navy,
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFE3EAF2),
        onSecondaryContainer: AppColors.navy,
        tertiary: const Color(0xFF6B7000),
        tertiaryContainer: AppColors.accent,
        onTertiaryContainer: AppColors.onAccent,
        error: AppColors.danger,
        errorContainer: AppColors.dangerContainer,
        surface: AppColors.surface,
        onSurface: AppColors.slate900,
        onSurfaceVariant: AppColors.slate600,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: AppColors.slate50,
        surfaceContainer: AppColors.slate100,
        surfaceContainerHigh: const Color(0xFFEAF0EF),
        surfaceContainerHighest: AppColors.slate200,
        outline: AppColors.slate300,
        outlineVariant: AppColors.slate200,
      );

  static final ColorScheme _darkScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFF5FD3C4),
        onPrimary: const Color(0xFF003731),
        primaryContainer: AppColors.primaryDark,
        onPrimaryContainer: const Color(0xFFBDF0E8),
        tertiaryContainer: AppColors.accent,
        onTertiaryContainer: AppColors.onAccent,
        surface: AppColors.darkSurface,
        surfaceContainerLowest: AppColors.darkBackground,
        surfaceContainerLow: AppColors.darkSurface,
        surfaceContainer: AppColors.darkSurfaceHigh,
        surfaceContainerHigh: AppColors.darkSurfaceHigh,
        surfaceContainerHighest: const Color(0xFF243634),
        outline: const Color(0xFF3E5451),
        outlineVariant: AppColors.darkOutline,
      );

  static ThemeData _build(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final background = isDark ? AppColors.darkBackground : AppColors.background;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
    );
    final textTheme = AppTypography.textTheme(
      base.textTheme,
      scheme.onSurface,
      scheme.onSurfaceVariant,
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: AppRadii.input,
      borderSide: BorderSide(color: scheme.outline),
    );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: scheme.shadow.withValues(alpha: 0.2),
        centerTitle: false,
        titleSpacing: 16,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 20),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.card,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, AppSizes.minTap),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
          textStyle: textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, AppSizes.minTap),
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, AppSizes.minTap),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, AppSizes.minTap),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(AppSizes.minTap, AppSizes.minTap),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        highlightElevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.lg)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurfaceHigh : Colors.white,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.slate400),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        secondarySelectedColor: scheme.primaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelMedium?.copyWith(color: scheme.onSurface),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onPrimaryContainer,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        checkmarkColor: scheme.primary,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        minVerticalPadding: 10,
        minTileHeight: 56,
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: textTheme.titleSmall?.copyWith(
          color: scheme.onSurface,
          fontSize: 15,
        ),
        subtitleTextStyle: textTheme.bodySmall,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            fontSize: 12,
            letterSpacing: 0.1,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(AppRadii.xl),
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: scheme.surface,
        showDragHandle: true,
        dragHandleColor: scheme.outline,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.sheet),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.xl)),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.slate200 : AppColors.slate900,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? AppColors.slate900 : Colors.white,
        ),
        actionTextColor: isDark ? AppColors.primary : AppColors.accent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        elevation: 3,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          minimumSize: const Size(0, AppSizes.minTap),
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
          side: BorderSide(color: scheme.outline),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
          textStyle: textTheme.labelLarge,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        dividerColor: scheme.outlineVariant,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
        circularTrackColor: Colors.transparent,
        refreshBackgroundColor: scheme.surface,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? scheme.onPrimary : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? scheme.primary : null,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xs - 2),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
        textStyle: textTheme.bodyMedium,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.slate800,
          borderRadius: BorderRadius.circular(AppRadii.xs),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: Colors.white),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: scheme.error,
        textColor: Colors.white,
      ),
    );
  }
}
