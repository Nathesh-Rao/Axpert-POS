import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/services/pricing/basis_points.dart';
import '../../../core/services/pricing/money.dart';
import '../../../core/services/pricing/qty.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_motion.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_shadows.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../core/utils/decimal_text.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_pressable.dart';
import '../../../shared/widgets/hold_to_repeat_button.dart';
import '../../../shared/widgets/number_field.dart';
import '../../../shared/widgets/product_image.dart';
import '../../../shared/widgets/quantity_field.dart';
import '../controllers/cart_actions_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/cart_selection_controller.dart';
import '../models/cart_line.dart';
import '../models/line_math.dart';

final Qty _one = Qty.units(1);

/// Column proportions of `.cart-table-head, .cart-line` at the reference size:
/// `20px minmax(0,1.6fr) 144px 76px 76px minmax(80px,.8fr) 40px`, gap 8.
abstract final class CartColumns {
  static const int itemFlex = 16;
  static const int totalFlex = 8;
}

/// One cart line (`.cart-line`), single-row layout. Listens only to its own
/// line and to the selection state.
class CartLineRow extends StatelessWidget {
  const CartLineRow({required this.productId, required this.index, super.key});

  final int productId;
  final int index;

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();
    final selection = Get.find<CartSelectionController>();
    return ValueListenableBuilder<CartLine?>(
      valueListenable: cart.lineListenable(productId),
      builder: (context, line, _) {
        if (line == null) return const SizedBox.shrink();
        return Obx(() {
          final selected = selection.selected.value == productId;
          final flashing = selection.highlight.value == productId;
          return _LineBox(
            selected: selected,
            flash: flashing ? selection.scrollRequest.value : null,
            onTap: () => selection.select(productId),
            child: _LineContent(line: line, index: index),
          );
        });
      },
    );
  }
}

/// Card with the line's border, shadow and the 1.6 s highlight animation
/// (0-35 % highlight colors, then back to the normal ones).
class _LineBox extends StatefulWidget {
  const _LineBox({
    required this.selected,
    required this.flash,
    required this.onTap,
    required this.child,
  });

  final bool selected;

  /// Changes each time the line is highlighted; null when not highlighted.
  final int? flash;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_LineBox> createState() => _LineBoxState();
}

class _LineBoxState extends State<_LineBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: AppMotion.highlightMs),
  );

  @override
  void initState() {
    super.initState();
    if (widget.flash != null) _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(_LineBox old) {
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
    final m = context.metrics;
    final baseBg = widget.selected ? c.selectedLineBg : c.card;
    final baseBorder = widget.selected ? c.selectedLineBorder : c.border;
    final shadows = widget.selected
        ? AppShadows.cartLineSelected.boxShadows
        : AppShadows.cartLine.boxShadows;
    // A raw pointer listener, not a tap recognizer: a click on any child
    // (inputs, qty buttons) also selects the line, as the DOM click bubbles.
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        if (event.buttons == kPrimaryButton) widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Keyframes: 0-35 % highlight, 100 % the line's own colors.
          final t = _controller.isAnimating
              ? ((_controller.value - 0.35) / 0.65).clamp(0.0, 1.0)
              : 1.0;
          final bg = Color.lerp(c.highlightBg, c.secondary, t)!;
          final border = Color.lerp(c.highlightBorder, baseBorder, t)!;
          final flashing = _controller.isAnimating;
          return Container(
            constraints: BoxConstraints(minHeight: m.cartLineMinHeight),
            margin: const EdgeInsets.only(bottom: AppSizes.cartLineMargin),
            padding: const EdgeInsets.all(AppSizes.cartPad),
            decoration: BoxDecoration(
              color: flashing ? bg : baseBg,
              borderRadius: BorderRadius.circular(AppRadii.r12),
              border: Border.all(color: flashing ? border : baseBorder),
              boxShadow: shadows,
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _LineContent extends StatelessWidget {
  const _LineContent({required this.line, required this.index});

  final CartLine line;
  final int index;

  @override
  Widget build(BuildContext context) {
    return context.metrics.lineStacked
        ? _StackedLine(line: line, index: index)
        : _WideLine(line: line, index: index);
  }
}

/// Fields shared by both layouts.
mixin _LineParts {
  Widget numberText(BuildContext context, int index) {
    final c = context.colors;
    return Text(
      context.strings.lineNumber(index + 1),
      textAlign: TextAlign.center,
      style: context.text
          .fluid(context.metrics.lineNumberFont, height: AppLineHeight.base)
          .copyWith(color: c.text),
    );
  }

  Widget productBlock(BuildContext context, CartLine line) {
    final m = context.metrics;
    final product = line.product;
    return Row(
      children: <Widget>[
        if (product.hasImage && m.showLineImage) ...<Widget>[
          SizedBox(
            width: AppSizes.cartLineImage,
            height: AppSizes.cartLineImage,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.cartLineImageRadius),
              child: ProductImage(
                image: product.image,
                name: product.name,
                beverage: product.category == 'Beverages',
              ),
            ),
          ),
          const SizedBox(width: AppSizes.cartLineGap),
        ],
        Expanded(child: _Names(line: line)),
      ],
    );
  }

  Widget priceField(BuildContext context, CartLine line) {
    final cart = Get.find<CartController>();
    return _boxField(
      context,
      value: line.price.minor,
      scale: line.price.currency.exponent,
      label: context.strings.priceInputLabel(line.product.name),
      onValue: (v) =>
          cart.setPrice(line.product.id, Money(v, line.price.currency)),
    );
  }

  Widget discountField(BuildContext context, CartLine line) {
    final cart = Get.find<CartController>();
    return _boxField(
      context,
      value: line.discount.value,
      scale: 2,
      label: context.strings.discountInputLabel(line.product.name),
      onValue: (v) => cart.setLineDiscount(line.product.id, Bp(v)),
    );
  }

  Widget _boxField(
    BuildContext context, {
    required int value,
    required int scale,
    required String label,
    required ValueChanged<int> onValue,
  }) {
    final c = context.colors;
    final m = context.metrics;
    return NumberField(
      value: value,
      scale: scale,
      height: m.lineEditHeight,
      fillColor: c.secondary,
      borderColor: c.lineEditBorder,
      radius: AppRadii.r8,
      style: context.text
          .fluid(m.lineEditFont, height: AppLineHeight.base)
          .copyWith(color: c.text),
      semanticLabel: label,
      onValue: onValue,
    );
  }

  Widget totalText(BuildContext context, CartLine line) {
    return Text(
      MoneyFormatter.format(LineMath.lineTotal(line)),
      maxLines: 1,
      softWrap: false,
      style: context.text
          .of(
            AppFontSize.s16,
            weight: AppFontWeight.bold,
            height: AppLineHeight.base,
          )
          .copyWith(color: context.colors.text),
    );
  }

  Widget trash(BuildContext context, CartLine line) =>
      _TrashButton(onTap: () => Get.find<CartActionsController>().remove(line));
}

/// Single-row line (window wider than 1700 px): the columns of
/// [CartHeaderColumns.wide], so header and rows always align.
class _WideLine extends StatelessWidget with _LineParts {
  const _WideLine({required this.line, required this.index});

  final CartLine line;
  final int index;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(width: AppSizes.cartLineGap);
    return Row(
      children: <Widget>[
        SizedBox(
          width: AppSizes.cartLineCheckbox,
          child: numberText(context, index),
        ),
        gap,
        Expanded(
          flex: CartColumns.itemFlex,
          child: productBlock(context, line),
        ),
        gap,
        SizedBox(
          width: AppSizes.qtyControlWidth,
          child: _QtyControl(line: line),
        ),
        gap,
        SizedBox(
          width: AppSizes.lineEditWidth,
          child: priceField(context, line),
        ),
        gap,
        SizedBox(
          width: AppSizes.lineEditWidth,
          child: discountField(context, line),
        ),
        gap,
        Expanded(
          flex: CartColumns.totalFlex,
          child: Align(
            alignment: Alignment.centerRight,
            child: totalText(context, line),
          ),
        ),
        gap,
        trash(context, line),
      ],
    );
  }
}

/// Stacked line (width <= 1700): product on top, quantity, price and discount
/// below with labels; number, total and trash are placed absolutely.
class _StackedLine extends StatelessWidget with _LineParts {
  const _StackedLine({required this.line, required this.index});

  final CartLine line;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    // Offsets are CSS offsets from the padding box minus the 12 px padding.
    const inset = AppSizes.cartPad;
    return Stack(
      children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              constraints: const BoxConstraints(
                minHeight: AppSizes.stackedRow1MinHeight,
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(
                left: AppSizes.stackedProductPadLeft,
                right: AppSizes.stackedProductPadRight,
              ),
              child: productBlock(context, line),
            ),
            const SizedBox(height: AppSizes.stackedRowGap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                SizedBox(
                  width: AppSizes.qtyControlStackedWidth,
                  child: _Labeled(
                    label: s.cartTableQty(),
                    color: c.muted,
                    child: _QtyControl(line: line),
                  ),
                ),
                const SizedBox(width: AppSizes.stackedColumnGap),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSizes.lineEditStackedMaxWidth,
                      ),
                      child: _Labeled(
                        label: s.cartTablePrice(),
                        color: c.muted,
                        child: priceField(context, line),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.stackedColumnGap),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSizes.lineEditStackedMaxWidth,
                      ),
                      child: _Labeled(
                        label: s.cartTableDiscount(),
                        color: c.muted,
                        child: discountField(context, line),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          left: AppSizes.stackedNumberLeft - inset,
          top: AppSizes.stackedNumberTop - inset,
          child: numberText(context, index),
        ),
        Positioned(
          right: AppSizes.stackedTotalRight - inset,
          top: AppSizes.stackedTotalTop - inset,
          child: totalText(context, line),
        ),
        Positioned(
          right: AppSizes.stackedTrashRight - inset,
          top: AppSizes.stackedTrashTop - inset,
          child: trash(context, line),
        ),
      ],
    );
  }
}

/// `.control-label` over a stacked control: 12 px muted, line 14, margin 4.
class _Labeled extends StatelessWidget {
  const _Labeled({
    required this.label,
    required this.color,
    required this.child,
  });

  final String label;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          maxLines: 1,
          style: context.text
              .of(AppFontSize.s12, height: AppSizes.controlLabelLineHeight / 12)
              .copyWith(color: color),
        ),
        const SizedBox(height: AppSizes.controlLabelGap),
        child,
      ],
    );
  }
}

class _Names extends StatelessWidget {
  const _Names({required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final text = context.text;
    final product = line.product;
    final small = text
        .of(AppFontSize.s11, height: AppLineHeight.lineSmall)
        .copyWith(color: c.muted);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: text
              .of(
                AppFontSize.s14,
                weight: AppFontWeight.semiBold,
                height: AppLineHeight.lineName,
              )
              .copyWith(color: c.text),
        ),
        const SizedBox(height: AppSpacing.s4),
        if (context.metrics.showLineBarcode)
          Text(product.barcode, style: small),
        Text(
          s.gstLabel(DecimalText.scaled(product.gst.value, 2)),
          style: small,
        ),
      ],
    );
  }
}

class _QtyControl extends StatelessWidget {
  const _QtyControl({required this.line});

  final CartLine line;

  /// Hold-to-repeat fires long after the build: always act on the live line.
  void _step(int milli) {
    final cart = Get.find<CartController>();
    final current = cart.lineOf(line.product.id) ?? line;
    Get.find<CartActionsController>().changeQty(
      current,
      Qty(current.qty.milli + milli),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final m = context.metrics;
    final radius = BorderRadius.circular(AppRadii.r22);
    return SizedBox(
      width: m.qtyControlWidth,
      height: m.qtyControlHeight,
      child: Stack(
        children: <Widget>[
          // `inset 0 0 0 1px #dbe5f3` on a card-colored pill, under the buttons.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: radius,
                border: Border.all(color: c.qtyRing),
              ),
            ),
          ),
          // `.qty-control{overflow:hidden}` also clips the input's focus ring.
          ClipRRect(
            borderRadius: radius,
            child: Row(
              children: <Widget>[
                _QtyButton(
                  icon: AppIcons.minus,
                  tooltip: s.decreaseQtyTooltip(),
                  remove: line.qty <= _one,
                  size: m.qtyButtonSize,
                  onAction: () => _step(-_one.milli),
                ),
                Expanded(
                  child: QuantityField(
                    value: line.qty,
                    semanticLabel: s.qtyInputLabel(line.product.name),
                    style: context.text
                        .of(
                          AppFontSize.s16,
                          weight: AppFontWeight.bold,
                          height: AppLineHeight.base,
                        )
                        .copyWith(color: c.text),
                    onValue: (qty) =>
                        Get.find<CartActionsController>().changeQty(
                          Get.find<CartController>().lineOf(line.product.id) ??
                              line,
                          qty,
                        ),
                  ),
                ),
                _QtyButton(
                  icon: AppIcons.plus,
                  tooltip: s.increaseQtyTooltip(),
                  remove: false,
                  size: m.qtyButtonSize,
                  onAction: () => _step(_one.milli),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.tooltip,
    required this.remove,
    required this.size,
    required this.onAction,
  });

  final IconData icon;
  final String tooltip;
  final bool remove;
  final double size;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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

class _TrashButton extends StatelessWidget {
  const _TrashButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppPressable(
      tooltip: context.strings.removeItemTooltip(),
      onTap: onTap,
      borderRadius: AppSizes.trashSize / 2,
      builder: (context, hovered) => Container(
        width: AppSizes.trashSize,
        height: AppSizes.trashSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: hovered ? c.trashHoverBg : c.trashBg,
        ),
        child: Icon(
          AppIcons.trash2,
          size: AppSizes.trashIcon,
          color: c.trashFg,
        ),
      ),
    );
  }
}
