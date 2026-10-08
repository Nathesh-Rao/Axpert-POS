import 'package:get/get.dart';

/// The prototype's single shared filter string (catalog filter and the
/// Products/Customers/Sales search boxes, KG-027). Cleared only by sidebar
/// navigation.
class PageFilterController extends GetxController {
  final RxString filter = ''.obs;

  void set(String value) => filter.value = value;

  void clear() => filter.value = '';
}
