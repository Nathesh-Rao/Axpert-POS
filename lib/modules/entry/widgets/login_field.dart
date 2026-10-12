import 'package:flutter/material.dart';

import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_entry_tokens.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../shared/widgets/focus_outline.dart';

/// A boxed login input: leading icon, optional trailing widget, hover, focus
/// ring and error border. [scale] is the window-width scale (EntryMetrics).
class LoginField extends StatefulWidget {
  const LoginField({
    required this.controller,
    required this.focusNode,
    required this.icon,
    required this.hint,
    required this.semanticLabel,
    required this.scale,
    this.error = false,
    this.obscure = false,
    this.trailing,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final IconData icon;
  final String hint;
  final String semanticLabel;
  final double scale;
  final bool error;
  final bool obscure;
  final Widget? trailing;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<LoginField> createState() => _LoginFieldState();
}

class _LoginFieldState extends State<LoginField> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final entry = context.entryColors;
    final s = widget.scale;
    final style = context.text
        .fluid(AppEntrySizes.inputFont * s)
        .copyWith(color: c.text);
    final border = widget.error
        ? c.actionRedFg
        : _hovered
        ? entry.fieldHoverBorder
        : c.border;
    final radius = AppEntrySizes.fieldRadius * s;
    final height = (AppEntrySizes.fieldHeight * s).clamp(
      AppEntrySizes.minTouch,
      double.infinity,
    );
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: FocusOutline(
        focusNode: widget.focusNode,
        borderRadius: radius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: AppEntryMotion.controlMs),
          height: height,
          padding: EdgeInsets.symmetric(
            horizontal: AppEntrySizes.fieldPadding * s,
          ),
          decoration: BoxDecoration(
            color: entry.fieldFill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: border, width: AppSizes.borderWidth),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                widget.icon,
                size: AppEntrySizes.fieldIcon * s,
                color: c.fieldIcon,
              ),
              SizedBox(width: AppEntrySizes.fieldIconGap * s),
              Expanded(
                child: Semantics(
                  label: widget.semanticLabel,
                  textField: true,
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    obscureText: widget.obscure,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: widget.autofillHints,
                    textInputAction: TextInputAction.done,
                    textAlignVertical: TextAlignVertical.center,
                    style: style,
                    cursorColor: c.blue,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: widget.hint,
                      hintMaxLines: 1,
                      hintStyle: style.copyWith(color: c.placeholder),
                    ),
                  ),
                ),
              ),
              ?widget.trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Label above a field (`Username or Email`).
class LoginLabel extends StatelessWidget {
  const LoginLabel({required this.text, required this.scale, super.key});

  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.text
          .fluid(AppEntrySizes.labelFont * scale)
          .copyWith(color: context.colors.labelText),
    );
  }
}

/// Error line under a field.
class LoginError extends StatelessWidget {
  const LoginError({required this.text, required this.scale, super.key});

  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.text
          .fluid(AppEntrySizes.smallFont * scale, weight: AppFontWeight.medium)
          .copyWith(color: context.colors.actionRedFg),
    );
  }
}
