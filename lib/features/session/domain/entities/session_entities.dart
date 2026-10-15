import '../../../../core/services/pricing/currency.dart';

/// A store row (receipt details and currency come from here).
class StoreInfo {
  const StoreInfo({
    required this.id,
    required this.name,
    required this.currencyCode,
    this.address = '',
    this.phone = '',
    this.taxId = '',
    this.receiptHeader = '',
    this.receiptFooter = '',
    this.region = '',
    this.allowNegativeStock = false,
  });

  final String id;
  final String name;
  final String currencyCode;
  final String address;
  final String phone;
  final String taxId;
  final String receiptHeader;
  final String receiptFooter;
  final String region;

  /// A sale may take stock below zero (with a warning), DEC-148.
  final bool allowNegativeStock;
}

class CounterInfo {
  const CounterInfo({
    required this.id,
    required this.storeId,
    required this.name,
  });

  final String id;
  final String storeId;
  final String name;
}

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
  });

  final String id;
  final String username;
  final String displayName;

  /// `admin`, `manager` or `cashier`; shown, not enforced yet.
  final String role;
}

/// A user's row with the stored hash (never shown or logged).
class UserCredential {
  const UserCredential({
    required this.user,
    required this.salt,
    required this.passwordHash,
    required this.hashAlgo,
  });

  final AppUser user;
  final String salt;
  final String passwordHash;
  final String hashAlgo;
}

/// One store a user may open and the counters they may pick in it.
class StoreAccess {
  const StoreAccess({required this.store, required this.counters});

  final StoreInfo store;
  final List<CounterInfo> counters;
}

/// The currency rows plus the quick cash amounts of each (whole units).
class CurrencyRow {
  const CurrencyRow({required this.currency, required this.quickCash});

  final Currency currency;
  final List<int> quickCash;
}

/// One foreign currency of a store: 1 [code] unit = `rateMicro / 1e6` units of
/// the store's currency.
class ForexRate {
  const ForexRate({required this.code, required this.rateMicro});

  final String code;
  final int rateMicro;
}

/// A slab of a tax regime.
class TaxSlabInfo {
  const TaxSlabInfo({required this.rateBp, this.label = ''});

  final int rateBp;
  final String label;
}

/// The tax regime of a store's region (`tax_regimes` and its `tax_slabs`).
class TaxRegimeInfo {
  const TaxRegimeInfo({
    required this.region,
    required this.label,
    required this.inclusive,
    this.splitParts = const <String>[],
    this.slabs = const <TaxSlabInfo>[],
  });

  final String region;
  final String label;
  final bool inclusive;
  final List<String> splitParts;
  final List<TaxSlabInfo> slabs;
}
