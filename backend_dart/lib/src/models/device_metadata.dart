class DeviceMetadata {
  String deviceId;
  double? x;
  double? y;
  String? roomId;
  String? name;
  String? icon;
  String? color;
  String? integration;
  bool hidden;
  bool isVirtual;

  DeviceMetadata({
    required this.deviceId,
    this.x,
    this.y,
    this.roomId,
    this.name,
    this.icon,
    this.color,
    this.integration,
    this.hidden = false,
    this.isVirtual = false,
  });

  factory DeviceMetadata.fromJson(Map<String, dynamic> json) {
    return DeviceMetadata(
      deviceId: json['device_id'] as String,
      x: (json['x'] as num?)?.toDouble(),
      y: (json['y'] as num?)?.toDouble(),
      roomId: json['room_id'] as String?,
      name: json['name'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      integration: json['integration'] as String?,
      hidden: json['hidden'] as bool? ?? false,
      isVirtual: json['is_virtual'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'x': x,
      'y': y,
      'room_id': roomId,
      'name': name,
      'icon': icon,
      'color': color,
      'integration': integration,
      'hidden': hidden,
      'is_virtual': isVirtual,
    };
  }
}