import 'package:dart_common/common/attributes.dart';
import 'package:dart_common/common/commands.dart';
import 'package:dart_common/common/device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend_flutter/cubits/devices_cubit.dart';
import 'package:frontend_flutter/tabs/devices/device_icon_utils.dart';
import 'package:frontend_flutter/cards/base.dart';
import 'package:frontend_flutter/consts.dart';

class CoverCard extends StatefulWidget {
  final Device device;
  final CoverAttribute cover;

  const CoverCard({super.key, required this.device, required this.cover});

  @override
  State<CoverCard> createState() => _CoverCardState();
}

class _CoverCardState extends State<CoverCard> {
  double? _tempPosition;
  bool _isDragging = false;

  int get _currentPosition => _isDragging ? _tempPosition!.round() : (widget.cover.position ?? 0);

  String _getPositionText() {
    return '$_currentPosition%';
  }

  Color _getColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (widget.cover.state == 'open' || _currentPosition > 50) {
      return colorScheme.primaryContainer;
    }
    return colorScheme.surfaceContainerHighest;
  }

  IconData _getIcon() {
    if (widget.device.icon != null) {
      return DeviceIconUtils.iconMap[widget.device.icon] ?? Icons.window;
    }
    if (widget.cover.state == 'open' || _currentPosition > 50) {
      return Icons.window;
    }
    return Icons.blinds_closed;
  }

  Future<void> _setPosition(int position) async {
    final command = CoverPositionCommand(guid: widget.device.id, attributeGuid: widget.cover.guid, position: position);

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

    return BaseCard(
      color: _getColor(context),
      child: Padding(
        padding: const EdgeInsets.all(cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(_getIcon(), color: colorScheme.onSurface, size: iconSize),
                Text(_getPositionText(), style: TextStyle(fontSize: secondaryTextSize, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FittedBox(
                    alignment: Alignment.bottomLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(widget.device.name, style: TextStyle(fontSize: primaryTextSize, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 8,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                    ),
                    child: Slider(
                      value: (_tempPosition ?? widget.cover.position ?? 0).toDouble(),
                      min: 0,
                      max: 100,
                      onChangeStart: (value) {
                        setState(() {
                          _isDragging = true;
                          _tempPosition = value;
                        });
                      },
                      onChanged: (value) {
                        setState(() {
                          _tempPosition = value;
                        });
                      },
                      onChangeEnd: (value) {
                        setState(() {
                          _isDragging = false;
                          _tempPosition = null;
                        });
                        _setPosition(value.round());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
