import 'package:flutter/material.dart';
import '../../../cubits/display_settings_cubit.dart';
import 'package:dart_common/dart_common.dart';

class BaseMapPainter extends CustomPainter {
  final MapData mapData;
  final double imageWidth;
  final double imageHeight;
  final DisplaySettings displaySettings;

  BaseMapPainter({required this.mapData, required this.imageWidth, required this.imageHeight, required this.displaySettings});

  @override
  void paint(Canvas canvas, Size size) {
    final dims = mapData.imageDimensions;
    final offsetX = dims != null ? dims.left.toDouble() : 0.0;
    final offsetY = dims != null ? dims.top.toDouble() : 0.0;

    final walls = mapData.walls;
    final virtualWalls = mapData.virtualWalls;
    // Map raw data to SegmentedRoom objects
    final Map<String, SegmentedRoom> segmentedRooms = mapData.rooms;

    final wallPaint =
        Paint()
          ..color = Colors.grey[800]!
          ..strokeWidth = 1;

    for (var wall in walls) {
      final x = (wall.x as num).toDouble();
      final y = imageHeight - (wall.y as num).toDouble();
      canvas.drawRect(Rect.fromCenter(center: Offset(x, y), width: 1, height: 1), wallPaint);
    }

    final roomColors = [
      Colors.blue.withOpacity(0.3),
      Colors.green.withOpacity(0.3),
      Colors.orange.withOpacity(0.3),
      Colors.purple.withOpacity(0.3),
      Colors.pink.withOpacity(0.3),
      Colors.teal.withOpacity(0.3),
      Colors.amber.withOpacity(0.3),
      Colors.cyan.withOpacity(0.3),
    ];

    int colorIndex = 0;
    for (var room in segmentedRooms.values) {
      final rectangles = room.rectangles;
      final roomName = room.name;
      final x0 = room.x0;
      final y0 = room.y0;
      final x1 = room.x1;
      final y1 = room.y1;

      if (displaySettings.showRoomColors) {
        final roomPaint =
            Paint()
              ..color = roomColors[colorIndex % roomColors.length]
              ..style = PaintingStyle.fill;

        for (var rect in rectangles) {
          final x = rect.x.toDouble();
          final y = rect.y.toDouble();
          final width = rect.width.toDouble();
          final height = rect.height.toDouble();

          final left = x - 0.5;
          final top = imageHeight - y - height + 0.5;
          canvas.drawRect(Rect.fromLTWH(left, top, width, height), roomPaint);
        }
      }

      if (displaySettings.showRoomLabels) {
        final centerX = (x0 + x1) / 2;
        final centerY = imageHeight - ((y0 + y1) / 2);

        final textPainter = TextPainter(
          text: TextSpan(text: roomName, style: const TextStyle(color: Colors.white, fontSize: 14)),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        final rrect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(centerX, centerY), width: textPainter.width + 12, height: textPainter.height + 8),
          const Radius.circular(6),
        );
        canvas.drawRRect(rrect, Paint()..color = Colors.black.withOpacity(0.7));
        textPainter.paint(canvas, Offset(centerX - textPainter.width / 2, centerY - textPainter.height / 2));
      }

      colorIndex++;
    }

    if (virtualWalls.isNotEmpty) {
      final virtualWallPaint =
          Paint()
            ..color = Colors.red
            ..strokeWidth = 2;

      for (var wall in virtualWalls) {
        final px0 = ((wall.x0 as num).toDouble() / 50) - offsetX;
        final py0 = imageHeight - (((wall.y0 as num).toDouble() / 50) - offsetY);
        final px1 = ((wall.x1 as num).toDouble() / 50) - offsetX;
        final py1 = imageHeight - (((wall.y1 as num).toDouble() / 50) - offsetY);
        canvas.drawLine(Offset(px0, py0), Offset(px1, py1), virtualWallPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
