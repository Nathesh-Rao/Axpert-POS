import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../../core/theme/tokens/app_icons.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/app_modal.dart';
import '../../../../shared/widgets/modal_actions.dart';
import '../../../../shared/widgets/modal_input.dart';
import '../../controllers/scan_controller.dart';

/// The barcode scan simulator (`modal === "scan"`).
class ScanDialog extends StatelessWidget {
  const ScanDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    final scan = Get.find<ScanController>();
    return AppModal(
      leading: const ModalSymbol(
        icon: AppIcons.barcode,
        iconSize: AppCheckoutSizes.scanSymbolIcon,
      ),
      title: s.scanDialogTitle(),
      children: <Widget>[
        ModalParagraph(s.scanDialogBody()),
        ModalInput(
          controller: scan.text,
          focusNode: scan.focus,
          autofocus: true,
          hint: s.scanInputHint(),
          semanticLabel: s.scanDialogTitle(),
          onSubmitted: (_) => scan.submit(),
        ),
        Obx(
          () => ModalActions(
            secondaryLabel: s.scanRandom(),
            onSecondary: scan.scanRandom,
            primaryLabel: s.scanSimulate(),
            onPrimary: scan.submit,
            primaryEnabled: scan.hasText.value,
          ),
        ),
        Text(
          s.scanTryHint(),
          style: context.text
              .fluid(AppCheckoutSizes.modalListSmallFont)
              .copyWith(color: c.muted),
        ),
      ],
    );
  }
}
