import 'package:flutter/material.dart';
import 'package:dart_common/dart_common.dart';

class DoorsOverlayPainter extends CustomPainter {
  final List<Door> doors;
  final double imageWidth;
  final double imageHeight;
  final double offsetX;
  final double offsetY;
  final MapPoint? doorStartPoint;
  final Offset? hoverPosition;

  DoorsOverlayPainter({
    required this.doors,
    required this.imageWidth,
    required this.imageHeight,
    required this.offsetX,
    required this.offsetY,
    this.doorStartPoint,
    this.hoverPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final doorPaint =
        Paint()
          ..color = Colors.orange
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    for (var door in doors) {
      final x0 = door.x0.toDouble();
      final y0 = imageHeight - door.y0.toDouble();
      final x1 = door.x1.toDouble();
      final y1 = imageHeight - door.y1.toDouble();

      canvas.drawLine(Offset(x0, y0), Offset(x1, y1), doorPaint);
    }

    if (doorStartPoint != null && hoverPosition != null) {
      final startX = doorStartPoint!.x.toDouble();
      final startY = imageHeight - doorStartPoint!.y.toDouble();
      final endX = hoverPosition!.dx;
      final endY = hoverPosition!.dy;

      final previewPaint =
          Paint()
            ..color = Colors.orange.withValues(alpha: 0.6)
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), previewPaint);
    } else if (doorStartPoint != null) {
      final startX = doorStartPoint!.x.toDouble();
      final startY = imageHeight - doorStartPoint!.y.toDouble();

      final pointPaint =
          Paint()
            ..color = Colors.orange
            ..strokeWidth = 1
            ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(startX, startY), 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(DoorsOverlayPainter oldDelegate) {
    return doors.length != oldDelegate.doors.length || doorStartPoint != oldDelegate.doorStartPoint || hoverPosition != oldDelegate.hoverPosition;
  }
}
