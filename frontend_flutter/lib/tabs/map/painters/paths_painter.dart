import 'package:flutter/material.dart';
import '../../../cubits/display_settings_cubit.dart';
import 'package:dart_common/dart_common.dart';

class PathsPainter extends CustomPainter {
  final MapData mapData;
  final double imageWidth;
  final double imageHeight;
  final List<Device> deviceList;
  final DisplaySettings displaySettings;

  PathsPainter({required this.mapData, required this.imageWidth, required this.imageHeight, required this.deviceList, required this.displaySettings});

  @override
  void paint(Canvas canvas, Size size) {
    final dims = mapData.imageDimensions;
    final offsetX = dims != null ? dims.left.toDouble() : 0.0;
    final offsetY = dims != null ? dims.top.toDouble() : 0.0;

    if (displaySettings.showDevicePaths) {
      for (var device in deviceList) {
        if (device.hasPaths) {
          final paths = device.paths!;
          for (var path in paths) {
            if (path.length < 2) continue;

            final pathPaint =
                Paint()
                  ..color = Colors.blue.withOpacity(0.6)
                  ..strokeWidth = 1
                  ..style = PaintingStyle.stroke
                  ..strokeCap = StrokeCap.round
                  ..strokeJoin = StrokeJoin.round;

            final pathPoints =
                path.map((point) {
                  final x = (point.x / 50.0) - offsetX;
                  final y = imageHeight - ((point.y / 50.0) - offsetY);
                  return Offset(x, y);
                }).toList();

            if (pathPoints.length == 2) {
              canvas.drawLine(pathPoints[0], pathPoints[1], pathPaint);
            } else {
              final pathToDraw = Path();
              pathToDraw.moveTo(pathPoints[0].dx, pathPoints[0].dy);
              for (int i = 1; i < pathPoints.length; i++) {
                pathToDraw.lineTo(pathPoints[i].dx, pathPoints[i].dy);
              }
              canvas.drawPath(pathToDraw, pathPaint);
            }
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
