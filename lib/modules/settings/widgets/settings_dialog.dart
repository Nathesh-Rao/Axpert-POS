import 'package:flutter/material.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../shared/widgets/app_modal.dart';
import 'settings_content.dart';

/// `modal === "settings"`: the title and the same rows as the page.
class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AppModal(
      title: context.strings.titleSettings(),
      scrollable: true,
      children: const <Widget>[SettingsContent()],
    );
  }
}
