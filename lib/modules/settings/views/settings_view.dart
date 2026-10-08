import 'package:flutter/material.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/management_page.dart';
import '../../shell/views/app_shell.dart';
import '../widgets/settings_content.dart';

/// `/more`: the Settings page (heading "Settings" and the shared rows). It
/// has no controller of its own: the toggles use the permanent
/// `SettingsController`.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      page: AppPage.more,
      child: ManagementPage(
        title: context.strings.titleSettings(),
        slivers: <Widget>[
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: context.metrics.managementPad,
            ),
            sliver: const SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.topLeft,
                child: SettingsContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
