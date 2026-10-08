import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_checkout_sizes.dart';
import '../../core/theme/tokens/app_typography.dart';
import 'app_pressable.dart';

/// `.modal-list>button`: icon, a bold title with a small muted line under it,
/// and a trailing widget; padding 17 / 8, 12 px gaps, a bottom border, the
/// secondary fill on hover (and while [highlighted] by the arrow keys).
class ModalListRow extends StatelessWidget {
  const ModalListRow({
    required this.icon,
    required this.iconSize,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    this.highlighted = false,
    this.semanticLabel,
    super.key,
  });

  final IconData icon;
  final double iconSize;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;
  final bool highlighted;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final titleStyle = context.text.of(
      AppFontSize.s14,
      weight: AppFontWeight.bold,
      height: AppLineHeight.base,
    );
    return AppPressable(
      semanticLabel: semanticLabel ?? title,
      onTap: onTap,
      builder: (context, hovered) => Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppCheckoutSizes.modalListRowPadY,
          horizontal: AppCheckoutSizes.modalListRowPadX,
        ),
        decoration: BoxDecoration(
          color: hovered || highlighted ? c.secondary : null,
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: iconSize, color: c.text),
            const SizedBox(width: AppCheckoutSizes.modalListRowGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle.copyWith(color: c.text),
                  ),
                  const SizedBox(
                    height: AppCheckoutSizes.modalListSmallMarginTop,
                  ),
                  Text(
                    subtitle,
                    style: context.text
                        .fluid(AppCheckoutSizes.modalListSmallFont)
                        .copyWith(color: c.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppCheckoutSizes.modalListRowGap),
            trailing,
          ],
        ),
      ),
    );
  }
}
