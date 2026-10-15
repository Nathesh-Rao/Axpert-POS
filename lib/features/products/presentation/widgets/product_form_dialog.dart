import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings_x.dart';
import '../../../../core/responsive/app_metrics_scope.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens/app_icons.dart';
import '../../../../core/theme/tokens/app_product_form_sizes.dart';
import '../../../../core/theme/tokens/app_radii.dart';
import '../../../../core/theme/tokens/app_sizes.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/decimal_text.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../shared/widgets/app_modal.dart';
import '../../../../shared/widgets/app_pressable.dart';
import '../../../../shared/widgets/app_spinner.dart';
import '../../../../shared/widgets/kbd_chip.dart';
import '../../../../shared/widgets/modal_actions.dart';
import '../controllers/product_admin_controller.dart';
import '../controllers/product_form_controller.dart';
import 'product_form_parts.dart';
import 'product_offers_section.dart';

/// Add and edit product (`modal === 'productForm'`, DEC-152). Desktop: a wide
/// modal with two columns; touch: the same sections full screen.
class ProductFormDialog extends StatelessWidget {
  const ProductFormDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final form = Get.find<ProductFormController>();
    final s = context.strings;
    final title = form.isEdit
        ? s.productFormEditTitle()
        : s.productFormAddTitle();
    if (context.metrics.touch) {
      final c = context.colors;
      return Material(
        color: c.card,
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(context.metrics.modalPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    ModalTitle(title),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _Sections(form: form, twoColumns: false),
                      ),
                    ),
                    _Actions(form: form),
                  ],
                ),
              ),
              const ModalCloseButton(),
            ],
          ),
        ),
      );
    }
    return AppModal(
      title: title,
      maxWidth: AppProductFormSizes.formWidth,
      scrollable: true,
      children: <Widget>[
        _Sections(form: form, twoColumns: true),
        _Actions(form: form),
      ],
    );
  }
}

class _Sections extends StatelessWidget {
  const _Sections({required this.form, required this.twoColumns});

  final ProductFormController form;
  final bool twoColumns;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (form.loading.value) {
        return const Padding(
          padding: EdgeInsets.all(AppSpacing.s32),
          child: Center(child: AppSpinner(size: AppSpacing.s32)),
        );
      }
      final left = <Widget>[
        _NameField(form: form),
        _CategoryField(form: form),
        _BrandField(form: form),
        _BaseUnitField(form: form),
      ];
      final right = <Widget>[
        _SkuField(form: form),
        _SubCategoryField(form: form),
        _PriceField(form: form),
        _TaxField(form: form),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (twoColumns)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: Column(children: left)),
                const SizedBox(width: AppSpacing.s20),
                Expanded(child: Column(children: right)),
              ],
            )
          else ...<Widget>[...left, ...right],
          _BarcodesField(form: form),
          _ActiveField(form: form),
          _PackagingSection(form: form),
          _StockSection(form: form),
          ProductOffersSection(form: form),
        ],
      );
    });
  }
}

TextStyle _valueStyle(BuildContext context) => context.text
    .of(AppFontSize.s14, height: AppLineHeight.base)
    .copyWith(color: context.colors.text);

class _NameField extends StatelessWidget {
  const _NameField({required this.form});

  final ProductFormController form;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Obx(
      () => FormBlock(
        label: s.productFieldName(),
        error: form.errors['name'],
        child: FormInput(
          controller: form.name,
          label: s.productFieldName(),
          hasError: form.errors.containsKey('name'),
          onSubmitted: (_) => form.submit(),
        ),
      ),
    );
  }
}

class _SkuField extends StatelessWidget {
  const _SkuField({required this.form});

  final ProductFormController form;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Obx(
      () => FormBlock(
        label: s.productFieldSku(),
        error: form.errors['sku'],
        child: FormInput(
          controller: form.sku,
          label: s.productFieldSku(),
          hasError: form.errors.containsKey('sku'),
          onSubmitted: (_) => form.submit(),
        ),
      ),
    );
  }
}

class _PriceField extends StatelessWidget {
  const _PriceField({required this.form});

  final ProductFormController form;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final label = s.productFieldPrice(form.currency.code);
    return Obx(
      () => FormBlock(
        label: label,
        error: form.errors['price'],
        child: FormInput(
          controller: form.price,
          label: label,
          decimal: true,
          hasError: form.errors.containsKey('price'),
          onSubmitted: (_) => form.submit(),
        ),
      ),
    );
  }
}

class _TaxField extends StatelessWidget {
  const _TaxField({required this.form});

  final ProductFormController form;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final label = s.productFieldTax(form.session.taxLabel);
    return Obx(() {
      final rates = <int>{...form.taxRates, ?form.gstBp.value}.toList();
      return FormBlock(
        label: label,
        error: form.errors['tax'],
        child: rates.isEmpty
            ? const SizedBox.shrink()
            : AppDropdown<int>(
                value: form.gstBp.value ?? rates.first,
                items: rates,
                labelOf: (bp) => s.percentSuffix(DecimalText.scaled(bp, 2)),
                onChanged: (bp) => form.gstBp.value = bp,
                style: _valueStyle(context),
                semanticLabel: label,
              ),
      );
    });
  }
}

class _BaseUnitField extends StatelessWidget {
  const _BaseUnitField({required this.form});

  final ProductFormController form;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Obx(() {
      final units = form.unitList.toList();
      final current = form.baseUnitId.value;
      return FormBlock(
        label: s.productFieldBaseUnit(),
        error: form.errors['unit'],
        child: units.isEmpty || current == null
            ? const SizedBox.shrink()
            : AppDropdown<String>(
                value: current,
                items: [for (final u in units) u.id],
                labelOf: (id) => form.unitById(id)?.name ?? '',
                onChanged: (id) => form.baseUnitId.value = id,
                style: _valueStyle(context),
                semanticLabel: s.productFieldBaseUnit(),
              ),
      );
    });
  }
}

/// A dropdown with a "None" entry and an inline "+ New" box.
class _PickOrCreate extends StatelessWidget {
  const _PickOrCreate({
    required this.label,
    required this.value,
    required this.ids,
    required this.nameOf,
    required this.onChanged,
    required this.creating,
    required this.createController,
    required this.createHint,
    required this.onCreate,
    this.canCreate = true,
  });

  final String label;
  final String? value;
  final List<String> ids;
  final String Function(String id) nameOf;
  final ValueChanged<String?> onChanged;
  final RxBool creating;
  final TextEditingController createController;
  final String createHint;
  final VoidCallback onCreate;
  final bool canCreate;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return FormBlock(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppDropdown<String?>(
            value: value,
            items: <String?>[null, ...ids],
            labelOf: (id) => id == null ? s.productNone() : nameOf(id),
            onChanged: onChanged,
            style: _valueStyle(context),
            semanticLabel: label,
          ),
          if (canCreate)
            Obx(
              () => creating.value
                  ? Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.s6),
                      child: FormInput(
                        controller: createController,
                        label: createHint,
                        hint: createHint,
                        onSubmitted: (_) => onCreate(),
                      ),
                    )
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: FormTextButton(
                        label: s.productNewInline(),
                        onTap: () => creating.value = true,
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

class _CategoryField extends StatelessWidget {
  const _CategoryField({required this.form});

  final ProductFormController form;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Obx(() {
      final tops = form.topCategories;
      return _PickOrCreate(
        label: s.productFieldCategory(),
        value: form.categoryId.value,
        ids: [for (final c in tops) c.id],
        nameOf: (id) => tops.firstWhere((c) => c.id == id).name,
        onChanged: (id) {
          form.categoryId.value = id;
          form.sub.value = '';
        },
        creating: form.creatingCategory,
        createController: form.newCategory,
        createHint: s.productNewCategoryHint(),
        onCreate: form.createCategory,
      );
    });
  }
}

class _SubCategoryField extends StatelessWidget {
  const _SubCategoryField({required this.form});

  final ProductFormController form;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Obx(() {
      final subs = form.subCategories;
      final names = {for (final c in subs) c.name: c.name};
      final current = names.containsKey(form.sub.value) ? form.sub.value : null;
      return _PickOrCreate(
        label: s.productFieldSubCategory(),
        value: current,
        ids: names.keys.toList(),
        nameOf: (id) => id,
        onChanged: (name) => form.sub.value = name ?? '',
        creating: form.creatingSub,
        createController: form.newSub,
        createHint: s.productNewCategoryHint(),
        onCreate: form.createSub,
        canCreate: form.categoryId.value != null,
      );
    });
  }
}

class _BrandField extends StatelessWidget {
  const _BrandField({required this.form});

  final ProductFormController form;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Obx(() {
      final brands = form.brandList.toList();
      return _PickOrCreate(
        label: s.productFieldBrand(),
        value: form.brandId.value,
        ids: [for (final b in brands) b.id],
        nameOf: (id) => brands.firstWhere((b) => b.id == id).name,
        onChanged: (id) => form.brandId.value = id,
        creating: form.creatingBrand,
        createController: form.newBrand,
        createHint: s.productNewBrandHint(),
        onCreate: form.createBrand,
      );
    });
  }
}

class _BarcodesField extends StatelessWidget {
  const _BarcodesField({required this.form});

  final ProductFormController form;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    return Obx(
      () => FormBlock(
        label: s.productFieldBarcodes(),
        error: form.errors['barcodes'],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            FormInput(
              controller: form.barcodeInput,
              label: s.productFieldBarcodes(),
              hint: s.productBarcodeAddHint(),
              hasError: form.errors.containsKey('barcodes'),
              onSubmitted: (_) => form.addBarcode(),
            ),
            if (form.barcodes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s8),
                child: Wrap(
                  spacing: AppSpacing.s8,
                  runSpacing: AppSpacing.s8,
                  children: <Widget>[
                    for (final code in form.barcodes)
                      Container(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.s10,
                          top: AppSpacing.s4,
                          bottom: AppSpacing.s4,
                          right: AppSpacing.s4,
                        ),
                        decoration: BoxDecoration(
                          color: c.secondary,
                          borderRadius: BorderRadius.circular(AppRadii.r8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              code,
                              style: context.text
                                  .of(AppFontSize.s13)
                                  .copyWith(color: c.text),
                            ),
                            const SizedBox(width: AppSpacing.s4),
                            AppPressable(
                              tooltip: s.productPackagingRemove(),
                              borderRadius: AppRadii.full,
                              onTap: () => form.removeBarcode(code),
                              builder: (context, hovered) => Icon(
                                AppIcons.x,
                                size: AppSpacing.s16,
                                color: hovered ? c.text : c.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActiveField extends StatelessWidget {
  const _ActiveField({required this.form});

  final ProductFormController form;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Obx(
          () => OnOffToggle(
            label: context.strings.productFieldActive(),
            value: form.active.value,
            onChanged: (v) => form.active.value = v,
          ),
        ),
      ),
    );
  }
}

class _PackagingSection extends StatelessWidget {
  const _PackagingSection({required this.form});

  final ProductFormController form;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FormSectionTitle(
          s.productSectionPackaging(),
          trailing: FormTextButton(
            label: s.productPackagingAdd(),
            icon: AppIcons.plus,
            onTap: form.addPackaging,
          ),
        ),
        Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (var i = 0; i < form.packagings.length; i++)
                _PackagingRow(
                  key: ObjectKey(form.packagings[i]),
                  form: form,
                  index: i,
                  row: form.packagings[i],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PackagingRow extends StatelessWidget {
  const _PackagingRow({
    required this.form,
    required this.index,
    required this.row,
    super.key,
  });

  final ProductFormController form;
  final int index;
  final PackagingRowState row;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s8),
      padding: const EdgeInsets.all(AppSpacing.s10),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppRadii.r10),
        border: Border.all(color: c.border, width: AppSizes.borderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Obx(() {
            final units = [
              for (final u in form.unitList)
                if (u.id != form.baseUnitId.value) u.id,
            ];
            final current = row.unitId.value;
            return Wrap(
              spacing: AppSpacing.s10,
              runSpacing: AppSpacing.s4,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: <Widget>[
                SizedBox(
                  width: AppProductFormSizes.unitWidth,
                  child: FormBlock(
                    label: s.productPackagingUnit(),
                    error: form.errors['p$index.unit'],
                    child: current == null
                        ? const SizedBox.shrink()
                        : AppDropdown<String>(
                            value: current,
                            items: {...units, current}.toList(),
                            labelOf: (id) => form.unitById(id)?.name ?? '',
                            onChanged: (id) => row.unitId.value = id,
                            style: _valueStyle(context),
                            semanticLabel: s.productPackagingUnit(),
                          ),
                  ),
                ),
                SizedBox(
                  width: AppProductFormSizes.factorWidth,
                  child: FormBlock(
                    label: s.productPackagingContains(form.baseUnitName),
                    error: form.errors['p$index.factor'],
                    child: FormInput(
                      controller: row.factor,
                      label: s.productPackagingContains(form.baseUnitName),
                      decimal: true,
                      hasError: form.errors.containsKey('p$index.factor'),
                      onSubmitted: (_) => form.submit(),
                    ),
                  ),
                ),
                SizedBox(
                  width: AppProductFormSizes.smallFieldWidth,
                  child: FormBlock(
                    label: s.productPackagingSku(),
                    child: FormInput(
                      controller: row.sku,
                      label: s.productPackagingSku(),
                      onSubmitted: (_) => form.submit(),
                    ),
                  ),
                ),
                SizedBox(
                  width: AppProductFormSizes.smallFieldWidth,
                  child: FormBlock(
                    label: s.productPackagingBarcode(),
                    error: form.errors['p$index.barcode'],
                    child: FormInput(
                      controller: row.barcode,
                      label: s.productPackagingBarcode(),
                      hasError: form.errors.containsKey('p$index.barcode'),
                      onSubmitted: (_) => form.submit(),
                    ),
                  ),
                ),
                SizedBox(
                  width: AppProductFormSizes.smallFieldWidth,
                  child: FormBlock(
                    label: s.productPackagingPrice(),
                    error: form.errors['p$index.price'],
                    child: FormInput(
                      controller: row.price,
                      label: s.productPackagingPrice(),
                      decimal: true,
                      hasError: form.errors.containsKey('p$index.price'),
                      onSubmitted: (_) => form.submit(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s20),
                  child: OnOffToggle(
                    label: s.productPackagingEnabled(),
                    value: row.enabledOn.value,
                    onChanged: (v) => row.enabledOn.value = v,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                  child: AppPressable(
                    tooltip: s.productPackagingRemove(),
                    semanticLabel: s.productPackagingRemove(),
                    borderRadius: AppRadii.r8,
                    onTap: () => form.removePackaging(row),
                    builder: (context, hovered) => Container(
                      width: AppSizes.modalInputHeight,
                      height: AppSizes.modalInputHeight,
                      decoration: BoxDecoration(
                        color: hovered ? c.trashHoverBg : c.trashBg,
                        borderRadius: BorderRadius.circular(AppRadii.r8),
                      ),
                      child: Icon(
                        AppIcons.trash2,
                        size: AppSizes.trashIcon,
                        color: c.trashFg,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
          Obx(() {
            final preview = form.previewOf(row);
            if (preview == null) return const SizedBox.shrink();
            return Text(
              preview.derived
                  ? '${preview.text} (${s.productPackagingDerived()})'
                  : preview.text,
              style: context.text
                  .of(AppFontSize.s13, height: AppLineHeight.base)
                  .copyWith(color: c.muted),
            );
          }),
        ],
      ),
    );
  }
}

class _StockSection extends StatelessWidget {
  const _StockSection({required this.form});

  final ProductFormController form;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    final muted = context.text
        .of(AppFontSize.s13, height: AppLineHeight.base)
        .copyWith(color: c.muted);
    if (form.isEdit) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FormSectionTitle(
            s.productSectionStock(),
            trailing: FormTextButton(
              label: s.productAdjustStock(),
              onTap: () =>
                  Get.find<ProductAdminController>().openAdjust(form.editing!),
            ),
          ),
          Obx(
            () => FormBlock(
              label: s.productCurrentStock(),
              child: Text(form.currentStock.value, style: _valueStyle(context)),
            ),
          ),
          Text(s.productAdjustHint(), style: muted),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FormSectionTitle(s.productSectionStock()),
        Obx(
          () => FormBlock(
            label: s.productOpeningStock(),
            error: form.errors['opening'],
            child: Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                for (final row in form.packagings)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox(
                        width: AppProductFormSizes.countWidth,
                        child: FormInput(
                          controller: row.stockCount,
                          label: form.unitById(row.unitId.value)?.name ?? '',
                          digitsOnly: true,
                          onSubmitted: (_) => form.submit(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s6),
                      Text(
                        '${form.unitById(row.unitId.value)?.name ?? ''} +',
                        style: _valueStyle(context),
                      ),
                    ],
                  ),
                SizedBox(
                  width: AppProductFormSizes.countWidth,
                  child: FormInput(
                    controller: form.stockBase,
                    label: form.baseUnitName,
                    decimal: true,
                    onSubmitted: (_) => form.submit(),
                  ),
                ),
                Text(form.baseUnitName, style: _valueStyle(context)),
                Obx(() {
                  final total = form.stockTotalText();
                  return total == null
                      ? const SizedBox.shrink()
                      : Text(total, style: muted);
                }),
              ],
            ),
          ),
        ),
        Text(s.productStockEntryHint(), style: muted),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.form});

  final ProductFormController form;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    final muted = context.text
        .of(AppFontSize.s13, height: AppLineHeight.base)
        .copyWith(color: c.muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Obx(
          () => ModalActions(
            secondaryLabel: s.productCancel(),
            onSecondary: form.close,
            primaryLabel: form.saving.value
                ? s.productSaving()
                : (form.isEdit ? s.productSave() : s.productCreate()),
            primaryEnabled: !form.saving.value && !form.loading.value,
            onPrimary: form.submit,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            KbdChip(s.keyEscape()),
            const SizedBox(width: AppSpacing.s6),
            Text(s.productHintCancel(), style: muted),
            const SizedBox(width: AppSpacing.s12),
            KbdChip(s.keyEnter()),
            const SizedBox(width: AppSpacing.s6),
            Text(s.productHintSave(), style: muted),
          ],
        ),
      ],
    );
  }
}
