import 'package:flutter/material.dart';

Widget wrap(Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Material(child: child),
  );
}
