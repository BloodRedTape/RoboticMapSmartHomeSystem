import 'package:dart_common/common/automation/events.dart';

abstract class EventSelect {
  const EventSelect();
  bool match(Event event);
  String get type;

  // Change this to an instance method
  bool supportsEventType(String eventType) {
    // Default implementation, should be overridden by concrete classes
    return true;
  }

  factory EventSelect.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case EventSelectOr.staticType:
        return EventSelectOr.fromJson(json);
      case EventSelectAnd.staticType:
        return EventSelectAnd.fromJson(json);
      case SwitchStateSelect.staticType:
        return SwitchStateSelect.fromJson(json);
      case HumanCountSelect.staticType:
        return HumanCountSelect.fromJson(json);
      case HumanLocationSelect.staticType:
        return HumanLocationSelect.fromJson(json);
      case HumanDeviceDistanceSelect.staticType:
        return HumanDeviceDistanceSelect.fromJson(json);
      default:
        throw ArgumentError('Unknown event select type: $type');
    }
  }

  Map<String, dynamic> toJson();
}

class EventSelectOr extends EventSelect {
  final List<EventSelect> selects;

  const EventSelectOr({required this.selects});

  @override
  bool match(Event event) {
    for (final select in selects) {
      if (select.match(event)) return true;
    }
    return false;
  }

  static const staticType = "or";

  @override
  String get type {
    return staticType;
  }

  factory EventSelectOr.fromJson(Map<String, dynamic> json) {
    return EventSelectOr(selects: (json['selects'] as List).map((e) => EventSelect.fromJson(e as Map<String, dynamic>)).toList());
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'selects': selects.map((e) => e.toJson()).toList()};
  }
}

class EventSelectAnd extends EventSelect {
  final List<EventSelect> selects;

  const EventSelectAnd({required this.selects});

  @override
  bool match(Event event) {
    for (final select in selects) {
      if (!select.match(event)) return false;
    }
    return true;
  }

  static const staticType = "and";

  @override
  String get type {
    return staticType;
  }

  factory EventSelectAnd.fromJson(Map<String, dynamic> json) {
    return EventSelectAnd(selects: (json['selects'] as List).map((e) => EventSelect.fromJson(e as Map<String, dynamic>)).toList());
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'selects': selects.map((e) => e.toJson()).toList()};
  }
}

class SwitchStateSelect extends EventSelect {
  final bool isOn;
  final String attributeGuid;
  const SwitchStateSelect({required this.isOn, required this.attributeGuid});

  @override
  bool match(Event event) {
    return event is SwitchChangedEvent && event.isOn == isOn && event.attributeGuid == attributeGuid;
  }

  static const staticType = "switch_state";

  @override
  String get type {
    return staticType;
  }

  factory SwitchStateSelect.fromJson(Map<String, dynamic> json) {
    return SwitchStateSelect(isOn: json['is_on'] as bool, attributeGuid: json['attribute_guid'] as String);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'is_on': isOn, 'attribute_guid': attributeGuid};
  }

  @override
  bool supportsEventType(String eventType) {
    return eventType == SwitchChangedEvent.staticType;
  }
}

class HumanCountSelect extends EventSelect {
  final String roomGuid;
  final int targetCount;
  final String operator; // ">", "<", "="

  const HumanCountSelect({required this.roomGuid, required this.targetCount, required this.operator});

  @override
  bool match(Event event) {
    if (event is! HumanCountChangedEvent) return false;

    switch (operator) {
      case ">":
        return event.count > targetCount;
      case "<":
        return event.count < targetCount;
      case "=":
        return event.count == targetCount;
      default:
        return false;
    }
  }

  static const staticType = "human_count";

  @override
  String get type {
    return staticType;
  }

  factory HumanCountSelect.fromJson(Map<String, dynamic> json) {
    return HumanCountSelect(roomGuid: json['room_guid'] as String, targetCount: json['target_count'] as int, operator: json['operator'] as String);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'room_guid': roomGuid, 'target_count': targetCount, 'operator': operator};
  }

  @override
  bool supportsEventType(String eventType) {
    return eventType == HumanCountChangedEvent.staticType;
  }
}

class HumanLocationSelect extends EventSelect {
  final String? roomGuid;

  const HumanLocationSelect({this.roomGuid});

  @override
  bool match(Event event) {
    if (event is! HumanLocationChangedEvent) return false;
    if (roomGuid == null) return true; // Any room
    return event.newRoomGuid == roomGuid;
  }

  static const staticType = "human_location";

  @override
  String get type {
    return staticType;
  }

  factory HumanLocationSelect.fromJson(Map<String, dynamic> json) {
    return HumanLocationSelect(roomGuid: json['room_guid'] as String?);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'room_guid': roomGuid};
  }

  @override
  bool supportsEventType(String eventType) {
    return eventType == HumanLocationChangedEvent.staticType;
  }
}

class HumanDeviceDistanceSelect extends EventSelect {
  final String deviceAttributeGuid;
  final double distance;
  final String operator; // ">", "<"
  final String humanMatcher; // "any", "all"

  const HumanDeviceDistanceSelect({required this.deviceAttributeGuid, required this.distance, required this.operator, required this.humanMatcher});

  @override
  bool match(Event event) {
    // The actual logic for this is on the backend, this is just for client-side validation.
    return event is HumanLocationChangedEvent;
  }

  static const staticType = "human_device_distance";

  @override
  String get type {
    return staticType;
  }

  factory HumanDeviceDistanceSelect.fromJson(Map<String, dynamic> json) {
    return HumanDeviceDistanceSelect(
      deviceAttributeGuid: json['device_attribute_guid'] as String,
      distance: (json['distance'] as num).toDouble(),
      operator: json['operator'] as String,
      humanMatcher: json['human_matcher'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'device_attribute_guid': deviceAttributeGuid, 'distance': distance, 'operator': operator, 'human_matcher': humanMatcher};
  }

  @override
  bool supportsEventType(String eventType) {
    return eventType == HumanLocationChangedEvent.staticType;
  }
}
