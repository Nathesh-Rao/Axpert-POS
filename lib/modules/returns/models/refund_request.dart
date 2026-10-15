import '../../../core/services/pricing/qty.dart';
import '../../pos/models/line_key.dart';

/// What the cashier typed on the Returns page for one bill: line (product and packaging) to the
/// quantity to return (only entries above zero count, as `refund()` filters).
class RefundRequest {
  const RefundRequest({required this.saleNumber, required this.entries});

  factory RefundRequest.fromJson(Map<String, dynamic> json) => RefundRequest(
    saleNumber: json['saleNumber'] as String,
    entries: <LineKey, Qty>{
      for (final e in (json['entries'] as Map<String, dynamic>).entries)
        LineKey.parse(e.key): Qty(e.value as int),
    },
  );

  final String saleNumber;
  final Map<LineKey, Qty> entries;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'saleNumber': saleNumber,
    'entries': <String, int>{
      for (final e in entries.entries) e.key.text: e.value.milli,
    },
  };
}

/// The outcome of the checks `refund()` runs before it asks to confirm.
enum RefundCheck { ok, noSelection, exceeds }
