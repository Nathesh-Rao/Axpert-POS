import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';

/// The Axpert logo (round mark with transparent corners; reads on light and
/// dark backgrounds, so there is one asset for both themes).
class BrandLogo extends StatelessWidget {
  const BrandLogo({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).ceil();
    return Image.asset(
      AppAssets.logo,
      width: size,
      height: size,
      cacheWidth: pixels,
      filterQuality: FilterQuality.high,
      excludeFromSemantics: true,
    );
  }
}
