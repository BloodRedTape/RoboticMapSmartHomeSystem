import 'dart:io';
import 'dart:convert';
import 'package:backend_dart/src/models/map_data_on_disk.dart';
import 'package:dart_common/dart_common.dart';
import 'package:backend_dart/src/models/device_metadata.dart';
import 'package:backend_dart/src/models/room_metadata.dart';
import 'package:backend_dart/src/models/settings.dart';
import 'package:path/path.dart' as p;

class DataStorage {
  final String _dataDir = p.join('data');

  List<Device> virtualDevices = [];
  List<Human> humans = [];
  Map<String, DeviceMetadata> deviceMetadata = {};
  Map<String, RoomMetadata> roomMetadata = {};
  List<EventData> eventList = [];
  Settings settingsData = Settings();
  MapDataOnDisk mapData = MapDataOnDisk(mapName: 'Initial map');
  List<Automation> automations = [];

  DataStorage() {
    _ensureDataDirectoryExists();
    loadAll();
  }

  String get dataDir {
    return _dataDir;
  }

  void _ensureDataDirectoryExists() {
    if (!Directory(_dataDir).existsSync()) {
      Directory(_dataDir).createSync(recursive: true);
    }
  }

  void loadAll() {
    loadVirtualDevices();
    loadDeviceMetadata();
    loadRoomMetadata();
    loadEvents();
    loadSettings();
    loadMapData();
    loadAutomations();
  }

  // Generic function to load a list of items
  List<T> _loadList<T>(String fileName, T Function(Map<String, dynamic>) fromJson) {
    final path = p.join(_dataDir, fileName);
    try {
      if (File(path).existsSync()) {
        final json = File(path).readAsStringSync();
        return (jsonDecode(json) as List<dynamic>).map((e) => fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      print('[INIT] Failed to load $fileName: $e');
    }
    return [];
  }

  // Generic function to load a single item
  T _loadItem<T>(String fileName, T Function(Map<String, dynamic>) fromJson, T defaultValue) {
    final path = p.join(_dataDir, fileName);
    try {
      if (File(path).existsSync()) {
        final json = File(path).readAsStringSync();
        return fromJson(jsonDecode(json) as Map<String, dynamic>);
      }
    } catch (e) {
      print('[INIT] Failed to load $fileName: $e');
    }
    return defaultValue;
  }

  // Generic function to load a map of items
  Map<String, T> _loadMap<T>(String fileName, T Function(Map<String, dynamic>) fromJson) {
    final path = p.join(_dataDir, fileName);
    try {
      if (File(path).existsSync()) {
        final json = File(path).readAsStringSync();
        return (jsonDecode(json) as Map<String, dynamic>).map((key, value) => MapEntry(key, fromJson(value as Map<String, dynamic>)));
      }
    } catch (e) {
      print('[INIT] Failed to load $fileName: $e');
    }
    return {};
  }

  void loadVirtualDevices() {
    virtualDevices = _loadList('virtual_devices.json', Device.fromJson);
    print('[INIT] Loaded ${virtualDevices.length} virtual devices');
  }

  void loadDeviceMetadata() {
    // C# uses ToDictionary, so we need to rebuild the map from a list
    final List<DeviceMetadata> metadataList = _loadList('device_metadata.json', DeviceMetadata.fromJson);
    deviceMetadata = {for (var item in metadataList) item.deviceId: item};
    print('[INIT] Loaded metadata for ${deviceMetadata.length} devices');
  }

  void loadRoomMetadata() {
    roomMetadata = _loadMap('room_metadata.json', RoomMetadata.fromJson);
    print('[INIT] Loaded metadata for ${roomMetadata.length} rooms');
  }

  void loadEvents() {
    eventList = _loadList('events.json', EventData.fromJson);
    print('[INIT] Loaded ${eventList.length} events');
  }

  void loadSettings() {
    settingsData = _loadItem('settings.json', Settings.fromJson, Settings());
    print('[INIT] Loaded settings');
  }

  void loadMapData() {
    mapData = _loadItem('parsed_map_data.json', MapDataOnDisk.fromJson, mapData);
    print('[INIT] Loaded map data');
  }

  void loadAutomations() {
    automations = _loadList('automations.json', Automation.fromJson);
    print('[INIT] Loaded ${automations.length} automations');
  }

  // Generic function to save a list of items
  void _saveList<T>(String fileName, List<T> items) {
    final path = p.join(_dataDir, fileName);
    try {
      final json = jsonEncode(items.map((e) => (e as dynamic).toJson()).toList());
      File(path).writeAsStringSync(json);
    } catch (e) {
      print('[ERROR] Failed to save $fileName: $e');
    }
  }

  // Generic function to save a single item
  void _saveItem<T>(String fileName, T item) {
    final path = p.join(_dataDir, fileName);
    try {
      final json = jsonEncode((item as dynamic).toJson());
      File(path).writeAsStringSync(json);
    } catch (e) {
      print('[ERROR] Failed to save $fileName: $e');
    }
  }

  // Generic function to save a map of items
  void _saveMap<T>(String fileName, Map<String, T> items) {
    final path = p.join(_dataDir, fileName);
    try {
      final json = jsonEncode(items.map((key, value) => MapEntry(key, (value as dynamic).toJson())));
      File(path).writeAsStringSync(json);
    } catch (e) {
      print('[ERROR] Failed to save $fileName: $e');
    }
  }

  void saveVirtualDevices() => _saveList('virtual_devices.json', virtualDevices);
  void saveHumans() => _saveList('humans.json', humans);
  void saveAutomations(List<Automation> automationsList) {
    automations = automationsList;
    _saveList('automations.json', automations);
  }

  void saveDeviceMetadata() {
    _saveList('device_metadata.json', deviceMetadata.values.toList());
  }

  void saveRoomMetadata() => _saveMap('room_metadata.json', roomMetadata);
  void saveEvents() => _saveList('events.json', eventList);
  void saveSettings() => _saveItem('settings.json', settingsData);
  void saveMapData() => _saveItem('map_data.json', mapData);

  // Specific load/save for BlockPoints, Doors
  List<BlockPoint> loadBlockPoints() => _loadList('map_blocks.json', BlockPoint.fromJson);
  void saveBlockPoints(List<BlockPoint> blocks) => _saveList('map_blocks.json', blocks);

  List<BlockPoint> loadMapBlocks() => _loadList('map_blocks.json', BlockPoint.fromJson);
  void saveMapBlocks(List<BlockPoint> blocks) => _saveList('map_blocks.json', blocks);

  List<Door> loadDoors() => _loadList('doors.json', Door.fromJson);
  void saveDoors(List<Door> doors) => _saveList('doors.json', doors);

  // UpdateDeviceMetadata function
  void updateDeviceMetadata({
    required String deviceId,
    double? x,
    double? y,
    String? roomId,
    bool? hidden,
    String? name,
    String? icon,
    String? color,
    String? integration,
    bool? isVirtual,
  }) {
    DeviceMetadata? metadata = deviceMetadata[deviceId];

    if (metadata != null) {
      if (x != null) metadata.x = x;
      if (y != null) metadata.y = y;
      if (roomId != null) metadata.roomId = roomId;
      if (hidden != null) metadata.hidden = hidden;
      if (name != null) metadata.name = name;
      if (icon != null) metadata.icon = icon;
      if (color != null) metadata.color = color;
      if (integration != null) metadata.integration = integration;
      if (isVirtual != null) metadata.isVirtual = isVirtual;
    } else {
      metadata = DeviceMetadata(
        deviceId: deviceId,
        x: x,
        y: y,
        roomId: roomId,
        hidden: hidden ?? false,
        name: name,
        icon: icon,
        color: color,
        integration: integration,
        isVirtual: isVirtual ?? false,
      );
      deviceMetadata[deviceId] = metadata;
    }
    saveDeviceMetadata();
  }

  // UpdateMetadata is a duplicate of UpdateDeviceMetadata in the C# code,
  // I will just keep one method with a clearer name.
  // The C# also had a general UpdateMetadata for things, but the implementation only
  // updated DeviceMetadata. I will keep it focused on DeviceMetadata as per the C# impl.
}
