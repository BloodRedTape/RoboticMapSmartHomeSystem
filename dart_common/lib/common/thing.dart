import 'package:dart_common/common/attributes.dart';

enum IntegrationType {
  homeAssistant('home_assistant'),
  zigbee('zigbee'),
  matter('matter'),
  homekit('homekit'),
  roborock('roborock'),
  virtual('virtual');

  final String value;
  const IntegrationType(this.value);

  factory IntegrationType.fromString(String value) {
    return IntegrationType.values.firstWhere((e) => e.value == value, orElse: () => throw ArgumentError('Unknown IntegrationType: $value'));
  }
}

enum LocationType {
  manual('manual'),
  auto('auto');

  final String value;
  const LocationType(this.value);

  factory LocationType.fromString(String value) {
    return LocationType.values.firstWhere((e) => e.value == value, orElse: () => throw ArgumentError('Unknown LocationType: $value'));
  }
}

class Thing {
  String id;
  String name;
  List<Attribute> attributes;

  Thing({required this.id, required this.name, required this.attributes});

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'attributes': attributes.map((attr) => attr.toJson()).toList()};
  }

  T? findAttribute<T extends Attribute>() {
    for (final attribute in attributes) {
      if (attribute is T) return attribute;
    }
    return null;
  }

  bool hasAttribute<T extends Attribute>() {
    return findAttribute<T>() != null;
  }

  bool get hasLocation {
    return findAttribute<LocationAttribute>() != null;
  }

  bool get isAutoLocation {
    final location = findAttribute<LocationAttribute>();

    return location != null ? location.locationType == LocationType.auto : false;
  }
}
