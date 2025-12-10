class HaEntityState {
  String entityId;
  String state;
  Map<String, dynamic> attributes;
  String lastChanged;
  String lastUpdated;

  HaEntityState({
    required this.entityId,
    required this.state,
    Map<String, dynamic>? attributes,
    required this.lastChanged,
    required this.lastUpdated,
  }) : attributes = attributes ?? {};

  factory HaEntityState.fromJson(Map<String, dynamic> json) {
    return HaEntityState(
      entityId: json['entity_id'] as String,
      state: json['state'] as String,
      attributes: (json['attributes'] as Map<String, dynamic>?) ?? {},
      lastChanged: json['last_changed'] as String,
      lastUpdated: json['last_updated'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entity_id': entityId,
      'state': state,
      'attributes': attributes,
      'last_changed': lastChanged,
      'last_updated': lastUpdated,
    };
  }
}

class HaEntityRegistry {
  String entityId;
  String? deviceId;
  String? areaId;
  String? platform;

  HaEntityRegistry({
    required this.entityId,
    this.deviceId,
    this.areaId,
    this.platform,
  });

  factory HaEntityRegistry.fromJson(Map<String, dynamic> json) {
    return HaEntityRegistry(
      entityId: json['entity_id'] as String,
      deviceId: json['device_id'] as String?,
      areaId: json['area_id'] as String?,
      platform: json['platform'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entity_id': entityId,
      'device_id': deviceId,
      'area_id': areaId,
      'platform': platform,
    };
  }
}

class HaDeviceRegistry {
  String id;
  String? name;
  String? nameByUser;
  String? areaId;
  String? manufacturer;
  String? model;

  HaDeviceRegistry({
    required this.id,
    this.name,
    this.nameByUser,
    this.areaId,
    this.manufacturer,
    this.model,
  });

  factory HaDeviceRegistry.fromJson(Map<String, dynamic> json) {
    return HaDeviceRegistry(
      id: json['id'] as String,
      name: json['name'] as String?,
      nameByUser: json['name_by_user'] as String?,
      areaId: json['area_id'] as String?,
      manufacturer: json['manufacturer'] as String?,
      model: json['model'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_by_user': nameByUser,
      'area_id': areaId,
      'manufacturer': manufacturer,
      'model': model,
    };
  }
}

class HaAreaRegistry {
  String areaId;
  String? name;

  HaAreaRegistry({
    required this.areaId,
    this.name,
  });

  factory HaAreaRegistry.fromJson(Map<String, dynamic> json) {
    return HaAreaRegistry(
      areaId: json['area_id'] as String,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'area_id': areaId,
      'name': name,
    };
  }
}

class HaStateChangedEvent {
  String entityId;
  HaEntityState? oldState;
  HaEntityState? newState;

  HaStateChangedEvent({
    required this.entityId,
    this.oldState,
    this.newState,
  });

  factory HaStateChangedEvent.fromJson(Map<String, dynamic> json) {
    return HaStateChangedEvent(
      entityId: json['entity_id'] as String,
      oldState: json['old_state'] != null
          ? HaEntityState.fromJson(json['old_state'] as Map<String, dynamic>)
          : null,
      newState: json['new_state'] != null
          ? HaEntityState.fromJson(json['new_state'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entity_id': entityId,
      'old_state': oldState?.toJson(),
      'new_state': newState?.toJson(),
    };
  }
}