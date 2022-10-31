import 'package:flutter/material.dart';

Widget buildScaleAnimatedSwitcher(Widget child) {
  return AnimatedSwitcher(
    duration: const Duration(
      milliseconds: 300,
    ),
    child: child,
    transitionBuilder: (Widget child, Animation<double> animation) {
      //执行缩放动画
      return ScaleTransition(child: child, scale: animation);
    },
  );
}
