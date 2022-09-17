import 'package:flutter/cupertino.dart';

Widget baseCursorPointer(Widget child,
    {MouseCursor cursor = SystemMouseCursors.click}) {
  return MouseRegion(child: child, cursor: cursor);
}
