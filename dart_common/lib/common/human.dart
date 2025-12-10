import 'thing.dart';
import 'attributes.dart';

class Human extends Thing {
  bool isDetected;
  String? lastSeen;
  String? detectionSource;

  Human({required super.id, required super.name, required super.attributes, this.isDetected = true, this.lastSeen, this.detectionSource});

  factory Human.fromJson(Map<String, dynamic> json) {
    return Human(
      id: json['id'] as String,
      name: json['name'] as String,
      attributes: (json['attributes'] as List<dynamic>?)?.map((attrJson) => Attribute.fromJson(attrJson as Map<String, dynamic>)).toList() ?? [],
      isDetected: json['is_detected'] as bool? ?? true,
      lastSeen: json['last_seen'] as String?,
      detectionSource: json['detection_source'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {...super.toJson(), 'is_detected': isDetected, 'last_seen': lastSeen, 'detection_source': detectionSource};
  }

  double get x {
    return findAttribute<LocationAttribute>()?.x ?? 0;
  }

  double get y {
    return findAttribute<LocationAttribute>()?.y ?? 0;
  }

  String? get roomId {
    return findAttribute<LocationAttribute>()?.roomId;
  }

  LocationType? get locationType {
    return findAttribute<LocationAttribute>()?.locationType;
  }
}
