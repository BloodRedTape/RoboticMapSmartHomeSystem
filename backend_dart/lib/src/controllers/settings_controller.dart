import 'dart:async';
import 'dart:convert';

import 'package:backend_dart/src/models/settings.dart';
import 'package:backend_dart/src/services/data_storage.dart';
import 'package:backend_dart/src/services/thing_manager.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class SettingsController {
  final DataStorage _storage;
  final ThingManager _thingManager;
  // final WebsocketManager _websocketManager; // Commented out in C#
  SettingsController(this._storage, this._thingManager);

  Router get router {
    final router = Router();

    router.get('/api/settings', _getSettings);
    router.post('/api/settings', _updateSettings);
    router.delete('/api/history', _deleteHistory);
    router.get('/api/export', _exportData);

    return router;
  }

  Future<Response> _getSettings(Request request) async {
    return Response.ok(jsonEncode(_storage.settingsData.toJson()), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _updateSettings(Request request) async {
    final payload = await request.readAsString();
    final Map<String, dynamic> json = jsonDecode(payload);
    _storage.settingsData = Settings.fromJson(json);
    _storage.saveSettings();
    return Response.ok(jsonEncode(_storage.settingsData.toJson()), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _deleteHistory(Request request) async {
    _storage.eventList.clear();
    _storage.saveEvents();
    // In C# this was commented out: await _websocketManager.BroadcastPresence(_storage.PresenceList);
    // So for now, I won't implement websocket broadcast for this.
    return Response.ok(jsonEncode({"status": "success", "message": "Historical data deleted"}), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _exportData(Request request) async {
    final allDevices = _thingManager.getAllDevices();
    final allEvents = _storage.eventList;
    final currentSettings = _storage.settingsData;

    final exportData = {
      "devices": allDevices.map((d) => d.toJson()).toList(),
      "events": allEvents.map((e) => e.toJson()).toList(),
      "settings": currentSettings.toJson(),
      "export_time": DateTime.now().toIso8601String(), // "o" format in C# is ISO 8601
    };

    return Response.ok(jsonEncode(exportData), headers: {'Content-Type': 'application/json'});
  }
}
