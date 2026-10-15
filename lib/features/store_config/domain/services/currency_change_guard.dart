/// A store that has sales keeps its currency: past amounts are stored in it.
abstract final class CurrencyChangeGuard {
  static bool isBlocked({
    required String currentCode,
    required String newCode,
    required bool hasSales,
  }) => hasSales && currentCode != newCode;
}
