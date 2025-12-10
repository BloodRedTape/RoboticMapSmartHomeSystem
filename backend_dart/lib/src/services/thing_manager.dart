import 'package:dart_common/dart_common.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

import 'data_storage.dart';
import 'device_merger.dart';
import 'home_assistant_integration.dart';
import 'room_manager.dart';
import 'websocket_manager.dart';

class ThingManager {
  final DataStorage _storage;
  final RoomManager _roomManager;
  final HomeAssistantIntegration _haIntegration;
  final WebsocketManager _websocketManager;

  List<dynamic> things = []; // Can contain Device or Human
  List<Device> _haDevices = [];

  ThingManager(this._storage, this._roomManager, this._haIntegration, this._websocketManager);

  Future<void> loadInitialData() async {
    print("[ThingManager] Loading initial data...");
    _storage.loadAll();
    await refreshThings();
    print("[ThingManager] Initial data loaded.");
  }

  Future<void> refreshThings() async {
    print("[ThingManager] Refreshing things...");

    _haDevices = await _haIntegration.getDevicesWithCoordinatesAsync(deviceMetadata: _storage.deviceMetadata);

    bool metadataChanged = false;
    for (var device in _haDevices) {
      final locationAttr = device.attributes.whereType<LocationAttribute>().firstWhereOrNull((attr) => true);
      if (locationAttr != null && locationAttr.locationType == LocationType.auto) {
        if (_storage.deviceMetadata.containsKey(device.id)) {
          final metadata = _storage.deviceMetadata[device.id]!;
          if (metadata.x != null || metadata.y != null) {
            metadata.x = null;
            metadata.y = null;
            metadataChanged = true;
          }
        }
      }
    }

    mergeThings();

    if (metadataChanged) {
      _storage.saveDeviceMetadata();
    }
    print("[ThingManager] Thing refresh complete. Total things: ${things.length}");
  }

  void mergeThings() {
    final devices = DeviceMerger.mergeDevices(_haDevices, _storage.virtualDevices, _storage.deviceMetadata);

    final humans = _storage.humans;

    things = [...devices, ...humans];
  }

  List<Device> getAllDevices() {
    final devices = things.whereType<Device>().toList();
    for (var device in devices) {
      final locationAttr = device.attributes.whereType<LocationAttribute>().firstWhereOrNull((attr) => true);
      if (locationAttr != null && locationAttr.x != null && locationAttr.y != null) {
        locationAttr.roomId = _roomManager.getRoomIdByCoordinates(locationAttr.x!, locationAttr.y!);
      }
    }
    return devices;
  }

  List<Human> getAllHumans() {
    final humans = things.whereType<Human>().toList();
    for (var human in humans) {
      final locationAttr = human.attributes.whereType<LocationAttribute>().firstWhereOrNull((attr) => true);
      if (locationAttr != null && locationAttr.x != null && locationAttr.y != null) {
        locationAttr.roomId = _roomManager.getRoomIdByCoordinates(locationAttr.x!, locationAttr.y!);
      }
    }
    return humans;
  }

  dynamic getThing(String thingId) {
    return things.firstWhereOrNull((t) => (t is Device && t.id == thingId) || (t is Human && t.id == thingId));
  }

  Future<void> notifyUpdate() async {
    _haDevices = await _haIntegration.getDevicesWithCoordinatesAsync(deviceMetadata: _storage.deviceMetadata);
    mergeThings();

    await _websocketManager.broadcastDevices(getAllDevices());
    await _websocketManager.broadcastHumans(getAllHumans());
  }

  Future<bool> sendCommand(Command command) async {
    print("[ThingManager] Received command: type=${command.type}, attribute_guid=${command.attributeGuid}");

    // The C# version checks _haIntegration == null, but in Dart constructor it's non-nullable.
    // If HA is not connected, it would throw earlier.

    final entityId = _haIntegration.getEntityIdByAttributeGuid(command.attributeGuid);
    if (entityId.isEmpty) {
      print("Entity ID not found for attribute GUID: ${command.attributeGuid}");
      return false;
    }

    print("[ThingManager] Mapped attribute GUID ${command.attributeGuid} to entity $entityId");

    if (command is SwitchCommand) {
      final state = command.state;
      print("[ThingManager] Executing switch_control: entity=$entityId, state=$state");
      if (state == "on") {
        final result = await _haIntegration.turnOnAsync(entityId);
        print("[ThingManager] turn_on result: $result");
        return result;
      } else {
        final result = await _haIntegration.turnOffAsync(entityId);
        print("[ThingManager] turn_off result: $result");
        return result;
      }
    } else if (command is BrightnessCommand) {
      final brightness = command.brightness;
      print("[ThingManager] Executing set_brightness: entity=$entityId, brightness=$brightness");
      final brightnessResult = await _haIntegration.turnOnAsync(entityId, brightness: brightness);
      print("[ThingManager] turn_on with brightness result: $brightnessResult");
      return brightnessResult;
    } else if (command is ColorCommand) {
      final rgbColor = command.rgbColor;
      print("[ThingManager] Executing set_color: entity=$entityId, rgb_color=${rgbColor.join(",")}");
      final colorResult = await _haIntegration.turnOnAsync(entityId, rgbColor: rgbColor);
      print("[ThingManager] turn_on with rgb_color result: $colorResult");
      return colorResult;
    } else {
      print("[ThingManager] Unknown command type: ${command.type}");
      return false;
    }
  }

  Future<void> onHaStateChange() async {
    print("[ThingManager] HA state change detected.");
    notifyUpdate();
  }

  Future<Device> addVirtualDevice(Device deviceData) async {
    _storage.virtualDevices.add(deviceData);
    _storage.saveVirtualDevices();

    // Directly update metadata using DataStorage's updateDeviceMetadata
    _storage.updateDeviceMetadata(
      deviceId: deviceData.id,
      x: deviceData.attributes.whereType<LocationAttribute>().firstWhereOrNull((attr) => true)?.x,
      y: deviceData.attributes.whereType<LocationAttribute>().firstWhereOrNull((attr) => true)?.y,
      roomId: deviceData.attributes.whereType<LocationAttribute>().firstWhereOrNull((attr) => true)?.roomId,
      isVirtual: true,
    );
    await notifyUpdate(); // NotifyUpdate is called by UpdateThingMetadata implicitly after save.
    return deviceData;
  }

  Future<bool> deleteVirtualDevice(String deviceId) async {
    final deviceToDelete = _storage.virtualDevices.firstWhereOrNull((d) => d.id == deviceId);
    if (deviceToDelete == null || deviceToDelete.integration != IntegrationType.virtual) {
      return false;
    }

    _storage.virtualDevices.remove(deviceToDelete);
    _storage.saveVirtualDevices();

    if (_storage.deviceMetadata.containsKey(deviceId)) {
      _storage.deviceMetadata.remove(deviceId);
      _storage.saveDeviceMetadata();
    }

    await notifyUpdate();
    return true;
  }

  Future<void> updateThingMetadata(
    String thingId, {
    double? x,
    double? y,
    String? name,
    String? icon,
    String? color,
    String? integration,
    bool? hidden,
    String? roomId,
    bool? isVirtual,
  }) async {
    // The C# code directly modifies metadata in storage, then saves.
    // My Dart DataStorage has an updateDeviceMetadata that does this.
    _storage.updateDeviceMetadata(deviceId: thingId, x: x, y: y, name: name, icon: icon, color: color, integration: integration, hidden: hidden, roomId: roomId, isVirtual: isVirtual);
    await notifyUpdate();
  }

  Future<void> customizeDevice(String deviceId, DeviceCustomization customization) async {
    await updateThingMetadata(deviceId, name: customization.name, icon: customization.icon, color: customization.color, integration: customization.integration);
  }

  Future<void> hideDevice(String deviceId) async {
    await updateThingMetadata(deviceId, hidden: true);
  }

  Future<void> showDevice(String deviceId) async {
    await updateThingMetadata(deviceId, hidden: false);
  }

  Future<Human> createHuman({String? name}) async {
    name ??= "Person ${_storage.humans.length + 1}";

    final x = 25000.0;
    final y = 25000.0;

    final human = Human(
      id: const Uuid().v4(),
      name: name,
      isDetected: true,
      detectionSource: "manual",
      attributes: [LocationAttribute(guid: const Uuid().v4(), x: x, y: y, locationType: LocationType.auto, roomId: _roomManager.getRoomIdByCoordinates(x, y))],
    );

    _storage.humans.add(human);
    await notifyUpdate();
    return human;
  }

  Future<bool> moveHuman(String humanId, double x, double y) async {
    final human = _storage.humans.firstWhereOrNull((h) => h.id == humanId);

    if (human == null) return false;

    final locAttr = human.findAttribute<LocationAttribute>();

    if (locAttr == null) return false;

    locAttr.x = x;
    locAttr.y = y;
    locAttr.roomId = _roomManager.getRoomIdByCoordinates(x, y);

    mergeThings(); // Re-merge to update human location in Things list
    await _websocketManager.broadcastHumans(getAllHumans()); // Only broadcast humans
    return true;
  }

  Future<bool> deleteHuman(String humanId) async {
    final humanToDelete = _storage.humans.firstWhereOrNull((h) => h.id == humanId);
    if (humanToDelete == null) return false;

    _storage.humans.remove(humanToDelete);
    await notifyUpdate();
    return true;
  }
}
