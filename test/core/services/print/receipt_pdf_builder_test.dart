import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/print/receipt_pdf_builder.dart';
import 'package:pos_application/core/services/print/receipt_print_model.dart';

Future<ByteData> _file(String asset) async {
  final bytes = await File(asset).readAsBytes();
  return ByteData.sublistView(bytes);
}

void main() {
  const model = ReceiptPrintModel(<PrintRow>[
    PrintText('AXPERT POS', center: true, bold: true, size: PrintSize.large),
    PrintDivider(),
    PrintItem(name: 'Cola ₹ €', qty: '1.000', total: '₹100.00', note: 'Free'),
    PrintColumns('Total', '₹100.00', bold: true, size: PrintSize.large),
  ]);

  Future<String> mediaBox(int mm) async {
    final bytes = await const ReceiptPdfBuilder(
      _file,
    ).build(model, paperMm: mm);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    // The page dictionary is plain text even when the streams are compressed.
    final text = latin1.decode(bytes);
    final match = RegExp(
      r'/MediaBox\s*\[\s*0\s+0\s+([0-9.]+)\s+([0-9.]+)',
    ).firstMatch(text);
    expect(match, isNotNull, reason: 'a page with a MediaBox');
    return match!.group(1)!;
  }

  test('the page is as wide as the paper (80 mm)', () async {
    expect(double.parse(await mediaBox(80)), closeTo(80 / 25.4 * 72, 0.1));
  });

  test('the page is as wide as the paper (58 mm)', () async {
    expect(double.parse(await mediaBox(58)), closeTo(58 / 25.4 * 72, 0.1));
  });

  test('narrow paper prints a smaller base font', () {
    expect(
      ReceiptPdfBuilder.baseFont(58),
      lessThan(ReceiptPdfBuilder.baseFont(80)),
    );
  });
}
