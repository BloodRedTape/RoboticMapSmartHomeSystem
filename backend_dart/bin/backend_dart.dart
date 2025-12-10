import 'dart:io';
import 'package:backend_dart/src/services/automation_manager.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';

import 'package:backend_dart/src/services/data_storage.dart';
import 'package:backend_dart/src/services/room_segmentation.dart';
import 'package:backend_dart/src/services/home_assistant_web_socket_client.dart';
import 'package:backend_dart/src/services/home_assistant_integration.dart';
import 'package:backend_dart/src/services/websocket_manager.dart';
import 'package:backend_dart/src/services/thing_manager.dart';
import 'package:backend_dart/src/services/room_manager.dart';

import 'package:backend_dart/src/controllers/devices_controller.dart';
import 'package:backend_dart/src/controllers/events_controller.dart';
import 'package:backend_dart/src/controllers/humans_controller.dart';
import 'package:backend_dart/src/controllers/map_controller.dart';
import 'package:backend_dart/src/controllers/settings_controller.dart';
import 'package:backend_dart/src/controllers/automations_controller.dart';

class EnvReader {
  final Map<String, String> _envVars = {};

  EnvReader(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw Exception('Env file not found at: $path');
    }
    for (var line in file.readAsLinesSync()) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final parts = line.split('=');
      if (parts.length == 2) {
        final key = parts[0].trim();
        final value = parts[1].trim();
        _envVars[key] = value;
      }
    }
  }

  String? get(String key) => _envVars[key];
}

void main(List<String> args) async {
  final env = EnvReader('.env');

  final haWsClient = HomeAssistantWebSocketClient();
  final haIntegration = HomeAssistantIntegration(haWsClient, url: env.get('HA_URL') ?? '', token: env.get('HA_TOKEN') ?? '');

  bool haConnected = await haIntegration.connectAsync();
  if (haConnected) {
    print("Successfully connected to Home Assistant.");
  } else {
    print("Failed to connect to Home Assistant.");
  }

  final dataStorage = DataStorage();
  final roomSegmentation = RoomSegmentation();
  final websocketManager = WebsocketManager();
  final roomManager = RoomManager(dataStorage, roomSegmentation);
  final thingManager = ThingManager(dataStorage, roomManager, haIntegration, websocketManager);
  final automationManager = AutomationManager(dataStorage.dataDir + '/automations.json');

  websocketManager.onMoveHuman = thingManager.moveHuman;

  // Set Home Assistant state change callback
  haIntegration.setStateChangeCallback(thingManager.onHaStateChange);

  // Load initial data
  await thingManager.loadInitialData();

  // Initialize Controllers
  final devicesController = DevicesController(thingManager);
  final eventsController = EventsController(dataStorage);
  final humansController = HumansController(thingManager);
  final mapController = MapController(dataStorage, roomManager);
  final settingsController = SettingsController(dataStorage, thingManager);
  final automationController = AutomationController(automationManager);

  // Setup Router
  final Router appRouter = Router();

  // Mount all controller routers
  appRouter.mount('/', devicesController.router);
  appRouter.mount('/', eventsController.router);
  appRouter.mount('/', humansController.router);
  appRouter.mount('/', mapController.router);
  appRouter.mount('/', settingsController.router);
  appRouter.mount('/', automationController.router);

  // WebSocket handler
  final wsHandler = webSocketHandler((webSocket) {
    websocketManager.addConnection(webSocket);
  });

  appRouter.get('/ws', wsHandler);

  // Fallback for unmatched routes
  appRouter.all('/<ignored|.*>', (Request request) {
    return Response.notFound('Not Found');
  });

  // Create a pipeline for handlers
  final handler = Pipeline().addMiddleware(corsHeaders()).addHandler(appRouter.call);

  // Start server
  final InternetAddress hostname = InternetAddress.anyIPv6;
  final int port = int.parse(Platform.environment['PORT'] ?? '5000');

  final HttpServer server = await io.serve(handler, hostname, port);

  print("Server listening on http://${server.address.host}:${server.port}");
}
