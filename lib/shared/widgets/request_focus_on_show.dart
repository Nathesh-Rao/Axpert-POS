import 'package:flutter/widgets.dart';

/// `autoFocus` of the prototype's modal inputs: asks for focus once the first
/// frame is built (the dialog route has its own focus scope).
class RequestFocusOnShow extends StatefulWidget {
  const RequestFocusOnShow({
    required this.focusNode,
    required this.child,
    super.key,
  });

  final FocusNode focusNode;
  final Widget child;

  @override
  State<RequestFocusOnShow> createState() => _RequestFocusOnShowState();
}

class _RequestFocusOnShowState extends State<RequestFocusOnShow> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
