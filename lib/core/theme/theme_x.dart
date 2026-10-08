import 'package:flutter/material.dart';

import 'tokens/app_colors.dart';
import 'tokens/app_typography.dart';

/// Shortcuts to the theme extensions: `context.colors`, `context.text`.
/// Static tokens (AppSpacing, AppRadii, AppSizes, AppShadows, AppMotion) are
/// used directly and need no context.
extension ThemeX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  AppTextStyles get text => Theme.of(this).extension<AppTextStyles>()!;
}
