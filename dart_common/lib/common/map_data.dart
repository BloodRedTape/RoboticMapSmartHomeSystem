import 'primitive.dart';

class MapData {
  final MapPoint? charger;
  final VacuumPosition? vacuumPosition;
  Map<String, SegmentedRoom> rooms;
  List<BlockPoint> walls;
  List<VirtualWall> virtualWalls;
  final ImageDimensions? imageDimensions;
  final String mapName;

  MapData({
    this.charger,
    this.vacuumPosition,
    this.rooms = const {},
    this.walls = const [],
    this.virtualWalls = const [],
    this.imageDimensions,
    required this.mapName,
  });

  /// Converts world coordinates (mm) to block coordinates
  /// World coords are in mm, blocks are pixel-like units on the map
  /// Formula: blockX = (mapX / 50) - offsetX
  BlockPoint mapToBlockPoint(double mapX, double mapY) {
    final offsetX = imageDimensions?.left.toDouble() ?? 0.0;
    final offsetY = imageDimensions?.top.toDouble() ?? 0.0;
    final imageHeight = imageDimensions?.height.toDouble() ?? 0.0;

    final x = ((mapX / 50.0) - offsetX).toInt();
    final y = (imageHeight - ((mapY / 50.0) - offsetY)).toInt();
    return BlockPoint(x: x, y: y);
  }

  /// Converts block coordinates to world coordinates (mm)
  /// Inverse of mapToBlockPoint
  /// Formula: mapX = (blockX + offsetX) * 50
  MapPoint blockToMapPoint(int blockX, int blockY) {
    final offsetX = imageDimensions?.left.toDouble() ?? 0.0;
    final offsetY = imageDimensions?.top.toDouble() ?? 0.0;
    final imageHeight = imageDimensions?.height.toDouble() ?? 0.0;

    final x = ((blockX + offsetX) * 50).toDouble();
    final y = ((imageHeight - blockY + offsetY) * 50).toDouble();
    return MapPoint(x: x, y: y);
  }

  factory MapData.fromJson(Map<String, dynamic> json) {
    return MapData(
      charger: json['charger'] != null ? MapPoint.fromJson(json['charger']) : null,
      vacuumPosition: json['vacuum_position'] != null ? VacuumPosition.fromJson(json['vacuum_position']) : null,
      rooms: (json['rooms'] as Map<String, dynamic>?)?.map((key, value) => MapEntry(key, SegmentedRoom.fromJson(value))) ?? {},
      walls: (json['walls'] as List?)?.map((w) => BlockPoint.fromJson(w)).toList() ?? [],
      virtualWalls: (json['virtual_walls'] as List?)?.map((w) => VirtualWall.fromJson(w)).toList() ?? [],
      imageDimensions: json['image_dimensions'] != null ? ImageDimensions.fromJson(json['image_dimensions']) : null,
      mapName: json['map_name'] ?? 'Unknown Map',
    );
  }

  factory MapData.fromJsonOnDisk(Map<String, dynamic> json) {
    return MapData(
      charger: json['charger'] != null ? MapPoint.fromJson(json['charger']) : null,
      vacuumPosition: json['vacuum_position'] != null ? VacuumPosition.fromJson(json['vacuum_position']) : null,
      rooms: {},
      walls: (json['walls'] as List?)?.map((w) => BlockPoint.fromJson(w)).toList() ?? [],
      virtualWalls: (json['virtual_walls'] as List?)?.map((w) => VirtualWall.fromJson(w)).toList() ?? [],
      imageDimensions: json['image_dimensions'] != null ? ImageDimensions.fromJson(json['image_dimensions']) : null,
      mapName: json['map_name'] ?? 'Unknown Map',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'charger': charger?.toJson(),
      'vacuum_position': vacuumPosition?.toJson(),
      'rooms': rooms.map((key, value) => MapEntry(key, value.toJson())),
      'walls': walls.map((w) => w.toJson()).toList(),
      'virtual_walls': virtualWalls.map((w) => w.toJson()).toList(),
      'image_dimensions': imageDimensions?.toJson(),
      'map_name': mapName,
    };
  }
}

class VacuumPosition {
  final double x;
  final double y;
  final double? angle;

  VacuumPosition({required this.x, required this.y, this.angle});

  factory VacuumPosition.fromJson(Map<String, dynamic> json) {
    return VacuumPosition(x: (json['x'] as num).toDouble(), y: (json['y'] as num).toDouble(), angle: json['a'] != null ? (json['a'] as num).toDouble() : null);
  }

  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y, if (angle != null) 'a': angle};
  }
}

class VirtualWall {
  final double x0;
  final double y0;
  final double x1;
  final double y1;

  VirtualWall({required this.x0, required this.y0, required this.x1, required this.y1});

  factory VirtualWall.fromJson(Map<String, dynamic> json) {
    return VirtualWall(
      x0: (json['x0'] as num).toDouble(),
      y0: (json['y0'] as num).toDouble(),
      x1: (json['x1'] as num).toDouble(),
      y1: (json['y1'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'x0': x0, 'y0': y0, 'x1': x1, 'y1': y1};
  }
}

class Door {
  final int x0;
  final int y0;
  final int x1;
  final int y1;

  Door({required this.x0, required this.y0, required this.x1, required this.y1});

  factory Door.fromJson(Map<String, dynamic> json) {
    return Door(x0: (json['x0'] as num).toInt(), y0: (json['y0'] as num).toInt(), x1: (json['x1'] as num).toInt(), y1: (json['y1'] as num).toInt());
  }

  Map<String, int> toJson() {
    return {'x0': x0, 'y0': y0, 'x1': x1, 'y1': y1};
  }
}

class ImageDimensions {
  final int top;
  final int left;
  final int height;
  final int width;
  final double scale;
  final int rotation;

  ImageDimensions({required this.top, required this.left, required this.height, required this.width, required this.scale, required this.rotation});

  factory ImageDimensions.fromJson(Map<String, dynamic> json) {
    return ImageDimensions(
      top: json['top'] as int,
      left: json['left'] as int,
      height: json['height'] as int,
      width: json['width'] as int,
      scale: (json['scale'] as num).toDouble(),
      rotation: json['rotation'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'top': top, 'left': left, 'height': height, 'width': width, 'scale': scale, 'rotation': rotation};
  }
}

class RoomRectangle {
  final int x;
  final int y;
  final int width;
  final int height;

  RoomRectangle({required this.x, required this.y, required this.width, required this.height});

  factory RoomRectangle.fromJson(Map<String, dynamic> json) {
    return RoomRectangle(
      x: (json['x'] as num).toInt(),
      y: (json['y'] as num).toInt(),
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
    );
  }

  Map<String, int> toJson() {
    return {'x': x, 'y': y, 'width': width, 'height': height};
  }
}

class SegmentedRoom {
  final String guid;
  final int? id;
  final List<RoomRectangle> rectangles;
  final double x0;
  final double y0;
  final double x1;
  final double y1;
  final String name;

  SegmentedRoom({
    required this.guid,
    this.id,
    required this.rectangles,
    required this.x0,
    required this.y0,
    required this.x1,
    required this.y1,
    required this.name,
  });

  factory SegmentedRoom.fromJson(Map<String, dynamic> json) {
    return SegmentedRoom(
      guid: json['guid'] as String,
      id: json['id'] as int?,
      rectangles: (json['rectangles'] as List? ?? []).map((r) => RoomRectangle.fromJson(r)).toList(),
      x0: (json['bounds']['x0'] as num).toDouble(),
      y0: (json['bounds']['y0'] as num).toDouble(),
      x1: (json['bounds']['x1'] as num).toDouble(),
      y1: (json['bounds']['y1'] as num).toDouble(),
      name: (json['name'] as String?) ?? 'Unknown Room',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'guid': guid,
      if (id != null) 'id': id,
      'rectangles': rectangles.map((r) => r.toJson()).toList(),
      'bounds': {'x0': x0, 'y0': y0, 'x1': x1, 'y1': y1},
      'name': name,
    };
  }
}
