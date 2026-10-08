import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/pricing/decimal_parser.dart';
import '../../core/services/pricing/qty.dart';
import '../../core/theme/theme_x.dart';
import '../../core/utils/qty_formatter.dart';
import 'focus_outline.dart';

/// Quantity input of a cart line (prototype `QuantityInput`): shows the value
/// with 3 decimals; while editing, every positive valid number is committed at
/// once; leaving the field with 0 commits 0 (removes the line) and always
/// shows the current value again; Enter leaves the field.
class QuantityField extends StatefulWidget {
  const QuantityField({
    required this.value,
    required this.onValue,
    required this.style,
    required this.semanticLabel,
    super.key,
  });

  final Qty value;
  final ValueChanged<Qty> onValue;
  final TextStyle style;
  final String semanticLabel;

  @override
  State<QuantityField> createState() => _QuantityFieldState();
}

class _QuantityFieldState extends State<QuantityField> {
  late final TextEditingController _controller = TextEditingController(
    text: QtyFormatter.fixed3(widget.value),
  );
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    if (_focus.hasFocus) return;
    final text = _controller.text;
    if (text.isNotEmpty && _toQty(text)?.milli == 0) {
      widget.onValue(Qty.zero);
    }
    _show(widget.value);
  }

  @override
  void didUpdateWidget(QuantityField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && widget.value != old.value) _show(widget.value);
  }

  Qty? _toQty(String text) {
    try {
      return Qty(DecimalParser.parseScaled(text, Qty.scale));
    } on FormatException {
      return null;
    }
  }

  void _show(Qty qty) {
    final text = QtyFormatter.fixed3(qty);
    if (_controller.text == text) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _changed(String text) {
    final qty = text.isEmpty ? null : _toQty(text);
    if (qty != null && qty > Qty.zero) widget.onValue(qty);
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
          textAlignVertical: TextAlignVertical.center,
          expands: true,
          maxLines: null,
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
