import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens/app_icons.dart';
import '../../../../core/theme/tokens/app_management_sizes.dart';
import '../../../../core/theme/tokens/app_radii.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../session/domain/entities/session_entities.dart';
import '../controllers/store_config_controller.dart';
import '../controllers/store_config_drafts.dart';
import 'config_primitives.dart';

/// The tax slabs of the store: each slab is a bundle of components.
class TaxSection extends StatelessWidget {
  const TaxSection({required this.controller, super.key});

  final StoreConfigController controller;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final editable = controller.canEdit;
    return ConfigCard(
      title: s.scSectionTax(),
      subtitle: controller.inclusive
          ? s.scPriceInclusive()
          : s.scPriceExclusive(),
      child: Obx(() {
        controller.revision.value;
        final slabs = controller.slabs.toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (var i = 0; i < slabs.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                child: _SlabCard(
                  controller: controller,
                  index: i,
                  slab: slabs[i],
                ),
              ),
            Text(s.scSlabEmptyHint(), style: configNoteStyle(context)),
            const SizedBox(height: AppSpacing.s8),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: <Widget>[
                ConfigButton(
                  label: s.scSlabAdd(),
                  icon: AppIcons.plus,
                  onTap: editable ? controller.addSlab : null,
                ),
                ConfigButton(
                  label: s.scSlabAddInterState(),
                  icon: AppIcons.plus,
                  onTap: editable
                      ? () => controller.addSlab(interState: true)
                      : null,
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _SlabCard extends StatelessWidget {
  const _SlabCard({
    required this.controller,
    required this.index,
    required this.slab,
  });

  final StoreConfigController controller;
  final int index;
  final SlabDraft slab;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    final editable = controller.canEdit;
    final interState = slab.scheme == TaxScheme.interState;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: c.secondary,
        borderRadius: BorderRadius.circular(AppRadii.r8),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: ConfigLabeled(
                  label: interState
                      ? '${s.scSlabName()} (${s.scSlabInterState()})'
                      : s.scSlabName(),
                  child: ConfigInput(
                    controller: slab.name,
                    editable: editable,
                    semanticLabel: s.scSlabName(),
                    onChanged: (_) => controller.touch(),
                    onSubmitted: (_) => controller.requestSave(),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
                child: Text(
                  s.scSlabTotal(controller.totalPercent(slab)),
                  style: context.text
                      .of(AppFontSize.s14, weight: AppFontWeight.bold)
                      .copyWith(color: c.text),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              ConfigIconButton(
                icon: AppIcons.trash2,
                tooltip: s.scSlabRemove(),
                onTap: editable ? () => controller.removeSlab(index) : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              ConfigCheck(
                label: s.scSlabEnabled(),
                value: slab.enabled,
                onChanged: editable
                    ? (v) => controller.setSlabEnabled(index, v)
                    : null,
              ),
              if (!interState)
                ConfigCheck(
                  label: slab.isDefault
                      ? s.scSlabDefault()
                      : s.scSlabMakeDefault(),
                  value: slab.isDefault,
                  onChanged: editable && !slab.isDefault
                      ? (_) => controller.makeDefault(index)
                      : null,
                ),
              Text(
                s.scSlabProducts(controller.productsAt(slab)),
                style: configNoteStyle(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          for (var j = 0; j < slab.components.length; j++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s8),
              child: _ComponentRow(
                controller: controller,
                slabIndex: index,
                index: j,
                component: slab.components[j],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: ConfigButton(
              label: s.scCompAdd(),
              icon: AppIcons.plus,
              onTap: editable ? () => controller.addComponent(index) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComponentRow extends StatelessWidget {
  const _ComponentRow({
    required this.controller,
    required this.slabIndex,
    required this.index,
    required this.component,
  });

  final StoreConfigController controller;
  final int slabIndex;
  final int index;
  final ComponentDraft component;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final editable = controller.canEdit;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          flex: 2,
          child: ConfigLabeled(
            label: s.scCompLabel(),
            child: ConfigDisabled(
              editable: editable,
              child: AppDropdown<String>(
                value: controller.pickerValue(component),
                items: controller.pickerEntries,
                labelOf: (entry) => entry == StoreConfigController.customEntry
                    ? s.scCompCustom()
                    : entry,
                onChanged: (entry) =>
                    controller.pickComponent(slabIndex, index, entry),
                style: configValueStyle(context),
                semanticLabel: s.scCompLabel(),
              ),
            ),
          ),
        ),
        if (component.custom) ...<Widget>[
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            flex: 2,
            child: ConfigLabeled(
              label: s.scCompCustom(),
              child: ConfigInput(
                controller: component.label,
                editable: editable,
                semanticLabel: s.scCompCustom(),
                onChanged: (_) => controller.touch(),
                onSubmitted: (_) => controller.requestSave(),
              ),
            ),
          ),
        ],
        const SizedBox(width: AppSpacing.s8),
        SizedBox(
          width: AppManagementSizes.configRateWidth,
          child: ConfigLabeled(
            label: s.scCompRate(),
            child: ConfigInput(
              controller: component.rate,
              editable: editable,
              decimal: true,
              semanticLabel: s.scCompRate(),
              onChanged: (_) => controller.touch(),
              onSubmitted: (_) => controller.requestSave(),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s4),
        ConfigCheck(
          label: s.scCompEnabled(),
          value: component.enabled,
          onChanged: editable
              ? (v) => controller.setComponentEnabled(slabIndex, index, v)
              : null,
        ),
        ConfigIconButton(
          icon: AppIcons.x,
          tooltip: s.scCompRemove(),
          onTap: editable
              ? () => controller.removeComponent(slabIndex, index)
              : null,
        ),
      ],
    );
  }
}
