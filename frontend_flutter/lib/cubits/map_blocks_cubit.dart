import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dart_common/dart_common.dart';

class MapBlocksCubit extends Cubit<List<BlockPoint>> {
  static const String baseUrl = 'http://localhost:5000/api';

  MapBlocksCubit() : super([]);

  Future<void> loadBlocks() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/map/blocks'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final blocks = data['blocks'] as List? ?? [];
        final pointsList = blocks.map((block) => BlockPoint(x: (block['x'] as num).toInt(), y: (block['y'] as num).toInt())).toList();
        emit(pointsList);
      }
    } catch (e) {
      print("BapBlocksCubit: Canlt get blocks: $e");
    }
  }

  void addBlock(BlockPoint point) {
    final currentBlocks = List<BlockPoint>.from(state);
    final exists = currentBlocks.any((p) => p.x == point.x && p.y == point.y);
    if (!exists) {
      currentBlocks.add(point);
      emit(currentBlocks);
    }
  }

  void addBlocks(List<BlockPoint> points) {
    final currentBlocks = List<BlockPoint>.from(state);
    for (var point in points) {
      final exists = currentBlocks.any((p) => p.x == point.x && p.y == point.y);
      if (!exists) {
        currentBlocks.add(point);
      }
    }
    emit(currentBlocks);
  }

  void removeBlock(BlockPoint point) {
    final currentBlocks = List<BlockPoint>.from(state);
    currentBlocks.removeWhere((p) => p.x == point.x && p.y == point.y);
    emit(currentBlocks);
  }

  Future<bool> saveBlocks() async {
    try {
      final blocks = state.map((point) => point.toJson()).toList();
      final response = await http.post(Uri.parse('$baseUrl/map/blocks'), headers: {'Content-Type': 'application/json'}, body: json.encode({'blocks': blocks}));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
