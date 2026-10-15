import '../../../session/domain/entities/session_entities.dart';

/// One foreign currency row of the forex table. [updatedAtMs] is the time the
/// row was last saved (the "effective date", read only).
class ForexRow {
  const ForexRow({
    required this.code,
    required this.rateMicro,
    this.active = true,
    this.updatedAtMs = 0,
  });

  final String code;

  /// 1 [code] unit = `rateMicro / 1e6` units of the store currency.
  final int rateMicro;
  final bool active;
  final int updatedAtMs;

  ForexRow copyWith({String? code, int? rateMicro, bool? active}) => ForexRow(
    code: code ?? this.code,
    rateMicro: rateMicro ?? this.rateMicro,
    active: active ?? this.active,
    updatedAtMs: updatedAtMs,
  );
}

/// What the Store configuration page edits for one store.
class StoreConfig {
  const StoreConfig({
    required this.storeId,
    required this.name,
    required this.countryCode,
    required this.stateCode,
    required this.currencyCode,
    required this.forex,
    required this.slabs,
    this.inclusive = false,
  });

  final String storeId;
  final String name;
  final String countryCode;
  final String stateCode;
  final String currencyCode;
  final List<ForexRow> forex;
  final List<TaxSlabInfo> slabs;

  /// Price mode of the regime (shown read only).
  final bool inclusive;

  StoreConfig copyWith({
    String? name,
    String? countryCode,
    String? stateCode,
    String? currencyCode,
    List<ForexRow>? forex,
    List<TaxSlabInfo>? slabs,
  }) => StoreConfig(
    storeId: storeId,
    name: name ?? this.name,
    countryCode: countryCode ?? this.countryCode,
    stateCode: stateCode ?? this.stateCode,
    currencyCode: currencyCode ?? this.currencyCode,
    forex: forex ?? this.forex,
    slabs: slabs ?? this.slabs,
    inclusive: inclusive,
  );
}
