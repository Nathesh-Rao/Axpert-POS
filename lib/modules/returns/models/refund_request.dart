import '../../../core/services/pricing/qty.dart';

/// What the cashier typed on the Returns page for one bill: product id to the
/// quantity to return (only entries above zero count, as `refund()` filters).
class RefundRequest {
  const RefundRequest({required this.saleNumber, required this.entries});

  factory RefundRequest.fromJson(Map<String, dynamic> json) => RefundRequest(
    saleNumber: json['saleNumber'] as String,
    entries: <int, Qty>{
      for (final e in (json['entries'] as Map<String, dynamic>).entries)
        int.parse(e.key): Qty(e.value as int),
    },
  );

  final String saleNumber;
  final Map<int, Qty> entries;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'saleNumber': saleNumber,
    'entries': <String, int>{
      for (final e in entries.entries) '${e.key}': e.value.milli,
    },
  };
}

/// The outcome of the checks `refund()` runs before it asks to confirm.
enum RefundCheck { ok, noSelection, exceeds }
