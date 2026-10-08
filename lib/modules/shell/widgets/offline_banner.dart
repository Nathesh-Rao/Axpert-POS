import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../shared/controllers/shell_chrome_controller.dart';

/// Shown under the top bar while the online chip is switched to offline.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final chrome = Get.find<ShellChromeController>();
    return Obx(() {
      if (chrome.online.value) return const SizedBox.shrink();
      final c = context.colors;
      return Container(
        width: double.infinity,
        color: c.offlineBannerBg,
        padding: const EdgeInsets.all(AppSpacing.s6),
        alignment: Alignment.center,
        child: Text(
          context.strings.offlineBanner(),
          style: context.text
              .of(AppFontSize.s14)
              .copyWith(color: c.offlineBannerFg),
        ),
      );
    });
  }
}
