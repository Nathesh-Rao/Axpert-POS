import 'package:flutter/material.dart';

import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_rail_sizes.dart';
import '../../../shared/widgets/app_pressable.dart';
import '../models/nav_destination.dart';

/// One icon-only item of the rail card: a square hit target with the icon
/// centered. States: default, hover, pressed, focus (ring from
/// [AppPressable]), selected, disabled (`onTap == null`).
class RailItem extends StatefulWidget {
  const RailItem({
    required this.destination,
    required this.label,
    required this.active,
    required this.onTap,
    this.badge,
    super.key,
  });

  final NavDestination destination;

  /// Tooltip and semantics label (the item's name).
  final String label;
  final bool active;
  final VoidCallback? onTap;

  /// Optional count badge, drawn in the corner slot. Not used yet.
  final Widget? badge;

  @override
  State<RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<RailItem> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final rail = context.rail;
    final size = context.metrics.railSizes.item;
    final enabled = widget.onTap != null;
    final iconColor = !enabled
        ? rail.iconDisabled
        : widget.active
        ? rail.iconSelected
        : rail.icon;
    return Semantics(
      selected: widget.active,
      child: Listener(
        onPointerDown: (_) => _setPressed(true),
        onPointerUp: (_) => _setPressed(false),
        onPointerCancel: (_) => _setPressed(false),
        child: AppPressable(
          tooltip: widget.label,
          semanticLabel: widget.label,
          borderRadius: AppRadii.r10,
          onTap: widget.onTap,
          builder: (context, hovered) {
            final Color? background = !enabled
                ? null
                : _pressed
                ? rail.pressedBackground
                : widget.active
                ? rail.selectedBackground
                : hovered
                ? rail.hoverBackground
                : null;
            return SizedBox(
              width: size,
              height: size,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(AppRadii.r10),
                      ),
                      child: Center(
                        child: Icon(
                          widget.destination.icon,
                          size: AppRailSizes.icon,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ),
                  if (widget.badge != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      width: AppRailSizes.badgeSlot,
                      height: AppRailSizes.badgeSlot,
                      child: widget.badge!,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
