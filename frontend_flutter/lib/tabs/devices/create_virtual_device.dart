import 'package:flutter/material.dart';
import 'package:frontend_flutter/bloc.dart';
import 'package:frontend_flutter/cubits/devices_cubit.dart';

class CreateVirtualDeviceForm extends StatefulWidget {
  final double x;
  final double y;

  const CreateVirtualDeviceForm({super.key, required this.x, required this.y});

  @override
  State<CreateVirtualDeviceForm> createState() => _CreateVirtualDeviceFormState();
}

class _CreateVirtualDeviceFormState extends State<CreateVirtualDeviceForm> {
  late TextEditingController nameController;
  String selectedIcon = 'place';
  Color selectedColor = const Color(0xFF2196F3);
  bool isLoading = false;

  static const List<MapEntry<String, IconData>> availableIcons = [
    MapEntry('place', Icons.place),
    MapEntry('location_on', Icons.location_on),
    MapEntry('flag', Icons.flag),
    MapEntry('star', Icons.star),
    MapEntry('favorite', Icons.favorite),
    MapEntry('push_pin', Icons.push_pin),
    MapEntry('radio_button_checked', Icons.radio_button_checked),
    MapEntry('trip_origin', Icons.trip_origin),
  ];

  static const List<Color> availableColors = [
    Color(0xFF2196F3),
    Color(0xFF009688),
    Color(0xFF4CAF50),
    Color(0xFFFFC107),
    Color(0xFFFF9800),
    Color(0xFFFF5722),
    Color(0xFFF44336),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF3F51B5),
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: 'Virtual Point');
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _createDevice() async {
    setState(() {
      isLoading = true;
    });

    try {
      final colorHex =
          '#${(selectedColor.r * 255).round().toRadixString(16).padLeft(2, '0')}'
          '${(selectedColor.g * 255).round().toRadixString(16).padLeft(2, '0')}'
          '${(selectedColor.b * 255).round().toRadixString(16).padLeft(2, '0')}';

      await context.read<DevicesCubit>().createVirtualDevice(nameController.text, widget.x, widget.y, icon: selectedIcon, color: colorHex);

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
              Icon(Icons.add_location, color: Colors.blue, size: 32),
              const SizedBox(width: 16),
              Expanded(child: Text('Create Virtual Point', style: Theme.of(context).textTheme.headlineSmall)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
            ],
          ),
          const SizedBox(height: 24),
          TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Point Name', border: OutlineInputBorder())),
          const SizedBox(height: 24),
          Text('Icon', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                availableIcons.map((icon) {
                  final isSelected = selectedIcon == icon.key;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedIcon = icon.key;
                      });
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.withValues(alpha: 0.2) : null,
                        border: Border.all(color: isSelected ? Colors.blue : Colors.grey.withValues(alpha: 0.3), width: isSelected ? 2 : 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon.value, color: isSelected ? Colors.blue : Colors.grey, size: 24),
                    ),
                  );
                }).toList(),
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
                onPressed: isLoading ? null : _createDevice,
                child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
