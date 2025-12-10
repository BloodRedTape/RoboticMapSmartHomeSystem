import 'package:dart_common/common/commands.dart';

abstract class Event {
  const Event();
  String get type;

  factory Event.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case SwitchChangedEvent.staticType:
        return SwitchChangedEvent.fromJson(json);
      case SensorChangedEvent.staticType:
        return SensorChangedEvent.fromJson(json);
      case HumanCountChangedEvent.staticType:
        return HumanCountChangedEvent.fromJson(json);
      case HumanLocationChangedEvent.staticType:
        return HumanLocationChangedEvent.fromJson(json);
      default:
        throw ArgumentError('Unknown event type: $type');
    }
  }

  Map<String, dynamic> toJson();
}

class SwitchChangedEvent extends Event {
  final bool isOn;
  final String attributeGuid;

  const SwitchChangedEvent({required this.isOn, required this.attributeGuid});

  static const staticType = "switch_changed";

  @override
  String get type {
    return staticType;
  }

  factory SwitchChangedEvent.fromJson(Map<String, dynamic> json) {
    return SwitchChangedEvent(isOn: json['is_on'] as bool, attributeGuid: json['attribute_guid'] as String);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'is_on': isOn, 'attribute_guid': attributeGuid};
  }
}

class SensorChangedEvent extends Event {
  final double value;
  final String attributeGuid;

  const SensorChangedEvent({required this.value, required this.attributeGuid});

  static const staticType = "sensor_changed";

  @override
  String get type {
    return staticType;
  }

  factory SensorChangedEvent.fromJson(Map<String, dynamic> json) {
    return SensorChangedEvent(value: (json['value'] as num).toDouble(), attributeGuid: json['attribute_guid'] as String);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'value': value, 'attribute_guid': attributeGuid};
  }
}

class HumanCountChangedEvent extends Event {
  final String roomGuid;
  final int count;

  const HumanCountChangedEvent({required this.roomGuid, required this.count});

  static const staticType = "human_count_changed";

  @override
  String get type {
    return staticType;
  }

  factory HumanCountChangedEvent.fromJson(Map<String, dynamic> json) {
    return HumanCountChangedEvent(roomGuid: json['room_guid'] as String, count: json['count'] as int);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'room_guid': roomGuid, 'count': count};
  }
}

class HumanLocationChangedEvent extends Event {
  final String humanGuid;
  final String newRoomGuid;
  final double x;
  final double y;

  @override
  String get type => staticType;

  const HumanLocationChangedEvent({required this.humanGuid, required this.newRoomGuid, required this.x, required this.y});

  static const staticType = "human_location_changed";

  @override
  List<Object?> get props => [humanGuid, newRoomGuid, x, y];

  factory HumanLocationChangedEvent.fromJson(Map<String, dynamic> json) {
    return HumanLocationChangedEvent(
        humanGuid: json['human_guid'] as String, newRoomGuid: json['new_room_guid'] as String, x: json['x'] as double, y: json['y'] as double);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'human_guid': humanGuid, 'new_room_guid': newRoomGuid, 'x': x, 'y': y};
  }
}
