import 'package:flutter/material.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/cart_compact_columns.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_density_sizes.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../features/offers/domain/services/offer_engine.dart';

/// A free item of a "spend X, get Y free" tier in the desktop table: the same
/// 48 px row as a line. Locked: lock icon and how much more to add; unlocked:
/// gift icon, the offer text and FREE. Not editable, not removable (DEC-134).
class CartCompactGiftRow extends StatelessWidget {
  const CartCompactGiftRow({
    required this.gift,
    required this.columns,
    super.key,
  });

  final GiftRow gift;
  final CartCompactColumns columns;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final text = context.text;
    final unlocked = gift.unlocked;
    final name = gift.product.name;
    final subtitle = unlocked
        ? s.giftFreeLabel(gift.offer.name)
        : s.giftLockedHint(MoneyFormatter.format(gift.remaining));
    final iconBox = Container(
      width: AppDensitySizes.cartRowThumb,
      height: AppDensitySizes.cartRowThumb,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: unlocked ? c.card : c.secondary,
        borderRadius: BorderRadius.circular(AppSizes.cartLineImageRadius),
      ),
      child: Icon(
        unlocked ? AppIcons.gift : AppIcons.lock,
        size: AppDensitySizes.deleteIcon,
        color: unlocked ? c.modalSymbolGreenFg : c.muted,
      ),
    );
    return Semantics(
      label: unlocked
          ? s.giftUnlockedSemantics(name)
          : s.giftLockedSemantics(name),
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: unlocked ? c.modalSymbolGreenBg : c.card,
            border: Border(
              bottom: BorderSide(
                color: c.border,
                width: AppDensitySizes.cartRowHairline,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.cartPad),
            child: Row(
              children: <Widget>[
                // The icon takes the number and thumbnail columns.
                SizedBox(
                  width: columns.showIndex || columns.showThumb
                      ? columns.index +
                            (columns.showIndex ? columns.gap : 0) +
                            columns.thumb
                      : AppDensitySizes.cartRowThumb,
                  child: Center(child: iconBox),
                ),
                SizedBox(width: columns.gap),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        name,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: text
                            .of(
                              AppFontSize.s14,
                              weight: AppFontWeight.semiBold,
                              height: AppLineHeight.lineName,
                            )
                            .copyWith(
                              color: unlocked ? c.modalSymbolGreenFg : c.muted,
                            ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: text
                            .of(
                              AppFontSize.s11,
                              height: AppLineHeight.lineSmall,
                            )
                            .copyWith(
                              color: unlocked ? c.modalSymbolGreenFg : c.muted,
                            ),
                      ),
                    ],
                  ),
                ),
                if (unlocked) ...<Widget>[
                  SizedBox(width: columns.gap),
                  Text(
                    s.giftFreePrice(),
                    maxLines: 1,
                    softWrap: false,
                    style: text
                        .of(
                          AppFontSize.s16,
                          weight: AppFontWeight.bold,
                          height: AppLineHeight.base,
                        )
                        .copyWith(color: c.modalSymbolGreenFg),
                  ),
                  SizedBox(width: columns.gap + columns.delete),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
