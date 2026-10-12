import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/entry_metrics.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_entry_tokens.dart';
import '../../../shared/widgets/request_focus_on_show.dart';
import '../controllers/login_controller.dart';
import '../widgets/form_rise.dart';
import '../widgets/login_extras.dart';
import '../widgets/login_form.dart';

/// `login.png`: the store photo full-bleed on the left, the form on the white
/// right side. Demo only: any non-empty username and password signs in.
class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctl = Get.find<LoginController>();
    ctl.reducedMotion = MediaQuery.disableAnimationsOf(context);
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: c.card,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final m = EntryMetrics.of(constraints.biggest);
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
                      padding: EdgeInsets.symmetric(
                        horizontal: m.px(AppEntrySizes.panelPadding),
                        vertical: m.px(AppEntrySizes.panelPadding),
                      ),
                      child: SizedBox(
                        width: m.formWidth,
                        child: RequestFocusOnShow(
                          focusNode: ctl.usernameFocus,
                          child: FormRise(child: LoginForm(scale: m.scale)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: m.px(AppEntrySizes.chipInset),
                right: m.px(AppEntrySizes.chipInset),
                child: LanguageChip(
                  label: context.strings.loginLanguage(),
                  scale: m.scale,
                  onTap: () => ctl.demoOnly(context.strings.loginLanguage()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
