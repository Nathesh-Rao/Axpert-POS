import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings_x.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../controllers/store_config_controller.dart';
import 'config_primitives.dart';

/// Store name, country and state or region.
class StoreSection extends StatelessWidget {
  const StoreSection({required this.controller, super.key});

  final StoreConfigController controller;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final editable = controller.canEdit;
    return ConfigCard(
      title: s.scSectionStore(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ConfigLabeled(
            label: s.scFieldName(),
            child: ConfigInput(
              controller: controller.name,
              editable: editable,
              semanticLabel: s.scFieldName(),
              onChanged: (_) => controller.touch(),
              onSubmitted: (_) => controller.requestSave(),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: ConfigLabeled(
                  label: s.scFieldCountry(),
                  child: ConfigDisabled(
                    editable: editable,
                    child: Obx(
                      () => AppDropdown<String>(
                        value: controller.country.value,
                        items: controller.countryCodes,
                        labelOf: controller.countryName,
                        onChanged: controller.setCountry,
                        style: configValueStyle(context),
                        semanticLabel: s.scFieldCountry(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: ConfigLabeled(
                  label: s.scFieldState(),
                  child: ConfigInput(
                    controller: controller.state,
                    editable: editable,
                    semanticLabel: s.scFieldState(),
                    onChanged: (_) => controller.touch(),
                    onSubmitted: (_) => controller.requestSave(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
