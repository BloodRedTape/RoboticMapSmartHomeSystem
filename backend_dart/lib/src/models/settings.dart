class Settings {
  bool enablePrivacyZones;
  bool enableCameras;
  int dataRetentionDays;
  double iconScale;

  Settings({
    this.enablePrivacyZones = true,
    this.enableCameras = true,
    this.dataRetentionDays = 90,
    this.iconScale = 1.0,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      enablePrivacyZones: json['EnablePrivacyZones'] ?? true,
      enableCameras: json['EnableCameras'] ?? true,
      dataRetentionDays: json['DataRetentionDays'] ?? 90,
      iconScale: (json['IconScale'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'EnablePrivacyZones': enablePrivacyZones,
      'EnableCameras': enableCameras,
      'DataRetentionDays': dataRetentionDays,
      'IconScale': iconScale,
    };
  }
}