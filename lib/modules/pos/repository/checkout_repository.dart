import '../../../core/database/persist_outcome.dart';
import '../../../features/payment/domain/entities/payment_result.dart';
import '../../../features/products/domain/entities/product.dart';
import '../../../features/products/domain/repositories/product_repository.dart';
import '../../customers/models/customer.dart';
import '../../customers/repository/customer_repository.dart';
import '../../sales/models/sale.dart';
import '../../sales/repository/sale_repository.dart';

/// What a completed checkout persists: the new sale, its payment (cash and
/// card only) and the three lists as they are in memory AFTER the checkout
/// (memory is authoritative; the stores diff against what they hold).
class CheckoutCommit {
  const CheckoutCommit({
    required this.sale,
    required this.payment,
    required this.salesAfter,
    required this.productsAfter,
    required this.customersAfter,
  });

  final Sale sale;

  /// Null for credit sales (nothing is paid at the till, DEC-123).
  final PaymentResult? payment;
  final List<Sale> salesAfter;
  final List<Product> productsAfter;
  final List<Customer> customersAfter;
}

/// Persists a checkout (DEC-129). Never throws for a storage failure: the
/// outcome says what happened.
abstract interface class CheckoutRepository {
  Future<PersistOutcome> commit(CheckoutCommit commit);
}

/// The status quo: three independent whole-list saves through the existing
/// repositories, started in the old order (sales, products, customers). Used
/// whenever sales, products and customers are not all on Drift (rollback flag,
/// tests): no atomicity, as before.
class IndependentCheckoutRepository implements CheckoutRepository {
  IndependentCheckoutRepository({
    required this.sales,
    required this.products,
    required this.customers,
  });

  final SaleRepository sales;
  final ProductRepository products;
  final CustomerRepository customers;

  @override
  Future<PersistOutcome> commit(CheckoutCommit commit) async {
    try {
      await Future.wait(<Future<void>>[
        sales.save(commit.salesAfter),
        products.save(commit.productsAfter),
        customers.save(commit.customersAfter),
      ]);
      return PersistOutcome.saved;
    } on Object {
      return PersistOutcome.failed;
    }
  }
}
