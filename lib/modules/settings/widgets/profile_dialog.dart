import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_management_sizes.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/controllers/shell_chrome_controller.dart';
import '../../../shared/widgets/app_modal.dart';
import '../../../shared/widgets/modal_info_row.dart';
import '../../shell/controllers/settings_controller.dart';
import '../../shift/controllers/shift_controller.dart';

/// `modal === "profile"`: the large avatar, the cashier id and role, and the
/// counter, today's sales and online status.
class ProfileDialog extends StatelessWidget {
  const ProfileDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    final settings = Get.find<SettingsController>().settings.value;
    final online = Get.find<ShellChromeController>().online;
    final shiftTotal = Get.find<ShiftController>().today.total;
    return AppModal(
      title: s.userName(),
      leading: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: AppManagementSizes.avatarLarge,
          height: AppManagementSizes.avatarLarge,
          margin: const EdgeInsets.only(
            bottom: AppManagementSizes.avatarLargeMarginBottom,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.avatarBg,
            border: Border.all(
              color: c.avatarBorder,
              width: AppManagementSizes.avatarBorder,
            ),
          ),
          child: Text(
            s.userInitial(),
            style: AppTypography.arial(
              AppManagementSizes.avatarLargeFont,
            ).copyWith(color: c.white),
          ),
        ),
      ),
      scrollable: true,
      children: <Widget>[
        ModalParagraph(s.profileRole(settings.store)),
        ModalInfoRow(label: s.profileCounter(), value: settings.counter),
        ModalInfoRow(
          label: s.profileShiftSales(),
          value: MoneyFormatter.format(shiftTotal),
        ),
        Obx(
          () => ModalInfoRow(
            label: s.profileStatus(),
            value: online.value ? s.online() : s.offline(),
          ),
        ),
      ],
    );
  }
}
