import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/responsive/cart_compact_columns.dart';
import '../../../core/services/pricing/basis_points.dart';
import '../../../core/services/pricing/money.dart';
import '../../../core/services/pricing/qty.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_density_sizes.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_motion.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../core/utils/decimal_text.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../features/offers/domain/entities/offer.dart';
import '../../../features/offers/domain/services/offer_engine.dart';
import '../../../features/session/presentation/controllers/active_session.dart';
import '../../../shared/widgets/app_pressable.dart';
import '../../../shared/widgets/hold_to_repeat_button.dart';
import '../../../shared/widgets/number_field.dart';
import '../../../shared/widgets/product_image.dart';
import '../../../shared/widgets/quantity_field.dart';
import '../controllers/cart_actions_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/cart_selection_controller.dart';
import '../models/line_key.dart';
import '../models/cart_line.dart';
import '../models/line_math.dart';
import '../services/offer_cart_builder.dart';

final Qty _one = Qty.units(1);

/// One cart line of the desktop layout: a 48 px table row with a hairline
/// divider, the same data and behavior as `CartLineRow` (select on pointer
/// down, hold-to-repeat quantity, price and discount inputs, remove).
class CartCompactRow extends StatelessWidget {
  const CartCompactRow({
    required this.lineKey,
    required this.index,
    required this.columns,
    super.key,
  });

  final LineKey lineKey;
  final int index;
  final CartCompactColumns columns;

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();
    final selection = Get.find<CartSelectionController>();
    return ValueListenableBuilder<CartLine?>(
      valueListenable: cart.lineListenable(lineKey),
      builder: (context, line, _) {
        if (line == null) return const SizedBox.shrink();
        return Obx(() {
          final selected = selection.selected.value == lineKey;
          final flashing = selection.highlight.value == lineKey;
          return _RowBox(
            selected: selected,
            flash: flashing ? selection.scrollRequest.value : null,
            onTap: () => selection.select(lineKey),
            child: _RowContent(line: line, index: index, columns: columns),
          );
        });
      },
    );
  }
}

/// Row background: hover, selected (with a left accent) and the add highlight.
class _RowBox extends StatefulWidget {
  const _RowBox({
    required this.selected,
    required this.flash,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final int? flash;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_RowBox> createState() => _RowBoxState();
}

class _RowBoxState extends State<_RowBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: AppMotion.highlightMs),
  );
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    if (widget.flash != null) _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(_RowBox old) {
    super.didUpdateWidget(old);
    if (widget.flash != null && widget.flash != old.flash) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = widget.selected
        ? c.selectedLineBg
        : _hovered
        ? c.secondary
        : c.card;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      // A raw pointer listener: a click on any child also selects the line.
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          if (event.buttons == kPrimaryButton) widget.onTap();
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.isAnimating
                ? ((_controller.value - 0.35) / 0.65).clamp(0.0, 1.0)
                : 1.0;
            final bg = _controller.isAnimating
                ? Color.lerp(c.highlightBg, base, t)!
                : base;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: bg,
                border: Border(
                  bottom: BorderSide(
                    color: c.border,
                    width: AppDensitySizes.cartRowHairline,
                  ),
                  left: widget.selected
                      ? BorderSide(
                          color: c.selectedLineBorder,
                          width: AppDensitySizes.cartRowAccent,
                        )
                      : BorderSide.none,
                ),
              ),
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.cartPad),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _RowContent extends StatelessWidget {
  const _RowContent({
    required this.line,
    required this.index,
    required this.columns,
  });

  final CartLine line;
  final int index;
  final CartCompactColumns columns;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final m = context.metrics;
    final cart = Get.find<CartController>();
    final product = line.product;
    final gap = SizedBox(width: columns.gap);
    final inputStyle = context.text
        .fluid(m.lineEditFont, height: AppLineHeight.base)
        .copyWith(color: c.text);
    Widget input({
      required int value,
      required int scale,
      required String label,
      required ValueChanged<int> onValue,
    }) => NumberField(
      value: value,
      scale: scale,
      height: AppDensitySizes.inputHeight,
      fillColor: c.secondary,
      borderColor: c.lineEditBorder,
      radius: AppRadii.r8,
      textAlign: TextAlign.right,
      style: inputStyle,
      semanticLabel: label,
      onValue: onValue,
    );
    return Row(
      children: <Widget>[
        if (columns.showIndex) ...<Widget>[
          SizedBox(
            width: columns.index,
            child: Text(
              s.lineNumber(index + 1),
              textAlign: TextAlign.center,
              style: context.text
                  .fluid(m.lineNumberFont, height: AppLineHeight.base)
                  .copyWith(color: c.muted),
            ),
          ),
          gap,
        ],
        if (columns.showThumb) ...<Widget>[
          SizedBox(
            width: columns.thumb,
            child: product.hasImage
                ? Center(
                    child: SizedBox(
                      width: AppDensitySizes.cartRowThumb,
                      height: AppDensitySizes.cartRowThumb,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSizes.cartLineImageRadius,
                        ),
                        child: ProductImage(
                          image: product.image,
                          name: product.name,
                          beverage: product.category == 'Beverages',
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          gap,
        ],
        Expanded(
          child: _Names(line: line, columns: columns),
        ),
        gap,
        SizedBox(
          width: columns.qty,
          child: _Stepper(line: line, width: columns.qty),
        ),
        gap,
        if (columns.showPrice) ...<Widget>[
          SizedBox(
            width: columns.price,
            child: input(
              value: line.price.minor,
              scale: line.price.currency.exponent,
              label: s.priceInputLabel(product.name),
              onValue: (v) =>
                  cart.setPrice(line.key, Money(v, line.price.currency)),
            ),
          ),
          gap,
        ],
        if (columns.showDisc) ...<Widget>[
          SizedBox(
            width: columns.disc,
            child: input(
              value: line.discount.value,
              scale: 2,
              label: s.discountInputLabel(product.name),
              onValue: (v) => cart.setLineDiscount(line.key, Bp(v)),
            ),
          ),
          gap,
        ],
        SizedBox(
          width: columns.total,
          child: Align(
            alignment: Alignment.centerRight,
            child: _Total(line: line),
          ),
        ),
        if (columns.showDelete) ...<Widget>[
          gap,
          SizedBox(
            width: columns.delete,
            child: Center(
              child: _DeleteButton(
                onTap: () => Get.find<CartActionsController>().remove(line),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Line total, never ellipsized: it scales down inside its column.
class _Total extends StatelessWidget {
  const _Total({required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final style = context.text
        .of(
          AppFontSize.s16,
          weight: AppFontWeight.bold,
          height: AppLineHeight.base,
        )
        .copyWith(color: context.colors.text);
    return ValueListenableBuilder<AppliedOffer?>(
      valueListenable: Get.find<CartController>().offerListenable(line.key),
      builder: (context, applied, _) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(
          MoneyFormatter.format(
            LineMath.lineTotal(
              applied == null
                  ? line
                  : line.withOffer(OfferCartBuilder.lineOffer(applied)),
            ),
          ),
          maxLines: 1,
          softWrap: false,
          style: style,
        ),
      ),
    );
  }
}

/// Name on the first line; barcode, tax rate and the offer on the second.
class _Names extends StatelessWidget {
  const _Names({required this.line, required this.columns});

  final CartLine line;
  final CartCompactColumns columns;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final text = context.text;
    final product = line.product;
    final session = Get.find<ActiveSession>();
    final small = text
        .of(AppFontSize.s11, height: AppLineHeight.lineSmall)
        .copyWith(color: c.muted);
    final info = <String>[
      if (columns.narrow)
        MoneyFormatter.format(line.price)
      else
        product.barcode,
      if (session.taxLabel.isNotEmpty)
        s.taxRateLabel(
          session.taxLabel,
          DecimalText.scaled(product.gst.value, 2),
        ),
    ].join(s.cartInfoSeparator());
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          product.name,
          // Very narrow cart (25%): the name may take two lines and the info
          // line goes, so the item stays recognizable.
          maxLines: columns.veryNarrow ? 2 : 1,
          softWrap: columns.veryNarrow,
          overflow: TextOverflow.ellipsis,
          style: text
              .of(
                AppFontSize.s14,
                weight: AppFontWeight.semiBold,
                height: AppLineHeight.lineName,
              )
              .copyWith(color: c.text),
        ),
        if (!columns.veryNarrow)
          ValueListenableBuilder<AppliedOffer?>(
            valueListenable: Get.find<CartController>().offerListenable(
              line.key,
            ),
            builder: (context, applied, _) => Row(
              children: <Widget>[
                Flexible(
                  child: Text(
                    info,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: small,
                  ),
                ),
                if (applied != null) ...<Widget>[
                  const SizedBox(width: AppSpacing.s6),
                  Flexible(
                    flex: 2,
                    child: Text(
                      s.offerSaved(
                        applied.name,
                        MoneyFormatter.format(applied.saving),
                      ),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: small.copyWith(
                        color: applied.kind == OfferKind.promotion
                            ? c.actionPurpleFg
                            : c.actionRedFg,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.line, required this.width});

  final CartLine line;
  final double width;

  /// Hold-to-repeat fires long after the build: always act on the live line.
  void _step(int milli) {
    final cart = Get.find<CartController>();
    final current = cart.lineOf(line.key) ?? line;
    Get.find<CartActionsController>().changeQty(
      current,
      Qty(current.qty.milli + milli),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final radius = BorderRadius.circular(AppRadii.r22);
    return Center(
      child: SizedBox(
        width: width,
        height: AppDensitySizes.stepperHeight,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: radius,
                  border: Border.all(color: c.qtyRing),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: radius,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Row(
                  children: <Widget>[
                    _StepButton(
                      icon: AppIcons.minus,
                      tooltip: s.decreaseQtyTooltip(),
                      remove: line.qty <= _one,
                      onAction: () => _step(-_one.milli),
                    ),
                    Expanded(
                      child: QuantityField(
                        value: line.qty,
                        semanticLabel: s.qtyInputLabel(line.product.name),
                        style: context.text
                            .of(
                              AppFontSize.s14,
                              weight: AppFontWeight.bold,
                              height: AppLineHeight.base,
                            )
                            .copyWith(color: c.text),
                        onValue: (qty) =>
                            Get.find<CartActionsController>().changeQty(
                              Get.find<CartController>().lineOf(line.key) ??
                                  line,
                              qty,
                            ),
                      ),
                    ),
                    _StepButton(
                      icon: AppIcons.plus,
                      tooltip: s.increaseQtyTooltip(),
                      remove: false,
                      onAction: () => _step(_one.milli),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.remove,
    required this.onAction,
  });

  final IconData icon;
  final String tooltip;
  final bool remove;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const size = AppDensitySizes.stepperButton;
    return HoldToRepeatButton(
      tooltip: tooltip,
      borderRadius: size / 2,
      onAction: onAction,
      builder: (context, hovered) {
        final bg = remove
            ? c.qtyRemoveBg
            : hovered
            ? c.qtyButtonHoverBg
            : c.qtyButtonBg;
        final fg = remove
            ? c.qtyRemoveFg
            : hovered
            ? c.qtyButtonHoverFg
            : c.qtyButtonFg;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
          child: Icon(icon, size: AppSizes.qtyButtonIcon, color: fg),
        );
      },
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppPressable(
      tooltip: context.strings.removeItemTooltip(),
      onTap: onTap,
      borderRadius: AppDensitySizes.deleteButton / 2,
      builder: (context, hovered) => Container(
        width: AppDensitySizes.deleteButton,
        height: AppDensitySizes.deleteButton,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: hovered ? c.trashHoverBg : c.trashBg,
        ),
        child: Icon(
          AppIcons.trash2,
          size: AppDensitySizes.deleteIcon,
          color: c.trashFg,
        ),
      ),
    );
  }
}
