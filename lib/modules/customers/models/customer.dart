/// Customer (prototype `Customer`); `walk` is the walk-in customer.
class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.member,
    required this.points,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String,
    email: json['email'] as String,
    member: json['member'] as String,
    points: json['points'] as int,
  );

  static const String walkInId = 'walk';

  final String id;
  final String name;
  final String phone;
  final String email;
  final String member;

  /// Whole loyalty points (1 point = one currency unit, KG-004, KG-009).
  final int points;

  bool get isWalkIn => id == walkInId;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'member': member,
    'points': points,
  };

  @override
  bool operator ==(Object other) =>
      other is Customer &&
      other.id == id &&
      other.name == name &&
      other.phone == phone &&
      other.email == email &&
      other.member == member &&
      other.points == points;

  @override
  int get hashCode => Object.hash(id, name, phone, email, member, points);
}
