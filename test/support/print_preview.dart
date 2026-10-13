import 'package:flutter/material.dart';
import 'package:pos_application/core/services/print/receipt_print_model.dart';

/// Draws a [ReceiptPrintModel] the way the PDF builder lays it out (rows, sizes,
/// dashed rules), on white paper `paperMm` wide at 96 dpi. Test support for the
/// print golden: it checks content and row structure, not PDF pixels.
class PrintPreview extends StatelessWidget {
  const PrintPreview({required this.model, this.paperMm = 80, super.key});

  final ReceiptPrintModel model;
  final int paperMm;

  static const double _px = 96 / 25.4;
  static const String font = 'RobotoCondensed';

  @override
  Widget build(BuildContext context) {
    final base = (paperMm >= 70 ? 9.5 : 8.5) * 96 / 72;
    TextStyle style(bool bold, PrintSize size) => TextStyle(
      fontFamily: font,
      color: Colors.black,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      fontSize:
          base *
          switch (size) {
            PrintSize.small => 0.88,
            PrintSize.normal => 1.0,
            PrintSize.large => 1.45,
          },
    );
    Widget row(PrintRow r) => switch (r) {
      PrintText() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: SizedBox(
          width: double.infinity,
          child: Text(
            r.text,
            textAlign: r.center ? TextAlign.center : TextAlign.left,
            style: style(r.bold, r.size),
          ),
        ),
      ),
      PrintColumns() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(r.label, style: style(r.bold, r.size)),
            Text(r.value, style: style(r.bold, r.size)),
          ],
        ),
      ),
      PrintItem() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(r.name, style: style(false, PrintSize.normal)),
            if (r.note != null)
              Text(r.note!, style: style(false, PrintSize.small)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(r.qty, style: style(false, PrintSize.small)),
                Text(r.total, style: style(false, PrintSize.normal)),
              ],
            ),
          ],
        ),
      ),
      PrintDivider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: _Dashes(),
      ),
    };
    return Container(
      width: paperMm * _px,
      color: Colors.white,
      padding: const EdgeInsets.all(3 * _px),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[for (final r in model.rows) row(r)],
      ),
    );
  }
}

class _Dashes extends StatelessWidget {
  const _Dashes();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => Row(
      children: <Widget>[
        for (var i = 0; i < c.maxWidth ~/ 6; i++)
          const Padding(
            padding: EdgeInsets.only(right: 2),
            child: SizedBox(
              width: 4,
              height: 0.7,
              child: ColoredBox(color: Colors.black),
            ),
          ),
      ],
    ),
  );
}
