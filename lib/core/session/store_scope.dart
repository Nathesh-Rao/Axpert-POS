import '../services/pricing/currency.dart';

/// The store, counter and user of the open session, read by the Drift
/// repositories to scope and stamp rows (DEC-132). A null [storeId] is the
/// legacy, unscoped mode: every row is visible and nothing is stamped.
class StoreScope {
  String? storeId;
  String? counterId;
  String? userId;
  String? userName;

  /// Currency of the store: carts and held bills are stored without one.
  Currency? currency;

  bool get scoped => storeId != null;

  void set({
    required String storeId,
    String? counterId,
    String? userId,
    String? userName,
    Currency? currency,
  }) {
    this.storeId = storeId;
    this.counterId = counterId;
    this.userId = userId;
    this.userName = userName;
    this.currency = currency;
  }

  void clear() {
    storeId = null;
    counterId = null;
    userId = null;
    userName = null;
    currency = null;
  }
}
