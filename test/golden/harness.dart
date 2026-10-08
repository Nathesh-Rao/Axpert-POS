// Golden harness (step 1.2). Fixes the reference viewport measured from the
// screenshots (css_metrics.md section 1), loads the real fonts from
// test/fonts (never the network) and compares with a small tolerance.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show debugDisableShadows;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/theme/tokens/app_typography.dart';

/// Image pixels per CSS px, measured (css_metrics.md section 1).
const double referenceScale = 1.125;

/// Page area of the reference screenshots (window frame excluded).
const Size referencePhysicalSize = Size(2102, 1164);

/// Top-left of the page area inside the 2124 x 1180 screenshots.
const Offset referencePageOffset = Offset(10, 8);

/// Logical size: 1868.44 x 1034.67 (fractional on purpose, DEC-066).
Size get referenceLogicalSize => referencePhysicalSize / referenceScale;

/// Roboto Condensed static TTFs the user places in test/fonts (DEC-044).
const Map<String, String> testFontFiles = <String, String>{
  'Regular': 'test/fonts/RobotoCondensed-Regular.ttf',
  'Medium': 'test/fonts/RobotoCondensed-Medium.ttf',
  'SemiBold': 'test/fonts/RobotoCondensed-SemiBold.ttf',
  'Bold': 'test/fonts/RobotoCondensed-Bold.ttf',
};

/// Files from [testFontFiles] that do not exist yet.
List<String> missingTestFonts() => <String>[
  for (final path in testFontFiles.values)
    if (!File(path).existsSync()) path,
];

/// Non-empty when font-dependent tests must be skipped. `testWidgets` only
/// takes a bool, so the reason goes into the test names and the log.
String fontsSkipReason() {
  final missing = missingTestFonts();
  if (missing.isEmpty) return '';
  final reason = 'SKIPPED, test fonts missing: ${missing.join(', ')}';
  debugPrint(reason);
  return reason;
}

/// Switches typography to the bundled family and loads the TTFs and the
/// Lucide icon font so goldens draw real glyphs instead of test boxes.
Future<void> loadTestFonts() async {
  AppTypography.useBundledFonts = true;
  final roboto = FontLoader(AppTypography.family);
  for (final path in testFontFiles.values) {
    final bytes = await File(path).readAsBytes();
    roboto.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  }
  await roboto.load();
  final lucide = FontLoader('packages/lucide_icons_flutter/Lucide')
    ..addFont(
      rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
    );
  await lucide.load();
}

/// flutter_test draws hard-edged shadows by default; a golden that compares
/// shadows needs real blur. Call in the test body and restore with
/// [restoreDefaultShadows] in a `finally` (the framework asserts it is reset
/// before tearDown callbacks run).
void useRealShadows() => debugDisableShadows = false;
void restoreDefaultShadows() => debugDisableShadows = true;

/// Sets the test window to the reference viewport (2102 x 1164 px at 1.125).
void useReferenceViewport(WidgetTester tester) {
  tester.view
    ..devicePixelRatio = referenceScale
    ..physicalSize = referencePhysicalSize;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Accepts pixel differences up to [tolerance] (fraction, 0.005 = 0.5 %).
class TolerantFileComparator extends LocalFileComparator {
  TolerantFileComparator(super.testFile, {required this.tolerance});

  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed) return true;
    if (result.diffPercent <= tolerance) {
      debugPrint(
        'Golden $golden differs by ${(result.diffPercent * 100).toStringAsFixed(3)} % '
        '(within tolerance ${(tolerance * 100).toStringAsFixed(3)} %).',
      );
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}

/// Call at the start of `main()` of a golden test file.
void useTolerantGoldens({double tolerance = 0.005}) {
  final current = goldenFileComparator;
  if (current is LocalFileComparator) {
    goldenFileComparator = TolerantFileComparator(
      current.basedir.resolve('golden_test.dart'),
      tolerance: tolerance,
    );
  }
}
