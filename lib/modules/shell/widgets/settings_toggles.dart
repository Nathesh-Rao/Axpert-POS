import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../controllers/settings_controller.dart';
import '../../../core/theme/tokens/app_icons.dart';

/// The prototype's two Settings rows (dark mode, scan beep). The full
/// Settings page is built in S5; the toggles live here so the dark theme can
/// be switched and persisted from S2 on.
class SettingsToggles extends StatelessWidget {
  const SettingsToggles({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final settings = Get.find<SettingsController>();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Obx(
        () => Column(
          children: <Widget>[
            _ToggleRow(
              icon: AppIcons.settings,
              title: s.darkModeTitle(),
              hint: s.darkModeHint(),
              value: settings.settings.value.dark,
              onChanged: settings.setDark,
            ),
            _ToggleRow(
              icon: AppIcons.volume2,
              title: s.beepTitle(),
              hint: s.beepHint(),
              value: settings.settings.value.beep,
              onChanged: settings.setBeep,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String hint;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s22),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 21, color: c.text),
            const SizedBox(width: AppSpacing.s13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: context.text
                        .of(AppFontSize.s14)
                        .copyWith(color: c.text),
                  ),
                  const SizedBox(height: AppSpacing.s5),
                  Text(
                    hint,
                    style: context.text
                        .of(AppFontSize.s12)
                        .copyWith(color: c.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s20),
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: c.blue,
              checkColor: c.white,
              side: BorderSide(color: c.radioBorder, width: 1.5),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
