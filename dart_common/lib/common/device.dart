import 'package:dart_common/common/primitive.dart';

import 'thing.dart';
import 'attributes.dart';

class Device extends Thing {
  bool isOnline;
  bool hidden;
  String? icon;
  String? color;
  IntegrationType integration;
  String? haEntityId;

  Device({
    required super.id,
    required super.name,
    super.attributes = const [],
    this.isOnline = true,
    this.hidden = false,
    this.icon,
    this.color,
    this.integration = IntegrationType.homeAssistant,
    this.haEntityId,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      name: json['name'] as String,
      attributes: (json['attributes'] as List<dynamic>?)?.map((attrJson) => Attribute.fromJson(attrJson as Map<String, dynamic>)).toList() ?? [],
      isOnline: json['is_online'] as bool? ?? true,
      hidden: json['hidden'] as bool? ?? false,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      integration: json['integration'] != null ? IntegrationType.fromString(json['integration'] as String) : IntegrationType.homeAssistant,
      haEntityId: json['ha_entity_id'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'is_online': isOnline,
      'hidden': hidden,
      'icon': icon,
      'color': color,
      'integration': integration.value,
      'ha_entity_id': haEntityId,
    };
  }

  double? get x {
    return findAttribute<LocationAttribute>()?.x;
  }

  double? get y {
    return findAttribute<LocationAttribute>()?.y;
  }

  String? get roomId {
    return findAttribute<LocationAttribute>()?.roomId;
  }

  LocationType? get locationType {
    return findAttribute<LocationAttribute>()?.locationType;
  }

  bool get hasPaths {
    return findAttribute<PathAttribute>() != null;
  }

  List<List<MapPoint>>? get paths {
    return findAttribute<PathAttribute>()?.paths;
  }
}
