import 'dart:convert';

import 'package:dart_common/common/attributes.dart';

abstract class Command {
  String guid;
  String attributeGuid;
  String get type;

  Command({required this.guid, required this.attributeGuid});

  factory Command.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'switch_control':
        return SwitchCommand.fromJson(json);
      case 'set_brightness':
        return BrightnessCommand.fromJson(json);
      case 'set_color':
        return ColorCommand.fromJson(json);
      case 'cover_control':
        return CoverCommand.fromJson(json);
      case 'set_cover_position':
        return CoverPositionCommand.fromJson(json);
      case 'rotate_by_angle':
        return RotateByAngleCommand.fromJson(json);
      case 'rotate_to_location_attribute':
        return RotateToLocationAttributeCommand.fromJson(json);
      case 'rotate_to_nearest_human':
        return RotateToNearestHumanCommand.fromJson(json);
      case 'vacuum_clean_room':
        return VacuumCleanRoomCommand.fromJson(json);
      case 'vacuum_pause_resume':
        return VacuumPauseResumeCommand.fromJson(json);
      case 'vacuum_fan_speed':
        return VacuumFanSpeedCommand.fromJson(json);
      default:
        throw ArgumentError('Unknown command type: $type');
    }
  }

  Map<String, dynamic> toJson();

  String toJsonString() => jsonEncode(toJson());

  bool isSupportedByAttribute(Attribute attribute);
}

class SwitchCommand extends Command {
  @override
  String get type => "switch_control";
  String state;

  SwitchCommand({required super.guid, required super.attributeGuid, required this.state});

  factory SwitchCommand.fromJson(Map<String, dynamic> json) {
    return SwitchCommand(guid: json['guid'] as String, attributeGuid: json['attribute_guid'] as String, state: json['state'] as String);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'guid': guid, 'attribute_guid': attributeGuid, 'state': state};
  }

  @override
  bool isSupportedByAttribute(Attribute attribute) {
    return attribute is LightAttribute || attribute is SwitchAttribute;
  }
}

class BrightnessCommand extends Command {
  @override
  String get type => "set_brightness";
  int brightness;

  BrightnessCommand({required super.guid, required super.attributeGuid, required this.brightness});

  factory BrightnessCommand.fromJson(Map<String, dynamic> json) {
    return BrightnessCommand(guid: json['guid'] as String, attributeGuid: json['attribute_guid'] as String, brightness: json['brightness'] as int);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'guid': guid, 'attribute_guid': attributeGuid, 'brightness': brightness};
  }

  @override
  bool isSupportedByAttribute(Attribute attribute) {
    return attribute is LightAttribute;
  }
}

class ColorCommand extends Command {
  @override
  String get type => "set_color";
  List<int> rgbColor;

  ColorCommand({required super.guid, required super.attributeGuid, required this.rgbColor});

  factory ColorCommand.fromJson(Map<String, dynamic> json) {
    return ColorCommand(
      guid: json['guid'] as String,
      attributeGuid: json['attribute_guid'] as String,
      rgbColor: (json['rgb_color'] as List<dynamic>).cast<int>().toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'guid': guid, 'attribute_guid': attributeGuid, 'rgb_color': rgbColor};
  }

  @override
  bool isSupportedByAttribute(Attribute attribute) {
    return attribute is LightAttribute;
  }
}

class CoverCommand extends Command {
  @override
  String get type => "cover_control";
  String action;

  CoverCommand({required super.guid, required super.attributeGuid, required this.action});

  factory CoverCommand.fromJson(Map<String, dynamic> json) {
    return CoverCommand(guid: json['guid'] as String, attributeGuid: json['attribute_guid'] as String, action: json['action'] as String);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'guid': guid, 'attribute_guid': attributeGuid, 'action': action};
  }

  @override
  bool isSupportedByAttribute(Attribute attribute) {
    return attribute is CoverAttribute;
  }
}

class CoverPositionCommand extends Command {
  @override
  String get type => "set_cover_position";
  int position;

  CoverPositionCommand({required super.guid, required super.attributeGuid, required this.position});

  factory CoverPositionCommand.fromJson(Map<String, dynamic> json) {
    return CoverPositionCommand(guid: json['guid'] as String, attributeGuid: json['attribute_guid'] as String, position: json['position'] as int);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'guid': guid, 'attribute_guid': attributeGuid, 'position': position};
  }

  @override
  bool isSupportedByAttribute(Attribute attribute) {
    return attribute is CoverAttribute;
  }
}

class RotateByAngleCommand extends Command {
  @override
  String get type => "rotate_by_angle";
  double angle;

  RotateByAngleCommand({required super.guid, required super.attributeGuid, required this.angle});

  factory RotateByAngleCommand.fromJson(Map<String, dynamic> json) {
    return RotateByAngleCommand(guid: json['guid'] as String, attributeGuid: json['attribute_guid'] as String, angle: (json['angle'] as num).toDouble());
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'guid': guid, 'attribute_guid': attributeGuid, 'angle': angle};
  }

  @override
  bool isSupportedByAttribute(Attribute attribute) {
    return attribute is RotationAttribute;
  }
}

class RotateToLocationAttributeCommand extends Command {
  @override
  String get type => "rotate_to_location_attribute";
  String locationAttributeGuid;

  RotateToLocationAttributeCommand({required super.guid, required super.attributeGuid, required this.locationAttributeGuid});

  factory RotateToLocationAttributeCommand.fromJson(Map<String, dynamic> json) {
    return RotateToLocationAttributeCommand(
      guid: json['guid'] as String,
      attributeGuid: json['attribute_guid'] as String,
      locationAttributeGuid: json['location_attribute_guid'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'guid': guid, 'attribute_guid': attributeGuid, 'location_attribute_guid': locationAttributeGuid};
  }

  @override
  bool isSupportedByAttribute(Attribute attribute) {
    return attribute is RotationAttribute;
  }
}

class RotateToNearestHumanCommand extends Command {
  @override
  String get type => "rotate_to_nearest_human";

  RotateToNearestHumanCommand({required super.guid, required super.attributeGuid});

  factory RotateToNearestHumanCommand.fromJson(Map<String, dynamic> json) {
    return RotateToNearestHumanCommand(guid: json['guid'] as String, attributeGuid: json['attribute_guid'] as String);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'guid': guid, 'attribute_guid': attributeGuid};
  }

  @override
  bool isSupportedByAttribute(Attribute attribute) {
    return attribute is RotationAttribute;
  }
}

class VacuumCleanRoomCommand extends Command {
  @override
  String get type => "vacuum_clean_room";
  String roomId;

  VacuumCleanRoomCommand({required super.guid, required super.attributeGuid, required this.roomId});

  factory VacuumCleanRoomCommand.fromJson(Map<String, dynamic> json) {
    return VacuumCleanRoomCommand(guid: json['guid'] as String, attributeGuid: json['attribute_guid'] as String, roomId: json['room_id'] as String);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'guid': guid, 'attribute_guid': attributeGuid, 'room_id': roomId};
  }

  @override
  bool isSupportedByAttribute(Attribute attribute) {
    return attribute is VacuumAttribute;
  }
}

class VacuumPauseResumeCommand extends Command {
  @override
  String get type => "vacuum_pause_resume";
  bool paused;

  VacuumPauseResumeCommand({required super.guid, required super.attributeGuid, required this.paused});

  factory VacuumPauseResumeCommand.fromJson(Map<String, dynamic> json) {
    return VacuumPauseResumeCommand(guid: json['guid'] as String, attributeGuid: json['attribute_guid'] as String, paused: json['paused'] as bool);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'guid': guid, 'attribute_guid': attributeGuid, 'paused': paused};
  }

  @override
  bool isSupportedByAttribute(Attribute attribute) {
    return attribute is VacuumAttribute;
  }
}

class VacuumFanSpeedCommand extends Command {
  @override
  String get type => "vacuum_fan_speed";
  String fanSpeed;

  VacuumFanSpeedCommand({required super.guid, required super.attributeGuid, required this.fanSpeed});

  factory VacuumFanSpeedCommand.fromJson(Map<String, dynamic> json) {
    return VacuumFanSpeedCommand(guid: json['guid'] as String, attributeGuid: json['attribute_guid'] as String, fanSpeed: json['fan_speed'] as String);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'guid': guid, 'attribute_guid': attributeGuid, 'fan_speed': fanSpeed};
  }

  @override
  bool isSupportedByAttribute(Attribute attribute) {
    return attribute is VacuumAttribute;
  }
}
