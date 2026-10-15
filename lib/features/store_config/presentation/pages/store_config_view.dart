import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings_x.dart';
import '../../../../core/responsive/app_metrics_scope.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/tokens/app_management_sizes.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../modules/shell/views/app_shell.dart';
import '../../../../shared/widgets/management_page.dart';
import '../controllers/store_config_controller.dart';
import '../widgets/config_footer.dart';
import '../widgets/config_primitives.dart';
import '../widgets/currency_section.dart';
import '../widgets/preview_section.dart';
import '../widgets/store_section.dart';
import '../widgets/tax_section.dart';

/// `/store-config`: country, currency, exchange rates and tax components of
/// the active store. Esc leaves without saving; Enter saves.
class StoreConfigView extends GetView<StoreConfigController> {
  const StoreConfigView({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return AppShell(
      page: AppPage.more,
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): controller.cancel,
        },
        child: Focus(
          autofocus: true,
          child: ManagementPage(
            title: s.scTitle(),
            slivers: <Widget>[
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.metrics.managementPad,
                ),
                sliver: SliverToBoxAdapter(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppManagementSizes.configMaxWidth,
                      ),
                      child: _Body(controller: controller),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: context.metrics.managementPad),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.controller});

  final StoreConfigController controller;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Obx(() {
      if (!controller.canView) {
        return Text(s.scNoAccess(), style: configNoteStyle(context));
      }
      if (controller.loading.value) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Text(s.scLoading(), style: configNoteStyle(context)),
        );
      }
      const gap = SizedBox(height: AppManagementSizes.configSectionGap);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          StoreSection(controller: controller),
          gap,
          CurrencySection(controller: controller),
          gap,
          TaxSection(controller: controller),
          gap,
          PreviewSection(controller: controller),
          gap,
          ConfigFooter(controller: controller),
        ],
      );
    });
  }
}
