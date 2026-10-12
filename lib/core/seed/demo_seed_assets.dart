import 'package:flutter/services.dart' show rootBundle;

/// Reads a seed file from `assets/seed/` (bundled with the app).
Future<String> loadSeedAsset(String name) =>
    rootBundle.loadString('assets/seed/$name');
