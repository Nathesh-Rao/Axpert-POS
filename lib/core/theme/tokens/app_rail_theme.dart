import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Colors of the side rail card, derived from [AppColors] (no new literals):
/// the selected square is the primary color at low alpha.
@immutable
class AppRailTheme extends ThemeExtension<AppRailTheme> {
  const AppRailTheme({
    required this.icon,
    required this.iconSelected,
    required this.iconDisabled,
    required this.hoverBackground,
    required this.pressedBackground,
    required this.selectedBackground,
    required this.divider,
  });

  static const double _selectedAlpha = 0.12;
  static const double _pressedAlpha = 0.08;
  static const double _disabledAlpha = 0.4;

  final Color icon;
  final Color iconSelected;
  final Color iconDisabled;
  final Color hoverBackground;
  final Color pressedBackground;
  final Color selectedBackground;
  final Color divider;

  static AppRailTheme _from(AppColors c) => AppRailTheme(
    icon: c.muted,
    iconSelected: c.primary,
    iconDisabled: c.muted.withValues(alpha: _disabledAlpha),
    hoverBackground: c.sidebarHover,
    pressedBackground: c.primary.withValues(alpha: _pressedAlpha),
    selectedBackground: c.primary.withValues(alpha: _selectedAlpha),
    divider: c.border,
  );

  static final AppRailTheme light = _from(AppColors.light);
  static final AppRailTheme dark = _from(AppColors.dark);

  @override
  AppRailTheme copyWith({
    Color? icon,
    Color? iconSelected,
    Color? iconDisabled,
    Color? hoverBackground,
    Color? pressedBackground,
    Color? selectedBackground,
    Color? divider,
  }) => AppRailTheme(
    icon: icon ?? this.icon,
    iconSelected: iconSelected ?? this.iconSelected,
    iconDisabled: iconDisabled ?? this.iconDisabled,
    hoverBackground: hoverBackground ?? this.hoverBackground,
    pressedBackground: pressedBackground ?? this.pressedBackground,
    selectedBackground: selectedBackground ?? this.selectedBackground,
    divider: divider ?? this.divider,
  );

  @override
  AppRailTheme lerp(ThemeExtension<AppRailTheme>? other, double t) {
    if (other is! AppRailTheme) return this;
    return AppRailTheme(
      icon: Color.lerp(icon, other.icon, t)!,
      iconSelected: Color.lerp(iconSelected, other.iconSelected, t)!,
      iconDisabled: Color.lerp(iconDisabled, other.iconDisabled, t)!,
      hoverBackground: Color.lerp(hoverBackground, other.hoverBackground, t)!,
      pressedBackground: Color.lerp(
        pressedBackground,
        other.pressedBackground,
        t,
      )!,
      selectedBackground: Color.lerp(
        selectedBackground,
        other.selectedBackground,
        t,
      )!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}
