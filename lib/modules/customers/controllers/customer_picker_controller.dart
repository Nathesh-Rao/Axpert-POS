import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../shared/controllers/overlay_controller.dart';
import '../../pos/controllers/cart_meta_controller.dart';
import '../../pos/controllers/member_controller.dart';
import '../models/customer.dart';
import '../services/customer_rules.dart';
import 'customers_controller.dart';

/// The "Find a customer" dialog: a search text that is kept between
/// openings, the debounced filtered list and the arrow-key highlight.
class CustomerPickerController extends GetxController {
  CustomerPickerController({
    required this.customers,
    required this.meta,
    required this.member,
    required this.overlay,
  });

  static const Duration debounceDuration = Duration(milliseconds: 150);

  final CustomersController customers;
  final CartMetaController meta;
  final MemberController member;
  final OverlayController overlay;

  final TextEditingController search = TextEditingController();
  final FocusNode searchFocus = FocusNode(debugLabel: 'customer-search');

  final RxList<Customer> filtered = <Customer>[].obs;
  final RxInt highlight = 0.obs;

  /// Drawn only after an arrow key moved it (the prototype shades nothing).
  final RxBool arrowed = false.obs;
  final RxString _typed = ''.obs;

  Map<String, String> _keys = <String, String>{};

  @override
  void onInit() {
    super.onInit();
    search.addListener(() {
      // Also notified on selection and focus changes: react to text only.
      if (search.text != _typed.value) _typed.value = search.text;
    });
    searchFocus.onKeyEvent = (node, event) {
      if (event is KeyUpEvent) return KeyEventResult.ignored;
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.arrowDown) {
        move(1);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowUp) {
        move(-1);
        return KeyEventResult.handled;
      }
      if (event is KeyDownEvent &&
          (key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.numpadEnter)) {
        selectHighlighted();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };
    debounce(_typed, (_) => refilter(), time: debounceDuration);
    ever(customers.customers, (_) {
      _keys = <String, String>{
        for (final c in customers.customers) c.id: CustomerRules.searchKey(c),
      };
      refilter();
    });
    _keys = <String, String>{
      for (final c in customers.customers) c.id: CustomerRules.searchKey(c),
    };
    refilter();
  }

  @override
  void onClose() {
    search.dispose();
    searchFocus.dispose();
    super.onClose();
  }

  /// Applies the search text now (the debounce calls it).
  void refilter() {
    filtered.assignAll(
      CustomerRules.filter(
        customers.customers,
        (c) => _keys[c.id] ?? CustomerRules.searchKey(c),
        search.text,
      ),
    );
    highlight.value = 0;
    arrowed.value = false;
  }

  void move(int delta) {
    if (filtered.isEmpty) return;
    arrowed.value = true;
    highlight.value = (highlight.value + delta) % filtered.length;
    if (highlight.value < 0) highlight.value += filtered.length;
  }

  /// A click or Enter on a row: select the customer (points reset), copy the
  /// membership number into the member field and close.
  void select(Customer customer) {
    meta.setCustomer(customer.id);
    member.memberText.text = customer.member;
    overlay.close();
  }

  void selectHighlighted() {
    if (filtered.isEmpty) return;
    final index = highlight.value < filtered.length ? highlight.value : 0;
    select(filtered[index]);
  }

  void openAdd() => overlay.open('addCustomer');
}
