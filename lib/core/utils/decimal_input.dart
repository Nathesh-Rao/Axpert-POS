import '../services/pricing/decimal_parser.dart';

/// Commit-time parsing of typed number text (no floats): null when the text
/// is empty or not a plain decimal.
abstract final class DecimalInput {
  static int? tryScaled(String text, int scale) {
    if (text.trim().isEmpty) return null;
    try {
      return DecimalParser.parseScaled(text, scale);
    } on FormatException {
      return null;
    }
  }
}
