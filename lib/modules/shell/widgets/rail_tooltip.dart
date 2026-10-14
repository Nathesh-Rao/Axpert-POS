import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_rail_sizes.dart';
import '../../../core/theme/tokens/app_shadows.dart';
import '../../../core/theme/tokens/app_typography.dart';

/// Tooltip of a rail item: opens to the RIGHT of the item, vertically
/// centered, so it never covers the next item (Flutter's `Tooltip` only opens
/// above or below). Shown after a short delay on hover and at once on
/// keyboard focus; hidden on leave, press and Esc. The text is excluded from
/// semantics (the item carries the label).
class RailTooltip extends StatefulWidget {
  const RailTooltip({
    required this.message,
    required this.child,
    this.shortcut,
    super.key,
  });

  final String message;

  /// Shortcut label shown after the name, when the item has one.
  final String? shortcut;
  final Widget child;

  @override
  State<RailTooltip> createState() => _RailTooltipState();
}

class _RailTooltipState extends State<RailTooltip> {
  final OverlayPortalController _portal = OverlayPortalController();
  final LayerLink _link = LayerLink();
  Timer? _timer;
  bool _hovered = false;
  bool _focused = false;

  bool get _wanted => _hovered || _focused;

  void _sync() {
    _timer?.cancel();
    if (!_wanted) return _hide();
    if (_focused) return _show();
    _timer = Timer(AppRailSizes.tooltipDelay, () {
      if (mounted && _wanted) _show();
    });
  }

  void _show() {
    if (_portal.isShowing) return;
    _portal.show();
    ServicesBinding.instance.keyboard.addHandler(_onKey);
  }

  void _hide() {
    _timer?.cancel();
    if (!_portal.isShowing) return;
    ServicesBinding.instance.keyboard.removeHandler(_onKey);
    _portal.hide();
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _hovered = false;
      _focused = false;
      _hide();
    }
    return false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_portal.isShowing) {
      ServicesBinding.instance.keyboard.removeHandler(_onKey);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (context) => CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.centerRight,
          followerAnchor: Alignment.centerLeft,
          offset: const Offset(AppRailSizes.tooltipGap, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: _Bubble(
                  message: widget.message,
                  shortcut: widget.shortcut,
                ),
              ),
            ),
          ),
        ),
        child: MouseRegion(
          onEnter: (_) {
            _hovered = true;
            _sync();
          },
          onExit: (_) {
            _hovered = false;
            _sync();
          },
          child: Listener(
            onPointerDown: (_) {
              _hovered = false;
              _hide();
            },
            child: Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onFocusChange: (focused) {
                // Only keyboard focus shows it (not a click or a refocus).
                _focused =
                    focused &&
                    FocusManager.instance.highlightMode ==
                        FocusHighlightMode.traditional;
                _sync();
              },
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, this.shortcut});

  final String message;
  final String? shortcut;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = context.text
        .of(AppFontSize.s12, weight: AppFontWeight.medium)
        .copyWith(color: c.white, decoration: TextDecoration.none);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.tooltipBg,
        borderRadius: BorderRadius.circular(AppRadii.r6),
        boxShadow: AppShadows.tooltip.boxShadows,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppRailSizes.tooltipPadX,
          vertical: AppRailSizes.tooltipPadY,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(message, style: style, maxLines: 1),
            if (shortcut != null) ...<Widget>[
              const SizedBox(width: AppRailSizes.tooltipShortcutGap),
              Text(
                shortcut!,
                style: style.copyWith(color: c.white.withValues(alpha: 0.7)),
                maxLines: 1,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
