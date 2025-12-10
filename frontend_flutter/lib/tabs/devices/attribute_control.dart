import 'package:dart_common/common/attributes.dart';
import 'package:dart_common/common/commands.dart';
import 'package:dart_common/common/device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/devices_cubit.dart';

class AttributeControl extends StatelessWidget {
  final Device device;
  final Attribute attribute;

  const AttributeControl(this.device, this.attribute, {super.key});

  @override
  Widget build(BuildContext context) {
    if (attribute is SwitchAttribute) {
      return _buildSwitchControl(context, attribute as SwitchAttribute);
    } else if (attribute is LightAttribute) {
      return _buildLightControl(context, attribute as LightAttribute);
    } else if (attribute is VacuumAttribute) {
      return _buildVacuumControl(context, attribute as VacuumAttribute);
    } else {
      return _buildFieldsList(attribute);
    }
  }

  Widget _buildFieldsList(Attribute attribute) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          attribute.getFields().entries.map((entry) {
            if (entry.value != null) {
              return Padding(
                padding: const EdgeInsets.only(left: 28, top: 4),
                child: Row(
                  children: [
                    Text('${entry.key}: ', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Text('${entry.value}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }).toList(),
    );
  }

  Widget _buildSwitchControl(BuildContext context, SwitchAttribute attr) {
    final cubit = context.read<DevicesCubit>();
    final isOn = attr.state == 'on';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(padding: const EdgeInsets.only(left: 28), child: Text('State: ${attr.state}', style: const TextStyle(fontSize: 12))),
        Switch(
          value: isOn,
          onChanged: (value) {
            cubit.sendDeviceCommand(SwitchCommand(guid: device.id, attributeGuid: attr.guid, state: value ? 'on' : 'off'));
          },
        ),
      ],
    );
  }

  Widget _buildLightControl(BuildContext context, LightAttribute attr) {
    final cubit = context.read<DevicesCubit>();
    final isOn = attr.state == 'on';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(padding: const EdgeInsets.only(left: 28), child: Text('State: ${attr.state}', style: const TextStyle(fontSize: 12))),
            Switch(
              value: isOn,
              onChanged: (value) {
                cubit.sendDeviceCommand(SwitchCommand(guid: device.id, attributeGuid: attr.guid, state: value ? 'on' : 'off'));
              },
            ),
          ],
        ),
        if (attr.brightness != null && isOn) ...[
          Padding(padding: const EdgeInsets.only(left: 28, top: 8), child: Text('Brightness: ${attr.brightness}', style: const TextStyle(fontSize: 12))),
          Slider(
            value: (attr.brightness ?? 0).toDouble(),
            min: 0,
            max: 255,
            divisions: 255,
            onChanged: (value) {
              cubit.sendDeviceCommand(BrightnessCommand(guid: device.id, attributeGuid: attr.guid, brightness: value.toInt()));
            },
          ),
        ],
        if (attr.rgbColor != null && isOn) ...[
          Padding(
            padding: const EdgeInsets.only(left: 28, top: 8),
            child: Row(
              children: [
                Text('Color: ', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, attr.rgbColor![0], attr.rgbColor![1], attr.rgbColor![2]),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(onPressed: () => _showColorPicker(context, cubit, attr), child: const Text('Change color', style: TextStyle(fontSize: 12))),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showColorPicker(BuildContext context, DevicesCubit cubit, LightAttribute attr) {
    final colors = [Colors.red, Colors.green, Colors.blue, Colors.yellow, Colors.orange, Colors.purple, Colors.pink, Colors.cyan, Colors.white];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Color'),
            content: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  colors.map((color) {
                    return GestureDetector(
                      onTap: () {
                        cubit.sendDeviceCommand(
                          ColorCommand(guid: device.id, attributeGuid: attr.guid, rgbColor: [color.r.toInt(), color.g.toInt(), color.b.toInt()]),
                        );
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey)),
                      ),
                    );
                  }).toList(),
            ),
          ),
    );
  }

  Widget _buildVacuumControl(BuildContext context, VacuumAttribute attr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (attr.state.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 4),
            child: Row(
              children: [
                Text('State: ', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(attr.state, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        if (attr.status != null)
          Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 4),
            child: Row(
              children: [
                Text('Status: ', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(attr.status!, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        if (attr.batteryLevel != null)
          Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 4),
            child: Row(
              children: [
                Icon(Icons.battery_std, size: 16, color: _getBatteryColor(attr.batteryLevel!)),
                const SizedBox(width: 4),
                Text('${attr.batteryLevel}%', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        if (attr.fanSpeed != null)
          Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 4),
            child: Row(
              children: [
                Text('Fan Speed: ', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(attr.fanSpeed!, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
      ],
    );
  }

  Color _getBatteryColor(int level) {
    if (level > 60) return Colors.green;
    if (level > 30) return Colors.orange;
    return Colors.red;
  }
}
