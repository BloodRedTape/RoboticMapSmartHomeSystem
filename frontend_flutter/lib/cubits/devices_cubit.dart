import 'dart:convert';
import 'package:dart_common/dart_common.dart';
import 'package:frontend_flutter/services/websocket_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';

class DevicesCubit extends Cubit<List<Device>> {
  static const String baseUrl = 'http://localhost:5000/api';
  List<Device> _allDevices = [];
  WebSocketService ws;

  DevicesCubit(this.ws) : super([]) {
    ws.deviceStream.listen(_updateDevices);
  }

  List<Device> get allDevices => _allDevices;
  List<Device> get visibleDevices => state;

  void _updateDevices(List<Device> devices) {
    _allDevices = devices;
    final visibleDevices = _allDevices.where((d) => !d.hidden).toList();
    emit(visibleDevices);
    print('DeviceCubit: device update');
  }

  Future<void> refresh() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/devices'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final devices = data.map((d) => Device.fromJson(d)).toList();
        emit(devices);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading devices: $e');
    }
  }

  Device? findDeviceOfAttribute(Attribute attribute) {
    for (final device in state) {
      for (final attr in device.attributes) {
        if (attr.guid == attribute.guid) return device;
      }
    }
    return null;
  }

  String attributeName(Attribute attribute) {
    Device? device = findDeviceOfAttribute(attribute);
    if (device == null) return 'Unknown';
    return '${device.name} | ${attribute.type}';
  }

  List<Attribute> attributes() {
    final result = <Attribute>[];
    for (final device in state) {
      result.addAll(device.attributes);
    }
    return result;
  }

  Future<void> refreshAll() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/devices_full'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _updateDevices(data.map((d) => Device.fromJson(d)).toList());
      } else {
        print('failed refresh all');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading all devices: $e');
    }
  }

  Future<void> sendCommand(String deviceId, String command, dynamic value) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/devices/$deviceId/command'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'command': command, 'value': value}),
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error sending command: $e');
      rethrow;
    }
  }

  Future<void> hideDevice(String deviceId) async {
    try {
      await http.post(Uri.parse('$baseUrl/devices/$deviceId/hide'), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      // ignore: avoid_print
      print('Error hiding device: $e');
      rethrow;
    }
  }

  Future<void> showDevice(String deviceId) async {
    try {
      await http.post(Uri.parse('$baseUrl/devices/$deviceId/show'), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      // ignore: avoid_print
      print('Error showing device: $e');
      rethrow;
    }
  }

  Future<void> toggleDeviceVisibility(String deviceId) async {
    final device = _allDevices.firstWhere((d) => d.id == deviceId);
    if (device.hidden) {
      await showDevice(deviceId);
    } else {
      await hideDevice(deviceId);
    }
  }

  Future<void> customizeDevice(String deviceId, {String? name, String? icon, String? color, String? integration}) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (icon != null) body['icon'] = icon;
      if (color != null) body['color'] = color;
      if (integration != null) body['integration'] = integration;

      await http.post(Uri.parse('$baseUrl/devices/$deviceId/customize'), headers: {'Content-Type': 'application/json'}, body: json.encode(body));
    } catch (e) {
      // ignore: avoid_print
      print('Error customizing device: $e');
      rethrow;
    }
  }

  Future<void> setDeviceCoordinates(String deviceId, double x, double y) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/ha/set_coordinates'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'entity_id': deviceId, 'x': x, 'y': y}),
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error setting coordinates: $e');
      rethrow;
    }
  }

  Future<Device> createVirtualDevice(String name, double x, double y, {String? icon, String? color}) async {
    try {
      final deviceData = {
        'name': name,
        'integration': 'virtual',
        'is_online': true,
        'hidden': false,
        'icon': icon ?? 'place',
        'color': color ?? '#2196F3',
        'attributes': {
          'location': {'x': x, 'y': y, 'room_id': null},
        },
      };

      final response = await http.post(Uri.parse('$baseUrl/devices'), headers: {'Content-Type': 'application/json'}, body: json.encode(deviceData));

      if (response.statusCode == 200) {
        final deviceJson = json.decode(response.body);
        final device = Device.fromJson(deviceJson);
        return device;
      } else {
        throw Exception('Failed to create device: ${response.statusCode}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error creating virtual device: $e');
      rethrow;
    }
  }

  Future<void> deleteDevice(String deviceId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/devices/$deviceId'));

      if (response.statusCode == 200) {
      } else {
        throw Exception('Failed to delete device: ${response.statusCode}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting device: $e');
      rethrow;
    }
  }

  Future<void> sendDeviceCommand(Command command) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/devices/${command.guid}/command'),
        headers: {'Content-Type': 'application/json'},
        body: command.toJsonString(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send command: ${response.statusCode}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error sending device command: $e');
      rethrow;
    }
  }

  // Internal method for WebSocket updates - should only be called from MainScreen
  void updateFromWebSocket(List<Device> devices) {
    _allDevices = devices;
    final visibleDevices = devices.where((d) => !d.hidden).toList();
    emit(visibleDevices);
  }
}
