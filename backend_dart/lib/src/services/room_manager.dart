import 'dart:convert';
import 'dart:math';
import 'package:backend_dart/src/models/room_metadata.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_common/common/map_data.dart';
import 'data_storage.dart';
import 'room_segmentation.dart';

class RoomManager {
  final DataStorage _storage;
  final RoomSegmentation _roomSegmentation;

  int _offsetX = 0;
  int _offsetY = 0;

  List<SegmentedRoom>? _cachedRooms;

  RoomManager(this._storage, this._roomSegmentation) {
    _loadMapDimensions();
  }

  void _loadMapDimensions() {
    try {
      if (_storage.mapData.imageDimensions != null) {
        _offsetX = _storage.mapData.imageDimensions!.left;
        _offsetY = _storage.mapData.imageDimensions!.top;
      }
    } catch (e) {
      print("[RoomManager] Error loading map dimensions: $e");
      _offsetX = 0;
      _offsetY = 0;
    }
  }

  String _generateGuid(List<RoomRectangle> roomRectangles) {
    final sortedRects = List<RoomRectangle>.from(roomRectangles)..sort((a, b) {
      final xComparison = a.x.compareTo(b.x);
      if (xComparison != 0) return xComparison;
      return a.y.compareTo(b.y);
    });

    final serializedRects = jsonEncode(sortedRects.map((r) => r.toJson()).toList());
    final bytes = utf8.encode(serializedRects);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  void invalidateCache() {
    _cachedRooms = null;
  }

  List<SegmentedRoom> _segmentRooms() {
    if (_cachedRooms != null) {
      return _cachedRooms!;
    }

    if (_storage.mapData.imageDimensions == null) {
      print("[RoomManager] Cannot segment rooms: MapData or ImageDimensions are missing.");
      return [];
    }

    var walls = _storage.loadMapBlocks();
    if (walls.isEmpty) {
      walls = _storage.mapData.walls;
    }

    var width = _storage.mapData.imageDimensions!.width.toInt();
    var height = _storage.mapData.imageDimensions!.height.toInt();

    var userDoors = _storage.loadDoors();

    final List<Map<String, int>> wallsAsDicts = walls.map((block) => {'x': block.x, 'y': block.y}).toList();

    var roomBlocksList = _roomSegmentation.segmentRooms(wallsAsDicts, width, height, userDoors);

    var rooms = <SegmentedRoom>[];
    for (int i = 0; i < roomBlocksList.length; i++) {
      var roomBlocks = roomBlocksList[i];
      var bounds = _roomSegmentation.calculateRoomBounds(roomBlocks);
      var rectanglesAsMaps = _roomSegmentation.blocksToRectangles(roomBlocks);
      var rectangles = rectanglesAsMaps.map((r) => RoomRectangle(x: r["x"]!, y: r["y"]!, width: r["width"]!, height: r["height"]!)).toList();
      var guid = _generateGuid(rectangles);

      RoomMetadata? metadata = _storage.roomMetadata[guid];
      String name = "Room ${i + 1}";
      if (metadata != null) {
        name = metadata.name;
      }

      rooms.add(
        SegmentedRoom(guid: guid, id: i + 1, rectangles: rectangles, x0: bounds["x0"]!, y0: bounds["y0"]!, x1: bounds["x1"]!, y1: bounds["y1"]!, name: name),
      );
    }

    _cachedRooms = rooms;
    return rooms;
  }

  List<SegmentedRoom> getRawRooms() {
    return _segmentRooms();
  }

  SegmentedRoom? renameRoom(String guid, String newName) {
    var rooms = getRawRooms();
    var room = rooms.where((r) => r.guid == guid).firstOrNull;
    if (room == null) return null;

    RoomMetadata? metadata = _storage.roomMetadata[guid];
    if (metadata != null) {
      metadata.name = newName;
    } else {
      metadata = RoomMetadata(guid: guid, name: newName);
      _storage.roomMetadata[guid] = metadata;
    }

    _storage.saveRoomMetadata();
    return SegmentedRoom(guid: room.guid, id: room.id, rectangles: room.rectangles, x0: room.x0, y0: room.y0, x1: room.x1, y1: room.y1, name: newName);
  }

  String? getRoomIdByCoordinates(double x, double y) {
    var rooms = _segmentRooms();

    double xBlock = (x / 50.0) - _offsetX;
    double yBlock = (y / 50.0) - _offsetY;

    for (var room in rooms) {
      for (var rect in room.rectangles) {
        var x0 = rect.x;
        var y0 = rect.y;
        var w = rect.width;
        var h = rect.height;
        if (x0 <= xBlock && xBlock < x0 + w && y0 <= yBlock && yBlock < y0 + h) {
          return room.guid;
        }
      }
    }

    if (rooms.isEmpty) return null;

    SegmentedRoom? nearestRoom;
    double minDistance = double.infinity;

    for (var room in rooms) {
      double centerX = (room.x0 + room.x1) / 2;
      double centerY = (room.y0 + room.y1) / 2;
      double distance = sqrt(pow(xBlock - centerX, 2) + pow(yBlock - centerY, 2));
      if (distance < minDistance) {
        minDistance = distance;
        nearestRoom = room;
      }
    }
    return nearestRoom?.guid;
  }
}
