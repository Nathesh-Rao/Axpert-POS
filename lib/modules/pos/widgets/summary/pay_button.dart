import 'package:flutter/material.dart';

import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../../core/theme/tokens/app_radii.dart';
import '../../../../core/theme/tokens/app_shadows.dart';
import '../../../../core/theme/tokens/app_sizes.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../shared/widgets/app_pressable.dart';

enum PayTone { cash, card }

/// `.payment-buttons button`: gradient fill while pressed (the active mode),
/// card background with a coloured border otherwise; 0.55 opacity disabled.
class PayButton extends StatelessWidget {
  const PayButton({
    required this.label,
    required this.icon,
    required this.tone,
    required this.pressed,
    required this.height,
    required this.fontSize,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final PayTone tone;
  final bool pressed;
  final double height;
  final double fontSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cash = tone == PayTone.cash;
    final fg = pressed ? c.white : (cash ? c.payCashIdleFg : c.payCardIdleFg);
    final body = AppPressable(
      onTap: onTap,
      borderRadius: AppRadii.r10,
      semanticLabel: label,
      builder: (context, hovered) => Container(
        height: height,
        decoration: BoxDecoration(
          gradient: pressed
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    cash ? c.payCashTop : c.payCardTop,
                    cash ? c.payCashBottom : c.payCardBottom,
                  ],
                )
              : null,
          color: pressed ? null : c.card,
          borderRadius: BorderRadius.circular(AppRadii.r10),
          border: Border.all(
            color: pressed
                ? c.white.withAlpha(0)
                : (cash ? c.payCashIdleBorder : c.payCardIdleBorder),
            width: AppCheckoutSizes.payButtonBorder,
          ),
          boxShadow: pressed ? AppShadows.payPressed.boxShadows : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: AppSizes.paymentIcon, color: fg),
            const SizedBox(width: AppSpacing.s8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: context.text
                    .fluid(fontSize, weight: AppFontWeight.semiBold)
                    .copyWith(color: fg),
              ),
            ),
          ],
        ),
      ),
    );
    return onTap == null
        ? Opacity(opacity: AppCheckoutSizes.disabledPayOpacity, child: body)
        : body;
  }
}
