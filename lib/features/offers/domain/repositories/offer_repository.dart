import '../entities/offer.dart';

abstract interface class OfferRepository {
  /// The active offers of [storeId] (and the ones for every store), with the
  /// products they refer to. Date windows are checked by the engine.
  Future<List<Offer>> load({required String? storeId});
}
