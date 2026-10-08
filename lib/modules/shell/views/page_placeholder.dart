import 'package:flutter/material.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/routes/app_routes.dart';

/// Temporary page body until the shell frame arrives (S2.c).
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
    return Scaffold(body: Center(child: Text(title)));
  }
}
