import '../../../core/database/persist_outcome.dart';
import '../../../features/products/domain/entities/product.dart';
import '../../sales/models/sale.dart';
import '../models/refund_request.dart';

/// What a confirmed refund persists: the sale ledger (the sale's `returned`
/// map changed) and the product list (the stock went up). Nothing else is
/// stored: the prototype keeps no refund record (KG-007).
class RefundCommit {
  const RefundCommit({
    required this.request,
    required this.sales,
    required this.products,
  });

  /// What was refunded (a real backend would receive this; the mock keeps
  /// only the two lists below).
  final RefundRequest request;
  final List<Sale> sales;
  final List<Product> products;
}

abstract interface class ReturnRepository {
  /// Saves both lists as one unit (one Drift transaction on the Drift path).
  /// Never throws for a storage failure: the outcome says what happened.
  Future<PersistOutcome> applyRefund(RefundCommit commit);
}
