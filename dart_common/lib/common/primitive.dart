class BlockPoint {
  final int x;
  final int y;

  BlockPoint({required this.x, required this.y});

  factory BlockPoint.fromJson(Map<String, dynamic> json) {
    return BlockPoint(x: (json['x'] as num).toInt(), y: (json['y'] as num).toInt());
  }

  Map<String, int> toJson() {
    return {'x': x, 'y': y};
  }
}

class MapPoint {
  final double x;
  final double y;

  MapPoint({required this.x, required this.y});

  factory MapPoint.fromJson(Map<String, dynamic> json) {
    return MapPoint(x: (json['x'] as num).toDouble(), y: (json['y'] as num).toDouble());
  }

  Map<String, double> toJson() {
    return {'x': x, 'y': y};
  }
}
