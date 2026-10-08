import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_sizes.dart';
import 'focus_outline.dart';

/// A boxed single-line text input (`input` inside `.field` or on its own):
/// fixed height, fill, 1 px border, the prototype's focus outline.
class AppInputBox extends StatefulWidget {
  const AppInputBox({
    required this.controller,
    required this.style,
    required this.height,
    required this.radius,
    this.focusNode,
    this.hint,
    this.fill,
    this.borderColor,
    this.padding = EdgeInsets.zero,
    this.enabled = true,
    this.readOnly = false,
    this.digitsOnly = false,
    this.decimal = false,
    this.textAlign = TextAlign.start,
    this.semanticLabel,
    this.onChanged,
    this.onSubmitted,
    this.onKey,
    this.trailing,
    this.opacity = 1,
    super.key,
  });

  final TextEditingController controller;
  final TextStyle style;
  final double height;
  final double radius;
  final FocusNode? focusNode;
  final String? hint;
  final Color? fill;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final bool enabled;
  final bool readOnly;

  /// Only `0-9` (whole numbers).
  final bool digitsOnly;

  /// Only `0-9 .` (non-negative decimals; KG-100).
  final bool decimal;
  final TextAlign textAlign;
  final String? semanticLabel;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final KeyEventResult Function(FocusNode, KeyEvent)? onKey;
  final Widget? trailing;
  final double opacity;

  @override
  State<AppInputBox> createState() => _AppInputBoxState();
}

class _AppInputBoxState extends State<AppInputBox> {
  FocusNode? _own;

  FocusNode get _focus =>
      widget.focusNode ?? (_own ??= FocusNode(debugLabel: 'input-box'));

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final field = TextField(
      controller: widget.controller,
      focusNode: _focus,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      textAlign: widget.textAlign,
      textAlignVertical: TextAlignVertical.center,
      strutStyle: StrutStyle.fromTextStyle(
        widget.style,
        forceStrutHeight: true,
      ),
      expands: true,
      maxLines: null,
      minLines: null,
      style: widget.style,
      cursorColor: c.blue,
      keyboardType: widget.digitsOnly || widget.decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: <TextInputFormatter>[
        if (widget.digitsOnly) FilteringTextInputFormatter.digitsOnly,
        if (widget.decimal)
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        hintText: widget.hint,
        hintMaxLines: 1,
        hintStyle: widget.style.copyWith(color: c.placeholder),
      ),
    );
    // The field is multi-line (`expands`), so Enter would insert a newline:
    // Enter submits instead, as a single-line `<input>` does.
    Widget input = Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            widget.onSubmitted != null &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
          widget.onSubmitted!(widget.controller.text);
          return KeyEventResult.handled;
        }
        return widget.onKey?.call(node, event) ?? KeyEventResult.ignored;
      },
      child: field,
    );
    final box = Container(
      height: widget.height,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.fill ?? c.secondary,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(
          color: widget.borderColor ?? c.border,
          width: AppSizes.borderWidth,
        ),
      ),
      child: widget.trailing == null
          ? input
          : Row(
              children: <Widget>[
                Expanded(child: input),
                widget.trailing!,
              ],
            ),
    );
    // The outline surrounds the whole box (border included), as the
    // prototype's `outline` on the `input` does, so it never touches the text.
    final outlined = FocusOutline(
      focusNode: _focus,
      borderRadius: widget.radius,
      child: box,
    );
    return Semantics(
      label: widget.semanticLabel,
      textField: true,
      child: widget.opacity == 1
          ? outlined
          : Opacity(opacity: widget.opacity, child: outlined),
    );
  }
}
