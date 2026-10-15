/// The only place that converts between the ISO 8601 text the app and the
/// LocalStore mirror use and the integer UTC epoch milliseconds the database
/// stores (DEC-147).
abstract final class EpochTime {
  /// Epoch milliseconds (UTC) of [iso], or null when it cannot be parsed.
  ///
  /// Accepts what the app wrote (`...Z` with milli or microsecond fraction) and
  /// what the prototype and imports may carry: no fraction, a `+05:30` offset,
  /// a date only. Sub-millisecond digits are dropped, not rounded.
  static int? tryParse(String iso) =>
      DateTime.tryParse(iso.trim())?.toUtc().millisecondsSinceEpoch;

  /// Like [tryParse]; throws a [FormatException] for text that is no date.
  static int parse(String iso) =>
      tryParse(iso) ?? (throw FormatException('Not an ISO 8601 date', iso));

  /// [tryParse] with 0 for text that is no date: the rule the v11 migration
  /// applies to stored values, so a sale with a malformed date still saves.
  static int parseOrZero(String iso) => tryParse(iso) ?? 0;

  /// Epoch milliseconds (UTC) of [time].
  static int fromDateTime(DateTime time) => time.toUtc().millisecondsSinceEpoch;

  /// Canonical UTC ISO text (`2026-10-07T11:27:08.000Z`) of [ms].
  static String toIso(int ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String();

  /// [toIso] of [time]: UTC ISO text at millisecond precision, the shape the
  /// database can hold. New sales and held bills are stamped with this so what
  /// is in memory, in the LocalStore mirror and in Drift is the same string.
  static String nowIso(DateTime time) => toIso(fromDateTime(time));

  /// The canonical form of [iso] (same instant, UTC, milliseconds); text that
  /// is no date becomes the epoch, as in the migration.
  static String canonicalIso(String iso) => toIso(parseOrZero(iso));

  /// [toIso] for a nullable column.
  static String? toIsoOrNull(int? ms) => ms == null ? null : toIso(ms);

  /// [tryParse] for a nullable value that must stay null.
  static int? parseOrNull(String? iso) => iso == null ? null : parse(iso);
}
