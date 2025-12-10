import 'dart:async';
import 'dart:convert';

import 'package:dart_common/dart_common.dart';
import 'package:backend_dart/src/services/data_storage.dart';
import 'package:backend_dart/src/services/room_manager.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class MapController {
  final DataStorage _storage;
  final RoomManager _roomManager;

  MapController(this._storage, this._roomManager);

  Router get router {
    final router = Router();

    router.get('/api/map', _getMap);
    router.post('/api/map/rooms/<roomGuid>/rename', _renameRoom);
    router.get('/api/map/blocks', _getMapBlocks);
    router.post('/api/map/blocks', _updateMapBlocks);
    router.get('/api/map/doors', _getDoors);
    router.post('/api/map/doors', _updateDoors);

    return router;
  }

  Future<Response> _getMap(Request request) async {
    try {
      final mapDataOnDisk = _storage.mapData;
      final rooms = _roomManager.getRawRooms();
      final roomsMap = {for (var room in rooms) room.guid: room};

      final result = MapData(
        charger: mapDataOnDisk.charger,
        vacuumPosition: mapDataOnDisk.vacuumPosition,
        rooms: roomsMap,
        walls: _storage.loadMapBlocks(),
        virtualWalls: mapDataOnDisk.virtualWalls,
        imageDimensions: mapDataOnDisk.imageDimensions,
        mapName: mapDataOnDisk.mapName,
      );

      return Response.ok(jsonEncode(result.toJson()), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print("Error getting map: $e");
      return Response.internalServerError(body: jsonEncode({"error": e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _renameRoom(Request request, String roomGuid) async {
    try {
      final payload = await request.readAsString();
      final Map<String, dynamic> json = jsonDecode(payload);
      final renameRequest = RenameRoomRequest.fromJson(json);

      final updatedRoom = _roomManager.renameRoom(roomGuid, renameRequest.name);
      if (updatedRoom == null) {
        return Response.notFound(jsonEncode({"detail": "Room not found"}), headers: {'Content-Type': 'application/json'});
      }

      final eventData = EventData(
        id: "evt_${DateTime.now().toUtc().millisecondsSinceEpoch}",
        type: "room_renamed",
        timestamp: DateTime.now().toIso8601String(),
        data: {"room_guid": roomGuid, "new_name": renameRequest.name},
      );
      _storage.eventList.add(eventData);
      _storage.saveEvents();

      return Response.ok(jsonEncode({"status": "success", "room": updatedRoom.toJson()}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print("Error renaming room $roomGuid: $e");
      return Response.internalServerError(body: jsonEncode({"error": e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _getMapBlocks(Request request) async {
    try {
      final blocks = _storage.loadMapBlocks();
      return Response.ok(jsonEncode({"blocks": blocks.map((b) => b.toJson()).toList()}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print("Error getting map blocks: $e");
      return Response.internalServerError(body: jsonEncode({"error": e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _updateMapBlocks(Request request) async {
    try {
      final payload = await request.readAsString();
      final List<dynamic> json = jsonDecode(payload);
      final blocksData = json.map((e) => BlockPoint.fromJson(e as Map<String, dynamic>)).toList();
      _storage.saveMapBlocks(blocksData);
      _roomManager.invalidateCache();

      final eventData = EventData(
        id: "evt_${DateTime.now().toUtc().millisecondsSinceEpoch}",
        type: "map_blocks_updated",
        timestamp: DateTime.now().toIso8601String(),
        data: {"blocks_count": blocksData.length},
      );
      _storage.eventList.add(eventData);
      _storage.saveEvents();

      return Response.ok(jsonEncode({"status": "success", "blocks_count": blocksData.length}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print("Error updating map blocks: $e");
      return Response.internalServerError(body: jsonEncode({"error": e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _getDoors(Request request) async {
    try {
      final doors = _storage.loadDoors();
      return Response.ok(jsonEncode({"doors": doors.map((d) => d.toJson()).toList()}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print("Error getting doors: $e");
      return Response.internalServerError(body: jsonEncode({"error": e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _updateDoors(Request request) async {
    try {
      final payload = await request.readAsString();
      final Map<String, dynamic> json = jsonDecode(payload);
      final doorsList = (json['doors'] as List).map((d) => Door.fromJson(d as Map<String, dynamic>)).toList();
      _storage.saveDoors(doorsList);
      _roomManager.invalidateCache();

      final eventData = EventData(
        id: "evt_${DateTime.now().toUtc().millisecondsSinceEpoch}",
        type: "doors_updated",
        timestamp: DateTime.now().toIso8601String(),
        data: {"doors_count": doorsList.length},
      );
      _storage.eventList.add(eventData);
      _storage.saveEvents();

      return Response.ok(jsonEncode({"status": "success", "doors_count": doorsList.length}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print("Error updating doors: $e");
      return Response.internalServerError(body: jsonEncode({"error": e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  }
}

class RenameRoomRequest {
  String name;

  RenameRoomRequest({required this.name});

  factory RenameRoomRequest.fromJson(Map<String, dynamic> json) {
    return RenameRoomRequest(name: json['name'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}
