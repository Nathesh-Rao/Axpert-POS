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
import '../../../features/session/presentation/controllers/active_session.dart';
import '../../shift/controllers/shift_controller.dart';

/// `modal === "profile"`: the large avatar, the cashier id and role, and the
/// counter, today's sales and online status.
class ProfileDialog extends StatelessWidget {
  const ProfileDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    final session = Get.find<ActiveSession>();
    final online = Get.find<ShellChromeController>().online;
    final shiftTotal = Get.find<ShiftController>().today.total;
    return AppModal(
      title: session.displayName,
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
            session.initial,
            style: AppTypography.arial(
              AppManagementSizes.avatarLargeFont,
            ).copyWith(color: c.white),
          ),
        ),
      ),
      scrollable: true,
      children: <Widget>[
        ModalParagraph(
          s.profileRole(session.store.value?.name ?? s.storeNone()),
        ),
        Obx(
          () => ModalInfoRow(
            label: s.profileCounter(),
            value: session.counter.value?.name ?? s.counterNone(),
          ),
        ),
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
