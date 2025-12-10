import 'dart:async';
import 'dart:convert';
import 'package:backend_dart/src/services/thing_manager.dart';
import 'package:dart_common/common/device.dart';
import 'package:dart_common/common/human.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';
import 'data_storage.dart'; // For Logger

class WebsocketManager {
  final Map<String, WebSocketChannel> _activeConnections = {};
  final Uuid _uuid = Uuid();

  void Function(String, double, double)? onMoveHuman;

  Future<void> addConnection(WebSocketChannel websocket) async {
    final connectionId = _uuid.v4();
    _activeConnections[connectionId] = websocket;
    print("WebSocket connection added: $connectionId. Total connections: ${_activeConnections.length}");

    try {
      await for (var message in websocket.stream) {
        onMessage(message);
      }
    } catch (e) {
      print("Error in WebSocket connection $connectionId: $e");
    } finally {
      removeConnection(connectionId);
    }
  }

  void onMessage(dynamic message) {
    try {
      Map<String, dynamic> payload = jsonDecode(message);

      if (payload['type'] == 'move_human') {
        onMoveHuman?.call(payload['data']['human_id'], payload['data']['x'], payload['data']['y']);
      }
    } catch (e) {
      print("WS: Unknown message[$e]: $message");
    }
  }

  void removeConnection(String connectionId) {
    if (_activeConnections.containsKey(connectionId)) {
      _activeConnections.remove(connectionId)?.sink.close();
      print("WebSocket connection removed: $connectionId. Total connections: ${_activeConnections.length}");
    }
  }

  Future<void> broadcastJson(dynamic message) async {
    if (_activeConnections.isEmpty) {
      return;
    }

    final jsonMessage = jsonEncode(message);
    final connectionsToRemove = <String>[];

    for (var entry in _activeConnections.entries) {
      final connectionId = entry.key;
      final websocket = entry.value;

      if (websocket.closeCode == null) {
        // Check if the connection is still open
        try {
          websocket.sink.add(jsonMessage);
        } catch (e) {
          print("Failed to send message to WebSocket $connectionId. Marking for removal: $e");
          connectionsToRemove.add(connectionId);
        }
      } else {
        print("WebSocket $connectionId is not open (${websocket.closeCode}). Marking for removal.");
        connectionsToRemove.add(connectionId);
      }
    }

    for (var connectionId in connectionsToRemove) {
      removeConnection(connectionId);
    }
  }

  Future<void> broadcastDevices(List<Device> devices) async {
    final message = {"type": "device_update", "data": devices.map((d) => d.toJson()).toList()};
    await broadcastJson(message);
  }

  Future<void> broadcastHumans(List<Human> humans) async {
    final message = {"type": "human_update", "data": humans.map((h) => h.toJson()).toList()};
    await broadcastJson(message);
  }
}
