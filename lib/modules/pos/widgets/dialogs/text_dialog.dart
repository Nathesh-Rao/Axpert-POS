import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings_x.dart';
import '../../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../../shared/controllers/overlay_controller.dart';
import '../../../../shared/widgets/app_modal.dart';
import '../../../../shared/widgets/modal_input.dart';
import '../../../../shared/widgets/modal_primary_button.dart';
import '../../controllers/text_dialog_controller.dart';

/// "Rename counter" and "Add order note": a text input and Save.
class TextDialog extends StatelessWidget {
  const TextDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final overlay = Get.find<OverlayController>();
    final dialog = Get.find<TextDialogController>();
    return Obx(() {
      final counter = overlay.modal.value == TextDialogController.counterId;
      return AppModal(
        title: counter ? s.orderRename() : s.noteDialogTitle(),
        children: <Widget>[
          ModalInput(
            controller: dialog.text,
            focusNode: dialog.focus,
            autofocus: true,
            semanticLabel: counter ? s.orderRename() : s.noteDialogTitle(),
          ),
          Obx(
            () => Opacity(
              opacity: dialog.canSave.value
                  ? 1
                  : AppCheckoutSizes.disabledOpacity,
              child: ModalPrimaryButton(
                label: s.textDialogSave(),
                marginTop: AppCheckoutSizes.primaryFullMarginTop,
                onTap: dialog.save,
              ),
            ),
          ),
        ],
      );
    });
  }
}
