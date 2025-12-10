import 'dart:io';
import 'dart:convert';
import 'package:dart_common/dart_common.dart';
import 'package:backend_dart/src/models/device_metadata.dart';
import 'package:backend_dart/src/models/home_assistant/ha_models.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart'; // For firstWhereOrNull

import 'data_storage.dart'; // For Logger
import 'home_assistant_web_socket_client.dart'; // Assuming this will be translated next
import 'home_assistant_entity_parser.dart';

class HomeAssistantIntegration {
  final HomeAssistantWebSocketClient _wsClient;
  final String _dataDir;
  final String _url;
  final String _token;
  final bool _verifySsl;

  static const String _entityIdToAttributeGuidFilename = "entity_id_to_attribute_guid.json";
  Map<String, String> _entityIdToAttributeGuid = {};
  static const String _deviceIdToDeviceGuidFilename = "device_id_to_device_guid.json";
  Map<String, String> _deviceIdToDeviceGuid = {};

  Map<String, String> _deviceNamesCache = {};

  Future<void> Function()? _stateChangeCallback;

  final Uuid _uuid = Uuid();

  HomeAssistantIntegration(this._wsClient, {String url = "http://homeassistant.local:8123", String token = "", bool verifySsl = true, String dataDir = "data"})
    : _url = url.endsWith('/') ? url.substring(0, url.length - 1) : url,
      _token = token,
      _verifySsl = verifySsl,
      _dataDir = dataDir {
    _ensureDataDirectoryExists();
    _loadData();

    if (!_verifySsl) {
      print("SSL verification is disabled - use only for development!");
    }

    print('Conencting at $url');
  }

  void _ensureDataDirectoryExists() {
    if (!Directory(_dataDir).existsSync()) {
      Directory(_dataDir).createSync(recursive: true);
    }
  }

  Future<bool> connectAsync() async {
    try {
      await _wsClient.connectAsync(_url, _token, _verifySsl);
      print("Connected to Home Assistant WebSocket");

      _wsClient.setStateChangeCallback(() {
        if (_stateChangeCallback != null) {
          _stateChangeCallback!();
        }
      });

      return true;
    } catch (e) {
      print("Failed to connect to Home Assistant: $e");
      return false;
    }
  }

  void setStateChangeCallback(Future<void> Function() callback) {
    _stateChangeCallback = callback;
  }

  List<HaEntityState> getEntitiesAsync() {
    try {
      return _wsClient.getStatesAsync();
    } catch (e) {
      print("Failed to get entities: $e");
      return [];
    }
  }

  Future<Map<String, List<String>>> getDeviceToEntitiesMapAsync(List<HaEntityState> entities) async {
    final deviceToEntities = <String, List<String>>{};
    final entityRegistryMap = <String, String>{};

    try {
      var entitiesReg = await _wsClient.getEntityRegistryAsync();
      for (var entity in entitiesReg) {
        if (entity.entityId.isNotEmpty && entity.deviceId != null && entity.deviceId!.isNotEmpty) {
          entityRegistryMap[entity.entityId] = entity.deviceId!;
        }
        // C# had an empty if for AreaId, I'll keep it as is for now
        if (entity.entityId.isNotEmpty && entity.areaId != null && entity.areaId!.isNotEmpty) {
          // Do something with AreaId if needed
        }
      }
      print("Got entity registry with ${entityRegistryMap.length} entity->device mappings");
    } catch (e) {
      print("Could not get entity registry (using naming patterns instead): $e");
    }

    for (var entity in entities) {
      if (entityRegistryMap.containsKey(entity.entityId)) {
        var deviceId = entityRegistryMap[entity.entityId]!;
        deviceToEntities.putIfAbsent(deviceId, () => <String>[]).add(entity.entityId);
      }
    }

    print("Mapped ${entities.length} entities to ${deviceToEntities.length} devices");
    return deviceToEntities;
  }

  Future<String> getDeviceNameAsync(String deviceId) async {
    if (_deviceNamesCache.containsKey(deviceId)) {
      return _deviceNamesCache[deviceId]!;
    }

    try {
      print("Start GetDeviceRegistryAsync");
      var deviceRegistry = await _wsClient.getDeviceRegistryAsync();
      print("End GetDeviceRegistryAsync");
      for (var device in deviceRegistry) {
        if (device.id.isNotEmpty) {
          var name = device.nameByUser ?? device.name ?? device.id;
          _deviceNamesCache[device.id] = name;
        }
      }

      print("Refreshed device names cache with ${_deviceNamesCache.length} devices");
      _saveDeviceNamesCache();

      return _deviceNamesCache[deviceId] ?? deviceId;
    } catch (e) {
      print("Could not get device registry: $e");
      return deviceId;
    }
  }

  Future<List<Device>> getDevicesWithCoordinatesAsync({Map<String, DeviceMetadata>? deviceMetadata}) async {
    final entities = getEntitiesAsync();
    final deviceToEntityIds = await getDeviceToEntitiesMapAsync(entities);
    final entitiesById = {for (var e in entities) e.entityId: e};

    final vacuumDevices = _createVacuumDevices(entitiesById);
    final usedVacuumEntityIds = vacuumDevices.map((d) => d.haEntityId).where((id) => id != null).toSet();

    final devices = <Device>[];

    for (var entry in deviceToEntityIds.entries) {
      final deviceId = entry.key;
      final entityIds = entry.value;

      final deviceEntities =
          entityIds.where((id) => entitiesById.containsKey(id)).where((id) => !usedVacuumEntityIds.contains(id)).map((id) => entitiesById[id]!).toList();

      if (deviceEntities.isNotEmpty) {
        final device = await _entitiesToDeviceAsync(deviceId, deviceEntities, deviceMetadata);
        if (device != null) {
          devices.add(device);
        }
      }
    }

    devices.addAll(vacuumDevices);

    final chargerDevices = _createChargerDevices(entitiesById);
    devices.addAll(chargerDevices);

    return devices;
  }

  String _getOrCreateDeviceGuid(String deviceId) {
    if (!_deviceIdToDeviceGuid.containsKey(deviceId)) {
      final guid = _uuid.v4();
      _deviceIdToDeviceGuid[deviceId] = guid;
      _saveGuidMappings();
    }
    return _deviceIdToDeviceGuid[deviceId]!;
  }

  String _getOrCreateAttributeGuid(String entityId) {
    if (!_entityIdToAttributeGuid.containsKey(entityId)) {
      final guid = _uuid.v4();
      _entityIdToAttributeGuid[entityId] = guid;
      _saveGuidMappings();
    }
    return _entityIdToAttributeGuid[entityId]!;
  }

  String getEntityIdByAttributeGuid(String attributeGuid) {
    for (var pair in _entityIdToAttributeGuid.entries) {
      if (pair.value == attributeGuid) {
        return pair.key;
      }
    }
    print("Can't find entity for guid '$attributeGuid'");
    return "";
  }

  bool _atLeastOneOnline(List<HaEntityState> entities) {
    return entities.any((e) => e.state != "unavailable" && e.state != "unknown");
  }

  Future<Device?> _entitiesToDeviceAsync(String deviceId, List<HaEntityState> entities, Map<String, DeviceMetadata>? deviceMetadata) async {
    if (entities.isEmpty) return null;

    final deviceGuid = _getOrCreateDeviceGuid(deviceId);
    final deviceAttributes = <Attribute>[];
    final deviceName = await getDeviceNameAsync(deviceId);

    (double, double)? coords;
    if (deviceMetadata != null && deviceMetadata.containsKey(deviceGuid)) {
      final metadata = deviceMetadata[deviceGuid]!;
      if (metadata.x != null && metadata.y != null) {
        coords = (metadata.x!, metadata.y!);
      }
    }

    final hasVacuumPosition = entities.any((e) {
      final domain = e.entityId.split('.')[0];
      return domain == "camera" && e.attributes.containsKey("vacuum_position");
    });

    if (hasVacuumPosition) {
      return null;
    }

    final hasAutoLocation = hasVacuumPosition;

    if (!hasAutoLocation) {
      final primaryEntityId = entities.first.entityId;
      final locationAttr = LocationAttribute(
        x: coords?.$1 ?? 25000.0,
        y: coords?.$2 ?? 25000.0,
        roomId: null,
        locationType: LocationType.manual,
        guid: _getOrCreateAttributeGuid("$primaryEntityId:location"),
      );
      deviceAttributes.add(locationAttr);
    }

    final isOnline = _atLeastOneOnline(entities);

    for (var entity in entities) {
      final domain = entity.entityId.split('.')[0];
      final state = entity.state;
      final attrs = entity.attributes;
      final friendlyName = attrs['friendly_name']?.toString() ?? entity.entityId;

      try {
        if (domain == "camera") {
          if (attrs.containsKey("vacuum_position") && attrs["vacuum_position"] is Map) {
            try {
              final vacuumPos = attrs["vacuum_position"] as Map<String, dynamic>;
              if (vacuumPos.containsKey("x") && vacuumPos.containsKey("y")) {
                final x = (vacuumPos["x"] as num).toDouble();
                final y = (vacuumPos["y"] as num).toDouble();
                final locationAttr = LocationAttribute(
                  x: x,
                  y: y,
                  roomId: null,
                  locationType: LocationType.auto,
                  guid: _getOrCreateAttributeGuid("${entity.entityId}:location"),
                );
                deviceAttributes.add(locationAttr);
              }
            } catch (e) {
              print("Error parsing vacuum_position for ${entity.entityId}: $e");
            }
          }

          if (attrs.containsKey("path")) {
            try {
              final pathData = attrs["path"];
              if (pathData is Map<String, dynamic> && pathData.containsKey("path") && pathData["path"] is List) {
                final List<List<MapPoint>> paths = [];
                for (var rawPath in (pathData["path"] as List)) {
                  final pathPoints = <MapPoint>[];
                  for (var pointData in (rawPath as List)) {
                    final x = (pointData['x'] as num).toDouble();
                    final y = (pointData['y'] as num).toDouble();
                    pathPoints.add(MapPoint(x: x, y: y));
                  }
                  if (pathPoints.isNotEmpty) {
                    paths.add(pathPoints);
                  }
                }

                if (paths.isNotEmpty) {
                  final pathAttr = PathAttribute(paths: paths, guid: _getOrCreateAttributeGuid("${entity.entityId}:path"));
                  deviceAttributes.add(pathAttr);
                }
              }
            } catch (e) {
              print("Error parsing path for ${entity.entityId}: $e");
            }
          }

          final cameraAttr = CameraAttribute(
            state: state ?? "idle",
            streamUrl: attrs["entity_picture"]?.toString(),
            snapshotUrl: attrs["entity_picture"]?.toString(),
            guid: _getOrCreateAttributeGuid(entity.entityId),
          );
          deviceAttributes.add(cameraAttr);
        } else {
          final attr = HomeAssistantEntityParser.createAttributeForEntity(entity, domain, state, _getOrCreateAttributeGuid);
          if (attr != null) {
            deviceAttributes.add(attr);
          }
        }
      } catch (e) {
        print("Error creating attribute for entity ${entity.entityId}: $e");
      }
    }

    if (deviceAttributes.length <= 1) return null;

    return Device(
      id: deviceGuid,
      name: deviceName,
      isOnline: isOnline,
      hidden: false,
      icon: null,
      color: null,
      integration: IntegrationType.homeAssistant,
      attributes: deviceAttributes,
      haEntityId: null,
    );
  }

  List<Device> _createVacuumDevices(Map<String, HaEntityState> entitiesById) {
    var vacuumDevice = Device(
      id: "vacuum_cleaner",
      name: "",
      isOnline: true,
      hidden: false,
      icon: "motion_photos_on",
      color: "#2196F3",
      integration: IntegrationType.homeAssistant,
      attributes: [],
      haEntityId: '',
    );

    for (var entry in entitiesById.entries) {
      final entityId = entry.key;
      final entity = entry.value;
      final domain = entityId.split('.')[0];

      if (domain == 'vacuum') {
        vacuumDevice.haEntityId = entityId;
        final vacuumEntity = entity;
        vacuumDevice.name = entity.attributes["friendly_name"]?.toString() ?? entityId;
        try {
          final vacuumAttr = VacuumAttribute(
            state: vacuumEntity.state,
            batteryLevel: _getIntValue(vacuumEntity.attributes, 'battery_level'),
            fanSpeed: vacuumEntity.attributes['fan_speed']?.toString(),
            status: vacuumEntity.attributes['status']?.toString(),
            fanSpeedList: _getStringListValue(vacuumEntity.attributes, 'fan_speed_list'),
            guid: _getOrCreateAttributeGuid(entityId),
          );
          vacuumDevice.attributes.add(vacuumAttr);
        } catch (e) {
          print("Error creating vacuum attribute for $entityId: $e");
        }
      }

      if (domain == "camera" && entity.attributes.containsKey("vacuum_position")) {
        try {
          final vacuumPos = entity.attributes["vacuum_position"];
          if (vacuumPos is Map<String, dynamic>) {
            if (vacuumPos.containsKey("x") && vacuumPos.containsKey("y")) {
              final x = (vacuumPos["x"] as num).toDouble();
              final y = (vacuumPos["y"] as num).toDouble();
              final friendlyName = entity.attributes["friendly_name"]?.toString() ?? entityId;

              final locationAttr = LocationAttribute(
                x: x,
                y: y,
                roomId: null,
                locationType: LocationType.auto,
                guid: _getOrCreateAttributeGuid("$entityId:vacuum:location"),
              );
              vacuumDevice.attributes.add(locationAttr);

              if (entity.attributes.containsKey("path")) {
                try {
                  final pathData = entity.attributes["path"];
                  if (pathData is Map<String, dynamic> && pathData.containsKey("path") && pathData["path"] is List) {
                    final List<List<MapPoint>> paths = [];
                    for (var rawPath in (pathData["path"] as List)) {
                      final pathPoints = <MapPoint>[];
                      for (var pointData in (rawPath as List)) {
                        final px = (pointData['x'] as num).toDouble();
                        final py = (pointData['y'] as num).toDouble();
                        pathPoints.add(MapPoint(x: px, y: py));
                      }
                      if (pathPoints.isNotEmpty) {
                        paths.add(pathPoints);
                      }
                    }

                    if (paths.isNotEmpty) {
                      final pathAttr = PathAttribute(paths: paths, guid: _getOrCreateAttributeGuid("$entityId:vacuum:path"));
                      vacuumDevice.attributes.add(pathAttr);
                    }
                  }
                } catch (e) {
                  print("Error parsing vacuum path for $entityId: $e");
                }
              }

              String? vacuumEntityId;

              if (vacuumPos.containsKey("entity_id")) {
                vacuumEntityId = vacuumPos["entity_id"] as String;
              } else {
                final cameraName = entityId.split('.').last;
                final possibleVacuumId = "vacuum.$cameraName";
                if (entitiesById.containsKey(possibleVacuumId)) {
                  vacuumEntityId = possibleVacuumId;
                } else {
                  for (var vacEntry in entitiesById.entries) {
                    final vDomain = vacEntry.key.split('.')[0];
                    if (vDomain == "vacuum") {
                      final vName = vacEntry.value.attributes["friendly_name"]?.toString() ?? "";
                      if (vName.isNotEmpty && friendlyName.toLowerCase().contains(vName.toLowerCase())) {
                        vacuumEntityId = vacEntry.key;
                        break;
                      }
                    }
                  }
                }
              }
            }
          }
        } catch (e) {
          print("Error creating vacuum device for $entityId: $e");
        }
      }
    }

    return [vacuumDevice];
  }

  int? _getIntValue(Map<String, dynamic> attrs, String key) {
    final value = attrs[key];
    if (value is int) {
      return value;
    } else if (value is String) {
      return int.tryParse(value);
    } else if (value is num) {
      return value.toInt();
    }
    return null;
  }

  List<String>? _getStringListValue(Map<String, dynamic> attrs, String key) {
    final value = attrs[key];
    if (value is List) {
      return value.cast<String>().toList();
    }
    return null;
  }

  List<Device> _createChargerDevices(Map<String, HaEntityState> entitiesById) {
    final chargerDevices = <Device>[];

    for (var entry in entitiesById.entries) {
      final entityId = entry.key;
      final entity = entry.value;
      final domain = entityId.split('.')[0];

      if (domain == "camera" && entity.attributes.containsKey("charger")) {
        try {
          final chargerObj = entity.attributes["charger"];
          if (chargerObj is Map<String, dynamic>) {
            if (chargerObj.containsKey("x") && chargerObj.containsKey("y")) {
              final x = (chargerObj["x"] as num).toDouble();
              final y = (chargerObj["y"] as num).toDouble();
              final friendlyName = entity.attributes["friendly_name"]?.toString() ?? entityId;

              final locationAttr = LocationAttribute(
                x: x,
                y: y,
                roomId: null,
                locationType: LocationType.auto,
                guid: _getOrCreateAttributeGuid("$entityId:charger:location"),
              );

              final chargerDevice = Device(
                id: "charger_$entityId",
                name: "$friendlyName Charger",
                isOnline: true,
                hidden: false,
                icon: "battery_charging_full",
                color: "#4CAF50",
                integration: IntegrationType.homeAssistant,
                attributes: [locationAttr],
              );

              chargerDevices.add(chargerDevice);
            }
          }
        } catch (e) {
          print("Error creating charger device for $entityId: $e");
        }
      }
    }

    return chargerDevices;
  }

  Future<bool> turnOnAsync(String entityId, {int? brightness, List<int>? rgbColor}) async {
    final domain = entityId.split('.')[0];
    final serviceData = <String, dynamic>{"entity_id": entityId};

    if (brightness != null) serviceData["brightness"] = brightness;
    if (rgbColor != null) serviceData["rgb_color"] = rgbColor;

    print("[HA] turn_on: entity_id=$entityId, domain=$domain");
    return await _wsClient.callServiceAsync(domain, "turn_on", serviceData);
  }

  Future<bool> turnOffAsync(String entityId) async {
    final domain = entityId.split('.')[0];
    final serviceData = <String, dynamic>{"entity_id": entityId};

    print("[HA] turn_off: entity_id=$entityId, domain=$domain");
    return await _wsClient.callServiceAsync(domain, "turn_off", serviceData);
  }

  void _loadData() {
    try {
      var guidFile = p.join(_dataDir, _entityIdToAttributeGuidFilename);
      if (File(guidFile).existsSync()) {
        var json = File(guidFile).readAsStringSync();
        _entityIdToAttributeGuid = (jsonDecode(json) as Map<String, dynamic>).cast<String, String>();
        print("Loaded ${_entityIdToAttributeGuid.length} entity-GUID mappings");
      }
    } catch (e) {
      print("Failed to load entity-GUID mappings: $e");
    }
    try {
      var guidFile = p.join(_dataDir, _deviceIdToDeviceGuidFilename);
      if (File(guidFile).existsSync()) {
        var json = File(guidFile).readAsStringSync();
        _deviceIdToDeviceGuid = (jsonDecode(json) as Map<String, dynamic>).cast<String, String>();
        print("Loaded ${_deviceIdToDeviceGuid.length} device-GUID mappings");
      }
    } catch (e) {
      print("Failed to load device-GUID mappings: $e");
    }

    try {
      var namesFile = p.join(_dataDir, "device_names_cache.json");
      if (File(namesFile).existsSync()) {
        var json = File(namesFile).readAsStringSync();
        _deviceNamesCache = (jsonDecode(json) as Map<String, dynamic>).cast<String, String>();
        print("Loaded ${_deviceNamesCache.length} device names from cache");
      }
    } catch (e) {
      print("Failed to load device names cache: $e");
    }
  }

  void _saveGuidMappings() {
    try {
      var ejson = jsonEncode(_entityIdToAttributeGuid);
      File(p.join(_dataDir, _entityIdToAttributeGuidFilename)).writeAsStringSync(ejson);

      var djson = jsonEncode(_deviceIdToDeviceGuid);
      File(p.join(_dataDir, _deviceIdToDeviceGuidFilename)).writeAsStringSync(djson);
    } catch (e) {
      print("Failed to save entity-GUID mappings: $e");
    }
  }

  void _saveDeviceNamesCache() {
    try {
      var json = jsonEncode(_deviceNamesCache);
      File(p.join(_dataDir, "device_names_cache.json")).writeAsStringSync(json);
    } catch (e) {
      print("Failed to save device names cache: $e");
    }
  }
}
