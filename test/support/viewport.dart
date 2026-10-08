// Reference viewport helpers shared by VM and web tests (no dart:io).
import 'package:flutter/painting.dart' show Size, Offset;
import 'package:flutter_test/flutter_test.dart';

/// Image pixels per CSS px, measured (css_metrics.md section 1).
const double referenceScale = 1.125;

/// Page area of the reference screenshots (window frame excluded).
const Size referencePhysicalSize = Size(2102, 1164);

/// Top-left of the page area inside the 2124 x 1180 screenshots.
const Offset referencePageOffset = Offset(10, 8);

/// Logical size: 1868.44 x 1034.67 (fractional on purpose, DEC-066).
Size get referenceLogicalSize => referencePhysicalSize / referenceScale;

/// Sets the test window to the reference viewport (2102 x 1164 px at 1.125).
void useReferenceViewport(WidgetTester tester) {
  tester.view
    ..devicePixelRatio = referenceScale
    ..physicalSize = referencePhysicalSize;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Sets the test window to a [logical] size at device pixel ratio 1.
void useLogicalViewport(WidgetTester tester, Size logical) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = logical;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
