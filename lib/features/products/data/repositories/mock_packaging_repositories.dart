import '../../../../core/constants/storage_keys.dart';
import '../../../../core/database/tables/unit_entries.dart';
import '../../../../core/mock/mock_delay.dart';
import '../../../../core/services/storage/local_store.dart';
import '../../domain/entities/packaging_entities.dart';
import '../../domain/repositories/packaging_repositories.dart';

/// The eight standard units, same ids as the database seed.
class MockUnitRepository implements UnitRepository {
  const MockUnitRepository();

  static final List<MeasureUnit> units = [
    for (final u in SeedUnits.all)
      MeasureUnit(
        id: u.id,
        code: u.code,
        name: u.name,
        kind: UnitKind.fromCode(u.kind),
      ),
  ];

  @override
  Future<List<MeasureUnit>> all() async {
    await MockDelay.wait();
    return units;
  }

  @override
  Future<MeasureUnit?> byCode(String code) async {
    await MockDelay.wait();
    for (final u in units) {
      if (u.code == code) return u;
    }
    return null;
  }
}

Future<List<Map<String, dynamic>>> _read(LocalStore store, String key) async {
  final json = await store.read(key);
  return [if (json is List<dynamic>) ...json.cast<Map<String, dynamic>>()];
}

class MockBrandRepository implements BrandRepository {
  MockBrandRepository(this._store);

  final LocalStore _store;

  @override
  Future<List<Brand>> all() async {
    await MockDelay.wait();
    return [
      for (final j in await _read(_store, StorageKeys.brands))
        Brand.fromJson(j),
    ]..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<void> save(Brand brand) async {
    await MockDelay.wait();
    final rows = await _read(_store, StorageKeys.brands);
    rows.removeWhere((j) => j['id'] == brand.id);
    rows.add(brand.toJson());
    await _store.write(StorageKeys.brands, rows);
  }

  @override
  Future<void> remove(String id) async {
    await MockDelay.wait();
    final rows = await _read(_store, StorageKeys.brands);
    rows.removeWhere((j) => j['id'] == id);
    await _store.write(StorageKeys.brands, rows);
  }
}

class MockPackagingRepository implements PackagingRepository {
  MockPackagingRepository(this._store);

  final LocalStore _store;

  @override
  Future<List<ProductPackaging>> forProduct(String productId) async {
    await MockDelay.wait();
    return [
      for (final j in await _read(_store, StorageKeys.packagings))
        if (j['productId'] == productId) ProductPackaging.fromJson(j),
    ]..sort(
      (a, b) => a.sortOrder != b.sortOrder
          ? a.sortOrder.compareTo(b.sortOrder)
          : a.quantityBaseMilli.compareTo(b.quantityBaseMilli),
    );
  }

  @override
  Future<Map<int, SellableUnits>> sellableByLegacyId() async =>
      const <int, SellableUnits>{};

  @override
  Future<void> save(ProductPackaging p) async {
    await MockDelay.wait();
    final rows = await _read(_store, StorageKeys.packagings);
    final clash = rows.any(
      (j) =>
          j['productId'] == p.productId &&
          j['unitId'] == p.unitId &&
          j['id'] != p.id,
    );
    if (clash) throw DuplicatePackagingException(p.productId, p.unitId);
    rows.removeWhere((j) => j['id'] == p.id);
    rows.add(p.toJson());
    await _store.write(StorageKeys.packagings, rows);
  }

  @override
  Future<void> remove(String id) async {
    await MockDelay.wait();
    final rows = await _read(_store, StorageKeys.packagings);
    rows.removeWhere((j) => j['id'] == id);
    await _store.write(StorageKeys.packagings, rows);
  }
}

/// Barcodes in [LocalStore]. A mock has no product table, so the legacy
/// product ids come from [legacyIds] (product uuid to legacy id).
class MockBarcodeRepository implements BarcodeRepository {
  MockBarcodeRepository(this._store, {this.legacyIds = const <String, int>{}});

  final LocalStore _store;
  final Map<String, int> legacyIds;

  @override
  Future<BarcodeMatch?> findByBarcode(String? storeId, String barcode) async {
    await MockDelay.wait();
    for (final j in await _read(_store, StorageKeys.barcodes)) {
      final b = ProductBarcode.fromJson(j);
      if (b.barcode != barcode) continue;
      if (storeId != null && b.storeId != storeId) continue;
      ProductPackaging? packaging;
      if (b.packagingId != null) {
        final all = await _read(_store, StorageKeys.packagings);
        final found = all.where((p) => p['id'] == b.packagingId);
        if (found.isEmpty) return null;
        packaging = ProductPackaging.fromJson(found.first);
      }
      return BarcodeMatch(
        productId: b.productId,
        productLegacyId: legacyIds[b.productId] ?? -1,
        barcode: b.barcode,
        packaging: packaging,
      );
    }
    return null;
  }

  @override
  Future<List<ProductBarcode>> forProduct(String productId) async {
    await MockDelay.wait();
    return [
      for (final j in await _read(_store, StorageKeys.barcodes))
        if (j['productId'] == productId) ProductBarcode.fromJson(j),
    ];
  }

  @override
  Future<void> save(ProductBarcode b) async {
    await MockDelay.wait();
    final rows = await _read(_store, StorageKeys.barcodes);
    final clash = rows.any(
      (j) =>
          j['barcode'] == b.barcode &&
          j['id'] != b.id &&
          (j['storeId'] as String? ?? '') == (b.storeId ?? ''),
    );
    if (clash) throw DuplicateBarcodeException(b.barcode);
    rows.removeWhere((j) => j['id'] == b.id);
    rows.add(b.toJson());
    await _store.write(StorageKeys.barcodes, rows);
  }

  @override
  Future<void> remove(String id) async {
    await MockDelay.wait();
    final rows = await _read(_store, StorageKeys.barcodes);
    rows.removeWhere((j) => j['id'] == id);
    await _store.write(StorageKeys.barcodes, rows);
  }
}
