import 'package:flutter/material.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/cart_compact_columns.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_density_sizes.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_typography.dart';

/// Head of the desktop cart table. Same columns as the rows
/// ([CartCompactColumns]); numbers are right aligned, the quantity centered.
class CartCompactHead extends StatelessWidget {
  const CartCompactHead({required this.columns, super.key});

  final CartCompactColumns columns;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final style = context.text
        .of(
          AppFontSize.s12,
          weight: AppFontWeight.semiBold,
          height: AppLineHeight.base,
        )
        .copyWith(color: c.muted);
    Widget cell(String text, double width, TextAlign align) => SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: align,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.clip,
        style: style,
      ),
    );
    final gap = SizedBox(width: columns.gap);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: c.border,
            width: AppDensitySizes.cartRowHairline,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.cartHeadPadY / 2,
          horizontal: AppSizes.cartPad,
        ),
        child: Row(
          children: <Widget>[
            if (columns.showIndex) ...<Widget>[
              cell(s.cartTableNumber(), columns.index, TextAlign.center),
              gap,
            ],
            if (columns.showThumb) SizedBox(width: columns.thumb + columns.gap),
            Expanded(
              child: Text(
                s.cartTableItem(),
                maxLines: 1,
                softWrap: false,
                style: style,
              ),
            ),
            gap,
            cell(s.cartTableQty(), columns.qty, TextAlign.center),
            gap,
            if (columns.showPrice) ...<Widget>[
              cell(s.cartTablePrice(), columns.price, TextAlign.right),
              gap,
            ],
            cell(s.cartTableDiscount(), columns.disc, TextAlign.right),
            gap,
            cell(s.cartTableTotal(), columns.total, TextAlign.right),
            gap,
            SizedBox(width: columns.delete),
          ],
        ),
      ),
    );
  }
}
