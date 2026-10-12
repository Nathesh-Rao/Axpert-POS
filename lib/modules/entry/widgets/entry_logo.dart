import 'package:flutter/material.dart';

import '../../../shared/widgets/brand_logo.dart';

/// The logo shared by splash and login: a [Hero], so it flies from the splash
/// centre to its place above the login form.
class EntryLogo extends StatelessWidget {
  const EntryLogo({required this.size, super.key});

  static const String heroTag = 'entry-logo';

  final double size;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag,
      child: SizedBox(
        width: size,
        height: size,
        child: BrandLogo(size: size),
      ),
    );
  }
}
