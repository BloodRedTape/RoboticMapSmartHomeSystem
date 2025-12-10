import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend_flutter/cubits/devices_cubit.dart';
import 'package:frontend_flutter/cubits/humans_cubit.dart';
import 'package:frontend_flutter/tabs/map/painters/base_map_painter.dart';
import 'package:frontend_flutter/tabs/map/painters/paths_painter.dart';
import 'package:frontend_flutter/tabs/map/thing_map_icon.dart';
import '../../../cubits/display_settings_cubit.dart';
import 'base_edit_mode.dart';
import '../../devices/device_icon_utils.dart';

class ViewMode extends BaseEditMode {
  ViewMode({super.key, required super.mapData, required super.iconScale});

  @override
  String get modeName => 'View';

  @override
  IconData get modeIcon => Icons.visibility;

  @override
  String get modeDescription => 'View map and devices';

  @override
  List<CustomPainter> getMapPainters(BuildContext context, double imageWidth, double imageHeight, DisplaySettings settings) {
    return [
      BaseMapPainter(mapData: mapData, imageWidth: imageWidth, imageHeight: imageHeight, displaySettings: settings),
      PathsPainter(
        mapData: mapData,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        deviceList: context.read<DevicesCubit>().state,
        displaySettings: settings,
      ),
    ];
  }

  @override
  Widget buildEditOverlay(BuildContext context, double displayWidth, double displayHeight, double currentScale) {
    final devices = context.watch<DevicesCubit>().state;
    final displaySettings = context.watch<DisplaySettingsCubit>().state;

    return Stack(
      children: [
        ...devices.where((d) => d.hasLocation && !d.hidden).map((device) {
          final x = (device.x! / 50) - offsetX;
          final y = imageHeight - ((device.y! / 50) - offsetY);
          return ThingMapIcon(currentScale: currentScale, x: x, y: y, iconScale: iconScale, thing: device);
        }),
        HumansView(imageHeight: imageHeight, iconScale: iconScale, currentScale: currentScale, offsetX: offsetX, offsetY: offsetY),
      ],
    );
  }
}

class HumansView extends StatelessWidget {
  final double imageHeight;
  final double iconScale;
  final double currentScale;
  final double offsetX;
  final double offsetY;

  const HumansView({super.key, required this.imageHeight, required this.iconScale, required this.currentScale, required this.offsetX, required this.offsetY});

  @override
  Widget build(BuildContext context) {
    final humans = context.watch<HumansCubit>().state;
    final displaySettings = context.watch<DisplaySettingsCubit>().state;

    return Stack(
      children: [
        ...humans.map((human) {
          final x = (human.x / 50) - offsetX;
          final y = imageHeight - ((human.y / 50) - offsetY);

          return ThingMapIcon(currentScale: currentScale, x: x, y: y, iconScale: iconScale, thing: human);
        }),
      ],
    );
  }
}
