import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_radii.dart';
import '../../core/theme/tokens/app_shadows.dart';
import '../../core/theme/tokens/app_sizes.dart';
import '../../core/theme/tokens/app_spacing.dart';

/// Panel anchored under [anchor], right edges aligned, 12 px below (the
/// prototype's `.popover`). Visibility is driven by [open]; there is no
/// outside-click dismissal (port as-is, controller closes it).
class AppPopover extends StatefulWidget {
  const AppPopover({
    required this.open,
    required this.anchor,
    required this.child,
    this.minWidth = AppSizes.popoverMinWidth,
    this.padding = const EdgeInsets.all(AppSpacing.s7),
    super.key,
  });

  final bool open;
  final Widget anchor;
  final Widget child;
  final double minWidth;
  final EdgeInsetsGeometry padding;

  @override
  State<AppPopover> createState() => _AppPopoverState();
}

class _AppPopoverState extends State<AppPopover> {
  final OverlayPortalController _portal = OverlayPortalController();
  final LayerLink _link = LayerLink();

  @override
  void initState() {
    super.initState();
    if (widget.open) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.open) _portal.show();
      });
    }
  }

  @override
  void didUpdateWidget(AppPopover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open != oldWidget.open) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.open ? _portal.show() : _portal.hide();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (context) {
          final c = context.colors;
          return CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, AppSizes.popoverOffset),
            child: Align(
              alignment: Alignment.topRight,
              child: Material(
                type: MaterialType.transparency,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: widget.minWidth),
                  child: IntrinsicWidth(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(AppRadii.r10),
                        border: Border.all(color: c.border),
                        boxShadow: AppShadows.popover.boxShadows,
                      ),
                      child: Padding(
                        padding: widget.padding,
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        child: widget.anchor,
      ),
    );
  }
}
