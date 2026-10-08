import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_strings_x.dart';
import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_typography.dart';
import '../controllers/overlay_controller.dart';
import 'app_modal.dart';
import 'modal_actions.dart';

/// "Confirm action" dialog: question, Cancel and Confirm. Like the prototype,
/// the primary button carries a 20 px top margin inside the flex row, so the
/// secondary button stretches to the taller row.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final overlay = Get.find<OverlayController>();
    return AppModal(
      title: s.confirmTitle(),
      children: <Widget>[
        Text(
          text,
          style: context.text
              .of(AppFontSize.s14, height: AppLineHeight.modalBody)
              .copyWith(color: c.text),
        ),
        ModalActions(
          secondaryLabel: s.confirmCancel(),
          onSecondary: overlay.close,
          primaryLabel: s.confirmAccept(),
          onPrimary: overlay.accept,
        ),
      ],
    );
  }
}
