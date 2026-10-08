import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Vertical stack of the Bill Summary blocks with computed gaps:
/// every gap is at least [minGap]; free height up to [availableHeight] is
/// spread evenly over the gaps until they reach [maxGap]; what is left goes
/// into the gap after child [autoGapIndex] (the prototype's `margin-top:auto`
/// on the checkout section). When the blocks plus the minimum gaps are taller
/// than [availableHeight] the column is simply taller (the parent scrolls).
class SummaryColumn extends MultiChildRenderObjectWidget {
  const SummaryColumn({
    required this.availableHeight,
    required this.minGap,
    required this.maxGap,
    required this.autoGapIndex,
    required super.children,
    super.key,
  });

  final double availableHeight;
  final double minGap;
  final double maxGap;
  final int autoGapIndex;

  @override
  RenderSummaryColumn createRenderObject(BuildContext context) =>
      RenderSummaryColumn(
        availableHeight: availableHeight,
        minGap: minGap,
        maxGap: maxGap,
        autoGapIndex: autoGapIndex,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSummaryColumn renderObject,
  ) {
    renderObject
      ..availableHeight = availableHeight
      ..minGap = minGap
      ..maxGap = maxGap
      ..autoGapIndex = autoGapIndex;
  }
}

class _ParentData extends ContainerBoxParentData<RenderBox> {}

class RenderSummaryColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ParentData> {
  RenderSummaryColumn({
    required double availableHeight,
    required double minGap,
    required double maxGap,
    required int autoGapIndex,
  }) : _availableHeight = availableHeight,
       _minGap = minGap,
       _maxGap = maxGap,
       _autoGapIndex = autoGapIndex;

  double _availableHeight;
  double _minGap;
  double _maxGap;
  int _autoGapIndex;

  set availableHeight(double v) {
    if (v == _availableHeight) return;
    _availableHeight = v;
    markNeedsLayout();
  }

  set minGap(double v) {
    if (v == _minGap) return;
    _minGap = v;
    markNeedsLayout();
  }

  set maxGap(double v) {
    if (v == _maxGap) return;
    _maxGap = v;
    markNeedsLayout();
  }

  set autoGapIndex(int v) {
    if (v == _autoGapIndex) return;
    _autoGapIndex = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ParentData) child.parentData = _ParentData();
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final inner = BoxConstraints.tightFor(width: width);
    final boxes = <RenderBox>[];
    var blocks = 0.0;
    for (var c = firstChild; c != null; c = childAfter(c)) {
      c.layout(
        inner.copyWith(minHeight: 0, maxHeight: double.infinity),
        parentUsesSize: true,
      );
      boxes.add(c);
      blocks += c.size.height;
    }
    final gaps = math.max(0, boxes.length - 1);
    final slack = gaps == 0
        ? 0.0
        : math.max(0.0, _availableHeight - blocks - gaps * _minGap);
    final room = math.max(0.0, _maxGap - _minGap);
    final extra = gaps == 0 ? 0.0 : math.min(slack / gaps, room);
    final leftover = gaps == 0 ? 0.0 : slack - extra * gaps;
    var y = 0.0;
    for (var i = 0; i < boxes.length; i++) {
      (boxes[i].parentData! as _ParentData).offset = Offset(0, y);
      y += boxes[i].size.height;
      if (i < gaps) {
        y += _minGap + extra + (i == _autoGapIndex ? leftover : 0);
      }
    }
    size = constraints.constrain(Size(width, y));
  }

  @override
  double computeMinIntrinsicHeight(double width) => _sumHeights(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _sumHeights(width);

  double _sumHeights(double width) {
    var h = 0.0;
    var n = 0;
    for (var c = firstChild; c != null; c = childAfter(c)) {
      h += c.getMaxIntrinsicHeight(width);
      n++;
    }
    return h + math.max(0, n - 1) * _minGap;
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
