import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dart_common/dart_common.dart';
import 'package:http/http.dart' as http;

class CalibrationEditMode extends StatefulWidget {
  final MapData mapData;
  final double iconScale;

  const CalibrationEditMode({
    super.key,
    required this.mapData,
    required this.iconScale,
  });

  @override
  State<CalibrationEditMode> createState() => _CalibrationEditModeState();
}

class _CalibrationEditModeState extends State<CalibrationEditMode> {
  String? cameraFrameBase64;
  bool isLoadingFrame = false;
  List<Offset> cameraPoints = [];
  List<Offset> mapPoints = [];
  bool isSelectingOnCamera = true;

  @override
  void initState() {
    super.initState();
    _loadFirstFrame();
  }

  Future<void> _loadFirstFrame() async {
    setState(() => isLoadingFrame = true);
    try {
      final response = await http.get(Uri.parse('http://localhost:5001/api/first_frame'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          cameraFrameBase64 = data['frame_base64'];
          isLoadingFrame = false;
        });
      } else {
        setState(() => isLoadingFrame = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load camera frame')),
          );
        }
      }
    } catch (e) {
      setState(() => isLoadingFrame = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _calibrate() async {
    if (cameraPoints.length < 4 || mapPoints.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 4 points on each side')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5001/api/calibrate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'camera_points': cameraPoints.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
          'map_points': mapPoints.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Calibration successful!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Calibration failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _handleCameraTap(Offset position, Size size) {
    setState(() {
      cameraPoints.add(position);
      if (cameraPoints.length == mapPoints.length + 1) {
        isSelectingOnCamera = false;
      }
    });
  }

  void _handleMapTap(Offset position) {
    if (cameraPoints.length > mapPoints.length) {
      setState(() {
        mapPoints.add(position);
        if (mapPoints.length < cameraPoints.length) {
          isSelectingOnCamera = false;
        } else {
          isSelectingOnCamera = true;
        }
      });
    }
  }

  void _clearPoints() {
    setState(() {
      cameraPoints.clear();
      mapPoints.clear();
      isSelectingOnCamera = true;
    });
  }

  Widget _buildCameraView() {
    if (isLoadingFrame) {
      return const Center(child: CircularProgressIndicator());
    }

    if (cameraFrameBase64 == null) {
      return const Center(child: Text('No camera frame available'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapUp: (details) {
            if (isSelectingOnCamera) {
              _handleCameraTap(details.localPosition, constraints.biggest);
            }
          },
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                Image.memory(
                  base64Decode(cameraFrameBase64!),
                  fit: BoxFit.contain,
                ),
                CustomPaint(
                  size: constraints.biggest,
                  painter: _PointsPainter(cameraPoints, isSelectingOnCamera),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    final mapWidth = widget.mapData.imageDimensions?.width.toDouble() ?? 1000.0;
    final mapHeight = widget.mapData.imageDimensions?.height.toDouble() ?? 1000.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / mapWidth).clamp(0.1, 10.0);

        return GestureDetector(
          onTapUp: (details) {
            if (!isSelectingOnCamera) {
              final x = details.localPosition.dx / scale;
              final y = details.localPosition.dy / scale;
              _handleMapTap(Offset(x, y));
            }
          },
          child: Container(
            color: Colors.grey[900],
            child: Stack(
              children: [
                Transform.scale(
                  scale: scale,
                  alignment: Alignment.topLeft,
                  child: CustomPaint(
                    size: Size(mapWidth, mapHeight),
                    painter: _MapBackgroundPainter(widget.mapData),
                  ),
                ),
                CustomPaint(
                  size: constraints.biggest,
                  painter: _MapPointsPainter(mapPoints, !isSelectingOnCamera, scale),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: isSelectingOnCamera ? Colors.blue : Colors.grey,
                      child: Text(
                        'Camera View - ${cameraPoints.length} points',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Expanded(child: _buildCameraView()),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: !isSelectingOnCamera ? Colors.blue : Colors.grey,
                      child: Text(
                        'Map View - ${mapPoints.length} points',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Expanded(child: _buildMapView()),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black87,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _clearPoints,
                icon: const Icon(Icons.clear),
                label: const Text('Clear Points'),
              ),
              ElevatedButton.icon(
                onPressed: cameraPoints.length >= 4 && mapPoints.length >= 4 ? _calibrate : null,
                icon: const Icon(Icons.check),
                label: Text('Calibrate (${cameraPoints.length}/${mapPoints.length})'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PointsPainter extends CustomPainter {
  final List<Offset> points;
  final bool isActive;

  _PointsPainter(this.points, this.isActive);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isActive ? Colors.red : Colors.grey
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 8, paint);

      textPainter.text = TextSpan(
        text: '${i + 1}',
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, points[i] + const Offset(-4, -18));
    }
  }

  @override
  bool shouldRepaint(_PointsPainter oldDelegate) => true;
}

class _MapBackgroundPainter extends CustomPainter {
  final MapData mapData;

  _MapBackgroundPainter(this.mapData);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final wallPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    for (final wall in mapData.walls) {
      canvas.drawRect(
        Rect.fromLTWH(wall.x.toDouble(), wall.y.toDouble(), 1, 1),
        wallPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_MapBackgroundPainter oldDelegate) => false;
}

class _MapPointsPainter extends CustomPainter {
  final List<Offset> points;
  final bool isActive;
  final double scale;

  _MapPointsPainter(this.points, this.isActive, this.scale);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isActive ? Colors.green : Colors.grey
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < points.length; i++) {
      final scaledPoint = Offset(points[i].dx * scale, points[i].dy * scale);
      canvas.drawCircle(scaledPoint, 8, paint);

      textPainter.text = TextSpan(
        text: '${i + 1}',
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, scaledPoint + const Offset(-4, -18));
    }
  }

  @override
  bool shouldRepaint(_MapPointsPainter oldDelegate) => true;
}
