import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/entry_metrics.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_entry_tokens.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../controllers/picker_controller.dart';
import '../widgets/entry_logo.dart';
import '../widgets/login_buttons.dart';
import '../widgets/login_field.dart';
import '../../../features/session/presentation/controllers/active_session.dart';

/// After sign-in: choose the store and counter (skipped when the user has
/// exactly one of each). Same photo and panel as the login page.
class StorePickerView extends StatelessWidget {
  const StorePickerView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctl = Get.find<PickerController>();
    ctl.reducedMotion = MediaQuery.disableAnimationsOf(context);
    final c = context.colors;
    final s = context.strings;
    final session = Get.find<ActiveSession>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: c.card,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final m = EntryMetrics.of(constraints.biggest);
          final k = m.scale;
          final Color? panelColor = dark
              ? context.entryColors.panel
              : m.panelOverlapsPhoto
              ? context.entryColors.panel.withValues(
                  alpha: AppEntrySizes.panelCoverAlpha,
                )
              : null;
          return Stack(
            children: <Widget>[
              Positioned.fill(
                child: Image.asset(
                  AppAssets.loginBackground,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerLeft,
                  filterQuality: FilterQuality.medium,
                  excludeFromSemantics: true,
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: m.panelWidth,
                child: Container(
                  color: panelColor,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(m.px(AppEntrySizes.panelPadding)),
                      child: SizedBox(
                        width: m.formWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: EntryLogo(
                                size: AppEntrySizes.loginLogo * k,
                              ),
                            ),
                            SizedBox(height: AppEntrySizes.logoGap * k),
                            Text(
                              s.pickerTitle(),
                              style: context.text
                                  .fluid(
                                    AppEntrySizes.titleFont * k,
                                    weight: AppFontWeight.bold,
                                  )
                                  .copyWith(color: c.text),
                            ),
                            SizedBox(height: AppEntrySizes.titleGap * k),
                            Text(
                              s.pickerSignedInAs(
                                session.displayName,
                                s.roleLabel(session.user.value?.role ?? ''),
                              ),
                              style: context.text
                                  .fluid(AppEntrySizes.subtitleFont * k)
                                  .copyWith(color: c.muted),
                            ),
                            SizedBox(height: AppEntrySizes.subtitleGap * k),
                            LoginLabel(
                              text: s.pickerStoreLabel(),
                              scale: k,
                              readableInDark: true,
                            ),
                            SizedBox(height: AppEntrySizes.labelGap * k),
                            Obx(
                              () => LoginSelectField(
                                value: ctl.store.value?.store.name ?? '',
                                items: <String>[
                                  for (final a in ctl.stores) a.store.name,
                                ],
                                icon: AppIcons.shoppingCart,
                                semanticLabel: s.pickerStoreLabel(),
                                scale: k,
                                onChanged: ctl.selectStore,
                              ),
                            ),
                            SizedBox(height: AppEntrySizes.fieldGap * k),
                            LoginLabel(
                              text: s.pickerCounterLabel(),
                              scale: k,
                              readableInDark: true,
                            ),
                            SizedBox(height: AppEntrySizes.labelGap * k),
                            Obx(
                              () => LoginSelectField(
                                value: ctl.counter.value?.name ?? '',
                                items: <String>[
                                  for (final c
                                      in ctl.store.value?.counters ?? const [])
                                    c.name,
                                ],
                                icon: AppIcons.banknote,
                                semanticLabel: s.pickerCounterLabel(),
                                scale: k,
                                onChanged: ctl.selectCounter,
                              ),
                            ),
                            SizedBox(height: AppEntrySizes.rowButtonGap * k),
                            Obx(
                              () => LoginPrimaryButton(
                                label: s.pickerContinue(),
                                icon: AppIcons.arrowRight,
                                scale: k,
                                loading: ctl.loading.value,
                                onTap: ctl.submit,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
