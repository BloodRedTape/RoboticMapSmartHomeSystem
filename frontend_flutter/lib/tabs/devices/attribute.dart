import 'package:dart_common/common/attributes.dart';
import 'package:dart_common/common/device.dart';
import 'package:flutter/material.dart';
import 'attribute_control.dart';

class DeviceAttributeWidget extends StatelessWidget {
  final Device device;
  final Attribute attribute;

  const DeviceAttributeWidget(this.device, this.attribute, {super.key});

  @override
  Widget build(BuildContext context) {
    final IconData icon = _getAttributeIcon(attribute.type);
    final String label = _getAttributeLabel(attribute.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            AttributeControl(device, attribute),
          ],
        ),
      ),
    );
  }

  IconData _getAttributeIcon(String type) {
    switch (type) {
      case 'light':
        return Icons.lightbulb;
      case 'camera':
        return Icons.videocam;
      case 'fan':
        return Icons.air;
      case 'switch':
        return Icons.power;
      case 'sensor':
        return Icons.sensors;
      case 'binary_sensor':
        return Icons.motion_photos_on;
      case 'climate':
        return Icons.thermostat;
      case 'lock':
        return Icons.lock;
      case 'cover':
        return Icons.window;
      case 'media_player':
        return Icons.speaker;
      case 'button':
        return Icons.radio_button_checked;
      case 'vacuum':
        return Icons.cleaning_services;
      default:
        return Icons.device_unknown;
    }
  }

  String _getAttributeLabel(String type) {
    switch (type) {
      case 'light':
        return 'Light';
      case 'camera':
        return 'Camera';
      case 'fan':
        return 'Fan';
      case 'switch':
        return 'Switch';
      case 'sensor':
        return 'Sensor';
      case 'binary_sensor':
        return 'Binary Sensor';
      case 'climate':
        return 'Climate';
      case 'lock':
        return 'Lock';
      case 'cover':
        return 'Cover';
      case 'media_player':
        return 'Media Player';
      case 'button':
        return 'Button';
      case 'vacuum':
        return 'Vacuum';
      default:
        return type;
    }
  }
}
