class DeviceCoordinates {
  String entityId;
  double x;
  double y;

  DeviceCoordinates({
    required this.entityId,
    required this.x,
    required this.y,
  });

  factory DeviceCoordinates.fromJson(Map<String, dynamic> json) {
    return DeviceCoordinates(
      entityId: json['entity_id'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entity_id': entityId,
      'x': x,
      'y': y,
    };
  }
}

class MoveCoordinates {
  double x;
  double y;

  MoveCoordinates({
    required this.x,
    required this.y,
  });

  factory MoveCoordinates.fromJson(Map<String, dynamic> json) {
    return MoveCoordinates(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
    };
  }
}

class DeviceCustomization {
  String? name;
  String? icon;
  String? color;
  String? integration;

  DeviceCustomization({
    this.name,
    this.icon,
    this.color,
    this.integration,
  });

  factory DeviceCustomization.fromJson(Map<String, dynamic> json) {
    return DeviceCustomization(
      name: json['name'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      integration: json['integration'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'color': color,
      'integration': integration,
    };
  }
}

class HumanCoordinates {
  String humanId;
  double x;
  double y;

  HumanCoordinates({
    required this.humanId,
    required this.x,
    required this.y,
  });

  factory HumanCoordinates.fromJson(Map<String, dynamic> json) {
    return HumanCoordinates(
      humanId: json['human_id'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'human_id': humanId,
      'x': x,
      'y': y,
    };
  }
}
