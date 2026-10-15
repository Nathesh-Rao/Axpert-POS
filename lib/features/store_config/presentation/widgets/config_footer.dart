import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../shared/widgets/kbd_chip.dart';
import '../../../../shared/widgets/modal_actions.dart';
import '../controllers/store_config_controller.dart';
import 'config_primitives.dart';

/// Problems found by the last save attempt, the key hints and Cancel / Save.
class ConfigFooter extends StatelessWidget {
  const ConfigFooter({required this.controller, super.key});

  final StoreConfigController controller;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    final muted = configNoteStyle(context);
    return Obx(() {
      final problems = controller.issues.toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final issue in problems)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s4),
              child: Text(
                controller.issueText(issue),
                style: muted.copyWith(color: c.validation),
              ),
            ),
          if (!controller.canEdit)
            Text(s.scReadOnly(), style: muted)
          else ...<Widget>[
            ModalActions(
              secondaryLabel: s.scCancel(),
              onSecondary: controller.cancel,
              primaryLabel: controller.saving.value ? s.scSaving() : s.scSave(),
              primaryEnabled: !controller.saving.value,
              onPrimary: controller.requestSave,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                KbdChip(s.keyEscape()),
                const SizedBox(width: AppSpacing.s6),
                Text(s.scHintCancel(), style: muted),
                const SizedBox(width: AppSpacing.s12),
                KbdChip(s.keyEnter()),
                const SizedBox(width: AppSpacing.s6),
                Text(s.scHintSave(), style: muted),
              ],
            ),
          ],
        ],
      );
    });
  }
}
