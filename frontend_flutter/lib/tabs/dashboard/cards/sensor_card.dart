import 'package:dart_common/common/attributes.dart';
import 'package:dart_common/common/device.dart';
import 'package:flutter/material.dart';
import 'package:frontend_flutter/tabs/devices/device_icon_utils.dart';
import 'package:frontend_flutter/cards/plain.dart';

abstract class BaseSensorCard extends StatelessWidget {
  final Device device;

  const BaseSensorCard({super.key, required this.device});

  List<SensorAttribute> getAllSensors() {
    final result = <SensorAttribute>[];

    for (final attr in device.attributes) {
      if (attr is SensorAttribute) {
        result.add(attr);
      }
    }

    return result;
  }
}

class SensorCard extends BaseSensorCard {
  const SensorCard({super.key, required super.device});

  SensorAttribute? _getPrimarySensor() {
    final sensors = getAllSensors();

    final primaryClasses = [
      SensorDeviceClass.temperature,
      SensorDeviceClass.humidity,
      SensorDeviceClass.illuminance,
      SensorDeviceClass.co2,
      SensorDeviceClass.pm25,
      SensorDeviceClass.pm10,
      SensorDeviceClass.power,
      SensorDeviceClass.energy,
      SensorDeviceClass.current,
      SensorDeviceClass.voltage,
      SensorDeviceClass.pressure,
      SensorDeviceClass.atmosphericPressure,
      SensorDeviceClass.moisture,
      SensorDeviceClass.aqi,
    ];

    for (final deviceClass in primaryClasses) {
      final sensor = sensors.where((s) => s.deviceClass == deviceClass).firstOrNull;
      if (sensor != null) return sensor;
    }

    return sensors.where((s) => s.deviceClass != SensorDeviceClass.battery &&
                                 s.deviceClass != SensorDeviceClass.signalStrength &&
                                 s.deviceClass != SensorDeviceClass.voltage).firstOrNull;
  }

  List<SensorAttribute> _getSecondarySensors() {
    final sensors = getAllSensors();
    final primary = _getPrimarySensor();

    return sensors.where((s) => s.guid != primary?.guid).toList();
  }

  String _getPrimaryState() {
    final primary = _getPrimarySensor();
    if (primary == null) return 'N/A';
    return '${primary.state}${primary.unit ?? ''}';
  }

  Color _getColor(BuildContext context) {
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  IconData _getIcon() {
    if (device.icon != null) {
      return DeviceIconUtils.iconMap[device.icon] ?? Icons.sensors;
    }
    return Icons.sensors;
  }

  String? _getTertiaryText() {
    final secondarySensors = _getSecondarySensors();
    if (secondarySensors.isEmpty) return null;

    final parts = <String>[];
    for (final sensor in secondarySensors) {
      String prefix = '';
      if (sensor.deviceClass == SensorDeviceClass.battery) {
        prefix = '🔋';
      } else if (sensor.deviceClass == SensorDeviceClass.signalStrength) {
        prefix = '📶';
      } else if (sensor.deviceClass == SensorDeviceClass.voltage) {
        prefix = '⚡';
      }
      parts.add('$prefix${sensor.state}${sensor.unit ?? ''}');
    }
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PlainCard(
      icon: _getIcon(),
      iconColor: colorScheme.onSurface,
      text: device.name,
      textColor: colorScheme.onSurface,
      subText: _getPrimaryState(),
      subTextColor: colorScheme.onSurfaceVariant,
      tertiaryText: _getTertiaryText(),
      tertiaryTextColor: colorScheme.onSurfaceVariant,
      color: _getColor(context),
      compact: true,
    );
  }
}

class BinarySensorCard extends StatelessWidget {
  final Device device;
  final BinarySensorAttribute sensor;

  const BinarySensorCard({super.key, required this.device, required this.sensor});

  String _getState() {
    return sensor.state;
  }

  Color _getColor(BuildContext context) {
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  IconData _getIcon() {
    if (device.icon != null) {
      return DeviceIconUtils.iconMap[device.icon] ?? Icons.sensors;
    }
    return Icons.sensors;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PlainCard(
      icon: _getIcon(),
      iconColor: colorScheme.onSurface,
      text: _getState(),
      textColor: colorScheme.onSurface,
      subText: _getState(),
      subTextColor: colorScheme.onSurfaceVariant,
      color: _getColor(context),
      compact: true,
    );
  }
}
