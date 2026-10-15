import '../../constants/app_strings.dart';

/// The text of a packaging: "Carton of 24". A packaging whose name already
/// carries its size ("Carton of 24", as the demo data names them) is not
/// given the size twice.
abstract final class PackagingLabel {
  static String sized(String name, String factorText) {
    final trimmed = name.trim();
    return trimmed.endsWith(factorText)
        ? trimmed
        : AppStrings.current.unitOptionLabel(trimmed, factorText);
  }
}
