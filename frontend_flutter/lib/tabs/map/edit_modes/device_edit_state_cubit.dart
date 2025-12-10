import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend_flutter/cubits/devices_cubit.dart';

class DeviceEditState {
  final Map<String, Map<String, double>> pendingCoordinates;
  final bool isCreatingDevice;

  const DeviceEditState({this.pendingCoordinates = const {}, this.isCreatingDevice = false});

  DeviceEditState copyWith({Map<String, Map<String, double>>? pendingCoordinates, bool? isCreatingDevice}) {
    return DeviceEditState(
      pendingCoordinates: pendingCoordinates ?? this.pendingCoordinates,
      isCreatingDevice: isCreatingDevice ?? this.isCreatingDevice,
    );
  }
}

class DeviceEditStateCubit extends Cubit<DeviceEditState> {
  DeviceEditStateCubit() : super(const DeviceEditState());

  void setPendingCoordinates(Map<String, Map<String, double>> coords) {
    emit(state.copyWith(pendingCoordinates: coords));
  }

  void clearPendingCoordinates() {
    emit(state.copyWith(pendingCoordinates: {}));
  }

  void toggleCreatingDevice() {
    emit(state.copyWith(isCreatingDevice: !state.isCreatingDevice));
  }

  Future<void> saveCoordinates(BuildContext context) async {
    final devicesCubit = context.read<DevicesCubit>();
    final pending = state.pendingCoordinates;
    if (pending.isEmpty) return;

    try {
      final devices = devicesCubit.allDevices;
      for (final entry in pending.entries) {
        final deviceId = entry.key;
        try {
          final device = devices.firstWhere((d) => d.id == deviceId);
          if (!device.isAutoLocation) {
            await devicesCubit.setDeviceCoordinates(device.id, entry.value['x']!, entry.value['y']!);
          }
        } catch (_) {}
      }
      clearPendingCoordinates();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device positions saved')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving positions: $e')));
    }
  }
}
