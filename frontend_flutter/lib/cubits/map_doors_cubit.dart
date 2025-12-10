import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dart_common/dart_common.dart';

class MapDoorsCubit extends Cubit<List<Door>> {
  static const String baseUrl = 'http://localhost:5000/api';

  MapDoorsCubit() : super([]);

  Future<void> loadDoors() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/map/doors'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final doors = data['doors'] as List? ?? [];
        final doorsList = doors.map((door) => Door.fromJson(door)).toList();
        emit(doorsList);
      }
    } catch (e) {
      emit([]);
    }
  }

  void addDoor(Door door) {
    final currentDoors = List<Door>.from(state);
    currentDoors.add(door);
    emit(currentDoors);
  }

  void removeDoor(int index) {
    final currentDoors = List<Door>.from(state);
    if (index >= 0 && index < currentDoors.length) {
      currentDoors.removeAt(index);
      emit(currentDoors);
    }
  }

  Future<bool> saveDoors() async {
    try {
      final doors = state.map((door) => door.toJson()).toList();
      final response = await http.post(Uri.parse('$baseUrl/map/doors'), headers: {'Content-Type': 'application/json'}, body: json.encode({'doors': doors}));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
