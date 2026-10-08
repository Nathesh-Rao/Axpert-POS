import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/pricing/decimal_parser.dart';
import '../../core/theme/theme_x.dart';
import '../../core/utils/decimal_text.dart';
import 'focus_outline.dart';

/// Small numeric input of a cart line (price, discount %). The value is an
/// integer scaled by `10^scale`; every valid edit is committed at once through
/// [onValue]. While focused the typed text is kept unless the committed value
/// differs from what was typed (clamping), as a controlled React input does.
class NumberField extends StatefulWidget {
  const NumberField({
    required this.value,
    required this.scale,
    required this.onValue,
    required this.style,
    required this.semanticLabel,
    super.key,
  });

  final int value;
  final int scale;
  final ValueChanged<int> onValue;
  final TextStyle style;
  final String semanticLabel;

  @override
  State<NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<NumberField> {
  late final TextEditingController _controller = TextEditingController(
    text: DecimalText.scaled(widget.value, widget.scale),
  );
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _showCanonical();
    });
  }

  @override
  void didUpdateWidget(NumberField old) {
    super.didUpdateWidget(old);
    if (widget.value == old.value) return;
    final typed = _parse(_controller.text);
    if (!_focus.hasFocus || typed != widget.value) _showCanonical();
  }

  int? _parse(String text) {
    try {
      return DecimalParser.parseScaled(text, widget.scale);
    } on FormatException {
      return null;
    }
  }

  void _showCanonical() {
    final text = DecimalText.scaled(widget.value, widget.scale);
    if (_controller.text == text) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _changed(String text) {
    final parsed = text.isEmpty ? null : _parse(text);
    if (parsed != null) widget.onValue(parsed);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusOutline(
      focusNode: _focus,
      child: Semantics(
        label: widget.semanticLabel,
        textField: true,
        child: TextField(
          controller: _controller,
          focusNode: _focus,
          textAlign: TextAlign.center,
          style: widget.style,
          cursorColor: context.colors.text,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
          ],
          onChanged: _changed,
          onSubmitted: (_) => _focus.unfocus(),
          decoration: const InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
