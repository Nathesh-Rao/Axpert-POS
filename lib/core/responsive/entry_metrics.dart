import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../theme/tokens/app_entry_tokens.dart';

/// Layout numbers of the login screen for one window size. Pure (no
/// context), so it is unit-tested. Everything scales with the width, clamped
/// to [AppEntrySizes.minScale]..[AppEntrySizes.maxScale].
class EntryMetrics {
  const EntryMetrics._({
    required this.scale,
    required this.panelWidth,
    required this.formWidth,
    required this.panelOverlapsPhoto,
  });

  factory EntryMetrics.of(Size size) {
    final scale = (size.width / AppEntrySizes.referenceWidth).clamp(
      AppEntrySizes.minScale,
      AppEntrySizes.maxScale,
    );
    final panelWidth = math.max(
      size.width * AppEntrySizes.panelFraction,
      (AppEntrySizes.formMinWidth + 2 * AppEntrySizes.panelPadding) * scale,
    );
    final formWidth = (panelWidth - 2 * AppEntrySizes.panelPadding * scale)
        .clamp(AppEntrySizes.formMinWidth, AppEntrySizes.formWidth * scale);
    // The photo is cover-fitted and left aligned; it fades to white at
    // [photoFadeEndFraction] of its drawn width.
    final photoWidth = math.max(
      size.width,
      size.height * AppEntrySizes.referenceWidth / _photoHeight,
    );
    final whiteFrom = photoWidth * AppEntrySizes.photoFadeEndFraction;
    return EntryMetrics._(
      scale: scale,
      panelWidth: panelWidth,
      formWidth: formWidth,
      panelOverlapsPhoto: size.width - panelWidth < whiteFrom,
    );
  }

  static const double _photoHeight = 941;

  final double scale;
  final double panelWidth;
  final double formWidth;

  /// True when the form panel reaches over the photo (narrow windows), so it
  /// needs an opaque background in light mode too.
  final bool panelOverlapsPhoto;

  double px(double base) => base * scale;
}
