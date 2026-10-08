import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/decimal_input.dart';
import '../../../shared/controllers/toast_controller.dart';
import '../../customers/controllers/customers_controller.dart';
import 'cart_controller.dart';
import 'cart_meta_controller.dart';

/// The member card: membership number (exact-match lookup selects the
/// customer), read-only info and the points redeem field.
class MemberController extends GetxController {
  MemberController({
    required this.cart,
    required this.customers,
    required this.meta,
    required this.toasts,
  });

  final CartController cart;
  final CustomersController customers;
  final CartMetaController meta;
  final ToastController toasts;

  final TextEditingController memberText = TextEditingController();
  final FocusNode memberFocus = FocusNode(debugLabel: 'member-number');
  final TextEditingController pointsText = TextEditingController();

  String _syncedCustomer = '';
  String _syncedMember = '';

  @override
  void onInit() {
    super.onInit();
    _syncFromCustomer();
    ever(cart.cart, (_) {
      _syncFromCustomer();
      _syncPoints();
    });
    ever(customers.customers, (_) {
      _syncFromCustomer();
      _syncPoints();
    });
    _syncPoints();
  }

  /// `useEffect(() => setMemberInput(customer.member), [id, member])`.
  void _syncFromCustomer() {
    final c = meta.customer;
    if (c.id == _syncedCustomer && c.member == _syncedMember) return;
    _syncedCustomer = c.id;
    _syncedMember = c.member;
    memberText.text = c.member;
  }

  void _syncPoints() {
    final points = cart.cart.value.points;
    if ((int.tryParse(pointsText.text) ?? 0) != points ||
        pointsText.text.isEmpty) {
      pointsText.text = '$points';
    }
  }

  /// Typed membership number: an exact (case-insensitive) match selects the
  /// customer and resets points.
  void lookup(String value) {
    final found = customers.customers.firstWhereOrNull(
      (c) =>
          c.member.isNotEmpty && c.member.toLowerCase() == value.toLowerCase(),
    );
    if (found == null) return;
    meta.setCustomer(found.id);
    toasts.show(AppStrings.current.toastWelcome(found.name));
  }

  /// Enter in the field with a number that is not an exact customer member.
  void submit() {
    final text = memberText.text;
    if (!customers.customers.any((c) => c.member == text)) {
      toasts.show(
        AppStrings.current.toastMemberNotFound(),
        kind: ToastKind.warning,
      );
    }
  }

  /// Redeem field: whole points (truncated, KG-004), clamped to 0..available.
  void setPoints(String text) {
    final available = meta.customer.points;
    final milli = DecimalInput.tryScaled(text, 3) ?? 0;
    var points = milli ~/ 1000;
    if (points < 0) points = 0;
    if (points > available) points = available;
    cart.patch((c) => c.copyWith(points: points));
    if (points.toString() != pointsText.text &&
        (int.tryParse(pointsText.text) ?? 0) != points) {
      pointsText.text = '$points';
    }
  }

  @override
  void onClose() {
    memberText.dispose();
    memberFocus.dispose();
    pointsText.dispose();
    super.onClose();
  }
}
