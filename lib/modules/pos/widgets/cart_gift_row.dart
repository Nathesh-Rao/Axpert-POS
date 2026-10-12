import 'package:flutter/material.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_shadows.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../features/offers/domain/services/offer_engine.dart';

/// A free item of a "spend X, get Y free" tier: locked (lock icon and how much
/// more to add) until the cart value reaches the tier, then unlocked at price
/// 0. Not editable and not removable: the cart value decides (DEC-134).
class CartGiftRow extends StatelessWidget {
  const CartGiftRow({required this.gift, super.key});

  final GiftRow gift;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final m = context.metrics;
    final text = context.text;
    final unlocked = gift.unlocked;
    final name = gift.product.name;
    final subtitle = unlocked
        ? s.giftFreeLabel(gift.offer.name)
        : s.giftLockedHint(MoneyFormatter.format(gift.remaining));
    return Semantics(
      label: unlocked
          ? s.giftUnlockedSemantics(name)
          : s.giftLockedSemantics(name),
      child: ExcludeSemantics(
        child: Container(
          constraints: BoxConstraints(minHeight: m.cartLineMinHeight),
          margin: const EdgeInsets.only(bottom: AppSizes.cartLineMargin),
          padding: const EdgeInsets.all(AppSizes.cartPad),
          decoration: BoxDecoration(
            color: unlocked ? c.modalSymbolGreenBg : c.secondary,
            borderRadius: BorderRadius.circular(AppRadii.r12),
            border: Border.all(color: c.border),
            boxShadow: AppShadows.cartLine.boxShadows,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: AppSizes.cartLineImage,
                height: AppSizes.cartLineImage,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(
                    AppSizes.cartLineImageRadius,
                  ),
                ),
                child: Icon(
                  unlocked ? AppIcons.gift : AppIcons.lock,
                  size: AppSizes.favouriteIcon,
                  color: unlocked ? c.modalSymbolGreenFg : c.muted,
                ),
              ),
              const SizedBox(width: AppSizes.cartLineGap),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text
                          .of(
                            AppFontSize.s14,
                            weight: AppFontWeight.semiBold,
                            height: AppLineHeight.lineName,
                          )
                          .copyWith(color: unlocked ? c.text : c.muted),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      subtitle,
                      style: text
                          .of(AppFontSize.s11, height: AppLineHeight.lineSmall)
                          .copyWith(
                            color: unlocked ? c.modalSymbolGreenFg : c.muted,
                          ),
                    ),
                  ],
                ),
              ),
              if (unlocked) ...<Widget>[
                const SizedBox(width: AppSizes.cartLineGap),
                Text(
                  s.giftFreePrice(),
                  maxLines: 1,
                  style: text
                      .of(
                        AppFontSize.s16,
                        weight: AppFontWeight.bold,
                        height: AppLineHeight.base,
                      )
                      .copyWith(color: c.modalSymbolGreenFg),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
