import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens/app_icons.dart';
import '../../../../core/theme/tokens/app_management_sizes.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/epoch_time.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../controllers/store_config_controller.dart';
import '../controllers/store_config_drafts.dart';
import 'config_primitives.dart';

/// The store currency and its exchange rates.
class CurrencySection extends StatelessWidget {
  const CurrencySection({required this.controller, super.key});

  final StoreConfigController controller;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    final editable = controller.canEdit;
    return ConfigCard(
      title: s.scSectionCurrency(),
      child: Obx(() {
        controller.revision.value;
        final currency = controller.currency.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ConfigLabeled(
              label: s.scFieldCurrency(),
              child: ConfigDisabled(
                editable: editable && !controller.currencyLocked,
                child: AppDropdown<String>(
                  value: currency,
                  items: controller.currencyCodes,
                  labelOf: (code) => code,
                  onChanged: controller.setCurrency,
                  style: configValueStyle(context),
                  semanticLabel: s.scFieldCurrency(),
                ),
              ),
            ),
            if (controller.currencyLocked)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s6),
                child: Text(
                  s.scCurrencyLocked(),
                  style: configNoteStyle(context),
                ),
              )
            else if (controller.currencyMismatch)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s6),
                child: Text(
                  s.scCurrencyMismatch(
                    controller.countryName(controller.country.value),
                    controller.usualCurrency ?? '',
                  ),
                  style: configNoteStyle(
                    context,
                  ).copyWith(color: c.toastWarning),
                ),
              ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              s.scForexTitle(),
              style: context.text
                  .of(AppFontSize.s14, weight: AppFontWeight.bold)
                  .copyWith(color: c.text),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(s.scForexHint(currency), style: configNoteStyle(context)),
            const SizedBox(height: AppSpacing.s8),
            if (controller.forex.isEmpty)
              Text(s.scForexEmpty(), style: configNoteStyle(context))
            else
              for (var i = 0; i < controller.forex.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                  child: _ForexRow(
                    controller: controller,
                    index: i,
                    draft: controller.forex[i],
                  ),
                ),
            Align(
              alignment: Alignment.centerLeft,
              child: ConfigButton(
                label: s.scForexAdd(),
                icon: AppIcons.plus,
                onTap: editable ? controller.addForex : null,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _ForexRow extends StatelessWidget {
  const _ForexRow({
    required this.controller,
    required this.index,
    required this.draft,
  });

  final StoreConfigController controller;
  final int index;
  final ForexDraft draft;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final editable = controller.canEdit;
    final effective = draft.updatedAtMs == 0
        ? ''
        : EpochTime.toIso(draft.updatedAtMs).substring(0, 10);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: ConfigLabeled(
            label: s.scForexColCurrency(),
            child: ConfigDisabled(
              editable: editable,
              child: AppDropdown<String>(
                value: draft.code,
                items: <String>[
                  for (final code in controller.currencyCodes)
                    if (code != controller.currency.value) code,
                ],
                labelOf: (code) => code,
                onChanged: (code) => controller.setForexCode(index, code),
                style: configValueStyle(context),
                semanticLabel: s.scForexColCurrency(),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: ConfigLabeled(
            label: s.scForexColRate(controller.currency.value),
            child: ConfigInput(
              controller: draft.rate,
              editable: editable,
              decimal: true,
              semanticLabel: s.scForexColRate(controller.currency.value),
              onChanged: (_) => controller.touch(),
              onSubmitted: (_) => controller.requestSave(),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        SizedBox(
          width: AppManagementSizes.configEffectiveWidth,
          child: ConfigLabeled(
            label: s.scForexColEffective(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
              child: Text(effective, style: configValueStyle(context)),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        ConfigIconButton(
          icon: AppIcons.trash2,
          tooltip: s.scForexRemove(),
          onTap: editable ? () => controller.removeForex(index) : null,
        ),
      ],
    );
  }
}
