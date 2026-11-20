import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static const String fontFamily = 'Cairo';

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
    );

    final textTheme = base.textTheme
        .apply(
          fontFamily: fontFamily,
          bodyColor: AppColors.ink,
          displayColor: AppColors.ink,
        )
        .copyWith(
          displaySmall: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 34,
            height: 1.25,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
          headlineMedium: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 28,
            height: 1.3,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
          headlineSmall: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 23,
            height: 1.35,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
          titleLarge: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 18,
            height: 1.4,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          titleMedium: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 15.5,
            height: 1.45,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          titleSmall: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 13,
            height: 1.4,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          bodyLarge: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 15,
            height: 1.7,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
          ),
          bodyMedium: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 13.5,
            height: 1.65,
            fontWeight: FontWeight.w500,
            color: AppColors.inkSoft,
          ),
          bodySmall: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 11.5,
            height: 1.55,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
          ),
          labelLarge: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          labelMedium: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            height: 1.4,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        );

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.softBlue,
          onPrimaryContainer: AppColors.primaryDark,
          secondary: AppColors.accent,
          onSecondary: AppColors.ink,
          surface: AppColors.surface,
          onSurface: AppColors.ink,
          error: AppColors.danger,
          outline: AppColors.lineStrong,
        );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      dividerColor: AppColors.line,
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.ink,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.muted,
        ),
        prefixIconColor: AppColors.muted,
        suffixIconColor: AppColors.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: AppColors.lineStrong),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        side: const BorderSide(color: AppColors.line),
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.inkSoft,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.softBlueStrong,
        thumbColor: Colors.white,
        overlayColor: AppColors.primary.withValues(alpha: 0.08),
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 11,
          elevation: 4,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.lineStrong,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        actionTextColor: AppColors.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.softBlueStrong,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
