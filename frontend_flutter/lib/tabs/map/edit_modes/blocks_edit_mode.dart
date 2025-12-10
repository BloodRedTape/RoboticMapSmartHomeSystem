import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend_flutter/cubits/display_settings_cubit.dart';
import 'package:dart_common/dart_common.dart';
import 'base_edit_mode.dart';
import '../../../cubits/map_blocks_cubit.dart';
import '../painters/blocks_overlay_painter.dart';

enum BlockEditTool { draw, erase, wall }

class BlocksEditState {
  final BlockEditTool currentTool;
  final Set<String> currentStroke;
  final Offset? hoverPosition;
  final BlockPoint? wallStartPoint;

  BlocksEditState({this.currentTool = BlockEditTool.draw, Set<String>? currentStroke, this.hoverPosition, this.wallStartPoint})
    : currentStroke = currentStroke ?? {};

  BlocksEditState copyWith({
    BlockEditTool? currentTool,
    Set<String>? currentStroke,
    Offset? hoverPosition,
    BlockPoint? wallStartPoint,
    bool clearHover = false,
    bool clearWallStart = false,
  }) {
    return BlocksEditState(
      currentTool: currentTool ?? this.currentTool,
      currentStroke: currentStroke ?? this.currentStroke,
      hoverPosition: clearHover ? null : (hoverPosition ?? this.hoverPosition),
      wallStartPoint: clearWallStart ? null : (wallStartPoint ?? this.wallStartPoint),
    );
  }
}

class BlocksEditCubit extends Cubit<BlocksEditState> {
  BlocksEditCubit() : super(BlocksEditState());

  void setTool(BlockEditTool tool) {
    emit(state.copyWith(currentTool: tool, clearWallStart: true));
  }

  void setHoverPosition(Offset? position) {
    if (position == null) {
      emit(state.copyWith(clearHover: true));
    } else {
      emit(state.copyWith(hoverPosition: position));
    }
  }

  void setWallStartPoint(BlockPoint? point) {
    if (point == null) {
      emit(state.copyWith(clearWallStart: true));
    } else {
      emit(state.copyWith(wallStartPoint: point));
    }
  }

  void clearStroke() {
    emit(state.copyWith(currentStroke: {}));
  }

  void addToStroke(String key) {
    if (!state.currentStroke.contains(key)) {
      final newStroke = Set<String>.from(state.currentStroke)..add(key);
      emit(state.copyWith(currentStroke: newStroke));
    }
  }
}

class BlocksEditMode extends StatelessWidget {
  final MapData mapData;
  final double iconScale;

  const BlocksEditMode({super.key, required this.mapData, required this.iconScale});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        context.read<MapBlocksCubit>().loadBlocks();
        return BlocksEditCubit();
      },
      child: BlocBuilder<BlocksEditCubit, BlocksEditState>(
        builder: (context, editState) {
          return BlocBuilder<MapBlocksCubit, List<BlockPoint>>(
            builder: (context, blocks) {
              return _BlocksEditModeContent(mapData: mapData, iconScale: iconScale, blocks: blocks, editState: editState);
            },
          );
        },
      ),
    );
  }
}

class _BlocksEditModeContent extends BaseEditMode {
  final List<BlockPoint> blocks;
  final BlocksEditState editState;

  const _BlocksEditModeContent({super.key, required super.mapData, required super.iconScale, required this.blocks, required this.editState})
    : super(drawBase: false);

  @override
  String get modeName => 'Edit Blocks';

  @override
  IconData get modeIcon => Icons.grid_on;

  @override
  String get modeDescription => 'Draw and erase map blocks';

  @override
  bool get enableMapPanning => false;

  @override
  bool get hideOriginalWalls => true;

  @override
  void handleMapTap(BuildContext context, Offset position) {
    final mapX = position.dx.round();
    final mapY = (imageHeight - position.dy).round();
    final cubit = context.read<BlocksEditCubit>();
    final mapBlocksCubit = context.read<MapBlocksCubit>();

    if (editState.currentTool == BlockEditTool.draw) {
      mapBlocksCubit.addBlock(BlockPoint(x: mapX, y: mapY));
    } else if (editState.currentTool == BlockEditTool.erase) {
      mapBlocksCubit.removeBlock(BlockPoint(x: mapX, y: mapY));
    } else if (editState.currentTool == BlockEditTool.wall) {
      if (editState.wallStartPoint == null) {
        cubit.setWallStartPoint(BlockPoint(x: mapX, y: mapY));
      } else {
        _drawLine(context, editState.wallStartPoint!, BlockPoint(x: mapX, y: mapY));
        cubit.setWallStartPoint(null);
      }
    }
  }

  @override
  void handleMapPanUpdate(BuildContext context, DragUpdateDetails details) {
    final cubit = context.read<BlocksEditCubit>();

    if (editState.currentTool == BlockEditTool.wall) {
      cubit.setHoverPosition(details.localPosition);
      return;
    }

    final localPos = details.localPosition;
    final mapX = localPos.dx.round();
    final mapY = (imageHeight - localPos.dy).round();
    final key = '$mapX,$mapY';

    if (editState.currentStroke.contains(key)) return;
    cubit.addToStroke(key);

    final mapBlocksCubit = context.read<MapBlocksCubit>();
    if (editState.currentTool == BlockEditTool.draw) {
      mapBlocksCubit.addBlock(BlockPoint(x: mapX, y: mapY));
    } else if (editState.currentTool == BlockEditTool.erase) {
      mapBlocksCubit.removeBlock(BlockPoint(x: mapX, y: mapY));
    }
  }

  @override
  void handleMapPanEnd(BuildContext context, DragEndDetails details) {
    context.read<BlocksEditCubit>().clearStroke();
  }

  void _drawLine(BuildContext context, BlockPoint start, BlockPoint end) {
    final dx = (end.x - start.x).abs();
    final dy = (end.y - start.y).abs();
    final sx = start.x < end.x ? 1 : -1;
    final sy = start.y < end.y ? 1 : -1;
    var err = dx - dy;

    var x = start.x;
    var y = start.y;
    final points = <BlockPoint>[];

    while (true) {
      points.add(BlockPoint(x: x, y: y));
      if (x == end.x && y == end.y) break;

      final e2 = 2 * err;
      if (e2 > -dy) {
        err -= dy;
        x += sx;
      }
      if (e2 < dx) {
        err += dx;
        y += sy;
      }
    }

    context.read<MapBlocksCubit>().addBlocks(points);
  }

  @override
  List<CustomPainter> getMapPainters(BuildContext context, double imageWidth, double imageHeight, DisplaySettings settings) {
    return [
      BlocksOverlayPainter(
        blocks: blocks,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        offsetX: offsetX,
        offsetY: offsetY,
        currentTool: editState.currentTool,
        hoverPosition: editState.hoverPosition,
        wallStartPoint: editState.wallStartPoint,
      ),
    ];
  }

  @override
  void onHover(BuildContext context, PointerHoverEvent event) {
    context.read<BlocksEditCubit>().setHoverPosition(event.localPosition);
  }

  @override
  void onHoverExit(BuildContext context) {
    context.read<BlocksEditCubit>().setHoverPosition(null);
  }

  @override
  Widget buildUiOverlay(BuildContext context) {
    final cubit = context.read<BlocksEditCubit>();
    final mapBlocksCubit = context.read<MapBlocksCubit>();

    return Positioned(
      bottom: 80,
      left: 20,
      child: Column(
        children: [
          FloatingActionButton(
            heroTag: 'draw',
            backgroundColor: editState.currentTool == BlockEditTool.draw ? Colors.blue : Colors.grey,
            onPressed: () => cubit.setTool(BlockEditTool.draw),
            child: const Icon(Icons.brush),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'wall',
            backgroundColor: editState.currentTool == BlockEditTool.wall ? Colors.blue : Colors.grey,
            onPressed: () => cubit.setTool(BlockEditTool.wall),
            child: const Icon(Icons.show_chart),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'erase',
            backgroundColor: editState.currentTool == BlockEditTool.erase ? Colors.red : Colors.grey,
            onPressed: () => cubit.setTool(BlockEditTool.erase),
            child: const Icon(Icons.cleaning_services),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'save',
            backgroundColor: Colors.green,
            onPressed: () async {
              final success = await mapBlocksCubit.saveBlocks();
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Blocks saved: ${mapBlocksCubit.state.length}'), duration: Duration(seconds: 1)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save blocks')));
                }
              }
            },
            child: const Icon(Icons.save),
          ),
        ],
      ),
    );
  }
}
