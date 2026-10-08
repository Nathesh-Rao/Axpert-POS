import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_icons.dart';
import '../../core/theme/tokens/app_radii.dart';
import '../../core/theme/tokens/app_shadows.dart';
import '../../core/theme/tokens/app_sizes.dart';
import '../../core/theme/tokens/app_spacing.dart';
import 'app_pressable.dart';

/// A borderless select (`<select>` inside a `.field`): current label plus a
/// chevron; the list opens below as a popover-styled menu.
class AppDropdown<T> extends StatefulWidget {
  const AppDropdown({
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    required this.style,
    this.semanticLabel,
    super.key,
  });

  final T value;
  final List<T> items;
  final String Function(T item) labelOf;
  final ValueChanged<T> onChanged;
  final TextStyle style;
  final String? semanticLabel;

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
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
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: _width,
                      maxHeight: AppSizes.dropdownMaxHeight,
                    ),
                    child: IntrinsicWidth(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(AppRadii.r10),
                          border: Border.all(color: c.border),
                          boxShadow: AppShadows.popover.boxShadows,
                        ),
                        child: SingleChildScrollView(
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
                                      child: Text(
                                        widget.labelOf(item),
                                        maxLines: 1,
                                        softWrap: false,
                                        style: widget.style.copyWith(
                                          color: c.text,
                                        ),
                                      ),
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
          ),
          child: AppPressable(
            semanticLabel: widget.semanticLabel,
            borderRadius: AppRadii.r6,
            onTap: _toggle,
            builder: (context, hovered) => Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    widget.labelOf(widget.value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: widget.style.copyWith(color: c.text),
                  ),
                ),
                Icon(
                  AppIcons.chevronDown,
                  size: AppSizes.dropdownChevron,
                  color: c.fieldIcon,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
