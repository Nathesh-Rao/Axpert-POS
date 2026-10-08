import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_sizes.dart';

/// A button-like region: hover, keyboard focus ring (`:focus-visible`, 2 px,
/// offset 2), Enter/Space activation, pointer cursor. No ink splash.
class AppPressable extends StatelessWidget {
  const AppPressable({
    required this.builder,
    required this.onTap,
    this.focusNode,
    this.tooltip,
    this.borderRadius = 0,
    this.semanticLabel,
    super.key,
  });

  final Widget Function(BuildContext context, bool hovered) builder;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final String? tooltip;
  final double borderRadius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return _PressableBody(
      builder: builder,
      onTap: onTap,
      focusNode: focusNode,
      tooltip: tooltip,
      borderRadius: borderRadius,
      semanticLabel: semanticLabel,
    );
  }
}

class _PressableBody extends StatefulWidget {
  const _PressableBody({
    required this.builder,
    required this.onTap,
    required this.focusNode,
    required this.tooltip,
    required this.borderRadius,
    required this.semanticLabel,
  });

  final Widget Function(BuildContext context, bool hovered) builder;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final String? tooltip;
  final double borderRadius;
  final String? semanticLabel;

  @override
  State<_PressableBody> createState() => _PressableBodyState();
}

class _PressableBodyState extends State<_PressableBody> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final ringVisible =
        _focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    Widget child = FocusableActionDetector(
      enabled: enabled,
      focusNode: widget.focusNode,
      mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            widget.builder(context, _hovered),
            if (ringVisible)
              Positioned(
                left: -AppSizes.focusRingOffset,
                top: -AppSizes.focusRingOffset,
                right: -AppSizes.focusRingOffset,
                bottom: -AppSizes.focusRingOffset,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        widget.borderRadius + AppSizes.focusRingOffset,
                      ),
                      border: Border.all(
                        color: context.colors.focusRing,
                        width: AppSizes.focusRingWidth,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (widget.semanticLabel != null) {
      child = Semantics(
        button: true,
        label: widget.semanticLabel,
        child: child,
      );
    }
    if (widget.tooltip != null) {
      child = Tooltip(message: widget.tooltip, child: child);
    }
    return child;
  }
}
