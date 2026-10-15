import '../../../../core/services/inventory/inventory_service.dart';

/// Read side of the stock ledger (DEC-148). The write side runs inside the
/// checkout and refund transactions (`DriftLedgerRepository`), never alone.
abstract interface class InventoryRepository {
  /// Balance (milli-units) of every product of [storeId] that has a row.
  Future<Map<String, int>> balances(String storeId);

  /// Transactions of [storeId], newest first; [productId] narrows them.
  Future<List<StockTransaction>> transactions(
    String storeId, {
    String? productId,
    int? limit,
  });

  /// Whether the store lets a sale take stock below zero.
  Future<bool> allowsNegativeStock(String storeId);
}
