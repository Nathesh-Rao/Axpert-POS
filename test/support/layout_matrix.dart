// Shared checks for the narrow-window rule (S4.0 lesson): a console overflow
// count proves nothing, so key texts are measured: one line, a minimum width
// per character (no per-character wrapping) and inside the window.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const List<double> matrixWidths = <double>[
  900,
  950,
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

const List<double> matrixHeights = <double>[
  600,
  719,
  720,
  733,
  820,
  900,
  960,
  1000,
];

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
  bool oneLine = true,
  String? reason,
}) {
  expect(finder, findsAtLeastNWidgets(1), reason: reason);
  final p = paragraphOf(tester, finder);
  final chars = p.text.toPlainText().length;
  final rect = tester.getRect(finder.first);
  final why = '${reason ?? ''} "${p.text.toPlainText()}" $rect in $window';
  // Plain widget tests draw with the wide test font (the real Roboto
  // Condensed is only loaded in goldens), so long strings may wrap there:
  // [oneLine] false keeps the other checks and leaves one-line to web_check.
  if (oneLine) expect(lineCount(tester, finder), 1, reason: 'one line: $why');
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

/// Global paint rect of [box] (scale transforms such as `FittedBox` included).
Rect globalRect(RenderBox box) =>
    MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);

/// Rects of everything under [root] that paints something visible: text,
/// editable text and decorated boxes. [skip] leaves out the card's own
/// decoration.
List<Rect> paintRects(Element root, {RenderObject? skip}) {
  final rects = <Rect>[];
  void visit(Element e) {
    final ro = e.renderObject;
    if (ro is RenderBox &&
        ro != skip &&
        ro.hasSize &&
        (ro is RenderParagraph ||
            ro is RenderEditable ||
            ro is RenderDecoratedBox) &&
        ro.size.width > 0 &&
        ro.size.height > 0) {
      rects.add(globalRect(ro));
    }
    e.visitChildren(visit);
  }

  visit(root);
  return rects;
}

/// The bounding box of the visible content of [card] (a widget with a
/// `SummaryCard` inside): everything except the card's own decoration.
Rect cardContentRect(WidgetTester tester, Finder card, Type summaryCard) {
  final inner = find.descendant(of: card, matching: find.byType(summaryCard));
  final cardElement = (inner.evaluate().isNotEmpty ? inner : card)
      .evaluate()
      .first;
  RenderDecoratedBox? own;
  void findOwn(Element e) {
    if (own != null) return;
    if (e.renderObject is RenderDecoratedBox) {
      own = e.renderObject! as RenderDecoratedBox;
      return;
    }
    e.visitChildren(findOwn);
  }

  findOwn(cardElement);
  final rects = paintRects(cardElement, skip: own);
  var union = rects.first;
  for (final r in rects.skip(1)) {
    union = union.expandToInclude(r);
  }
  return union;
}

/// Every side of [content] is at least [min] inside [card].
void expectInset(
  Rect card,
  Rect content,
  double min, {
  required String reason,
}) {
  const tol = 0.01;
  expect(
    content.left - card.left,
    greaterThanOrEqualTo(min - tol),
    reason: 'left: $reason',
  );
  expect(
    content.top - card.top,
    greaterThanOrEqualTo(min - tol),
    reason: 'top: $reason',
  );
  expect(
    card.right - content.right,
    greaterThanOrEqualTo(min - tol),
    reason: 'right: $reason',
  );
  expect(
    card.bottom - content.bottom,
    greaterThanOrEqualTo(min - tol),
    reason: 'bottom: $reason',
  );
}

/// The vertical gap from [upper]'s bottom to [lower]'s top is at least [min].
void expectGap(Rect upper, Rect lower, double min, {required String reason}) {
  expect(
    lower.top - upper.bottom,
    greaterThanOrEqualTo(min - 0.01),
    reason: 'gap $upper -> $lower: $reason',
  );
}

/// The text inside the focused [outline] (a `FocusOutline`) keeps at least
/// [min] from the ring (2 px outside the box) on top, bottom and left.
void expectRingClearance(
  WidgetTester tester,
  Finder outline,
  double min, {
  required String reason,
}) {
  final box = tester.getRect(outline);
  final ringInner = box.inflate(2);
  RenderEditable? editable;
  void visit(Element e) {
    if (e.renderObject is RenderEditable) {
      editable = e.renderObject! as RenderEditable;
    }
    e.visitChildren(visit);
  }

  visit(outline.evaluate().first);
  final r = editable!;
  final boxes = r.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: r.text!.toPlainText().length),
  );
  final origin = r.localToGlobal(Offset.zero);
  var text = boxes.first.toRect().shift(origin);
  for (final b in boxes.skip(1)) {
    text = text.expandToInclude(b.toRect().shift(origin));
  }
  // The painted line box is the strut: the line height, centred.
  final top = r
      .localToGlobal(Offset(0, (r.size.height - r.preferredLineHeight) / 2))
      .dy;
  final line = Rect.fromLTRB(
    text.left,
    top,
    text.right,
    top + r.preferredLineHeight,
  );
  final why = 'text $line ring $ringInner box $box: $reason';
  expect(
    line.top - ringInner.top,
    greaterThanOrEqualTo(min - 0.01),
    reason: 'top $why',
  );
  expect(
    ringInner.bottom - line.bottom,
    greaterThanOrEqualTo(min - 0.01),
    reason: 'bottom $why',
  );
  expect(
    line.left - ringInner.left,
    greaterThanOrEqualTo(min - 0.01),
    reason: 'left $why',
  );
}
