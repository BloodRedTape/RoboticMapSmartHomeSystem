import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:dart_common/dart_common.dart';

import '../services/automation_manager.dart';

class AutomationController {
  final AutomationManager _automationManager;

  AutomationController(this._automationManager);

  Router get router {
    final router = Router();

    router.get('/automations', (Request request) {
      final automations = _automationManager.getAutomations();
      return Response.ok(jsonEncode(automations.map((a) => a.toJson()).toList()));
    });

    router.post('/automations', (Request request) async {
      final requestBody = await request.readAsString();
      final info = AutomationInfo.fromJson(jsonDecode(requestBody));
      final newAutomation = _automationManager.createAutomation(info);
      return Response.ok(jsonEncode(newAutomation.toJson()));
    });

    router.put('/automations/<guid>', (Request request, String guid) async {
      final requestBody = await request.readAsString();
      final info = AutomationInfo.fromJson(jsonDecode(requestBody));
      final updatedAutomation = _automationManager.updateAutomation(guid, info);
      if (updatedAutomation != null) {
        return Response.ok(jsonEncode(updatedAutomation.toJson()));
      } else {
        return Response.notFound('Automation with GUID $guid not found');
      }
    });

    router.delete('/automations/<guid>', (Request request, String guid) {
      _automationManager.deleteAutomation(guid);
      return Response.ok('Automation with GUID $guid deleted');
    });

    return router;
  }
}
