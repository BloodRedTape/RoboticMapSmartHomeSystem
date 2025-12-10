import 'package:dart_common/common/attributes.dart';
import 'package:dart_common/common/device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend_flutter/cubits/devices_cubit.dart';
import 'package:frontend_flutter/cubits/map_cubit.dart';
import 'package:frontend_flutter/tabs/dashboard/cards/light_card.dart';
import 'package:frontend_flutter/tabs/dashboard/cards/switch_card.dart';
import 'package:frontend_flutter/tabs/dashboard/cards/sensor_card.dart';
import 'package:frontend_flutter/tabs/dashboard/cards/cover_card.dart';
import 'package:frontend_flutter/tabs/dashboard/cards/vacuum_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapCubit, MapState>(
      builder: (context, mapState) {
        if (mapState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (mapState.mapData == null || mapState.mapData!.rooms.isEmpty) {
          return const Center(child: Text('No rooms available'));
        }

        final rooms = mapState.mapData!.rooms.values.toList();

        return DefaultTabController(
          length: rooms.length,
          child: Scaffold(
            appBar: AppBar(title: const Text('Dashboard'), bottom: TabBar(isScrollable: true, tabs: rooms.map((room) => Tab(text: room.name)).toList())),
            body: TabBarView(children: rooms.map((room) => RoomDashboard(roomId: room.guid)).toList()),
          ),
        );
      },
    );
  }
}

class RoomDashboard extends StatelessWidget {
  final String roomId;

  const RoomDashboard({super.key, required this.roomId});

  String? _getDeviceRoom(Device device, MapState mapState) {
    final location = device.findAttribute<LocationAttribute>();
    if (location == null) return null;

    if (location.roomId != null) {
      return location.roomId;
    }

    if (mapState.mapData == null) return null;

    final blockPoint = mapState.mapData!.mapToBlockPoint(location.x, location.y);

    for (final room in mapState.mapData!.rooms.values) {
      for (final rect in room.rectangles) {
        if (blockPoint.x >= rect.x && blockPoint.x <= rect.x + rect.width && blockPoint.y >= rect.y && blockPoint.y <= rect.y + rect.height) {
          return room.guid;
        }
      }
    }

    return _findNearestRoom(blockPoint.x.toDouble(), blockPoint.y.toDouble(), mapState);
  }

  String? _findNearestRoom(double x, double y, MapState mapState) {
    if (mapState.mapData == null) return null;

    String? nearestRoomId;
    double minDistance = double.infinity;

    for (final room in mapState.mapData!.rooms.values) {
      for (final rect in room.rectangles) {
        final centerX = rect.x + rect.width / 2;
        final centerY = rect.y + rect.height / 2;

        final distance = _calculateDistance(x, y, centerX, centerY);

        if (distance < minDistance) {
          minDistance = distance;
          nearestRoomId = room.guid;
        }
      }
    }

    return nearestRoomId;
  }

  double _calculateDistance(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return dx * dx + dy * dy;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapCubit, MapState>(
      builder: (context, mapState) {
        return BlocBuilder<DevicesCubit, List<Device>>(
          builder: (context, devices) {
            final roomDevices =
                devices.where((device) {
                  return _getDeviceRoom(device, mapState) == roomId;
                }).toList();

            print('Room devices: ${roomDevices.length}');

            final filteredDevices =
                roomDevices.where((device) {
                  return device.findAttribute<LightAttribute>() != null ||
                      device.findAttribute<SwitchAttribute>() != null ||
                      device.findAttribute<SensorAttribute>() != null ||
                      device.findAttribute<CoverAttribute>() != null ||
                      device.findAttribute<VacuumAttribute>() != null;
                }).toList();

            if (filteredDevices.isEmpty) {
              return const Center(child: Text('No devices in this room'));
            }

            return DeviceGrid(devices: filteredDevices);
          },
        );
      },
    );
  }
}

class DeviceGrid extends StatelessWidget {
  final List<Device> devices;

  const DeviceGrid({super.key, required this.devices});

  bool _isCompact(Device device) {
    return device.findAttribute<SensorAttribute>() != null || device.findAttribute<BinarySensorAttribute>() != null;
  }

  List<dynamic> _groupDevices() {
    final List<dynamic> grouped = [];
    int i = 0;

    while (i < devices.length) {
      final device = devices[i];

      if (_isCompact(device)) {
        if (i + 1 < devices.length && _isCompact(devices[i + 1])) {
          grouped.add([device, devices[i + 1]]);
          i += 2;
        } else {
          grouped.add([device]);
          i += 1;
        }
      } else {
        grouped.add(device);
        i += 1;
      }
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedDevices = _groupDevices();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.0,
            crossAxisSpacing: 0,
            mainAxisSpacing: 0,
          ),
          itemCount: groupedDevices.length,
          itemBuilder: (context, index) {
            final item = groupedDevices[index];

            if (item is List<Device>) {
              return Column(mainAxisAlignment: MainAxisAlignment.start, children: item.map((device) => Expanded(child: DeviceCard(device: device))).toList());
            } else {
              return DeviceCard(device: item as Device);
            }
          },
        );
      },
    );
  }
}

class DeviceCard extends StatelessWidget {
  final Device device;

  const DeviceCard({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final vacuum = device.findAttribute<VacuumAttribute>();
    if (vacuum != null) {
      return VacuumCard(device: device, vacuum: vacuum);
    }

    final light = device.findAttribute<LightAttribute>();
    if (light != null) {
      return LightCard(device: device, light: light);
    }

    final cover = device.findAttribute<CoverAttribute>();
    if (cover != null) {
      return CoverCard(device: device, cover: cover);
    }

    final switchAttr = device.findAttribute<SwitchAttribute>();
    if (switchAttr != null) {
      return SwitchCard(device: device, switchAttr: switchAttr);
    }

    final binarySensorAttr = device.findAttribute<BinarySensorAttribute>();

    if (binarySensorAttr != null) {
      return BinarySensorCard(device: device, sensor: binarySensorAttr);
    }

    final sensorNonBattery = findSensorAttributeExcept([SensorDeviceClass.battery, SensorDeviceClass.voltage]);

    if (sensorNonBattery != null) {
      return SensorCard(device: device);
    }

    final sensor = device.findAttribute<SensorAttribute>();
    if (sensor != null) {
      return SensorCard(device: device);
    }

    return const SizedBox();
  }

  SensorAttribute? findSensorAttributeExcept(List<SensorDeviceClass> deviceClass) {
    for (final attribute in device.attributes) {
      if (attribute is SensorAttribute && !deviceClass.contains(attribute.deviceClass)) return attribute;
    }
    return null;
  }
}
