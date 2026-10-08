import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/pricing/decimal_parser.dart';
import '../../../core/services/pricing/qty.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/controllers/overlay_controller.dart';
import '../../../shared/controllers/toast_controller.dart';
import '../../products/controllers/products_controller.dart';
import '../../sales/controllers/sales_controller.dart';
import '../../sales/models/sale.dart';
import '../models/refund_request.dart';
import '../repository/return_repository.dart';
import '../services/refund_service.dart';

/// The Returns page: bill lookup, the typed quantities and the refund flow
/// (prototype `returnNumber`, `returnQty`, `refund()`).
class ReturnsController extends GetxController {
  ReturnsController({
    required this.sales,
    required this.products,
    required this.repository,
    required this.toasts,
    required this.overlay,
  });

  final SalesController sales;
  final ProductsController products;
  final ReturnRepository repository;
  final ToastController toasts;
  final OverlayController overlay;

  AppStrings get _s => AppStrings.current;

  /// The bill number box.
  final TextEditingController billNumber = TextEditingController();

  /// The raw text (`returnNumber`): "No matching bill found." shows for any
  /// non-empty text, even blanks.
  final RxString text = ''.obs;

  /// The sale that matches the text, if any.
  final Rxn<Sale> sale = Rxn<Sale>();

  /// Typed return quantities (`returnQty`), product id to quantity.
  final RxMap<int, Qty> qty = <int, Qty>{}.obs;

  final Map<int, TextEditingController> _fields =
      <int, TextEditingController>{};
  Map<String, Sale> _index = <String, Sale>{};
  Worker? _worker;

  @override
  void onInit() {
    super.onInit();
    _reindex();
    _worker = ever(sales.sales, (_) {
      _reindex();
      sale.value = _lookup();
    });
  }

  /// Lowercase number to sale, first sale wins (`find`); rebuilt once per
  /// ledger change so typing never scans the list.
  void _reindex() {
    _index = <String, Sale>{};
    for (final s in sales.sales) {
      _index.putIfAbsent(RefundService.keyOf(s.number), () => s);
    }
  }

  Sale? _lookup() => _index[text.value.trim().toLowerCase()];

  /// The bill box `onChange`: a new text starts over (quantities cleared).
  void onBillChanged(String value) {
    text.value = value;
    _clearQty();
    sale.value = _lookup();
  }

  /// The text controller of a quantity box, created on first use.
  TextEditingController fieldFor(int productId) =>
      _fields.putIfAbsent(productId, () => TextEditingController(text: '0'));

  /// A quantity box `onChange`: `Math.max(0, Number(value))`.
  void onQtyChanged(int productId, String value) {
    Qty parsed;
    try {
      parsed = value.trim().isEmpty
          ? Qty.zero
          : Qty(DecimalParser.parseScaled(value, Qty.scale));
    } on FormatException {
      parsed = Qty.zero;
    }
    if (parsed < Qty.zero) parsed = Qty.zero;
    final next = Map<int, Qty>.of(qty)..[productId] = parsed;
    qty.assignAll(next);
    // A controlled input shows the stored value: "0" again for an empty or
    // invalid box.
    if (parsed == Qty.zero && value != '0') {
      fieldFor(productId).value = const TextEditingValue(
        text: '0',
        selection: TextSelection.collapsed(offset: 1),
      );
    } else if (RegExp(r'^0+\d').hasMatch(value)) {
      // "01" is the number 1: the box shows it as the prototype's does.
      final shown = value.replaceFirst(RegExp(r'^0+(?=\d)'), '');
      fieldFor(productId).value = TextEditingValue(
        text: shown,
        selection: TextSelection.collapsed(offset: shown.length),
      );
    }
  }

  void _clearQty() {
    qty.clear();
    for (final field in _fields.values) {
      if (field.text != '0') field.text = '0';
    }
  }

  /// "Refund & restock".
  void refund() {
    final found = sale.value;
    if (found == null) return;
    switch (RefundService.check(found, qty)) {
      case RefundCheck.noSelection:
        toasts.show(_s.toastRefundSelect(), kind: ToastKind.warning);
      case RefundCheck.exceeds:
        toasts.show(_s.toastRefundExceeds(), kind: ToastKind.error);
      case RefundCheck.ok:
        final typed = Map<int, Qty>.of(qty);
        final amount = MoneyFormatter.format(RefundService.quote(found, typed));
        overlay.openConfirm(_s.refundConfirm(amount), () {
          _commit(found, typed, amount);
        });
    }
  }

  Future<void> _commit(Sale found, Map<int, Qty> typed, String amount) {
    products.restock(RefundService.restockUnits(typed));
    sales.replace(RefundService.applyReturned(found, typed));
    _clearQty();
    toasts.show(_s.toastRefundDone(amount));
    return repository.applyRefund(
      RefundCommit(
        request: RefundRequest(
          saleNumber: found.number,
          entries: Map<int, Qty>.of(typed),
        ),
        sales: sales.sales.toList(),
        products: products.products.toList(),
      ),
    );
  }

  @override
  void onClose() {
    _worker?.dispose();
    billNumber.dispose();
    for (final field in _fields.values) {
      field.dispose();
    }
    super.onClose();
  }
}
