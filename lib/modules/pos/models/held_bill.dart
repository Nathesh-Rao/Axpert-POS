import 'cart.dart';

/// A held bill (prototype `Held`): short reference, ISO time and the cart.
class HeldBill {
  const HeldBill({required this.ref, required this.time, required this.cart});

  factory HeldBill.fromJson(Map<String, dynamic> json) => HeldBill(
    ref: json['ref'] as String,
    time: json['time'] as String,
    cart: Cart.fromJson(json['cart'] as Map<String, dynamic>),
  );

  final String ref;
  final String time;
  final Cart cart;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'ref': ref,
    'time': time,
    'cart': cart.toJson(),
  };
}
