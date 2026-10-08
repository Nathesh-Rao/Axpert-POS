import 'rational.dart';

/// Parses plain decimal text ("12", "12.5", "-0.25", ".5") into an integer at
/// a fixed scale without ever going through a binary float. Digits beyond the
/// scale are rounded half-up (the "commit" rule, see KG-002/003/004).
class DecimalParser {
  const DecimalParser._();

  static final RegExp _pattern = RegExp(r'^([+-]?)(\d*)(?:\.(\d*))?$');

  static int parseScaled(String text, int scale) {
    final match = _pattern.firstMatch(text.trim());
    if (match == null) throw FormatException('Not a decimal number', text);
    final whole = match.group(2)!;
    final frac = match.group(3) ?? '';
    if (whole.isEmpty && frac.isEmpty) {
      throw FormatException('Not a decimal number', text);
    }
    var value = Rational(
      BigInt.parse('${whole.isEmpty ? '0' : whole}$frac'),
      BigInt.from(10).pow(frac.length),
    );
    if (match.group(1) == '-') value = -value;
    return (value * Rational(BigInt.from(10).pow(scale))).roundHalfUp().toInt();
  }
}
