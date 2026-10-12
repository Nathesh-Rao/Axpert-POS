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
