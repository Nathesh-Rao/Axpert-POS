import 'package:flutter/material.dart';

import '../../core/responsive/app_metrics_scope.dart';
import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_checkout_sizes.dart';
import '../../core/theme/tokens/app_radii.dart';
import '../../core/theme/tokens/app_shadows.dart';
import '../../core/theme/tokens/app_sizes.dart';
import 'app_modal.dart';

/// `.modal.drawer`: the modal shell docked to the right edge, 390 wide (at
/// most the window), full height, rounded on the left, 45 px top padding.
/// Content that does not fit scrolls (`.modal{overflow:auto}`).
class AppDrawer extends StatelessWidget {
  const AppDrawer({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = context.metrics;
    return Align(
      alignment: Alignment.centerRight,
      child: LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          width: constraints.maxWidth < AppSizes.drawerWidth
              ? constraints.maxWidth
              : AppSizes.drawerWidth,
          height: constraints.maxHeight,
          child: Material(
            type: MaterialType.transparency,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadii.r16),
                ),
                boxShadow: AppShadows.modal.boxShadows,
              ),
              child: Stack(
                children: <Widget>[
                  SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      m.modalPad,
                      AppCheckoutSizes.drawerPadTop,
                      m.modalPad,
                      m.modalPad,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  ),
                  const ModalCloseButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.modal-symbol`: 57 square, 14 radius, tinted blue, centred icon.
class ModalSymbol extends StatelessWidget {
  const ModalSymbol({
    required this.icon,
    this.iconSize = AppCheckoutSizes.symbolIcon,
    super.key,
  });

  final IconData icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: AppSizes.modalSymbol,
        height: AppSizes.modalSymbol,
        margin: const EdgeInsets.only(
          bottom: AppCheckoutSizes.symbolMarginBottom,
        ),
        decoration: BoxDecoration(
          color: c.modalSymbolBg,
          borderRadius: BorderRadius.circular(AppRadii.r14),
        ),
        child: Icon(icon, size: AppCheckoutSizes.symbolIcon, color: c.blue),
      ),
    );
  }
}
