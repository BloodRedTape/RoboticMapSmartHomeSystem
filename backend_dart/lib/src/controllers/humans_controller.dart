import 'dart:async';
import 'dart:convert';

import 'package:dart_common/dart_common.dart';
import 'package:backend_dart/src/services/thing_manager.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class HumansController {
  final ThingManager _thingManager;

  HumansController(this._thingManager);

  Router get router {
    final router = Router();

    router.get('/api/humans', _getHumans);
    router.post('/api/humans', _createHuman);
    router.delete('/api/humans/<humanId>', _deleteHuman);
    router.put('/api/humans/<humanId>/move', _moveHuman);

    return router;
  }

  Future<Response> _getHumans(Request request) async {
    final allHumans = _thingManager.getAllHumans();
    return Response.ok(jsonEncode(allHumans.map((h) => h.toJson()).toList()), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _createHuman(Request request) async {
    print("[API] Request to create human");
    try {
      final human = await _thingManager.createHuman();
      return Response.ok(jsonEncode(human.toJson()), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print("Error creating human: $e");
      return Response.badRequest(body: jsonEncode({"detail": e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _deleteHuman(Request request, String humanId) async {
    print("[API] Request to delete human: $humanId");
    final success = await _thingManager.deleteHuman(humanId);
    if (!success) {
      return Response.notFound(jsonEncode({"detail": "Human not found"}), headers: {'Content-Type': 'application/json'});
    }
    return Response.ok(jsonEncode({"status": "success", "message": "Human deleted"}), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _moveHuman(Request request, String humanId) async {
    final payload = await request.readAsString();
    print("[API] Request to move human $humanId: $payload");
    try {
      final Map<String, dynamic> json = jsonDecode(payload);
      final coords = MoveCoordinates.fromJson(json);
      final success = await _thingManager.moveHuman(humanId, coords.x, coords.y);
      if (!success) {
        return Response.notFound(jsonEncode({"detail": "Human not found"}), headers: {'Content-Type': 'application/json'});
      }
      return Response.ok(jsonEncode({"status": "success", "message": "Human moved"}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print("Error moving human: $e");
      return Response.badRequest(body: jsonEncode({"detail": e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  }
}
