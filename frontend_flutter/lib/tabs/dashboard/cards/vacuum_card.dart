import 'package:dart_common/common/attributes.dart';
import 'package:dart_common/common/commands.dart';
import 'package:dart_common/common/device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend_flutter/cubits/devices_cubit.dart';
import 'package:frontend_flutter/tabs/devices/device_icon_utils.dart';
import 'package:frontend_flutter/cards/plain.dart';

class VacuumCard extends StatelessWidget {
  final Device device;
  final VacuumAttribute vacuum;

  const VacuumCard({super.key, required this.device, required this.vacuum});

  String _getMainText() {
    final parts = <String>[];

    if (vacuum.status != null && vacuum.status!.isNotEmpty) {
      parts.add(vacuum.status!);
    }

    if (vacuum.batteryLevel != null) {
      parts.add('${vacuum.batteryLevel}%');
    }

    return parts.isNotEmpty ? parts.join(' · ') : device.name;
  }

  String _getSubText() {
    final parts = <String>[];

    if (vacuum.fanSpeed != null && vacuum.fanSpeed!.isNotEmpty) {
      parts.add('Fan: ${vacuum.fanSpeed}');
    }

    return parts.isNotEmpty ? parts.join(' · ') : _getStateText();
  }

  String _getStateText() {
    switch (vacuum.state.toLowerCase()) {
      case 'cleaning':
        return 'Cleaning';
      case 'docked':
        return 'Docked';
      case 'returning':
        return 'Returning';
      case 'idle':
        return 'Idle';
      case 'paused':
        return 'Paused';
      case 'error':
        return 'Error';
      default:
        return vacuum.state;
    }
  }

  Color _getColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (vacuum.state.toLowerCase()) {
      case 'cleaning':
        return Colors.blue.shade300;
      case 'docked':
        return Colors.green.shade300;
      case 'returning':
        return Colors.orange.shade300;
      case 'error':
        return Colors.red.shade300;
      default:
        return colorScheme.surfaceContainerHighest;
    }
  }

  IconData _getIcon() {
    if (device.icon != null) {
      return DeviceIconUtils.iconMap[device.icon] ?? Icons.cleaning_services;
    }
    return Icons.cleaning_services;
  }

  Color? _getBatteryColor() {
    if (vacuum.batteryLevel == null) return null;

    if (vacuum.batteryLevel! <= 20) {
      return Colors.red;
    } else if (vacuum.batteryLevel! <= 50) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  IconData _getBatteryIcon() {
    if (vacuum.batteryLevel == null) return Icons.battery_unknown;

    if (vacuum.state.toLowerCase() == 'docked') {
      return Icons.battery_charging_full;
    }

    if (vacuum.batteryLevel! <= 20) {
      return Icons.battery_0_bar;
    } else if (vacuum.batteryLevel! <= 40) {
      return Icons.battery_2_bar;
    } else if (vacuum.batteryLevel! <= 60) {
      return Icons.battery_4_bar;
    } else if (vacuum.batteryLevel! <= 80) {
      return Icons.battery_5_bar;
    } else {
      return Icons.battery_full;
    }
  }

  Future<void> _toggleVacuum(BuildContext context) async {
    final newState = vacuum.state.toLowerCase() == 'cleaning' ? 'off' : 'on';
    final command = SwitchCommand(guid: device.id, attributeGuid: vacuum.guid, state: newState);

    try {
      await context.read<DevicesCubit>().sendDeviceCommand(command);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final batteryAction = vacuum.batteryLevel != null
        ? PlainAction(
            icon: _getBatteryIcon(),
            iconColor: _getBatteryColor(),
            onTap: () {},
          )
        : null;

    return PlainCard(
      icon: _getIcon(),
      iconColor: colorScheme.onSurface,
      text: _getMainText(),
      textColor: colorScheme.onSurface,
      subText: _getSubText(),
      subTextColor: colorScheme.onSurfaceVariant,
      color: _getColor(context),
      compact: false,
      action: () => _toggleVacuum(context),
      subAction: batteryAction,
    );
  }
}
