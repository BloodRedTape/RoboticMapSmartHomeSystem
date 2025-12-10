import 'package:dart_common/common/device.dart';
import 'package:dart_common/common/thing.dart';
import 'package:flutter/material.dart';
import 'package:frontend_flutter/bloc.dart';
import 'package:frontend_flutter/cubits/devices_cubit.dart';
import 'package:frontend_flutter/tabs/devices/device_icon_utils.dart';

class DeviceEditForm extends StatefulWidget {
  final Device device;

  const DeviceEditForm({super.key, required this.device});

  @override
  State<DeviceEditForm> createState() => _DeviceEditFormState();
}

class _DeviceEditFormState extends State<DeviceEditForm> {
  late TextEditingController nameController;
  String? selectedIcon;
  Color? selectedColor;
  String? selectedIntegration;
  bool isLoading = false;

  List<String> availableIntegrations = IntegrationType.values.map((e) => e.value).toList();

  static final List<MapEntry<String, IconData>> availableIcons = DeviceIconUtils.iconMap.entries.toList();

  static const List<Color> availableColors = [
    Color(0xFF009688),
    Color(0xFF2196F3),
    Color(0xFF3F51B5),
    Color(0xFF9C27B0),
    Color(0xFFE91E63),
    Color(0xFFF44336),
    Color(0xFFFF5722),
    Color(0xFFFF9800),
    Color(0xFFFFC107),
    Color(0xFFFFEB3B),
    Color(0xFFCDDC39),
    Color(0xFF8BC34A),
    Color(0xFF4CAF50),
    Color(0xFF00BCD4),
    Color(0xFF607D8B),
    Color(0xFF9E9E9E),
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.device.name);
    selectedIcon = widget.device.icon;
    selectedIntegration = widget.device.integration.value;
    if (widget.device.color != null) {
      try {
        selectedColor = Color(int.parse(widget.device.color!.replaceFirst('#', '0xFF')));
      } catch (e) {
        selectedColor = null;
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  IconData? _getIconData(String? iconName) {
    if (iconName == null) return null;
    return DeviceIconUtils.iconMap[iconName];
  }

  Future<void> _saveChanges() async {
    setState(() {
      isLoading = true;
    });

    try {
      final colorHex =
          selectedColor != null
              ? '#${(selectedColor!.r * 255).round().toRadixString(16).padLeft(2, '0')}'
                  '${(selectedColor!.g * 255).round().toRadixString(16).padLeft(2, '0')}'
                  '${(selectedColor!.b * 255).round().toRadixString(16).padLeft(2, '0')}'
              : null;

      await context.read<DevicesCubit>().customizeDevice(
        widget.device.id,
        name: nameController.text,
        icon: selectedIcon,
        color: colorHex,
        integration: selectedIntegration,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getIconData(selectedIcon) ?? Icons.device_unknown, color: selectedColor ?? Colors.teal, size: 32),
              const SizedBox(width: 16),
              Expanded(child: Text('Edit Device', style: Theme.of(context).textTheme.headlineSmall)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
            ],
          ),
          const SizedBox(height: 24),
          TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Device Name', border: OutlineInputBorder())),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: selectedIntegration,
            decoration: const InputDecoration(labelText: 'Integration', border: OutlineInputBorder()),
            items:
                availableIntegrations.map((integration) {
                  return DropdownMenuItem(value: integration, child: Text(integration));
                }).toList(),
            onChanged: (value) {
              setState(() {
                selectedIntegration = value;
              });
            },
          ),
          const SizedBox(height: 24),
          Text('Icon', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Container(
            height: 200,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8, mainAxisSpacing: 8, crossAxisSpacing: 8),
              itemCount: availableIcons.length,
              itemBuilder: (context, index) {
                final icon = availableIcons[index];
                final isSelected = selectedIcon == icon.key;
                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedIcon = icon.key;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.withValues(alpha: 0.2) : null,
                      border: Border.all(color: isSelected ? Colors.blue : Colors.grey.withValues(alpha: 0.3), width: isSelected ? 2 : 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon.value, color: isSelected ? Colors.blue : Colors.grey, size: 24),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text('Color', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                availableColors.map((color) {
                  final isSelected = selectedColor == color;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: isSelected ? Colors.white : Colors.grey.withValues(alpha: 0.3), width: isSelected ? 4 : 2),
                        boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)] : null,
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: isLoading ? null : _saveChanges,
                child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
