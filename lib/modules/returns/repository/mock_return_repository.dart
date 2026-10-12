import '../../../core/database/persist_outcome.dart';
import '../../../features/products/domain/repositories/product_repository.dart';
import '../../sales/repository/sale_repository.dart';
import 'return_repository.dart';

/// Writes through the existing sale and product repositories (which carry the
/// 200 to 500 ms mock delay), so a refund persists exactly what the prototype's
/// `setSales` and `setProducts` persist and nothing more. Two independent
/// saves: not atomic (the Drift path is, DEC-129).
class MockReturnRepository implements ReturnRepository {
  MockReturnRepository({required this.sales, required this.products});

  final SaleRepository sales;
  final ProductRepository products;

  @override
  Future<PersistOutcome> applyRefund(RefundCommit commit) async {
    try {
      await Future.wait(<Future<void>>[
        sales.save(commit.sales),
        products.save(commit.products),
      ]);
      return PersistOutcome.saved;
    } on Object {
      return PersistOutcome.failed;
    }
  }
}
