import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_radii.dart';
import '../../core/theme/tokens/app_shadows.dart';
import '../../core/theme/tokens/app_spacing.dart';
import 'app_pressable.dart';
import '../../core/theme/tokens/app_icons.dart';

/// Replacement for the prototype's native `<select>`: a flat button with a
/// chevron that opens a list under it. The native popup cannot be matched in
/// Flutter, so only the closed state follows the prototype (logged gap).
class AppSelect extends StatefulWidget {
  const AppSelect({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.fontSize,
    this.semanticLabel,
    super.key,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final double fontSize;
  final String? semanticLabel;

  @override
  State<AppSelect> createState() => _AppSelectState();
}

class _AppSelectState extends State<AppSelect> {
  final OverlayPortalController _portal = OverlayPortalController();
  final LayerLink _link = LayerLink();
  final Object _group = Object();
  double _width = 0;

  void _toggle() {
    if (_portal.isShowing) {
      _portal.hide();
    } else {
      _width = context.size?.width ?? 0;
      _portal.show();
    }
    setState(() {});
  }

  void _close() {
    if (_portal.isShowing) {
      _portal.hide();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = context.text.fluid(widget.fontSize);
    return TapRegion(
      groupId: _group,
      onTapOutside: (_) => _close(),
      child: CompositedTransformTarget(
        link: _link,
        child: OverlayPortal(
          controller: _portal,
          overlayChildBuilder: (context) => CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, AppSpacing.s4),
            child: Align(
              alignment: Alignment.topLeft,
              child: TapRegion(
                groupId: _group,
                child: Material(
                  type: MaterialType.transparency,
                  child: SizedBox(
                    width: _width,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(AppRadii.r10),
                        border: Border.all(color: c.border),
                        boxShadow: AppShadows.popover.boxShadows,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.s7),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            for (final item in widget.items)
                              AppPressable(
                                borderRadius: AppRadii.r6,
                                onTap: () {
                                  widget.onChanged(item);
                                  _close();
                                },
                                builder: (context, hovered) => DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: hovered || item == widget.value
                                        ? c.secondary
                                        : null,
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.r6,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.s11,
                                    ),
                                    child: Text(item, style: style),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          child: AppPressable(
            semanticLabel: widget.semanticLabel,
            borderRadius: AppRadii.r6,
            onTap: _toggle,
            builder: (context, hovered) => Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: c.border)),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s8,
                vertical: AppSpacing.s4,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      widget.value,
                      style: style,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    AppIcons.chevronDown,
                    size: widget.fontSize + AppSpacing.s6,
                    color: c.text,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
