import 'package:flutter/material.dart';

class CameraCalibrationFakeScreen extends StatelessWidget {
  const CameraCalibrationFakeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Калібрування камери'),
        backgroundColor: Colors.indigo.shade700,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.indigo.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.videocam, color: Colors.indigo.shade700, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Камера вітальні',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Виберіть 4 опорні точки',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Text(
                        '2 / 4',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Виберіть відповідні точки на підлозі у превью камери та на карті приміщення',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.grey.shade800,
                        child: const Row(
                          children: [
                            Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Превью камери',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          color: Colors.grey.shade900,
                          child: Stack(
                            children: [
                              Center(
                                child: Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.grey.shade700,
                                        Colors.grey.shade800,
                                      ],
                                    ),
                                  ),
                                  child: CustomPaint(
                                    painter: CameraViewPainter(),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 60,
                                top: 80,
                                child: _buildCalibrationPoint(1, Colors.red, true),
                              ),
                              Positioned(
                                right: 80,
                                top: 90,
                                child: _buildCalibrationPoint(2, Colors.blue, true),
                              ),
                              Positioned(
                                left: 100,
                                bottom: 120,
                                child: _buildCalibrationPoint(3, Colors.green, false),
                              ),
                              Positioned(
                                right: 120,
                                bottom: 130,
                                child: _buildCalibrationPoint(4, Colors.orange, false),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.indigo.shade700,
                        child: const Row(
                          children: [
                            Icon(Icons.map, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Карта приміщення',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          color: Colors.grey.shade200,
                          child: Stack(
                            children: [
                              Center(
                                child: Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  child: CustomPaint(
                                    painter: MapViewPainter(),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 80,
                                top: 100,
                                child: _buildCalibrationPoint(1, Colors.red, true),
                              ),
                              Positioned(
                                right: 100,
                                top: 110,
                                child: _buildCalibrationPoint(2, Colors.blue, true),
                              ),
                              Positioned(
                                left: 120,
                                bottom: 140,
                                child: _buildCalibrationPoint(3, Colors.green, false),
                              ),
                              Positioned(
                                right: 140,
                                bottom: 150,
                                child: _buildCalibrationPoint(4, Colors.orange, false),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Скасувати',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.orange.shade700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Скинути',
                          style: TextStyle(fontSize: 16, color: Colors.orange.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.indigo.shade700,
                      disabledBackgroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Обчислити гомографію',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationPoint(int number, Color color, bool isSelected) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isSelected ? color : Colors.grey.shade400,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          number.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

class CameraViewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    paint.color = Colors.grey.shade600;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.6, size.width * 0.3, size.height * 0.35),
      paint,
    );

    paint.color = Colors.grey.shade500;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.65, size.height * 0.55, size.width * 0.25, size.height * 0.4),
      paint,
    );

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 1.5;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), linePaint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MapViewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wallPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.fill;

    final floorPaint = Paint()
      ..color = Colors.grey.shade100
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), floorPaint);

    canvas.drawRect(Rect.fromLTWH(size.width * 0.05, size.height * 0.05, size.width * 0.9, 20), wallPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.05, size.height * 0.05, 20, size.height * 0.9), wallPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.95 - 20, size.height * 0.05, 20, size.height * 0.9), wallPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.05, size.height * 0.95 - 20, size.width * 0.9, 20), wallPaint);

    final roomPaint = Paint()
      ..color = Colors.blue.shade100.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.1, size.width * 0.35, size.height * 0.8),
      roomPaint,
    );

    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.55, size.height * 0.1, size.width * 0.35, size.height * 0.8),
      roomPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
