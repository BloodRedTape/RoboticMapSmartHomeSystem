import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';

class DisplaySettings {
  final bool showDeviceLabels;
  final bool showRoomColors;
  final bool showRoomLabels;
  final bool showDevicePaths;
  final double iconScale;

  DisplaySettings({
    this.showDeviceLabels = true,
    this.showRoomColors = true,
    this.showRoomLabels = true,
    this.showDevicePaths = true,
    this.iconScale = 1.0,
  });

  DisplaySettings copyWith({
    bool? showDeviceLabels,
    bool? showRoomColors,
    bool? showRoomLabels,
    bool? showDevicePaths,
    double? iconScale,
  }) {
    return DisplaySettings(
      showDeviceLabels: showDeviceLabels ?? this.showDeviceLabels,
      showRoomColors: showRoomColors ?? this.showRoomColors,
      showRoomLabels: showRoomLabels ?? this.showRoomLabels,
      showDevicePaths: showDevicePaths ?? this.showDevicePaths,
      iconScale: iconScale ?? this.iconScale,
    );
  }

  Map<String, dynamic> toJson() => {
    'show_device_labels': showDeviceLabels,
    'show_room_colors': showRoomColors,
    'show_room_labels': showRoomLabels,
    'show_device_paths': showDevicePaths,
    'icon_scale': iconScale,
  };

  factory DisplaySettings.fromJson(Map<String, dynamic> json) {
    return DisplaySettings(
      showDeviceLabels: json['show_device_labels'] ?? true,
      showRoomColors: json['show_room_colors'] ?? true,
      showRoomLabels: json['show_room_labels'] ?? true,
      showDevicePaths: json['show_device_paths'] ?? true,
      iconScale: (json['icon_scale'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class DisplaySettingsCubit extends Cubit<DisplaySettings> {
  static const String baseUrl = 'http://localhost:5000/api';
  bool _isInitialized = false;

  DisplaySettingsCubit() : super(DisplaySettings()) {
    loadSettings();
  }

  bool get isInitialized => _isInitialized;

  Future<void> loadSettings() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/settings'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        emit(DisplaySettings.fromJson(data));
        _isInitialized = true;
      }
    } catch (e) {
      print('Error loading display settings: $e');
      _isInitialized = true;
    }
  }

  Future<void> saveSettings() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/settings'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(state.toJson()),
      );
    } catch (e) {
      print('Error saving display settings: $e');
      rethrow;
    }
  }

  void updateShowDeviceLabels(bool value) {
    emit(state.copyWith(showDeviceLabels: value));
  }

  void updateShowRoomColors(bool value) {
    emit(state.copyWith(showRoomColors: value));
  }

  void updateShowRoomLabels(bool value) {
    emit(state.copyWith(showRoomLabels: value));
  }

  void updateShowDevicePaths(bool value) {
    emit(state.copyWith(showDevicePaths: value));
  }

  void updateIconScale(double value) {
    emit(state.copyWith(iconScale: value));
  }
}
