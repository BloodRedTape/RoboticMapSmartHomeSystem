import 'package:dart_common/common/primitive.dart';
import 'thing.dart';

abstract class Attribute {
  String guid;
  String type;

  Attribute({required this.guid, required this.type});

  factory Attribute.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'location':
        return LocationAttribute.fromJson(json);
      case 'path':
        return PathAttribute.fromJson(json);
      case 'light':
        return LightAttribute.fromJson(json);
      case 'switch':
        return SwitchAttribute.fromJson(json);
      case 'button':
        return ButtonAttribute.fromJson(json);
      case 'sensor':
        return SensorAttribute.fromJson(json);
      case 'binary_sensor':
        return BinarySensorAttribute.fromJson(json);
      case 'camera':
        return CameraAttribute.fromJson(json);
      case 'fan':
        return FanAttribute.fromJson(json);
      case 'climate':
        return ClimateAttribute.fromJson(json);
      case 'lock':
        return LockAttribute.fromJson(json);
      case 'cover':
        return CoverAttribute.fromJson(json);
      case 'media_player':
        return MediaPlayerAttribute.fromJson(json);
      case 'vacuum':
        return VacuumAttribute.fromJson(json);
      case 'rotation':
        return RotationAttribute.fromJson(json);
      default:
        throw ArgumentError('Unknown attribute type: $type');
    }
  }

  Map<String, dynamic> toJson();

  Map<String, dynamic> getFields();
}

class LocationAttribute extends Attribute {
  double x;
  double y;
  String? roomId;
  LocationType locationType;

  LocationAttribute({required super.guid, required this.x, required this.y, this.roomId, required this.locationType}) : super(type: 'location');

  factory LocationAttribute.fromJson(Map<String, dynamic> json) {
    return LocationAttribute(
      guid: json['guid'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      roomId: json['room_id'] as String?,
      locationType: LocationType.fromString(json['location_type'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'guid': guid, 'x': x, 'y': y, 'room_id': roomId, 'location_type': locationType.value};
  }

  @override
  Map<String, dynamic> getFields() => {'x': x, 'y': y, 'room_id': roomId, 'location_type': locationType.name};
}

class PathAttribute extends Attribute {
  List<List<MapPoint>> paths;

  PathAttribute({required super.guid, List<List<MapPoint>>? paths}) : paths = paths ?? [], super(type: 'path');

  factory PathAttribute.fromJson(Map<String, dynamic> json) {
    return PathAttribute(
      guid: json['guid'] as String,
      paths:
          (json['paths'] as List<dynamic>?)?.map((p) => (p as List<dynamic>).map((pt) => MapPoint.fromJson(pt as Map<String, dynamic>)).toList()).toList() ??
          [],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'guid': guid, 'paths': paths.map((p) => p.map((pt) => pt.toJson()).toList()).toList()};
  }

  @override
  Map<String, dynamic> getFields() => {'paths': paths.map((path) => path.map((p) => p.toJson()).toList()).toList()};
}

class LightAttribute extends Attribute {
  String state;
  int? brightness;
  int? colorTemp;
  List<int>? rgbColor;

  LightAttribute({required super.guid, required this.state, this.brightness, this.colorTemp, this.rgbColor}) : super(type: 'light');

  factory LightAttribute.fromJson(Map<String, dynamic> json) {
    return LightAttribute(
      guid: json['guid'] as String,
      state: json['state'] as String,
      brightness: json['brightness'] as int?,
      colorTemp: json['color_temp'] as int?,
      rgbColor: (json['rgb_color'] as List<dynamic>?)?.cast<int>().toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'guid': guid, 'state': state, 'brightness': brightness, 'color_temp': colorTemp, 'rgb_color': rgbColor};
  }

  @override
  Map<String, dynamic> getFields() => {'state': state, 'brightness': brightness, 'color_temp': colorTemp, 'rgb_color': rgbColor};
}

class SwitchAttribute extends Attribute {
  String state;

  SwitchAttribute({required super.guid, required this.state}) : super(type: 'switch');

  factory SwitchAttribute.fromJson(Map<String, dynamic> json) {
    return SwitchAttribute(guid: json['guid'] as String, state: json['state'] as String);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'guid': guid, 'state': state};
  }

  @override
  Map<String, dynamic> getFields() => {'state': state};
}

class ButtonAttribute extends Attribute {
  String? lastPressed;
  String? lastAction;

  ButtonAttribute({required super.guid, this.lastPressed, this.lastAction}) : super(type: 'button');

  factory ButtonAttribute.fromJson(Map<String, dynamic> json) {
    return ButtonAttribute(guid: json['guid'] as String, lastPressed: json['last_pressed'] as String?, lastAction: json['last_action'] as String?);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'guid': guid, 'last_pressed': lastPressed, 'last_action': lastAction};
  }

  @override
  Map<String, dynamic> getFields() => {'last_pressed': lastPressed, 'last_action': lastAction};
}

enum SensorDeviceClass {
  aqi,
  area,
  atmosphericPressure,
  battery,
  co2,
  current,
  energy,
  enumType,
  frequency,
  humidity,
  illuminance,
  moisture,
  pm1,
  pm25,
  pm4,
  pm10,
  power,
  precipitation,
  pressure,
  signalStrength,
  speed,
  temperature,
  timestamp,
  voltage,
  volume,
  water,
  weight,
  windDirection,
  windSpeed,
  unknown,
}

class SensorAttribute extends Attribute {
  String state;
  double? measurement;
  String? unit;
  SensorDeviceClass deviceClass;

  SensorAttribute({required super.guid, required this.state, this.measurement, this.unit, required this.deviceClass}) : super(type: 'sensor');

  static SensorDeviceClass parseDeviceClass(String? value) {
    if (value == null) return SensorDeviceClass.unknown;
    return SensorDeviceClass.values.firstWhere((e) => e.name.toLowerCase() == value.toLowerCase(), orElse: () => SensorDeviceClass.unknown);
  }

  factory SensorAttribute.fromJson(Map<String, dynamic> json) {
    return SensorAttribute(
      guid: json['guid'] as String,
      state: json['state'] as String,
      measurement: (json['measurement'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      deviceClass: parseDeviceClass(json['device_class']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'guid': guid, 'state': state, 'measurement': measurement, 'unit': unit, 'device_class': deviceClass.name};
  }

  @override
  Map<String, dynamic> getFields() => {'state': state, 'measurement': measurement, 'unit': unit, 'device_class': deviceClass.name};
}

class BinarySensorAttribute extends Attribute {
  String state;
  String? deviceClass;

  BinarySensorAttribute({required super.guid, required this.state, this.deviceClass}) : super(type: 'binary_sensor');

  factory BinarySensorAttribute.fromJson(Map<String, dynamic> json) {
    return BinarySensorAttribute(guid: json['guid'] as String, state: json['state'] as String, deviceClass: json['device_class'] as String?);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'guid': guid, 'state': state, 'device_class': deviceClass};
  }

  @override
  Map<String, dynamic> getFields() => {'state': state, 'device_class': deviceClass};
}

class CameraAttribute extends Attribute {
  String state;
  String? streamUrl;
  String? snapshotUrl;
  double? pan;
  double? tilt;

  CameraAttribute({required super.guid, required this.state, this.streamUrl, this.snapshotUrl, this.pan, this.tilt}) : super(type: 'camera');

  factory CameraAttribute.fromJson(Map<String, dynamic> json) {
    return CameraAttribute(
      guid: json['guid'] as String,
      state: json['state'] as String,
      streamUrl: json['stream_url'] as String?,
      snapshotUrl: json['snapshot_url'] as String?,
      pan: (json['pan'] as num?)?.toDouble(),
      tilt: (json['tilt'] as num?)?.toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'guid': guid, 'state': state, 'stream_url': streamUrl, 'snapshot_url': snapshotUrl, 'pan': pan, 'tilt': tilt};
  }

  @override
  Map<String, dynamic> getFields() => {'state': state, 'stream_url': streamUrl, 'snapshot_url': snapshotUrl, 'pan': pan, 'tilt': tilt};
}

class FanAttribute extends Attribute {
  String state;
  int? speed;
  bool? oscillating;
  String? direction;

  FanAttribute({required super.guid, required this.state, this.speed, this.oscillating, this.direction}) : super(type: 'fan');

  factory FanAttribute.fromJson(Map<String, dynamic> json) {
    return FanAttribute(
      guid: json['guid'] as String,
      state: json['state'] as String,
      speed: json['speed'] as int?,
      oscillating: json['oscillating'] as bool?,
      direction: json['direction'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'guid': guid, 'state': state, 'speed': speed, 'oscillating': oscillating, 'direction': direction};
  }

  @override
  Map<String, dynamic> getFields() => {'state': state, 'speed': speed, 'oscillating': oscillating, 'direction': direction};
}

class ClimateAttribute extends Attribute {
  String state;
  double? currentTemperature;
  double? targetTemperature;
  String? fanMode;
  double? humidity;

  ClimateAttribute({required super.guid, required this.state, this.currentTemperature, this.targetTemperature, this.fanMode, this.humidity})
    : super(type: 'climate');

  factory ClimateAttribute.fromJson(Map<String, dynamic> json) {
    return ClimateAttribute(
      guid: json['guid'] as String,
      state: json['state'] as String,
      currentTemperature: (json['current_temperature'] as num?)?.toDouble(),
      targetTemperature: (json['target_temperature'] as num?)?.toDouble(),
      fanMode: json['fan_mode'] as String?,
      humidity: (json['humidity'] as num?)?.toDouble(),
    );
  }

  @override
  Map<String, dynamic> getFields() => {
    'state': state,
    'current_temperature': currentTemperature,
    'target_temperature': targetTemperature,
    'fan_mode': fanMode,
    'humidity': humidity,
  };

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'guid': guid,
      'state': state,
      'current_temperature': currentTemperature,
      'target_temperature': targetTemperature,
      'fan_mode': fanMode,
      'humidity': humidity,
    };
  }
}

class LockAttribute extends Attribute {
  String state;

  LockAttribute({required super.guid, required this.state}) : super(type: 'lock');

  factory LockAttribute.fromJson(Map<String, dynamic> json) {
    return LockAttribute(guid: json['guid'] as String, state: json['state'] as String);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'guid': guid, 'state': state};
  }

  @override
  Map<String, dynamic> getFields() => {'state': state};
}

class CoverAttribute extends Attribute {
  String state;
  int? position;
  int? tiltPosition;

  CoverAttribute({required super.guid, required this.state, this.position, this.tiltPosition}) : super(type: 'cover');

  factory CoverAttribute.fromJson(Map<String, dynamic> json) {
    return CoverAttribute(
      guid: json['guid'] as String,
      state: json['state'] as String,
      position: json['position'] as int?,
      tiltPosition: json['tilt_position'] as int?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'guid': guid, 'state': state, 'position': position, 'tilt_position': tiltPosition};
  }

  @override
  Map<String, dynamic> getFields() => {'state': state, 'position': position, 'tilt_position': tiltPosition};
}

class MediaPlayerAttribute extends Attribute {
  String state;
  double? volume;
  bool? isMuted;
  String? mediaTitle;
  String? mediaArtist;
  String? source;

  MediaPlayerAttribute({required super.guid, required this.state, this.volume, this.isMuted, this.mediaTitle, this.mediaArtist, this.source})
    : super(type: 'media_player');

  factory MediaPlayerAttribute.fromJson(Map<String, dynamic> json) {
    return MediaPlayerAttribute(
      guid: json['guid'] as String,
      state: json['state'] as String,
      volume: (json['volume'] as num?)?.toDouble(),
      isMuted: json['is_muted'] as bool?,
      mediaTitle: json['media_title'] as String?,
      mediaArtist: json['media_artist'] as String?,
      source: json['source'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'guid': guid,
      'state': state,
      'volume': volume,
      'is_muted': isMuted,
      'media_title': mediaTitle,
      'media_artist': mediaArtist,
      'source': source,
    };
  }

  @override
  Map<String, dynamic> getFields() => {
    'state': state,
    'volume': volume,
    'is_muted': isMuted,
    'media_title': mediaTitle,
    'media_artist': mediaArtist,
    'source': source,
  };
}

class VacuumAttribute extends Attribute {
  String state;
  int? batteryLevel;
  String? fanSpeed;
  String? status;
  List<String>? fanSpeedList;

  VacuumAttribute({required super.guid, required this.state, this.batteryLevel, this.fanSpeed, this.status, this.fanSpeedList})
    : super(type: 'vacuum');

  factory VacuumAttribute.fromJson(Map<String, dynamic> json) {
    return VacuumAttribute(
      guid: json['guid'] as String,
      state: json['state'] as String,
      batteryLevel: json['battery_level'] as int?,
      fanSpeed: json['fan_speed'] as String?,
      status: json['status'] as String?,
      fanSpeedList: (json['fan_speed_list'] as List<dynamic>?)?.cast<String>().toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'guid': guid,
      'state': state,
      'battery_level': batteryLevel,
      'fan_speed': fanSpeed,
      'status': status,
      'fan_speed_list': fanSpeedList,
    };
  }

  @override
  Map<String, dynamic> getFields() => {
    'state': state,
    'battery_level': batteryLevel,
    'fan_speed': fanSpeed,
    'status': status,
  };
}

class RotationAttribute extends Attribute {
  double angle;

  RotationAttribute({required super.guid, required this.angle}) : super(type: 'rotation');

  factory RotationAttribute.fromJson(Map<String, dynamic> json) {
    return RotationAttribute(
      guid: json['guid'] as String,
      angle: (json['angle'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'guid': guid, 'angle': angle};
  }

  @override
  Map<String, dynamic> getFields() => {'angle': angle};
}
