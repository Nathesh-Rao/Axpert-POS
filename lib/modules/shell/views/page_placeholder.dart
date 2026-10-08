import 'package:flutter/material.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/routes/app_routes.dart';
import 'app_shell.dart';

/// Temporary page body until the real screens arrive (S3 onwards).
class PagePlaceholder extends StatelessWidget {
  const PagePlaceholder({required this.page, super.key});

  final AppPage page;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final title = switch (page) {
      AppPage.pos => s.navPos(),
      AppPage.products => s.navProducts(),
      AppPage.customers => s.navCustomers(),
      AppPage.sales => s.navSales(),
      AppPage.returns => s.navReturns(),
      AppPage.reports => s.navReports(),
      AppPage.more => s.titleSettings(),
    };
    return AppShell(
      page: page,
      child: Center(child: Text(title)),
    );
  }
}
