import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/responsive/app_metrics_scope.dart';
import '../../../../core/services/packaging/packaging_label.dart';
import '../../../../core/services/pricing/qty.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens/app_pack_sizes.dart';
import '../../../../core/theme/tokens/app_radii.dart';
import '../../../../core/theme/tokens/app_shadows.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/utils/qty_formatter.dart';
import '../../../../shared/widgets/app_pressable.dart';
import '../../models/unit_option.dart';

/// "Piece" for the base unit, "Carton of 24" for a packaging.
String unitOptionText(BuildContext context, UnitOption o) => o.isBase
    ? o.name
    : PackagingLabel.sized(o.name, QtyFormatter.compact(Qty(o.factorMilli)));

/// A popover with the units of a product and their prices (DEC-154). The
/// [trigger] builds the control that opens it; arrow keys move, Enter picks,
/// Esc closes (the popover handles Esc itself so the page does not).
class UnitPopover extends StatefulWidget {
  const UnitPopover({
    required this.options,
    required this.currentPackagingId,
    required this.onPick,
    required this.trigger,
    super.key,
  });

  final List<UnitOption> options;

  /// The packaging of the current unit; null = the base unit.
  final String? currentPackagingId;
  final ValueChanged<UnitOption> onPick;
  final Widget Function(BuildContext context, VoidCallback toggle) trigger;

  @override
  State<UnitPopover> createState() => _UnitPopoverState();
}

class _UnitPopoverState extends State<UnitPopover> {
  final OverlayPortalController _portal = OverlayPortalController();
  final LayerLink _link = LayerLink();
  final Object _group = Object();
  final FocusNode _focus = FocusNode(debugLabel: 'unit-popover');
  int _active = 0;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_portal.isShowing) {
      _close();
      return;
    }
    _active = widget.options.indexWhere(
      (o) => o.packagingId == widget.currentPackagingId,
    );
    if (_active < 0) _active = 0;
    _portal.show();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _portal.isShowing) _focus.requestFocus();
    });
  }

  void _close() {
    if (_portal.isShowing) _portal.hide();
    if (mounted) setState(() {});
  }

  void _pick(UnitOption option) {
    _close();
    widget.onPick(option);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final count = widget.options.length;
    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() => _active = (_active + 1) % count);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() => _active = (_active - 1 + count) % count);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _pick(widget.options[_active]);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final touch = context.metrics.touch;
    final rowHeight = touch
        ? AppPackSizes.popoverRowTouch
        : AppPackSizes.popoverRow;
    final style = context.text.of(AppFontSize.s13).copyWith(color: c.text);
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
                child: Focus(
                  focusNode: _focus,
                  onKeyEvent: _onKey,
                  child: Material(
                    type: MaterialType.transparency,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: AppPackSizes.popoverMinWidth,
                      ),
                      child: IntrinsicWidth(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: c.card,
                            borderRadius: BorderRadius.circular(AppRadii.r10),
                            border: Border.all(color: c.border),
                            boxShadow: AppShadows.popover.boxShadows,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(
                              AppPackSizes.popoverPad,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                for (var i = 0; i < widget.options.length; i++)
                                  AppPressable(
                                    borderRadius: AppRadii.r6,
                                    onTap: () => _pick(widget.options[i]),
                                    builder: (context, hovered) => DecoratedBox(
                                      decoration: BoxDecoration(
                                        color:
                                            hovered ||
                                                i == _active ||
                                                widget.options[i].packagingId ==
                                                    widget.currentPackagingId
                                            ? c.secondary
                                            : null,
                                        borderRadius: BorderRadius.circular(
                                          AppRadii.r6,
                                        ),
                                      ),
                                      child: SizedBox(
                                        height: rowHeight,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.s11,
                                          ),
                                          child: Row(
                                            children: <Widget>[
                                              Expanded(
                                                child: Text(
                                                  unitOptionText(
                                                    context,
                                                    widget.options[i],
                                                  ),
                                                  maxLines: 1,
                                                  softWrap: false,
                                                  style: style,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: AppSpacing.s11,
                                              ),
                                              Text(
                                                MoneyFormatter.format(
                                                  widget.options[i].price,
                                                ),
                                                maxLines: 1,
                                                softWrap: false,
                                                style: style.copyWith(
                                                  color: c.muted,
                                                ),
                                              ),
                                            ],
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
          ),
          child: widget.trigger(context, _toggle),
        ),
      ),
    );
  }
}
