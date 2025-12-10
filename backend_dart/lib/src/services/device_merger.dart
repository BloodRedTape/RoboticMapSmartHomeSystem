import 'package:dart_common/dart_common.dart';
import 'package:backend_dart/src/models/device_metadata.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart'; // For firstWhereOrNull

class DeviceMerger {
  static List<Device> mergeDevices(List<Device> haDevices, List<Device> virtualDevices, Map<String, DeviceMetadata> deviceMetadata) {
    final result = <Device>[];
    final haDeviceIds = <String>{};

    for (var haDevice in haDevices) {
      if (haDevice.id.isEmpty) continue;
      haDeviceIds.add(haDevice.id);

      if (deviceMetadata.containsKey(haDevice.id)) {
        final metadata = deviceMetadata[haDevice.id]!;

        if (metadata.name != null && metadata.name!.isNotEmpty) haDevice.name = metadata.name!;
        if (metadata.icon != null && metadata.icon!.isNotEmpty) haDevice.icon = metadata.icon;
        if (metadata.color != null && metadata.color!.isNotEmpty) haDevice.color = metadata.color;
        if (metadata.integration != null && metadata.integration!.isNotEmpty) {
          haDevice.integration = IntegrationType.fromString(metadata.integration!);
        }
        haDevice.hidden = metadata.hidden;

        if (metadata.x != null && metadata.y != null) {
          LocationAttribute? locationAttr = haDevice.attributes.whereType<LocationAttribute>().firstWhereOrNull((attr) => true);

          if (locationAttr == null) {
            locationAttr = LocationAttribute(roomId: metadata.roomId, locationType: LocationType.manual, guid: Uuid().v4(), x: metadata.x!, y: metadata.y!);
            haDevice.attributes.add(locationAttr);
          }
          locationAttr.roomId = metadata.roomId;
        }
      }
      result.add(haDevice);
    }

    for (var virtualDevice in virtualDevices) {
      if (virtualDevice.id.isEmpty) continue;

      if (deviceMetadata.containsKey(virtualDevice.id)) {
        final metadata = deviceMetadata[virtualDevice.id]!;

        if (metadata.hidden) continue;

        if (metadata.name != null && metadata.name!.isNotEmpty) virtualDevice.name = metadata.name!;
        if (metadata.icon != null && metadata.icon!.isNotEmpty) virtualDevice.icon = metadata.icon;
        if (metadata.color != null && virtualDevice.color!.isNotEmpty) virtualDevice.color = metadata.color;
        if (metadata.integration != null && metadata.integration!.isNotEmpty) {
          virtualDevice.integration = IntegrationType.fromString(metadata.integration!);
        }
        virtualDevice.hidden = metadata.hidden;
      }
      result.add(virtualDevice);
    }

    return result;
  }
}
