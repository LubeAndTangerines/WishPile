import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StrikeThroughDecoration extends Decoration {
  @override
  BoxPainter createBoxPainter([VoidCallback onChanged]) {
    return new _StrikeThroughPainter();
  }
}

class _StrikeThroughPainter extends BoxPainter {
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final paint = new Paint()
      ..strokeWidth = 1.0
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final rect = offset & configuration.size;
    canvas.drawLine(new Offset(rect.left + 10, rect.top + rect.height / 2), new Offset(rect.right - 10, rect.top + rect.height / 2), paint);
    canvas.restore();
  }
}
