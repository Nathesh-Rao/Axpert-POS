import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A short description of the focused widget: its debug label or the first
/// text inside it (`global-search`, `Products`, `field(C3)`).
String describeFocus() {
  final node = FocusManager.instance.primaryFocus;
  final ctx = node?.context;
  if (ctx == null) return '<none>';
  String? text;
  void visit(Element e) {
    if (text != null) return;
    final w = e.widget;
    if (w is Text && w.data != null) {
      text = w.data;
      return;
    }
    if (w is EditableText) {
      text = 'field(${w.controller.text})';
      return;
    }
    e.visitChildren(visit);
  }

  (ctx as Element).visitChildren(visit);
  final label = node!.debugLabel;
  if (label != null && !label.startsWith('_') && label != 'Focus Scope') {
    return label;
  }
  return text ?? '';
}

/// Presses Tab (or Shift+Tab) [count] times and returns what each press
/// focused.
Future<List<String>> walkTab(
  WidgetTester tester,
  int count, {
  bool reverse = false,
}) async {
  final out = <String>[];
  for (var i = 0; i < count; i++) {
    if (reverse) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    if (reverse) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    out.add(describeFocus());
  }
  return out;
}
