import 'package:dart_common/common/attributes.dart';
import 'package:dart_common/common/commands.dart';
import 'package:dart_common/common/device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend_flutter/cubits/devices_cubit.dart';
import 'package:frontend_flutter/tabs/devices/device_icon_utils.dart';
import 'package:frontend_flutter/cards/plain.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class LightCard extends StatelessWidget {
  final Device device;
  final LightAttribute light;

  const LightCard({super.key, required this.device, required this.light});

  String _getState() {
    return light.state == 'on' ? 'On' : 'Off';
  }

  Color _getColor(BuildContext context) {
    if (_getState() == 'On') {
      if (light.rgbColor != null) {
        return HSVColor.fromColor(DeviceIconUtils.fromRGBA(light.rgbColor)!).withSaturation(0.5).toColor();
      }
      return DeviceIconUtils.getDeviceColor(device);
    }

    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  IconData _getIcon() {
    if (device.icon != null) {
      return DeviceIconUtils.iconMap[device.icon] ?? Icons.lightbulb;
    }
    return Icons.lightbulb;
  }

  Future<void> _toggleLight(BuildContext context) async {
    final newState = light.state == 'on' ? 'off' : 'on';
    final command = SwitchCommand(guid: device.id, attributeGuid: light.guid, state: newState);

    try {
      await context.read<DevicesCubit>().sendDeviceCommand(command);
    } catch (e) {
      // ignore: use_build_context_synchronously
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _openColorPicker(BuildContext context) async {
    final devices = context.read<DevicesCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return BlocProvider.value(
          value: devices,
          child: LightControlSheet(device: device, light: light),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onLongPress: () => _openColorPicker(context),
      child: PlainCard(
        icon: _getIcon(),
        iconColor: colorScheme.onSurface,
        text: device.name,
        textColor: colorScheme.onSurface,
        subText: _getState(),
        subTextColor: colorScheme.onSurfaceVariant,
        color: _getColor(context),
        compact: false,
        action: () => _toggleLight(context),
      ),
    );
  }
}

class LightControlSheet extends StatefulWidget {
  final Device device;
  final LightAttribute light;

  const LightControlSheet({super.key, required this.device, required this.light});

  @override
  State<LightControlSheet> createState() => _LightControlSheetState();
}

class _LightControlSheetState extends State<LightControlSheet> {
  late Color _selectedColor;
  late double _brightness;

  @override
  void initState() {
    super.initState();
    _selectedColor = DeviceIconUtils.fromRGBA(widget.light.rgbColor) ?? Colors.white;
    _brightness = (widget.light.brightness ?? 255) / 255.0;
  }

  Future<void> _setColor(Color color) async {
    final command = ColorCommand(
      guid: widget.device.id,
      attributeGuid: widget.light.guid,
      rgbColor: [color.red, color.green, color.blue],
    );

    try {
      await context.read<DevicesCubit>().sendDeviceCommand(command);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _setBrightness(double brightness) async {
    final brightnessValue = (brightness * 255).round();
    final command = BrightnessCommand(
      guid: widget.device.id,
      attributeGuid: widget.light.guid,
      brightness: brightnessValue,
    );

    try {
      await context.read<DevicesCubit>().sendDeviceCommand(command);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.device.name,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Яскравість', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.brightness_low, color: colorScheme.onSurfaceVariant),
              Expanded(
                child: Slider(
                  value: _brightness,
                  onChanged: (value) {
                    setState(() => _brightness = value);
                  },
                ),
              ),
              Icon(Icons.brightness_high, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              SizedBox(
                width: 50,
                child: Text('${(_brightness * 100).round()}%', style: TextStyle(color: colorScheme.onSurfaceVariant)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _setBrightness(_brightness),
              icon: const Icon(Icons.check),
              label: const Text('Застосувати яскравість'),
            ),
          ),
          const SizedBox(height: 24),
          Text('Колір', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) {
                setState(() => _selectedColor = color);
              },
              pickerAreaHeightPercent: 0.8,
              displayThumbColor: true,
              enableAlpha: false,
              labelTypes: const [],
              paletteType: PaletteType.hueWheel,
              portraitOnly: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _setColor(_selectedColor),
              icon: const Icon(Icons.check),
              label: const Text('Застосувати колір'),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
        ],
      ),
    );
  }
}
