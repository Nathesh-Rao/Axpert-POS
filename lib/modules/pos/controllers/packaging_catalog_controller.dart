import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/services/packaging/packaging_ref.dart';
import '../../../core/services/packaging/packaging_service.dart';
import '../../../core/services/pricing/money.dart';
import '../../../core/session/session_scoped.dart';
import '../../../features/products/domain/entities/packaging_entities.dart';
import '../../../features/products/domain/entities/product.dart';
import '../../../features/products/domain/repositories/packaging_repositories.dart';
import '../models/unit_option.dart';

/// The units each product of the sales screen can be sold in (DEC-154): the
/// base unit plus the ENABLED packagings, read once per catalog load and kept
/// in a map by product id, so tiles and cart rows never query the database.
/// Products without packagings are absent and look exactly as before.
class PackagingCatalogController extends GetxController
    implements SessionScoped {
  PackagingCatalogController(this._repository);

  final PackagingRepository _repository;

  Map<int, SellableUnits> _byProduct = <int, SellableUnits>{};

  /// Bumped on every reload so tiles and rows pick up edited packagings.
  final RxInt revision = 0.obs;

  Future<void> load() async {
    try {
      _byProduct = await _repository.sellableByLegacyId();
    } on Object {
      _byProduct = <int, SellableUnits>{};
    }
    revision.value++;
  }

  /// Replaces the units (tests).
  @visibleForTesting
  void seed(Map<int, SellableUnits> units) {
    _byProduct = units;
    revision.value++;
  }

  bool hasPackagings(int productId) => _byProduct.containsKey(productId);

  /// Number of units (base unit included) a product can be sold in.
  int unitCount(int productId) => _byProduct[productId] == null
      ? 1
      : _byProduct[productId]!.packagings.length + 1;

  /// Base unit first, then the packagings by sort order.
  List<UnitOption> optionsFor(Product product) {
    final units = _byProduct[product.id];
    final base = UnitOption(
      name: units?.baseUnitName ?? '',
      factorMilli: 1000,
      price: product.price,
    );
    if (units == null) return <UnitOption>[base];
    return <UnitOption>[
      base,
      for (final p in units.packagings) optionOf(product, p),
    ];
  }

  /// The option of a packaging row (price: explicit or base price x factor).
  UnitOption optionOf(Product product, ProductPackaging p) => UnitOption(
    name: p.name,
    factorMilli: p.quantityBaseMilli,
    price: Money(
      const PackagingService().packagePriceMinor(
        basePriceMinor: product.price.minor,
        factorMilli: p.quantityBaseMilli,
        explicitMinor: p.priceMinor,
      ),
      product.price.currency,
    ),
    packaging: PackagingRef(
      id: p.id,
      unitName: p.name,
      quantityBaseMilli: p.quantityBaseMilli,
    ),
  );

  /// The option of a scanned packaging, null when it is not enabled.
  UnitOption? optionForPackaging(Product product, String packagingId) {
    for (final o in optionsFor(product)) {
      if (o.packagingId == packagingId) return o;
    }
    return null;
  }

  @override
  void resetForSignOut() {
    _byProduct = <int, SellableUnits>{};
    revision.value++;
  }
}
