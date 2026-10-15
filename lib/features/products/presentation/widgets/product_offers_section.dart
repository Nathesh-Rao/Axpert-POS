import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens/app_icons.dart';
import '../../../../core/theme/tokens/app_product_form_sizes.dart';
import '../../../../core/theme/tokens/app_radii.dart';
import '../../../../core/theme/tokens/app_sizes.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../offers/domain/entities/offer.dart';
import '../../../offers/domain/entities/offer_draft.dart';
import '../../../offers/presentation/controllers/offer_editor_controller.dart';
import '../controllers/product_form_controller.dart';
import 'package:get/get.dart';
import 'product_form_parts.dart';

ProductOfferStyle _styleOf(OfferKind kind) => switch (kind) {
  OfferKind.discount => ProductOfferStyle.discount,
  OfferKind.promotion => ProductOfferStyle.promotion,
  OfferKind.giftTier => ProductOfferStyle.gift,
};

String _kindName(BuildContext context, OfferKind kind) => switch (kind) {
  OfferKind.discount => context.strings.offerKindDiscount(),
  OfferKind.promotion => context.strings.offerKindPromotion(),
  OfferKind.giftTier => context.strings.offerKindGift(),
};

/// "Offers & promotions" of the product form (DEC-153): the product's offers,
/// one inline editor and a live preview of the tile badge and price.
class ProductOffersSection extends StatelessWidget {
  const ProductOffersSection({required this.form, super.key});

  final ProductFormController form;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    final editor = form.offerEditor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FormSectionTitle(
          s.offerSectionTitle(),
          trailing: FormTextButton(
            label: s.offerAdd(),
            icon: AppIcons.plus,
            onTap: editor.beginAdd,
          ),
        ),
        Text(
          s.offerRulesHint(),
          style: context.text
              .of(AppFontSize.s13, height: AppLineHeight.base)
              .copyWith(color: c.muted),
        ),
        const SizedBox(height: AppSpacing.s8),
        Obx(() {
          final list = editor.offers.toList();
          final overlapping = editor.overlapping;
          if (list.isEmpty && !editor.open.value) {
            return Text(
              s.offerEmpty(),
              style: context.text
                  .of(AppFontSize.s14, height: AppLineHeight.base)
                  .copyWith(color: c.muted),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (var i = 0; i < list.length; i++)
                _OfferRow(
                  editor: editor,
                  index: i,
                  offer: list[i],
                  overlaps: overlapping.contains(i),
                ),
            ],
          );
        }),
        Obx(
          () => editor.open.value
              ? _OfferEditor(form: form)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _OfferRow extends StatelessWidget {
  const _OfferRow({
    required this.editor,
    required this.index,
    required this.offer,
    required this.overlaps,
  });

  final OfferEditorController editor;
  final int index;
  final OfferDraft offer;
  final bool overlaps;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    final window = editor.window(offer);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s8),
      padding: const EdgeInsets.all(AppSpacing.s10),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppRadii.r10),
        border: Border.all(
          color: overlaps ? c.validation : c.border,
          width: AppSizes.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: AppSpacing.s12,
            runSpacing: AppSpacing.s4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              OfferBadge(
                label: editor.summary(offer),
                style: _styleOf(offer.kind),
              ),
              Text(
                '${_kindName(context, offer.kind)}: ${offer.name}',
                style: context.text
                    .of(AppFontSize.s14, height: AppLineHeight.base)
                    .copyWith(color: c.text),
              ),
              if (window.isNotEmpty)
                Text(
                  window,
                  style: context.text
                      .of(AppFontSize.s13, height: AppLineHeight.base)
                      .copyWith(color: c.muted),
                ),
              OnOffToggle(
                label: s.productFieldActive(),
                value: offer.active,
                onChanged: (on) => editor.toggle(index, on),
              ),
              FormTextButton(
                label: s.offerEdit(),
                onTap: () => editor.beginEdit(index),
              ),
              FormTextButton(
                label: s.offerRemove(),
                onTap: () => editor.remove(index),
              ),
            ],
          ),
          if (overlaps)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s4),
              child: Text(
                s.offerOverlapWarning(),
                style: context.text
                    .of(AppFontSize.s12, height: AppLineHeight.base)
                    .copyWith(color: c.validation),
              ),
            ),
        ],
      ),
    );
  }
}

class _OfferEditor extends StatelessWidget {
  const _OfferEditor({required this.form});

  final ProductFormController form;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    final e = form.offerEditor;
    final muted = context.text
        .of(AppFontSize.s13, height: AppLineHeight.base)
        .copyWith(color: c.muted);
    final value = context.text
        .of(AppFontSize.s14, height: AppLineHeight.base)
        .copyWith(color: c.text);
    final code = form.currency.code;
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.s4),
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: c.secondary,
        borderRadius: BorderRadius.circular(AppRadii.r10),
        border: Border.all(color: c.border, width: AppSizes.borderWidth),
      ),
      child: Obx(() {
        final kind = e.kind.value;
        final err = e.errors;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Wrap(
              spacing: AppSpacing.s10,
              runSpacing: AppSpacing.s4,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: <Widget>[
                SizedBox(
                  width: AppProductFormSizes.unitWidth,
                  child: FormBlock(
                    label: s.offerFieldKind(),
                    child: AppDropdown<OfferKind>(
                      value: kind,
                      items: OfferKind.values,
                      labelOf: (k) => _kindName(context, k),
                      onChanged: (k) => e.kind.value = k,
                      style: value,
                      semanticLabel: s.offerFieldKind(),
                    ),
                  ),
                ),
                SizedBox(
                  width: AppProductFormSizes.offerNameWidth,
                  child: FormBlock(
                    label: s.offerFieldName(),
                    error: err['name'],
                    child: FormInput(
                      controller: e.name,
                      label: s.offerFieldName(),
                      hasError: err.containsKey('name'),
                      onSubmitted: (_) => e.apply(),
                    ),
                  ),
                ),
                if (kind == OfferKind.discount) ...<Widget>[
                  SizedBox(
                    width: AppProductFormSizes.unitWidth,
                    child: FormBlock(
                      label: s.offerFieldMode(),
                      child: AppDropdown<DiscountMode>(
                        value: e.mode.value,
                        items: DiscountMode.values,
                        labelOf: (m) => m == DiscountMode.percent
                            ? s.offerModePercent()
                            : s.offerModeAmount(),
                        onChanged: (m) => e.mode.value = m,
                        style: value,
                        semanticLabel: s.offerFieldMode(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: AppProductFormSizes.smallFieldWidth,
                    child: FormBlock(
                      label: e.mode.value == DiscountMode.percent
                          ? s.offerFieldPercent()
                          : s.offerFieldAmount(code),
                      error: err['value'],
                      child: FormInput(
                        controller: e.value,
                        label: s.offerFieldPercent(),
                        decimal: true,
                        hasError: err.containsKey('value'),
                        onSubmitted: (_) => e.apply(),
                      ),
                    ),
                  ),
                ],
                if (kind == OfferKind.giftTier)
                  SizedBox(
                    width: AppProductFormSizes.minCartWidth,
                    child: FormBlock(
                      label: s.offerFieldMinCart(code),
                      error: err['minCart'],
                      child: FormInput(
                        controller: e.minCart,
                        label: s.offerFieldMinCart(code),
                        decimal: true,
                        hasError: err.containsKey('minCart'),
                        onSubmitted: (_) => e.apply(),
                      ),
                    ),
                  ),
              ],
            ),
            if (kind == OfferKind.promotion)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                child: Text(s.offerPromotionInfo(), style: muted),
              ),
            if (kind == OfferKind.giftTier)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                child: Text(s.offerGiftInfo(), style: muted),
              ),
            Wrap(
              spacing: AppSpacing.s10,
              runSpacing: AppSpacing.s4,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: <Widget>[
                SizedBox(
                  width: AppProductFormSizes.smallFieldWidth,
                  child: FormBlock(
                    label: s.offerFieldStart(),
                    error: err['starts'],
                    child: FormInput(
                      controller: e.starts,
                      label: s.offerFieldStart(),
                      hasError: err.containsKey('starts'),
                      onSubmitted: (_) => e.apply(),
                    ),
                  ),
                ),
                SizedBox(
                  width: AppProductFormSizes.smallFieldWidth,
                  child: FormBlock(
                    label: s.offerFieldEnd(),
                    error: err['ends'],
                    child: FormInput(
                      controller: e.ends,
                      label: s.offerFieldEnd(),
                      hasError: err.containsKey('ends'),
                      onSubmitted: (_) => e.apply(),
                    ),
                  ),
                ),
                SizedBox(
                  width: AppProductFormSizes.countWidth,
                  child: FormBlock(
                    label: s.offerFieldPriority(),
                    error: err['priority'],
                    child: FormInput(
                      controller: e.priority,
                      label: s.offerFieldPriority(),
                      digitsOnly: true,
                      hasError: err.containsKey('priority'),
                      onSubmitted: (_) => e.apply(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s20),
                  child: OnOffToggle(
                    label: s.productFieldActive(),
                    value: e.active.value,
                    onChanged: (v) => e.active.value = v,
                  ),
                ),
              ],
            ),
            Obx(() {
              form.tick.value; // the base price changed
              final preview = e.preview();
              return preview == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                      child: Wrap(
                        spacing: AppSpacing.s10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Text('${s.offerPreviewLabel()}:', style: muted),
                          OfferBadge(
                            label: preview.badge,
                            style: _styleOf(preview.kind),
                          ),
                          if (preview.text != null)
                            Text(preview.text!, style: value),
                        ],
                      ),
                    );
            }),
            Obx(
              () => e.candidateOverlaps
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                      child: Text(
                        s.offerOverlapWarning(),
                        style: context.text
                            .of(AppFontSize.s12, height: AppLineHeight.base)
                            .copyWith(color: c.validation),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Row(
              children: <Widget>[
                FormTextButton(
                  label: e.editingIndex.value == null
                      ? s.offerApply()
                      : s.offerUpdate(),
                  icon: AppIcons.check,
                  onTap: e.apply,
                ),
                const SizedBox(width: AppSpacing.s12),
                FormTextButton(label: s.offerCancel(), onTap: e.cancel),
                const Spacer(),
                Text(s.offerHintEnter(), style: muted),
              ],
            ),
          ],
        );
      }),
    );
  }
}
