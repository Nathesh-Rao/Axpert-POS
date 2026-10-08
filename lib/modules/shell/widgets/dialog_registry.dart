import 'package:flutter/widgets.dart';

import '../../customers/widgets/add_customer_dialog.dart';
import '../../customers/widgets/customer_picker_dialog.dart';
import '../../pos/widgets/dialogs/discount_drawer.dart';
import '../../pos/widgets/dialogs/price_check_dialog.dart';
import '../../pos/widgets/dialogs/recall_dialog.dart';
import '../../pos/widgets/dialogs/scan_dialog.dart';

/// Dialog id (the prototype's `modal` string) to the widget it shows. Ids
/// without an entry open the placeholder dialog until their step is built.
/// A dialog widget lays itself out as a centred modal (`AppModal`) or a right
/// drawer (`AppDrawer`).
abstract final class DialogRegistry {
  static final Map<String, Widget Function()> builders =
      <String, Widget Function()>{
        'scan': () => const ScanDialog(),
        'priceCheck': () => const PriceCheckDialog(),
        'customers': () => const CustomerPickerDialog(),
        'addCustomer': () => const AddCustomerDialog(),
        'recall': () => const RecallDialog(),
        'discount': () => const DiscountDrawer(),
      };

  static Widget? build(String id) => builders[id]?.call();
}
