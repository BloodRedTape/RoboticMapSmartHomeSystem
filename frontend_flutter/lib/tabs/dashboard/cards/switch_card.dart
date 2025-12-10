import 'package:dart_common/common/attributes.dart';
import 'package:dart_common/common/commands.dart';
import 'package:dart_common/common/device.dart' show Device;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend_flutter/cubits/devices_cubit.dart';
import 'package:frontend_flutter/tabs/devices/device_icon_utils.dart';
import 'package:frontend_flutter/cards/plain.dart';

class SwitchCard extends StatelessWidget {
  final Device device;
  final SwitchAttribute switchAttr;

  const SwitchCard({super.key, required this.device, required this.switchAttr});

  String _getState() {
    return switchAttr.state == 'on' ? 'On' : 'Off';
  }

  Color _getColor(BuildContext context) {
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  IconData _getIcon() {
    if (device.icon != null) {
      return DeviceIconUtils.iconMap[device.icon] ?? Icons.power;
    }
    return Icons.power;
  }

  Future<void> _toggleSwitch(BuildContext context) async {
    final newState = switchAttr.state == 'on' ? 'off' : 'on';
    final command = SwitchCommand(guid: device.id, attributeGuid: switchAttr.guid, state: newState);

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

    return PlainCard(
      icon: _getIcon(),
      iconColor: colorScheme.onSurface,
      text: device.name,
      textColor: colorScheme.onSurface,
      subText: _getState(),
      subTextColor: colorScheme.onSurfaceVariant,
      color: _getColor(context),
      compact: false,
      action: () => _toggleSwitch(context),
    );
  }
}
