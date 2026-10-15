import 'package:drift/drift.dart';

/// Currencies (local-only, DEC-132). The active store's currency row decides
/// symbol, minor-unit digits, grouping and the quick cash amounts.
@DataClassName('CurrencyEntry')
class CurrencyEntries extends Table {
  @override
  String get tableName => 'currencies';

  /// ISO 4217 code.
  TextColumn get code => text()();

  TextColumn get name => text()();

  /// Printed before an amount; may carry a trailing space (`AED `).
  TextColumn get symbol => text()();

  /// Decimal places of the minor unit: 0, 2 or 3.
  IntColumn get exponent =>
      // ignore: recursive_getters
      integer().check(exponent.isIn(const [0, 2, 3]))();

  /// `thousands` or `lakh`.
  TextColumn get grouping =>
      // ignore: recursive_getters
      text().check(grouping.isIn(const ['thousands', 'lakh']))();

  /// Quick cash buttons in whole currency units, comma separated.
  TextColumn get quickCash => text().withDefault(const Constant(''))();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {code};
}
