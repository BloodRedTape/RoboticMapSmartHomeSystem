// device_widget.dart
import 'package:dart_common/common/device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend_flutter/cubits/devices_cubit.dart';
import 'package:frontend_flutter/tabs/devices/attribute.dart';
import 'device_icon_utils.dart';

class DeviceWidget extends StatelessWidget {
  final Device device;

  const DeviceWidget({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(DeviceIconUtils.getDeviceIcon(device), color: DeviceIconUtils.getDeviceColor(device), size: 32),
        title: _buildTitle(context),
        subtitle: _buildSubtitle(),
        trailing: device.isOnline ? IconButton(icon: const Icon(Icons.send), onPressed: () => _showCommandDialog(context, device, 'turn_on')) : null,
        children: [_buildExpandedBody(context)],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(device.name)),
        if (device.integration == 'virtual')
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: SizedBox(
              width: 24,
              height: 24,
              child: IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.red),
                onPressed: () => _confirmDeleteDevice(context, device),
                tooltip: 'Delete virtual device',
                padding: EdgeInsets.zero,
                iconSize: 16,
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: (device.isOnline ? Colors.green : Colors.red).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
          child: Text(
            device.isOnline ? 'Online' : 'Offline',
            style: TextStyle(fontSize: 12, color: device.isOnline ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (device.hasLocation)
          Text('Position: (${device.x!.toStringAsFixed(1)}, ${device.y!.toStringAsFixed(1)})')
        else
          const Text('Position: Not set', style: TextStyle(color: Colors.orange)),
        Text('Integration: ${device.integration}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text('${device.attributes.length} attribute(s)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildExpandedBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Attributes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...device.attributes.map((attr) => DeviceAttributeWidget(device, attr)),
        ],
      ),
    );
  }

  Future<void> _sendCommand(BuildContext context, String deviceId, String command, dynamic value) async {
    try {
      await context.read<DevicesCubit>().sendCommand(deviceId, command, value);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _confirmDeleteDevice(BuildContext context, Device device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Delete Virtual Device'),
            content: Text('Are you sure you want to delete "${device.name}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<DevicesCubit>().deleteDevice(device.id);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Device "${device.name}" deleted')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting device: $e')));
      }
    }
  }

  void _showCommandDialog(BuildContext context, Device device, String command) {
    if (command == 'orient') {
      final xController = TextEditingController();
      final yController = TextEditingController();
      showDialog(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('Orient Device'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: xController, decoration: const InputDecoration(labelText: 'X coordinate'), keyboardType: TextInputType.number),
                  TextField(controller: yController, decoration: const InputDecoration(labelText: 'Y coordinate'), keyboardType: TextInputType.number),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                TextButton(
                  onPressed: () {
                    final x = double.tryParse(xController.text);
                    final y = double.tryParse(yController.text);
                    if (x != null && y != null) {
                      _sendCommand(context, device.id, command, {'x': x, 'y': y});
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Send'),
                ),
              ],
            ),
      );
    } else {
      _sendCommand(context, device.id, command, null);
    }
  }
}
