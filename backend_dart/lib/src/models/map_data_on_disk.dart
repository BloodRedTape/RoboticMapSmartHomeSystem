import 'package:dart_common/common/map_data.dart';
import 'package:dart_common/common/primitive.dart';

class MapDataOnDisk {
  final MapPoint? charger;
  final VacuumPosition? vacuumPosition;
  List<BlockPoint> walls;
  List<VirtualWall> virtualWalls;
  final ImageDimensions? imageDimensions;
  final String mapName;

  MapDataOnDisk({this.charger, this.vacuumPosition, this.walls = const [], this.virtualWalls = const [], this.imageDimensions, required this.mapName});

  factory MapDataOnDisk.fromJson(Map<String, dynamic> json) {
    return MapDataOnDisk(
      charger: json['charger'] != null ? MapPoint.fromJson(json['charger']) : null,
      vacuumPosition: json['vacuum_position'] != null ? VacuumPosition.fromJson(json['vacuum_position']) : null,
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
      'walls': walls.map((w) => w.toJson()).toList(),
      'virtual_walls': virtualWalls.map((w) => w.toJson()).toList(),
      'image_dimensions': imageDimensions?.toJson(),
      'map_name': mapName,
    };
  }
}
