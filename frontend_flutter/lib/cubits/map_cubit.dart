import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dart_common/dart_common.dart';
import 'package:http/http.dart' as http;

class MapState {
  final MapData? mapData;
  final bool isLoading;
  final String? error;

  const MapState({this.mapData, this.isLoading = false, this.error});

  MapState copyWith({MapData? mapData, bool? isLoading, String? error}) {
    return MapState(mapData: mapData ?? this.mapData, isLoading: isLoading ?? this.isLoading, error: error);
  }
}

class MapCubit extends Cubit<MapState> {
  MapCubit() : super(const MapState(isLoading: true));

  Future<void> loadMap() async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final response = await http.get(Uri.parse('http://localhost:5000/api/map'));
      if (response.statusCode == 200) {
        final mapJson = json.decode(response.body);
        emit(MapState(mapData: MapData.fromJson(mapJson), isLoading: false));
      } else {
        emit(MapState(isLoading: false, error: 'Failed to load map'));
      }
    } catch (e) {
      emit(MapState(isLoading: false, error: 'MapCubit: ${e.toString()}'));
    }
  }
}
