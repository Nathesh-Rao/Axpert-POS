import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../modules/pos/models/cart.dart';
import '../axpert_database.dart';
import 'fnv1a.dart';

/// What [CartRows.read] found.
class CartRead {
  const CartRead({required this.cart, required this.unreadable, this.json});

  /// The stored cart, or the empty cart when there is no row or it is unreadable.
  final Cart cart;

  /// A row exists but cannot be parsed: the cart resets silently to empty, as
  /// the LocalStore path always did (DEC-130).
  final bool unreadable;

  /// Canonical JSON of [cart] when a readable row exists, else null.
  final String? json;
}

/// Cart <-> the single `current_cart` row (DEC-130).
abstract final class CartRows {
  static const int rowId = 1;

  /// The canonical text stored in `cart_json` and compared for equality.
  static String encode(Cart cart) => jsonEncode(cart.toJson());

  /// Upserts the one row. A single statement: the web file system flushes
  /// after a statement outside a transaction, so it needs no
  /// `durableTransaction` (checked in the browser, DEC-130).
  static Future<void> write(
    AxpertDatabase db,
    String json, {
    required int now,
  }) => db
      .into(db.currentCartEntries)
      .insertOnConflictUpdate(
        CurrentCartEntriesCompanion(
          id: const Value(rowId),
          cartJson: Value(json),
          updatedAt: Value(now),
        ),
      );

  /// Never throws for stored data: any parse problem is `unreadable`.
  static Future<CartRead> read(AxpertDatabase db) async {
    final row = await (db.select(
      db.currentCartEntries,
    )..where((t) => t.id.equals(rowId))).getSingleOrNull();
    if (row == null) return const CartRead(cart: Cart.empty, unreadable: false);
    try {
      final cart = Cart.fromJson(
        jsonDecode(row.cartJson) as Map<String, dynamic>,
      );
      return CartRead(cart: cart, unreadable: false, json: encode(cart));
    } on Object {
      return const CartRead(cart: Cart.empty, unreadable: true);
    }
  }

  static String checksum(Cart cart) => fnv1a32Hex(encode(cart));
}
