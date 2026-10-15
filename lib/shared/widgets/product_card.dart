import 'package:flutter/material.dart';

import '../../core/constants/app_strings_x.dart';
import '../../core/responsive/app_metrics_scope.dart';
import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_density_sizes.dart';
import '../../core/theme/tokens/app_icons.dart';
import '../../core/theme/tokens/app_motion.dart';
import '../../core/theme/tokens/app_radii.dart';
import '../../core/theme/tokens/app_shadows.dart';
import '../../core/theme/tokens/app_sizes.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_typography.dart';
import 'app_pressable.dart';
import 'star_icon.dart';

/// Look of the one offer badge of a card.
enum ProductOfferStyle { discount, promotion, gift }

/// Catalog product card (`.product-card`), grid or list layout. Pure
/// presentation: the caller supplies texts, the picture and the callbacks.
class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.name,
    required this.code,
    required this.price,
    required this.image,
    required this.favourite,
    required this.list,
    required this.onAdd,
    required this.onToggleFavourite,
    this.qtyBadge,
    this.onRemoveOne,
    this.packs,
    this.offerLabel,
    this.offerStyle,
    this.strikePrice,
    this.compact = false,
    super.key,
  });

  final String name;
  final String code;
  final String price;
  final Widget image;
  final bool favourite;
  final bool list;
  final VoidCallback onAdd;
  final VoidCallback onToggleFavourite;

  /// Badge text (`x2`); null when the product is not in the cart.
  final String? qtyBadge;

  /// Shown only when the product is in the cart.
  final VoidCallback? onRemoveOne;

  /// The unit chooser of a product with packagings (DEC-154), left of the
  /// stepper; null for every other product.
  final Widget? packs;

  /// The one offer badge (`-20%`, `Buy 1 Get 1`, `Free gift`); null = none.
  final String? offerLabel;
  final ProductOfferStyle? offerStyle;

  /// The original price, struck through beside [price] (discounts only).
  final String? strikePrice;

  /// The narrow Products panel (DEC-141): a smaller grid card with the offer
  /// badge on its own line under the picture. Ignored in list mode.
  final bool compact;

  bool get inCart => qtyBadge != null;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = context.metrics;
    final s = context.strings;
    return AppPressable(
      onTap: onAdd,
      semanticLabel: s.addProductTooltip(name),
      borderRadius: AppRadii.r9,
      builder: (context, hovered) {
        final border = inCart
            ? c.productInCartBorder
            : hovered
            ? c.productHoverBorder
            : c.border;
        return AnimatedContainer(
          duration: const Duration(milliseconds: AppMotion.cardMs),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(AppRadii.r9),
            border: Border.all(color: border),
            boxShadow: hovered ? AppShadows.productHover.boxShadows : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.r9 - 1),
            child: Stack(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(
                    list ? AppSpacing.s8 : m.productCardPad,
                  ),
                  child: list ? _listBody(context) : _gridBody(context),
                ),
                Positioned(
                  right: list ? AppSpacing.s4 : AppSpacing.s9,
                  top: list ? AppSpacing.s8 : AppSpacing.s10,
                  child: _FavouriteButton(
                    favourite: favourite,
                    onTap: onToggleFavourite,
                  ),
                ),
                if (offerLabel != null && offerStyle != null && !compact)
                  Positioned(
                    right:
                        (list ? AppSpacing.s4 : AppSpacing.s9) +
                        AppSizes.favouriteIcon +
                        AppSpacing.s3 * 2 +
                        AppSpacing.s4,
                    top: list ? AppSpacing.s8 : AppSpacing.s10,
                    child: OfferBadge(label: offerLabel!, style: offerStyle!),
                  ),
                if (qtyBadge != null)
                  Positioned(
                    left: list ? 60 : AppSpacing.s8,
                    top: AppSpacing.s8,
                    child: _QtyBadge(text: qtyBadge!),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _gridBody(BuildContext context) {
    final m = context.metrics;
    final c = context.colors;
    final text = context.text;
    // Natural height with a fixed grid extent: sub-pixel text rounding must
    // not raise an overflow error, so the column may exceed its box (clipped).
    return OverflowBox(
      minHeight: 0,
      maxHeight: double.infinity,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: AppSpacing.s4),
          SizedBox(
            height: compact
                ? AppDensitySizes.compactImageHeight
                : m.productImageHeight,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.r5),
              child: Center(child: image),
            ),
          ),
          if (compact) ...<Widget>[
            const SizedBox(height: AppSpacing.s4),
            // The one offer badge, or the code when there is none.
            SizedBox(
              height: AppDensitySizes.compactBadgeRow,
              child: Align(
                alignment: Alignment.centerLeft,
                child: offerLabel != null && offerStyle != null
                    ? OfferBadge(label: offerLabel!, style: offerStyle!)
                    : Text(
                        code,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text
                            .fluid(
                              m.productCodeFont,
                              height: AppLineHeight.base,
                            )
                            .copyWith(color: c.muted),
                      ),
              ),
            ),
            _name(context, m.catalogFont),
            const SizedBox(height: AppSpacing.s4),
            _bottom(context),
          ] else ...<Widget>[
            const SizedBox(height: AppSpacing.s8),
            _name(context, m.catalogFont),
            const SizedBox(height: AppSpacing.s4),
            Text(
              code,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text
                  .fluid(m.productCodeFont, height: AppLineHeight.base)
                  .copyWith(color: c.muted),
            ),
            const SizedBox(height: AppSpacing.s5),
            _bottom(context),
          ],
        ],
      ),
    );
  }

  Widget _listBody(BuildContext context) {
    final m = context.metrics;
    final c = context.colors;
    final text = context.text;
    return Stack(
      children: <Widget>[
        Row(
          children: <Widget>[
            SizedBox(
              width: AppSizes.productListImageWidth,
              height: AppSizes.productListImageHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.r5),
                child: Center(child: image),
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 80),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _name(context, m.productListNameFont),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text
                          .fluid(m.productCodeFont, height: AppLineHeight.base)
                          .copyWith(color: c.muted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          right: AppSpacing.s24 - AppSpacing.s8,
          bottom: 0,
          child: _bottom(context, gap: AppSpacing.s8),
        ),
      ],
    );
  }

  Widget _name(BuildContext context, double font) {
    return Text(
      name,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      style: context.text
          .fluid(font, height: AppLineHeight.base)
          .copyWith(color: context.colors.text),
    );
  }

  Widget _bottom(BuildContext context, {double? gap}) {
    final m = context.metrics;
    final c = context.colors;
    final s = context.strings;
    final priceOnly = Text(
      price,
      maxLines: 1,
      style: context.text
          .fluid(
            m.productPriceFont,
            weight: AppFontWeight.bold,
            height: AppLineHeight.base,
          )
          .copyWith(color: c.text),
    );
    final priceText = strikePrice == null
        ? priceOnly
        : FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  strikePrice!,
                  maxLines: 1,
                  style: context.text
                      .of(AppFontSize.s11, height: AppLineHeight.base)
                      .copyWith(
                        color: c.muted,
                        decoration: TextDecoration.lineThrough,
                      ),
                ),
                const SizedBox(width: AppSpacing.s4),
                priceOnly,
              ],
            ),
          );
    final stepper = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ?packs,
        if (onRemoveOne != null) ...<Widget>[
          _StepButton(
            size: m.productStepperFirst,
            icon: AppIcons.minus,
            iconSize: AppSizes.stepperMinusIcon,
            tooltip: s.removeOneTooltip(name),
            onTap: onRemoveOne!,
          ),
          SizedBox(width: m.productStepperGap),
        ],
        _StepButton(
          size: m.productStepperButton,
          icon: AppIcons.plus,
          iconSize: AppSizes.stepperPlusIcon,
          tooltip: s.addProductTooltip(name),
          onTap: onAdd,
        ),
      ],
    );
    if (gap != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          priceText,
          SizedBox(width: gap),
          stepper,
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Flexible(child: priceText),
        stepper,
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.size,
    required this.icon,
    required this.iconSize,
    required this.tooltip,
    required this.onTap,
  });

  final double size;
  final IconData icon;
  final double iconSize;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppPressable(
      tooltip: tooltip,
      onTap: onTap,
      borderRadius: size / 2,
      builder: (context, hovered) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.productStepperBg,
        ),
        child: Icon(icon, size: iconSize, color: c.blue),
      ),
    );
  }
}

class _FavouriteButton extends StatelessWidget {
  const _FavouriteButton({required this.favourite, required this.onTap});

  final bool favourite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppPressable(
      tooltip: context.strings.favouriteTooltip(),
      onTap: onTap,
      borderRadius: AppRadii.r4,
      builder: (context, hovered) => Padding(
        padding: const EdgeInsets.all(AppSpacing.s3),
        child: StarIcon(
          size: AppSizes.favouriteIcon,
          color: favourite ? c.favouriteActive : c.favouriteFg,
          fill: favourite ? c.favouriteFill : null,
        ),
      ),
    );
  }
}

class _QtyBadge extends StatelessWidget {
  const _QtyBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.qtyBadgeBg,
        borderRadius: BorderRadius.circular(AppRadii.r5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s6,
          vertical: AppSpacing.s3,
        ),
        child: Text(
          text,
          style: context.text
              .of(
                AppFontSize.s11,
                weight: AppFontWeight.bold,
                height: AppLineHeight.base,
              )
              .copyWith(color: c.qtyBadgeFg),
        ),
      ),
    );
  }
}

class OfferBadge extends StatelessWidget {
  const OfferBadge({required this.label, required this.style, super.key});

  final String label;
  final ProductOfferStyle style;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = switch (style) {
      ProductOfferStyle.discount => (c.actionRedBg, c.actionRedFg),
      ProductOfferStyle.promotion => (c.actionPurpleBg, c.actionPurpleFg),
      ProductOfferStyle.gift => (c.modalSymbolGreenBg, c.modalSymbolGreenFg),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.r5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s6,
          vertical: AppSpacing.s3,
        ),
        child: Text(
          label,
          maxLines: 1,
          style: context.text
              .of(
                AppFontSize.s11,
                weight: AppFontWeight.bold,
                height: AppLineHeight.base,
              )
              .copyWith(color: fg),
        ),
      ),
    );
  }
}
