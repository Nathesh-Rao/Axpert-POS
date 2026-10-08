import '../../../core/services/pricing/currency.dart';
import '../../../core/services/pricing/currency_registry.dart';
import '../../../core/services/pricing/money.dart';
import '../../pos/services/checkout_service.dart';
import '../../sales/models/sale.dart';

/// The day's takings (prototype `dailySales` / `shiftTotal`): the sales made on
/// the same local calendar day as `now` (`toDateString`), their total, count,
/// average and the total per payment mode. Plain Dart over integer minor
/// units; nothing is priced here, the sale totals are summed as stored.
class ShiftSummary {
  ShiftSummary._(this.day, this.sales, this.currency, this.total);

  /// The summary of [all] for the local day of [now].
  factory ShiftSummary.of(
    Iterable<Sale> all,
    DateTime now, {
    Currency currency = CurrencyRegistry.inr,
  }) {
    final today = <Sale>[
      for (final sale in all)
        if (sameDay(DateTime.parse(sale.date).toLocal(), now)) sale,
    ];
    var total = 0;
    for (final sale in today) {
      total += sale.totals.total.minor;
    }
    return ShiftSummary._(
      DateTime(now.year, now.month, now.day),
      List<Sale>.unmodifiable(today),
      currency,
      Money(total, currency),
    );
  }

  /// The payment modes of the bar chart, in the prototype's order.
  static const List<String> modes = <String>[
    SaleMode.cash,
    SaleMode.card,
    SaleMode.credit,
  ];

  /// `Date.toDateString()` equality in local time.
  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Midnight of the day this summary covers.
  final DateTime day;

  /// `dailySales`
  final List<Sale> sales;
  final Currency currency;

  /// `shiftTotal`
  final Money total;

  int get count => sales.length;

  /// `shiftTotal / count`, exact and rounded half up to a minor unit (the
  /// prototype divides floats and formats; ties may differ by one unit,
  /// KG-157).
  Money get average {
    if (count == 0) return Money.zero(currency);
    final n = total.minor;
    return Money((2 * n + count) ~/ (2 * count), currency);
  }

  /// The total of the sales paid with [mode].
  Money byMode(String mode) {
    var sum = 0;
    for (final sale in sales) {
      if (sale.mode == mode) sum += sale.totals.total.minor;
    }
    return Money(sum, currency);
  }

  /// [value] as a share of the day's total in basis points (bar width, layout
  /// only); 0 when there are no takings.
  int barBasisPoints(Money value) {
    final t = total.minor;
    if (t <= 0) return 0;
    return (2 * value.minor * 10000 + t) ~/ (2 * t);
  }
}
