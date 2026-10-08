import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/debug/theme_swatch_page.dart';

// TEMPORARY (DEC-065): debug-only swatch, deleted in step 1.4c.
const bool _swatchFlag = bool.fromEnvironment('SWATCH');

bool get _showSwatch =>
    kDebugMode &&
    (_swatchFlag || Uri.base.queryParameters.containsKey('swatch'));

void main() {
  runApp(const PosApp());
}

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      home: _showSwatch
          ? const ThemeSwatchPage()
          : const Scaffold(body: SizedBox.shrink()),
    );
  }
}
