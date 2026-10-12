import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Salted SHA-256 for the demo login (DEC-133). The stored value is
/// `sha256(salt + ':' + password)` in hex; [algorithm] is saved with each user
/// so a slower scheme can replace it later. Never logs or returns a password.
class PasswordHasher {
  const PasswordHasher();

  static const String algorithm = 'sha256-salted-v1';

  /// 16 random bytes as hex.
  String newSalt([Random? random]) {
    final r = random ?? Random.secure();
    return [
      for (var i = 0; i < 16; i++)
        r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
  }

  String hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  /// Compares without stopping at the first differing character.
  bool verify({
    required String salt,
    required String password,
    required String expected,
  }) {
    final actual = hash(salt, password);
    if (actual.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual.codeUnitAt(i) ^ expected.codeUnitAt(i);
    }
    return diff == 0;
  }
}
