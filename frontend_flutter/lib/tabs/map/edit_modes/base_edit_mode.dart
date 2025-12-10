import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend_flutter/cubits/devices_cubit.dart';
import 'package:dart_common/dart_common.dart';
import '../../../cubits/display_settings_cubit.dart';
import '../painters/base_map_painter.dart';

abstract class BaseEditMode extends StatelessWidget {
  final MapData mapData;
  final double iconScale;
  final bool drawBase;

  const BaseEditMode({super.key, required this.mapData, required this.iconScale, this.drawBase = true});

  String get modeName;
  IconData get modeIcon;
  String get modeDescription;
  Color get modeColor => Colors.orange;

  bool get enableMapPanning => true;
  bool get hideOriginalWalls => false;

  double get imageWidth => mapData.imageDimensions?.width.toDouble() ?? 0.0;
  double get imageHeight => mapData.imageDimensions?.height.toDouble() ?? 0.0;
  double get offsetX => mapData.imageDimensions?.left.toDouble() ?? 0.0;
  double get offsetY => mapData.imageDimensions?.top.toDouble() ?? 0.0;

  Offset localToMapCoordinates(Offset localPosition) {
    final x = (localPosition.dx + offsetX) * 50;
    final y = (imageHeight - localPosition.dy + offsetY) * 50;
    return Offset(x, y);
  }

  Offset mapToLocalCoordinates(double mapX, double mapY) {
    final x = (mapX / 50.0) - offsetX;
    final y = imageHeight - ((mapY / 50.0) - offsetY);
    return Offset(x, y);
  }

  void handleMapTap(BuildContext context, Offset position) {}
  void handleMapLongPress(BuildContext context, Offset position) {}
  void handleMapPanStart(BuildContext context, DragStartDetails details) {}
  void handleMapPanUpdate(BuildContext context, DragUpdateDetails details) {}
  void handleMapPanEnd(BuildContext context, DragEndDetails details) {}

  void onHover(BuildContext context, PointerHoverEvent event) {}
  void onHoverExit(BuildContext context) {}

  List<CustomPainter> getMapPainters(BuildContext context, double imageWidth, double imageHeight, DisplaySettings settings) {
    return [BaseMapPainter(mapData: mapData, imageWidth: imageWidth, imageHeight: imageHeight, displaySettings: settings)];
  }

  Widget buildEditOverlay(BuildContext context, double displayWidth, double displayHeight, double currentScale) {
    return SizedBox.shrink();
  }

  Widget buildUiOverlay(BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return _BaseEditModeWrapper(mapData: mapData, iconScale: iconScale, drawBase: drawBase, child: this);
  }
}

class _BaseEditModeWrapper extends StatefulWidget {
  final MapData mapData;
  final double iconScale;
  final bool drawBase;
  final BaseEditMode child;

  const _BaseEditModeWrapper({required this.mapData, required this.iconScale, required this.drawBase, required this.child});

  @override
  State<_BaseEditModeWrapper> createState() => _BaseEditModeWrapperState();
}

class _BaseEditModeWrapperState extends State<_BaseEditModeWrapper> {
  final transformationController = TransformationController();

  @override
  void dispose() {
    transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devices = context.watch<DevicesCubit>().state;
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final imageWidth = widget.child.imageWidth;
        final imageHeight = widget.child.imageHeight;
        final aspectRatio = imageWidth / imageHeight;

        double displayWidth, displayHeight;
        if (screenWidth / screenHeight > aspectRatio) {
          displayHeight = screenHeight;
          displayWidth = screenHeight * aspectRatio;
        } else {
          displayWidth = screenWidth;
          displayHeight = screenWidth / aspectRatio;
        }

        return Stack(
          children: [
            InteractiveViewer(
              transformationController: transformationController,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              minScale: 0.5,
              maxScale: 8.0,
              panEnabled: widget.child.enableMapPanning,
              scaleEnabled: true,
              child: Center(
                child: SizedBox(
                  width: displayWidth,
                  height: displayHeight,
                  child: GestureDetector(
                    onTapUp: (details) => widget.child.handleMapTap(context, details.localPosition),
                    onLongPressStart: (details) => widget.child.handleMapLongPress(context, details.localPosition),
                    onPanStart: (details) => widget.child.handleMapPanStart(context, details),
                    onPanUpdate: (details) => widget.child.handleMapPanUpdate(context, details),
                    onPanEnd: (details) => widget.child.handleMapPanEnd(context, details),
                    child: MouseRegion(
                      onHover: (event) => widget.child.onHover(context, event),
                      onExit: (_) => widget.child.onHoverExit(context),
                      child: BlocBuilder<DisplaySettingsCubit, DisplaySettings>(
                        builder: (context, displaySettings) {
                          return Stack(
                            children: [
                              ...widget.child.getMapPainters(context, imageWidth, imageHeight, displaySettings).map((p) {
                                return CustomPaint(size: Size(displayWidth, displayHeight), painter: p);
                              }),
                              AnimatedBuilder(
                                animation: transformationController,
                                builder: (context, child) {
                                  final currentScale = transformationController.value.getMaxScaleOnAxis();
                                  return widget.child.buildEditOverlay(context, displayWidth, displayHeight, currentScale);
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            widget.child.buildUiOverlay(context),
          ],
        );
      },
    );
  }
}
