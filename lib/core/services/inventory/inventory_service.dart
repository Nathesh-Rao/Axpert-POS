/// Why a stock balance moved (the `reason` column of
/// `inventory_transactions`).
enum StockReason {
  sale('sale'),
  returned('return'),
  purchase('purchase'),
  adjustment('adjustment'),
  damage('damage'),
  transfer('transfer'),
  opening('opening');

  const StockReason(this.code);

  /// The value stored in the database.
  final String code;

  static StockReason fromCode(String code) =>
      values.firstWhere((r) => r.code == code);
}

/// One requested change of one product's stock, in milli-units (negative =
/// stock leaves). Several movements of the same product and reason are merged
/// into one transaction row.
class StockMovement {
  const StockMovement({
    required this.productId,
    required this.deltaMilli,
    required this.reason,
    this.refType,
    this.refId,
    this.note = '',
  });

  final String productId;
  final int deltaMilli;
  final StockReason reason;
  final String? refType;
  final String? refId;
  final String note;
}

/// A row to insert into `inventory_transactions`.
class StockTransaction {
  const StockTransaction({
    required this.id,
    required this.storeId,
    required this.productId,
    required this.deltaMilli,
    required this.reason,
    required this.createdAt,
    this.refType,
    this.refId,
    this.userId,
    this.note = '',
  });

  final String id;
  final String storeId;
  final String productId;
  final int deltaMilli;
  final StockReason reason;
  final String? refType;
  final String? refId;
  final String? userId;
  final String note;

  /// Epoch milliseconds (UTC).
  final int createdAt;
}

/// A product whose balance would be below zero.
class StockShortfall {
  const StockShortfall({
    required this.productId,
    required this.availableMilli,
    required this.requestedMilli,
  });

  final String productId;
  final int availableMilli;
  final int requestedMilli;
}

/// What [InventoryService.plan] decided.
class StockPlan {
  const StockPlan({
    required this.transactions,
    required this.balances,
    required this.negative,
    required this.blocked,
  });

  /// Rows to insert, in order (opening or adjustment rows first).
  final List<StockTransaction> transactions;

  /// New balance of every touched product (milli-units).
  final Map<String, int> balances;

  /// Products that went below zero because the store allows it (a warning).
  final List<StockShortfall> negative;

  /// Products that would go below zero while the store forbids it. A blocked
  /// plan must not be written.
  final List<StockShortfall> blocked;

  bool get isBlocked => blocked.isNotEmpty;
}

/// Stock rules, plain Dart (no GetX, no Flutter, no database).
///
/// The balance table is the exact record (milli-units); `products.stock` is
/// the whole-unit cache the screens still read and edit (DEC-148). Before a
/// movement is applied the two are reconciled, so a balance never silently
/// drifts from what the cashier sees:
///  * no balance row yet: an `opening` row creates it from the cache;
///  * the cache disagrees with `floor(balance)` (someone edited the stock on
///    the Products screen): an `adjustment` row moves the balance to the
///    cache. `floor` is the rule because the cache is reduced by whole units
///    rounded up (KG-106), so `floor(S - q) == S - ceil(q)` stays in sync.
///
/// A movement that would take a balance below zero is `blocked` unless the
/// store allows negative stock, in which case it is applied and reported in
/// [StockPlan.negative]. Stock never goes negative silently.
class InventoryService {
  const InventoryService();

  /// Plans the rows and balances for [movements].
  ///
  /// [balances] holds the existing balance rows (milli) by product id;
  /// [stockUnits] the whole-unit cache of the same products before the
  /// movement. [newId] creates the UUID of each row.
  StockPlan plan({
    required String storeId,
    String? userId,
    required int now,
    required List<StockMovement> movements,
    required Map<String, int> balances,
    required Map<String, int> stockUnits,
    required bool allowNegative,
    required String Function() newId,
  }) {
    final byProduct = <String, List<StockMovement>>{};
    for (final m in movements) {
      byProduct.putIfAbsent(m.productId, () => <StockMovement>[]).add(m);
    }
    final rows = <StockTransaction>[];
    final next = <String, int>{};
    final negative = <StockShortfall>[];
    final blocked = <StockShortfall>[];

    StockTransaction row(
      String productId,
      int delta,
      StockReason reason, {
      String? refType,
      String? refId,
      String note = '',
    }) => StockTransaction(
      id: newId(),
      storeId: storeId,
      productId: productId,
      deltaMilli: delta,
      reason: reason,
      createdAt: now,
      refType: refType,
      refId: refId,
      userId: userId,
      note: note,
    );

    for (final entry in byProduct.entries) {
      final id = entry.key;
      var current = balances[id];
      final units = stockUnits[id];
      if (units != null) {
        if (current == null) {
          rows.add(
            row(
              id,
              units * 1000,
              StockReason.opening,
              note: 'balance created from products.stock',
            ),
          );
          current = units * 1000;
        } else if (_floorUnits(current) != units) {
          rows.add(
            row(
              id,
              units * 1000 - current,
              StockReason.adjustment,
              note: 'products.stock edited: ${current}m to ${units * 1000}m',
            ),
          );
          current = units * 1000;
        }
      }
      current ??= 0;

      // One row per (reason, reference): merged quantities.
      final merged = <String, StockMovement>{};
      for (final m in entry.value) {
        final key = '${m.reason.code}|${m.refType}|${m.refId}';
        final prior = merged[key];
        merged[key] = prior == null
            ? m
            : StockMovement(
                productId: id,
                deltaMilli: prior.deltaMilli + m.deltaMilli,
                reason: m.reason,
                refType: m.refType,
                refId: m.refId,
                note: prior.note,
              );
      }
      final total = merged.values.fold<int>(0, (a, m) => a + m.deltaMilli);
      final after = current + total;
      var note = '';
      if (after < 0 && total < 0) {
        final shortfall = StockShortfall(
          productId: id,
          availableMilli: current,
          requestedMilli: -total,
        );
        if (allowNegative) {
          negative.add(shortfall);
          note = 'negative stock allowed: balance ${after}m';
        } else {
          blocked.add(shortfall);
        }
      }
      for (final m in merged.values) {
        rows.add(
          row(
            id,
            m.deltaMilli,
            m.reason,
            refType: m.refType,
            refId: m.refId,
            note: [m.note, note].where((n) => n.isNotEmpty).join('; '),
          ),
        );
      }
      next[id] = after;
    }
    return StockPlan(
      transactions: rows,
      balances: next,
      negative: negative,
      blocked: blocked,
    );
  }

  static int _floorUnits(int milli) => (milli - milli % 1000) ~/ 1000;
}
