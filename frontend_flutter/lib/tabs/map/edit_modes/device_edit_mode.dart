import 'package:dart_common/common/device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend_flutter/tabs/devices/create_virtual_device.dart';
import 'package:frontend_flutter/tabs/devices/edit_device_info.dart';
import 'package:frontend_flutter/tabs/map/edit_modes/device_edit_state_cubit.dart';
import 'package:frontend_flutter/tabs/map/thing_map_icon.dart';
import '../../../cubits/devices_cubit.dart';
import 'base_edit_mode.dart';
import '../../devices/device_icon_utils.dart';

class DeviceEditMode extends BaseEditMode {
  const DeviceEditMode({super.key, required super.mapData, required super.iconScale});

  @override
  String get modeName => 'Device Positions';

  @override
  IconData get modeIcon => Icons.edit_location;

  @override
  String get modeDescription => 'Drag devices to move them';

  @override
  bool get enableMapPanning => true;

  @override
  void handleMapTap(BuildContext context, Offset position) {
    if (context.read<DeviceEditStateCubit>().state.isCreatingDevice) {
      final mapCoords = localToMapCoordinates(position);
      _showCreateDeviceDialog(context, mapCoords.dx, mapCoords.dy);
    }
  }

  @override
  Widget buildEditOverlay(BuildContext context, double dw, double dh, double currentScale) {
    final deviceEditState = context.watch<DeviceEditStateCubit>().state;
    final pendingCoordinates = deviceEditState.pendingCoordinates;
    final isCreatingDevice = deviceEditState.isCreatingDevice;
    final deviceList = context.watch<DevicesCubit>().state;

    return Stack(
      children:
          deviceList.where((d) => d.hasLocation && !d.hidden && !d.isAutoLocation).map((device) {
            final localCoords = pendingCoordinates[device.id];
            final deviceX = localCoords != null ? localCoords['x']! : device.x!;
            final deviceY = localCoords != null ? localCoords['y']! : device.y!;

            final x = (deviceX / 50) - offsetX;
            final y = imageHeight - ((deviceY / 50) - offsetY);

            return ThingMapIcon(
              currentScale: currentScale,
              x: x,
              y: y,
              iconScale: iconScale,
              thing: device,
              onPanUpdate: (details) {
                if (isCreatingDevice) return;

                final sensitivity = 200.0;
                final newX = deviceX + (details.delta.dx * imageWidth / dw * sensitivity);
                final newY = deviceY - (details.delta.dy * imageHeight / dh * sensitivity);

                final updatedCoords = Map<String, Map<String, double>>.from(pendingCoordinates);
                updatedCoords[device.id] = {'x': newX, 'y': newY};
                context.read<DeviceEditStateCubit>().setPendingCoordinates(updatedCoords);
              },
              onLongPress: () => _showDeviceEditDialog(context, device),
            );
          }).toList(),
    );
  }

  @override
  Widget buildUiOverlay(BuildContext context) {
    final deviceEditState = context.watch<DeviceEditStateCubit>().state;
    final pendingCoordinates = deviceEditState.pendingCoordinates;
    final isCreatingDevice = deviceEditState.isCreatingDevice;

    return Stack(
      children: [
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: 'create_virtual_device',
                onPressed: () => context.read<DeviceEditStateCubit>().toggleCreatingDevice(),
                backgroundColor: isCreatingDevice ? Colors.green : Colors.orange,
                child: Icon(isCreatingDevice ? Icons.check : Icons.add_location),
              ),
              if (pendingCoordinates.isNotEmpty) ...[
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'save_devices',
                  onPressed: () => context.read<DeviceEditStateCubit>().saveCoordinates(context),
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.save),
                ),
              ],
            ],
          ),
        ),
        if (isCreatingDevice)
          Positioned(
            left: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), borderRadius: BorderRadius.circular(8)),
              child: const Text('Tap on map to create virtual point', style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ),
      ],
    );
  }

  Future<void> _showCreateDeviceDialog(BuildContext context, double x, double y) async {
    final devices = context.read<DevicesCubit>();
    final result = await showDialog(
      context: context,
      builder:
          (ctx) => BlocProvider.value(
            value: context.read<DeviceEditStateCubit>(),
            child: BlocProvider.value(
              value: devices,
              child: Dialog(child: Container(width: 400, padding: const EdgeInsets.all(24), child: CreateVirtualDeviceForm(x: x, y: y))),
            ),
          ),
    );
    if (result == true && context.mounted) {
      context.read<DeviceEditStateCubit>().toggleCreatingDevice();
      await context.read<DevicesCubit>().refreshAll();
    }
  }

  Future<void> _showDeviceEditDialog(BuildContext context, Device device) async {
    final result = await showDialog(
      context: context,
      builder: (context) => Dialog(child: Container(width: 500, padding: const EdgeInsets.all(24), child: DeviceEditForm(device: device))),
    );
    if (result == true && context.mounted) {
      await context.read<DevicesCubit>().refreshAll();
    }
  }
}
