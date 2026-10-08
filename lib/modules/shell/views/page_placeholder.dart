import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../shared/widgets/app_panel.dart';
import 'app_shell.dart';

String pageTitle(AppStrings s, AppPage page) => switch (page) {
  AppPage.pos => s.navPos(),
  AppPage.products => s.navProducts(),
  AppPage.customers => s.navCustomers(),
  AppPage.sales => s.navSales(),
  AppPage.returns => s.navReturns(),
  AppPage.reports => s.navReports(),
  AppPage.more => s.titleSettings(),
};

/// Temporary page body until the real screens arrive (S3 onwards): an empty
/// catalog panel on POS, the management heading on every other page.
class PagePlaceholder extends StatelessWidget {
  const PagePlaceholder({required this.page, super.key});

  final AppPage page;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      page: page,
      child: page == AppPage.pos
          ? const AppPanel()
          : _ManagementPanel(title: pageTitle(context.strings, page)),
    );
  }
}

class _ManagementPanel extends StatelessWidget {
  const _ManagementPanel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox.expand(
      child: AppPanel(
        padding: EdgeInsets.all(context.metrics.managementPad),
        child: Align(
          alignment: Alignment.topLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.strings.workspaceEyebrow(),
                style: context.text
                    .of(
                      AppFontSize.s10,
                      letterSpacing: AppTracking.managementEyebrow,
                    )
                    .copyWith(color: c.muted),
              ),
              const SizedBox(height: AppSpacing.s7),
              Text(
                title,
                style: context.text
                    .of(AppFontSize.s30, weight: AppFontWeight.bold)
                    .copyWith(color: c.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
