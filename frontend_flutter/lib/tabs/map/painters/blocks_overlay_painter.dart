import 'package:flutter/material.dart';
import 'package:dart_common/dart_common.dart';
import '../edit_modes/blocks_edit_mode.dart';

class BlocksOverlayPainter extends CustomPainter {
  final List<BlockPoint> blocks;
  final double imageWidth;
  final double imageHeight;
  final double offsetX;
  final double offsetY;
  final BlockEditTool currentTool;
  final Offset? hoverPosition;
  final BlockPoint? wallStartPoint;

  BlocksOverlayPainter({
    required this.blocks,
    required this.imageWidth,
    required this.imageHeight,
    required this.offsetX,
    required this.offsetY,
    required this.currentTool,
    this.hoverPosition,
    this.wallStartPoint,
  });

  List<BlockPoint> _calculateLineBlockPoints(BlockPoint start, BlockPoint end) {
    final points = <BlockPoint>[];
    final dx = (end.x - start.x).abs();
    final dy = (end.y - start.y).abs();
    final sx = start.x < end.x ? 1 : -1;
    final sy = start.y < end.y ? 1 : -1;
    var err = dx - dy;

    var x = start.x;
    var y = start.y;

    while (true) {
      points.add(BlockPoint(x: x, y: y));
      if (x == end.x && y == end.y) break;

      final e2 = 2 * err;
      if (e2 > -dy) {
        err -= dy;
        x += sx;
      }
      if (e2 < dx) {
        err += dx;
        y += sy;
      }
    }
    return points;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final wallPaint =
        Paint()
          ..color = Colors.grey[800]!
          ..strokeWidth = 1;

    for (var block in blocks) {
      final x = block.x.toDouble();
      final y = imageHeight - block.y.toDouble();
      canvas.drawRect(Rect.fromCenter(center: Offset(x, y), width: 1, height: 1), wallPaint);
    }

    if (hoverPosition != null) {
      final hoverX = hoverPosition!.dx.round();
      final hoverY = (imageHeight - hoverPosition!.dy).round();

      if (currentTool == BlockEditTool.draw) {
        final previewPaint =
            Paint()
              ..color = Colors.blue.withValues(alpha: 0.6)
              ..strokeWidth = 1;
        final displayY = imageHeight - hoverY;
        canvas.drawCircle(Offset(hoverX.toDouble(), displayY), 0.5, previewPaint);
      } else if (currentTool == BlockEditTool.erase) {
        final previewPaint =
            Paint()
              ..color = Colors.red.withValues(alpha: 0.6)
              ..strokeWidth = 1;
        final displayY = imageHeight - hoverY;
        canvas.drawCircle(Offset(hoverX.toDouble(), displayY), 0.5, previewPaint);
      } else if (currentTool == BlockEditTool.wall) {
        if (wallStartPoint != null) {
          final lineBlockPoints = _calculateLineBlockPoints(wallStartPoint!, BlockPoint(x: hoverX, y: hoverY));

          final previewPaint =
              Paint()
                ..color = Colors.blue.withValues(alpha: 0.6)
                ..strokeWidth = 1;

          for (var point in lineBlockPoints) {
            final x = point.x.toDouble();
            final y = imageHeight - point.y.toDouble();
            canvas.drawCircle(Offset(x, y), 0.5, previewPaint);
          }
        } else {
          final previewPaint =
              Paint()
                ..color = Colors.blue.withValues(alpha: 0.6)
                ..strokeWidth = 1;
          final displayY = imageHeight - hoverY;
          canvas.drawCircle(Offset(hoverX.toDouble(), displayY), 0.5, previewPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(BlocksOverlayPainter oldDelegate) {
    return blocks.length != oldDelegate.blocks.length ||
        currentTool != oldDelegate.currentTool ||
        hoverPosition != oldDelegate.hoverPosition ||
        wallStartPoint != oldDelegate.wallStartPoint;
  }
}
