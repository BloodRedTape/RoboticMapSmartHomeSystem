import 'dart:async';
import 'dart:convert';

import 'package:dart_common/dart_common.dart';
import 'package:backend_dart/src/services/data_storage.dart';
import 'package:backend_dart/src/services/thing_manager.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:collection/collection.dart'; // For firstWhereOrNull

class DevicesController {
  final ThingManager _thingManager;

  DevicesController(this._thingManager);

  Router get router {
    final router = Router();

    router.get('/api/devices', _getDevices);
    router.get('/api/devices_full', _getDevicesFull);
    router.post('/api/devices', _createDevice);
    router.delete('/api/devices/<deviceId>', _deleteDevice);
    router.post('/api/devices/<deviceId>/hide', _hideDevice);
    router.post('/api/devices/<deviceId>/show', _showDevice);
    router.post('/api/devices/<deviceId>/customize', _customizeDevice);
    router.post('/api/devices/<deviceId>/command', _sendDeviceCommand);
    router.post('/api/ha/set_coordinates', _setHaCoordinates);

    return router;
  }

  Future<Response> _getDevices(Request request) async {
    final allDevices = _thingManager.getAllDevices();
    final visible = allDevices.where((d) => !d.hidden).toList();
    print("[API] Returning ${visible.length} visible devices (from ${allDevices.length} total)");
    return Response.ok(jsonEncode(visible.map((d) => d.toJson()).toList()), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _getDevicesFull(Request request) async {
    final allDevices = _thingManager.getAllDevices();
    print("[API] Returning ${allDevices.length} total devices");
    return Response.ok(jsonEncode(allDevices.map((d) => d.toJson()).toList()), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _createDevice(Request request) async {
    final payload = await request.readAsString();
    print("[API] Request to create virtual device: $payload");
    try {
      final Map<String, dynamic> json = jsonDecode(payload);
      final deviceData = Device.fromJson(json);
      final device = await _thingManager.addVirtualDevice(deviceData);
      return Response.ok(jsonEncode(device.toJson()), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print("Error creating device: $e");
      return Response.badRequest(body: jsonEncode({"detail": e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _deleteDevice(Request request, String deviceId) async {
    print("[API] Request to delete device: $deviceId");
    final success = await _thingManager.deleteVirtualDevice(deviceId);
    if (!success) {
      return Response.notFound(jsonEncode({"detail": "Device not found or not a virtual device"}), headers: {'Content-Type': 'application/json'});
    }
    return Response.ok(jsonEncode({"status": "success", "message": "Device deleted"}), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _hideDevice(Request request, String deviceId) async {
    print("[API] Request to hide device: $deviceId");
    await _thingManager.hideDevice(deviceId);
    return Response.ok(jsonEncode({"status": "success", "message": "Device hidden"}), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _showDevice(Request request, String deviceId) async {
    print("[API] Request to show device: $deviceId");
    await _thingManager.showDevice(deviceId);
    return Response.ok(jsonEncode({"status": "success", "message": "Device shown"}), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _customizeDevice(Request request, String deviceId) async {
    final payload = await request.readAsString();
    print("[API] Request to customize device: $deviceId");
    try {
      final Map<String, dynamic> json = jsonDecode(payload);
      final customization = DeviceCustomization.fromJson(json);
      await _thingManager.customizeDevice(deviceId, customization);
      return Response.ok(jsonEncode({"status": "success", "message": "Device customized"}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print("Error customizing device: $e");
      return Response.badRequest(body: jsonEncode({"detail": e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _sendDeviceCommand(Request request, String deviceId) async {
    final payload = await request.readAsString();
    print("[API] Received command for device $deviceId: $payload");
    try {
      final Map<String, dynamic> json = jsonDecode(payload);
      final commandData = Command.fromJson(json); // Use the polymorphic factory
      await _thingManager.sendCommand(commandData);
      return Response.ok(jsonEncode({"status": "success", "message": "Command sent"}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print("Error sending command: $e");
      return Response.badRequest(body: jsonEncode({"detail": e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _setHaCoordinates(Request request) async {
    final payload = await request.readAsString();
    print("[API] Request to set coordinates for HA device: $payload");
    try {
      final Map<String, dynamic> json = jsonDecode(payload);
      final coords = DeviceCoordinates.fromJson(json);

      final allThings = _thingManager.things;
      final deviceToUpdate = allThings.whereType<Device>().firstWhereOrNull((d) => d.id == coords.entityId);

      if (deviceToUpdate != null) {
        final locationAttr = deviceToUpdate.attributes.whereType<LocationAttribute>().firstWhereOrNull((attr) => true);
        if (locationAttr != null && locationAttr.locationType == LocationType.auto) {
          return Response.badRequest(
            body: jsonEncode({"error": "Cannot set coordinates for device with auto location", "entity_id": coords.entityId}),
            headers: {'Content-Type': 'application/json'},
          );
        }
      }

      await _thingManager.updateThingMetadata(coords.entityId, x: coords.x, y: coords.y);
      return Response.ok(jsonEncode({"status": "success", "entity_id": coords.entityId}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print("Error setting HA coordinates: $e");
      return Response.badRequest(body: jsonEncode({"detail": e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  }
}
