import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_checkout_sizes.dart';
import '../../core/theme/tokens/app_icons.dart';
import '../../core/theme/tokens/app_typography.dart';

/// `.modal-list` plus the `.empty-state` under it: a scrolling list of
/// [rows] (at most `min(400px, 40dvh)` high, 20 px above and below) and, when
/// there are none, the file icon with [emptyText].
class ModalListView extends StatelessWidget {
  const ModalListView({required this.rows, required this.emptyText, super.key});

  final List<Widget> rows;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxHeight = [
      AppCheckoutSizes.modalListMaxHeight,
      MediaQuery.sizeOf(context).height *
          AppCheckoutSizes.modalListMaxHeightFraction,
    ].reduce((a, b) => a < b ? a : b);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppCheckoutSizes.modalListMarginY,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: rows,
                ),
              ),
            ),
          ),
        ),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppCheckoutSizes.emptyStatePadY,
              horizontal: AppCheckoutSizes.emptyStatePadX,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  AppIcons.fileText,
                  size: AppCheckoutSizes.emptyStateIcon,
                  color: c.muted,
                ),
                const SizedBox(height: AppCheckoutSizes.emptyStateGap),
                Text(
                  emptyText,
                  textAlign: TextAlign.center,
                  style: context.text
                      .of(AppFontSize.s14, height: AppLineHeight.base)
                      .copyWith(color: c.muted),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
