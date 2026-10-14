import 'package:flutter/material.dart';

import 'tokens/app_colors.dart';
import 'tokens/app_entry_colors.dart';
import 'tokens/app_rail_theme.dart';
import 'tokens/app_typography.dart';

/// Central light/dark [ThemeData]. Dark replicates only the prototype's
/// 13 `.dark` rules (UNVERIFIED VISUALLY, known_gaps.md section C).
abstract final class AppTheme {
  static ThemeData get light => _build(
    Brightness.light,
    AppColors.light,
    AppEntryColors.light,
    AppRailTheme.light,
  );
  static ThemeData get dark => _build(
    Brightness.dark,
    AppColors.dark,
    AppEntryColors.dark,
    AppRailTheme.dark,
  );

  static ThemeData _build(
    Brightness brightness,
    AppColors c,
    AppEntryColors entry,
    AppRailTheme rail,
  ) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.white,
      secondary: c.blue,
      onSecondary: c.white,
      error: c.actionRedFg,
      onError: c.white,
      surface: c.card,
      onSurface: c.text,
      outline: c.border,
    );
    final base = ThemeData(brightness: brightness).textTheme;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      dividerColor: c.border,
      splashFactory: NoSplash.splashFactory,
      textTheme: AppTypography.textTheme(base, c.text),
      extensions: <ThemeExtension<dynamic>>[
        c,
        entry,
        rail,
        const AppTextStyles(),
      ],
    );
  }
}
