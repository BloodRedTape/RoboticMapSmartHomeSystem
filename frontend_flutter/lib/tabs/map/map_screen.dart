import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend_flutter/bloc.dart';
import 'package:frontend_flutter/services/websocket_service.dart';
import '../../cubits/map_cubit.dart';
import '../../cubits/devices_cubit.dart';
import '../../cubits/display_settings_cubit.dart';
import 'package:dart_common/dart_common.dart';
import 'map_settings_screen.dart';
import 'edit_modes/device_edit_mode.dart';
import 'edit_modes/blocks_edit_mode.dart';
import 'edit_modes/doors_edit_mode.dart';
import 'edit_modes/calibration_edit_mode.dart';
import 'package:frontend_flutter/tabs/map/edit_modes/device_edit_state_cubit.dart';
import 'edit_modes/view_mode.dart';

enum EditMode { none, devices, blocks, doors, calibration }

class MapUIState {
  final EditMode editMode;

  const MapUIState({this.editMode = EditMode.none});

  MapUIState copyWith({EditMode? editMode}) {
    return MapUIState(editMode: editMode ?? this.editMode);
  }
}

class MapUICubit extends Cubit<MapUIState> {
  MapUICubit() : super(const MapUIState());

  void setEditMode(EditMode mode) => emit(state.copyWith(editMode: mode));
}

class MapScreenWidget extends CubitProviderWidget<MapUICubit, MapUIState> {
  MapScreenWidget({super.key}) : super((_) => MapUICubit());

  IconData _getEditModeIcon(EditMode mode) {
    switch (mode) {
      case EditMode.devices:
        return Icons.edit_location;
      case EditMode.blocks:
        return Icons.grid_on;
      case EditMode.doors:
        return Icons.door_front_door;
      case EditMode.calibration:
        return Icons.camera_alt;
      case EditMode.none:
        return Icons.edit;
    }
  }

  String _getEditModeText(EditMode mode) {
    switch (mode) {
      case EditMode.devices:
        return 'Edit Mode - Drag devices';
      case EditMode.blocks:
        return 'Edit Mode - Draw/erase blocks';
      case EditMode.doors:
        return 'Edit Mode - Draw doors';
      case EditMode.calibration:
        return 'Calibration Mode - Map camera points';
      case EditMode.none:
        return 'Edit Mode';
    }
  }

  void _showEditModeMenu(BuildContext context, EditMode currentMode) {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text('Exit Edit Mode'),
                  enabled: currentMode != EditMode.none,
                  onTap: () async {
                    Navigator.pop(context);
                    context.read<MapUICubit>().setEditMode(EditMode.none);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.edit_location),
                  title: const Text('Edit Device Positions'),
                  selected: currentMode == EditMode.devices,
                  onTap: () async {
                    Navigator.pop(context);
                    context.read<MapUICubit>().setEditMode(EditMode.devices);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.grid_on),
                  title: const Text('Edit Blocks'),
                  selected: currentMode == EditMode.blocks,
                  onTap: () {
                    context.read<MapUICubit>().setEditMode(EditMode.blocks);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.door_front_door),
                  title: const Text('Edit Doors'),
                  selected: currentMode == EditMode.doors,
                  onTap: () {
                    context.read<MapUICubit>().setEditMode(EditMode.doors);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Calibrate Camera'),
                  selected: currentMode == EditMode.calibration,
                  onTap: () {
                    context.read<MapUICubit>().setEditMode(EditMode.calibration);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildMapWidget(BuildContext context, MapData mapData, MapUIState uiState) {
    return BlocBuilder<DevicesCubit, List<Device>>(
      builder: (context, deviceList) {
        return BlocBuilder<DisplaySettingsCubit, DisplaySettings>(
          builder: (context, displaySettings) {
            final iconScale = displaySettings.iconScale;
            switch (uiState.editMode) {
              case EditMode.devices:
                return BlocProvider(create: (_) => DeviceEditStateCubit(), child: DeviceEditMode(mapData: mapData, iconScale: iconScale));
              case EditMode.blocks:
                return BlocksEditMode(mapData: mapData, iconScale: iconScale);
              case EditMode.doors:
                return DoorsEditMode(mapData: mapData, iconScale: iconScale);
              case EditMode.calibration:
                return CalibrationEditMode(mapData: mapData, iconScale: iconScale);
              case EditMode.none:
                return ViewMode(mapData: mapData, iconScale: iconScale);
            }
          },
        );
      },
    );
  }

  @override
  Widget buildFromState(BuildContext context, MapUIState uiState) {
    final isConnected = context.watch<WebSocketService>().state;

    return BlocBuilder<MapCubit, MapState>(
      builder: (context, mapState) {
        if (mapState.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (mapState.error != null) {
          return Scaffold(body: Center(child: Text('Error: ${mapState.error}')));
        } else if (mapState.mapData == null) {
          return const Scaffold(body: Center(child: Text('No map data')));
        }

        final mapData = mapState.mapData!;
        return Scaffold(
          body: Stack(
            children: [
              _buildMapWidget(context, mapData, uiState),
              Positioned(
                top: 40,
                right: 20,
                child: Column(
                  children: [
                    FloatingActionButton(
                      heroTag: 'edit',
                      backgroundColor: uiState.editMode != EditMode.none ? Colors.orange : null,
                      onPressed: () => _showEditModeMenu(context, uiState.editMode),
                      child: Icon(uiState.editMode != EditMode.none ? Icons.edit : Icons.edit_location),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton(heroTag: 'refresh', onPressed: () => context.read<MapCubit>().loadMap(), child: const Icon(Icons.refresh)),
                    const SizedBox(height: 10),
                    FloatingActionButton(
                      heroTag: 'settings',
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MapSettingsScreen()));
                      },
                      child: const Icon(Icons.settings),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 40,
                left: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Icon(isConnected ? Icons.cloud_done : Icons.cloud_off, color: isConnected ? Colors.green : Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Text(isConnected ? 'Connected' : 'Disconnected', style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (uiState.editMode != EditMode.none) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            Icon(_getEditModeIcon(uiState.editMode), color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(_getEditModeText(uiState.editMode), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
