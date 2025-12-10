import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend_flutter/cubits/display_settings_cubit.dart';
import 'package:dart_common/dart_common.dart';
import 'base_edit_mode.dart';
import '../../../cubits/map_doors_cubit.dart';
import '../painters/doors_overlay_painter.dart';

class DoorsEditState {
  final MapPoint? doorStartPoint;
  final Offset? hoverPosition;

  DoorsEditState({this.doorStartPoint, this.hoverPosition});

  DoorsEditState copyWith({MapPoint? doorStartPoint, Offset? hoverPosition, bool clearDoorStartPoint = false, bool clearHoverPosition = false}) {
    return DoorsEditState(
      doorStartPoint: clearDoorStartPoint ? null : doorStartPoint ?? this.doorStartPoint,
      hoverPosition: clearHoverPosition ? null : hoverPosition ?? this.hoverPosition,
    );
  }
}

class DoorsEditCubit extends Cubit<DoorsEditState> {
  DoorsEditCubit() : super(DoorsEditState());

  void setDoorStartPoint(MapPoint? point) {
    if (point == null) {
      emit(state.copyWith(clearDoorStartPoint: true));
    } else {
      emit(state.copyWith(doorStartPoint: point));
    }
  }

  void setHoverPosition(Offset? position) {
    if (position == null) {
      emit(state.copyWith(clearHoverPosition: true));
    } else {
      emit(state.copyWith(hoverPosition: position));
    }
  }
}

class DoorsEditMode extends StatelessWidget {
  final MapData mapData;
  final double iconScale;

  const DoorsEditMode({super.key, required this.mapData, required this.iconScale});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        context.read<MapDoorsCubit>().loadDoors();
        return DoorsEditCubit();
      },
      child: BlocBuilder<DoorsEditCubit, DoorsEditState>(
        builder: (context, editState) {
          return BlocBuilder<MapDoorsCubit, List<Door>>(
            builder: (context, doors) {
              return _DoorsEditModeContent(mapData: mapData, iconScale: iconScale, doors: doors, editState: editState);
            },
          );
        },
      ),
    );
  }
}

class _DoorsEditModeContent extends BaseEditMode {
  final List<Door> doors;
  final DoorsEditState editState;

  const _DoorsEditModeContent({super.key, required super.mapData, required super.iconScale, required this.doors, required this.editState});

  @override
  String get modeName => 'Edit Doors';

  @override
  IconData get modeIcon => Icons.door_front_door;

  @override
  String get modeDescription => 'Draw doors between rooms';

  @override
  bool get enableMapPanning => false;

  @override
  bool get hideOriginalWalls => false;

  @override
  void handleMapTap(BuildContext context, Offset position) {
    final mapX = position.dx.round();
    final mapY = (imageHeight - position.dy).round();
    final cubit = context.read<DoorsEditCubit>();

    if (editState.doorStartPoint == null) {
      cubit.setDoorStartPoint(MapPoint(x: mapX.toDouble(), y: mapY.toDouble()));
    } else {
      final door = Door(x0: editState.doorStartPoint!.x.toInt(), y0: editState.doorStartPoint!.y.toInt(), x1: mapX, y1: mapY);
      context.read<MapDoorsCubit>().addDoor(door);
      cubit.setDoorStartPoint(null);
    }
  }

  @override
  void onHover(BuildContext context, PointerHoverEvent event) {
    context.read<DoorsEditCubit>().setHoverPosition(event.localPosition);
  }

  @override
  void onHoverExit(BuildContext context) {
    context.read<DoorsEditCubit>().setHoverPosition(null);
  }

  @override
  List<CustomPainter> getMapPainters(BuildContext context, double imageWidth, double imageHeight, DisplaySettings settings) {
    return super.getMapPainters(context, imageWidth, imageHeight, settings)..add(
      DoorsOverlayPainter(
        doors: doors,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        offsetX: offsetX,
        offsetY: offsetY,
        doorStartPoint: editState.doorStartPoint,
        hoverPosition: editState.hoverPosition,
      ),
    );
  }

  @override
  Widget buildUiOverlay(BuildContext context) {
    final mapDoorsCubit = context.read<MapDoorsCubit>();

    return Stack(
      children: [
        Positioned(
          bottom: 80,
          left: 20,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: 'save_doors',
                backgroundColor: Colors.green,
                onPressed: () async {
                  final success = await mapDoorsCubit.saveDoors();
                  if (context.mounted) {
                    if (success) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Doors saved: ${mapDoorsCubit.state.length}'), duration: const Duration(seconds: 1)));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save doors')));
                    }
                  }
                },
                child: const Icon(Icons.save),
              ),
            ],
          ),
        ),
        if (doors.isNotEmpty)
          Positioned(
            top: 200,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Doors: ${doors.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...List.generate(doors.length, (index) {
                    final door = doors[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text('${index + 1}. (${door.x0},${door.y0}) to (${door.x1},${door.y1})'),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 16),
                            color: Colors.red,
                            onPressed: () => mapDoorsCubit.removeDoor(index),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
