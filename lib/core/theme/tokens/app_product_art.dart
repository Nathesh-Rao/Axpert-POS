import 'package:flutter/painting.dart';

/// Colors of the CSS placeholder drawn for products without an image
/// (`.placeholder-product`, `.juice` and `.care`). The prototype does not
/// override them in dark mode, so both modes use these values (KG-060).
abstract final class AppProductArt {
  static const List<Color> juiceGradient = <Color>[
    Color(0xFFFFCF55),
    Color(0xFFF48C29),
  ];
  static const Color juiceTopBorder = Color(0xFFF4FAFB);
  static const Color juiceText = Color(0xFFFFFFFF);
  static const Color juiceSmall = Color(0xFFFFFFFF);
  static const Color juiceTextShadow = Color(0x33000000);

  static const List<Color> careGradient = <Color>[
    Color(0xFFF4F8FC),
    Color(0xFFE5EDFA),
  ];
  static const Color careTopBorder = Color(0xFF194E88);
  static const Color careText = Color(0xFF174B85);
  static const Color careSmall = Color(0xFF3D648F);

  /// `box-shadow: inset -6px 0 0 #0000000a` of the juice carton.
  static const Color juiceSideShade = Color(0x0A000000);

  static const double juiceWidth = 58.0;
  static const double juiceHeight = 70.0;
  static const double juiceTopBorderWidth = 5.0;
  static const double juiceSideShadeWidth = 6.0;
  static const double juiceRotationDeg = -3.0;
  static const double careWidth = 65.0;
  static const double careHeight = 65.0;
  static const double careTopBorderWidth = 8.0;
  static const double nameFont = 15.0;
  static const double smallFont = 6.0;
  static const double smallTracking = 1.0;
  static const double smallGap = 7.0;
}
