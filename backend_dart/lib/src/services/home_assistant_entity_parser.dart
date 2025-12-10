import 'package:dart_common/dart_common.dart';
import 'package:backend_dart/src/models/home_assistant/ha_models.dart';

class HomeAssistantEntityParser {
  static Attribute? createAttributeForEntity(HaEntityState entity, String domain, String state, String Function(String) getOrCreateAttributeGuid) {
    final attrs = entity.attributes;
    final guid = getOrCreateAttributeGuid(entity.entityId);

    switch (domain) {
      case 'light':
        return LightAttribute(
          state: state,
          brightness: _getIntValue(attrs, 'brightness'),
          colorTemp: _getIntValue(attrs, 'color_temp'),
          rgbColor: _getIntListValue(attrs, 'rgb_color'),
          guid: guid,
        );
      case 'switch':
        return SwitchAttribute(state: state, guid: guid);
      case 'button':
        return ButtonAttribute(lastPressed: entity.lastChanged, lastAction: attrs['action']?.toString(), guid: guid);
      case 'sensor':
        return SensorAttribute(
          state: state,
          measurement: _safeDouble(state),
          unit: attrs['unit_of_measurement']?.toString(),
          deviceClass: SensorAttribute.parseDeviceClass(attrs['device_class']?.toString()),
          guid: guid,
        );
      case 'binary_sensor':
        return BinarySensorAttribute(state: state, deviceClass: attrs['device_class']?.toString(), guid: guid);
      case 'fan':
        return FanAttribute(
          state: state,
          speed: _getIntValue(attrs, 'percentage'),
          oscillating: _getBoolValue(attrs, 'oscillating'),
          direction: attrs['direction']?.toString(),
          guid: guid,
        );
      case 'climate':
        return ClimateAttribute(
          state: state,
          currentTemperature: _getDoubleValue(attrs, 'current_temperature'),
          targetTemperature: _getDoubleValue(attrs, 'temperature'),
          fanMode: attrs['fan_mode']?.toString(),
          humidity: _getDoubleValue(attrs, 'current_humidity'),
          guid: guid,
        );
      case 'lock':
        return LockAttribute(state: state, guid: guid);
      case 'cover':
        return CoverAttribute(
          state: state,
          position: _getIntValue(attrs, 'current_position'),
          tiltPosition: _getIntValue(attrs, 'current_tilt_position'),
          guid: guid,
        );
      case 'media_player':
        return MediaPlayerAttribute(
          state: state,
          volume: _getDoubleValue(attrs, 'volume_level'),
          isMuted: _getBoolValue(attrs, 'is_volume_muted'),
          mediaTitle: attrs['media_title']?.toString(),
          mediaArtist: attrs['media_artist']?.toString(),
          source: attrs['source']?.toString(),
          guid: guid,
        );
      case 'vacuum':
        return VacuumAttribute(
          state: state,
          batteryLevel: _getIntValue(attrs, 'battery_level'),
          fanSpeed: attrs['fan_speed']?.toString(),
          status: attrs['status']?.toString(),
          fanSpeedList: _getStringListValue(attrs, 'fan_speed_list'),
          guid: guid,
        );
      default:
        return null;
    }
  }

  static int? _getIntValue(Map<String, dynamic> attrs, String key) {
    final value = attrs[key];
    if (value is int) {
      return value;
    } else if (value is String) {
      return int.tryParse(value);
    } else if (value is num) {
      return value.toInt();
    }
    return null;
  }

  static double? _getDoubleValue(Map<String, dynamic> attrs, String key) {
    final value = attrs[key];
    if (value is double) {
      return value;
    } else if (value is int) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static bool _getBoolValue(Map<String, dynamic> attrs, String key) {
    final value = attrs[key];
    if (value is bool) {
      return value;
    } else if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return false;
  }

  static List<int>? _getIntListValue(Map<String, dynamic> attrs, String key) {
    final value = attrs[key];
    if (value is List) {
      return value.cast<int>().toList();
    }
    return null;
  }

  static List<String>? _getStringListValue(Map<String, dynamic> attrs, String key) {
    final value = attrs[key];
    if (value is List) {
      return value.cast<String>().toList();
    }
    return null;
  }

  static double? _safeDouble(String value) {
    return double.tryParse(value);
  }
}
