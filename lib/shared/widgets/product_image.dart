import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_strings_x.dart';
import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_product_art.dart';
import '../../core/theme/tokens/app_radii.dart';
import '../../core/theme/tokens/app_sizes.dart';
import '../../core/theme/tokens/app_typography.dart';
import 'css_gradient.dart';

/// Product picture: the PNG asset `assets/products/<image>.png`, or the CSS
/// placeholder (`.placeholder-product` juice carton for Beverages, care
/// bottle otherwise) when [image] is negative.
class ProductImage extends StatelessWidget {
  const ProductImage({
    required this.image,
    required this.name,
    required this.beverage,
    this.fit = BoxFit.contain,
    super.key,
  });

  final int image;
  final String name;
  final bool beverage;
  final BoxFit fit;

  static String assetPath(int image) => 'assets/products/$image.png';

  @override
  Widget build(BuildContext context) {
    if (image >= 0) {
      final picture = Image.asset(
        assetPath(image),
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: AppSizes.productImageCacheWidth.toInt(),
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
      );
      final radius = context.colors.productImageRadius;
      // Light mode multiplies the PNG with the white card (no visible
      // change); dark mode draws it normally with a 4 px radius (KG-074).
      return radius > 0
          ? ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: picture,
            )
          : picture;
    }
    return _Placeholder(
      word: name.split(' ').first,
      tag: beverage
          ? context.strings.placeholderJuiceTag()
          : context.strings.placeholderCareTag(),
      beverage: beverage,
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.word,
    required this.tag,
    required this.beverage,
  });

  final String word;
  final String tag;
  final bool beverage;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final width = beverage ? AppProductArt.juiceWidth : AppProductArt.careWidth;
    final height = beverage
        ? AppProductArt.juiceHeight
        : AppProductArt.careHeight;
    final topWidth = beverage
        ? AppProductArt.juiceTopBorderWidth
        : AppProductArt.careTopBorderWidth;
    final topColor = beverage
        ? AppProductArt.juiceTopBorder
        : AppProductArt.careTopBorder;
    final fg = beverage ? AppProductArt.juiceText : AppProductArt.careText;
    final small = beverage ? AppProductArt.juiceSmall : AppProductArt.careSmall;
    final body = SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: const Radius.circular(AppRadii.r4),
          bottom: Radius.circular(beverage ? AppRadii.r8 : AppRadii.r4),
        ),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: topWidth,
              width: double.infinity,
              child: ColoredBox(color: topColor),
            ),
            Expanded(
              child: CssGradientBox(
                angleDeg: beverage ? 110 : 120,
                colors: beverage
                    ? AppProductArt.juiceGradient
                    : AppProductArt.careGradient,
                child: Stack(
                  children: <Widget>[
                    if (beverage)
                      const Positioned(
                        top: 0,
                        bottom: 0,
                        right: 0,
                        width: AppProductArt.juiceSideShadeWidth,
                        child: ColoredBox(color: AppProductArt.juiceSideShade),
                      ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            word,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.clip,
                            style: text
                                .fluid(
                                  AppProductArt.nameFont,
                                  weight: AppFontWeight.bold,
                                  height: AppLineHeight.base,
                                )
                                .copyWith(
                                  color: fg,
                                  shadows: beverage
                                      ? const <Shadow>[
                                          Shadow(
                                            color:
                                                AppProductArt.juiceTextShadow,
                                            offset: Offset(0, 1),
                                            blurRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                          ),
                          const SizedBox(height: AppProductArt.smallGap),
                          Text(
                            tag,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.clip,
                            style: text
                                .fluid(
                                  AppProductArt.smallFont,
                                  letterSpacing: AppProductArt.smallTracking,
                                  height: AppLineHeight.base,
                                )
                                .copyWith(color: small),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (!beverage) return body;
    return Transform.rotate(
      angle: AppProductArt.juiceRotationDeg * math.pi / 180,
      child: body,
    );
  }
}
