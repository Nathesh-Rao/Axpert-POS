import '../models/customer.dart';

/// The customer picker and "Add Customer" rules of the prototype as plain Dart.
abstract final class CustomerRules {
  static final RegExp _phone = RegExp(r'^\+?[\d\s-]{7,15}$');
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Lowercase `"name phone member"`, the text the picker filters on.
  static String searchKey(Customer c) =>
      '${c.name} ${c.phone} ${c.member}'.toLowerCase();

  /// `customers.filter(name phone member includes query)`, in list order.
  static List<Customer> filter(
    Iterable<Customer> customers,
    String Function(Customer) keyOf,
    String query,
  ) {
    final needle = query.toLowerCase();
    return <Customer>[
      for (final c in customers)
        if (keyOf(c).contains(needle)) c,
    ];
  }

  /// `saveCustomer` validation: a name (trimmed), a phone of 7 to 15 digits,
  /// spaces or dashes with an optional leading plus, and an empty or
  /// well-formed email.
  static bool isValid({
    required String name,
    required String phone,
    required String email,
  }) =>
      name.trim().isNotEmpty &&
      _phone.hasMatch(phone) &&
      (email.isEmpty || _email.hasMatch(email));

  /// The saved customer: id `String(Date.now())`, member `"MG"` plus the last
  /// five digits of the clock (collisions possible, KG-008), 0 points. The
  /// form values are stored as typed (not trimmed).
  static Customer create({
    required String name,
    required String phone,
    required String email,
    required DateTime now,
  }) {
    final millis = now.millisecondsSinceEpoch.toString();
    final tail = millis.length > 5
        ? millis.substring(millis.length - 5)
        : millis;
    return Customer(
      id: millis,
      name: name,
      phone: phone,
      email: email,
      member: 'MG$tail',
      points: 0,
    );
  }
}
