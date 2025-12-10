import 'package:dart_common/common/device.dart';
import 'package:dart_common/common/thing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend_flutter/cubits/display_settings_cubit.dart';
import 'package:frontend_flutter/tabs/devices/device_icon_utils.dart';

class ThingMapIcon extends StatelessWidget {
  final double x;
  final double y;
  final double iconScale;
  final double currentScale;
  final Thing thing;
  final void Function(DragUpdateDetails)? onPanUpdate;
  final void Function()? onLongPress;

  const ThingMapIcon({
    super.key,
    required this.x,
    required this.y,
    required this.iconScale,
    required this.currentScale,
    required this.thing,
    this.onPanUpdate,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final displaySettings = context.watch<DisplaySettingsCubit>().state;

    return Positioned(
      left: x,
      top: y,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Transform.scale(
          scale: iconScale / currentScale,
          child: GestureDetector(
            onPanUpdate: onPanUpdate,
            onLongPress: onLongPress,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  thing is Device ? DeviceIconUtils.getDeviceIcon(thing as Device) : Icons.person,
                  color: thing is Device ? DeviceIconUtils.getDeviceColor(thing as Device) : Colors.blueGrey,
                  size: 24,
                ),
                const SizedBox(height: 2),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: thing.isAutoLocation ? Colors.blue : Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
                if (displaySettings.showDeviceLabels) ...[
                  const SizedBox(height: 2),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 60),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      thing.name,
                      style: const TextStyle(color: Colors.white, fontSize: 9),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
