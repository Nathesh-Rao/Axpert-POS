import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Colors only the login screen needs, derived from [AppColors] (no new
/// literals). The login background photo is light in both modes, so the form
/// sits on a panel that follows the theme.
@immutable
class AppEntryColors extends ThemeExtension<AppEntryColors> {
  const AppEntryColors({
    required this.panel,
    required this.fieldFill,
    required this.fieldHoverBorder,
    required this.splashBackground,
  });

  /// Opaque panel behind the form (drawn only where the form overlaps the
  /// photo, always in dark mode).
  final Color panel;
  final Color fieldFill;
  final Color fieldHoverBorder;
  final Color splashBackground;

  static final AppEntryColors light = AppEntryColors(
    panel: AppColors.light.card,
    fieldFill: AppColors.light.card,
    fieldHoverBorder: AppColors.light.placeholder,
    splashBackground: AppColors.light.card,
  );

  static final AppEntryColors dark = AppEntryColors(
    panel: AppColors.dark.card,
    fieldFill: AppColors.dark.secondary,
    fieldHoverBorder: AppColors.dark.placeholder,
    splashBackground: AppColors.dark.background,
  );

  @override
  AppEntryColors copyWith({
    Color? panel,
    Color? fieldFill,
    Color? fieldHoverBorder,
    Color? splashBackground,
  }) => AppEntryColors(
    panel: panel ?? this.panel,
    fieldFill: fieldFill ?? this.fieldFill,
    fieldHoverBorder: fieldHoverBorder ?? this.fieldHoverBorder,
    splashBackground: splashBackground ?? this.splashBackground,
  );

  @override
  AppEntryColors lerp(ThemeExtension<AppEntryColors>? other, double t) {
    if (other is! AppEntryColors) return this;
    return AppEntryColors(
      panel: Color.lerp(panel, other.panel, t)!,
      fieldFill: Color.lerp(fieldFill, other.fieldFill, t)!,
      fieldHoverBorder: Color.lerp(
        fieldHoverBorder,
        other.fieldHoverBorder,
        t,
      )!,
      splashBackground: Color.lerp(
        splashBackground,
        other.splashBackground,
        t,
      )!,
    );
  }
}
