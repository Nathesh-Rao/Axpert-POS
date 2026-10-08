// Shared checks for the narrow-window rule (S4.0 lesson): a console overflow
// count proves nothing, so key texts are measured: one line, a minimum width
// per character (no per-character wrapping) and inside the window.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const List<double> matrixWidths = <double>[
  1000,
  1100,
  1101,
  1280,
  1281,
  1440,
  1700,
  1701,
  1868,
  1900,
];

const List<double> matrixHeights = <double>[600, 719, 720, 820, 900, 960, 1000];

/// The paragraph that renders [finder]'s first match.
RenderParagraph paragraphOf(WidgetTester tester, Finder finder) {
  final element = finder.evaluate().first;
  RenderParagraph? found;
  void visit(Element e) {
    if (found != null) return;
    final ro = e.renderObject;
    if (e.widget is RichText && ro is RenderParagraph) {
      found = ro;
      return;
    }
    e.visitChildren(visit);
  }

  if (element.widget is RichText) {
    return element.renderObject! as RenderParagraph;
  }
  visit(element);
  return found!;
}

/// Lines used by [finder]'s text: its rendered height over the height of the
/// same text laid out on one unbounded line (robust on VM and web).
int lineCount(WidgetTester tester, Finder finder) {
  final p = paragraphOf(tester, finder);
  final single = TextPainter(
    text: p.text,
    textDirection: TextDirection.ltr,
    textScaler: p.textScaler,
  )..layout();
  if (single.height == 0) return 0;
  return (p.size.height / single.height).round();
}

/// The text is on one line, at least [minPerChar] logical px wide per
/// character, and inside the [window].
void expectReadable(
  WidgetTester tester,
  Finder finder,
  Size window, {
  double minPerChar = 3,
  String? reason,
}) {
  expect(finder, findsAtLeastNWidgets(1), reason: reason);
  final p = paragraphOf(tester, finder);
  final chars = p.text.toPlainText().length;
  final rect = tester.getRect(finder.first);
  final why = '${reason ?? ''} "${p.text.toPlainText()}" $rect in $window';
  expect(lineCount(tester, finder), 1, reason: 'one line: $why');
  expect(
    p.size.width,
    greaterThanOrEqualTo(chars * minPerChar),
    reason: 'min width: $why',
  );
  expect(rect.left, greaterThanOrEqualTo(-0.5), reason: 'left: $why');
  expect(
    rect.right,
    lessThanOrEqualTo(window.width + 0.5),
    reason: 'right: $why',
  );
}
