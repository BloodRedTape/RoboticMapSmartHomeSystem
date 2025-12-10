import 'package:dart_common/common/attributes.dart';
import 'package:dart_common/common/device.dart';
import 'package:flutter/material.dart';

class DeviceIconUtils {
  static final Map<String, IconData> iconMap = {
    'lightbulb': Icons.lightbulb,
    'videocam': Icons.videocam,
    'air': Icons.air,
    'power': Icons.power,
    'sensors': Icons.sensors,
    'motion_photos_on': Icons.motion_photos_on,
    'thermostat': Icons.thermostat,
    'lock': Icons.lock,
    'window': Icons.window,
    'speaker': Icons.speaker,
    'place': Icons.place,
    'location_on': Icons.location_on,
    'flag': Icons.flag,
    'star': Icons.star,
    'favorite': Icons.favorite,
    'push_pin': Icons.push_pin,
    'radio_button_checked': Icons.radio_button_checked,
    'trip_origin': Icons.trip_origin,
    'battery_charging_full': Icons.battery_charging_full,
    'tv': Icons.tv,
    'computer': Icons.computer,
    'phone_android': Icons.phone_android,
    'tablet': Icons.tablet,
    'watch': Icons.watch,
    'router': Icons.router,
    'wifi': Icons.wifi,
    'bluetooth': Icons.bluetooth,
    'kitchen': Icons.kitchen,
    'microwave': Icons.microwave,
    'coffee': Icons.coffee,
    'local_laundry_service': Icons.local_laundry_service,
    'shower': Icons.shower,
    'bathtub': Icons.bathtub,
    'bed': Icons.bed,
    'chair': Icons.chair,
    'weekend': Icons.weekend,
    'light_mode': Icons.light_mode,
    'dark_mode': Icons.dark_mode,
    'wb_incandescent': Icons.wb_incandescent,
    'flashlight_on': Icons.flashlight_on,
    'nightlight': Icons.nightlight,
    'wb_sunny': Icons.wb_sunny,
    'ac_unit': Icons.ac_unit,
    'local_fire_department': Icons.local_fire_department,
    'water_drop': Icons.water_drop,
    'opacity': Icons.opacity,
    'garage': Icons.garage,
    'meeting_room': Icons.meeting_room,
    'doorbell': Icons.doorbell,
    'alarm': Icons.alarm,
    'notifications': Icons.notifications,
    'volume_up': Icons.volume_up,
    'music_note': Icons.music_note,
    'headphones': Icons.headphones,
    'lightbulb_outline': Icons.lightbulb_outline,
    'settings_remote': Icons.settings_remote,
    'toys': Icons.toys,
    'pets': Icons.pets,
    'grass': Icons.grass,
    'local_florist': Icons.local_florist,
    'yard': Icons.yard,
    'pool': Icons.pool,
    'device_thermostat': Icons.device_thermostat,
    'device_hub': Icons.device_hub,
    'home': Icons.home,
    'home_work': Icons.home_work,
    'bed_outlined': Icons.bed_outlined,
    'living': Icons.living,
    'desk': Icons.desk,
    'dining': Icons.dining,
    'outlet': Icons.outlet,
    'power_settings_new': Icons.power_settings_new,
    'electric_bolt': Icons.electric_bolt,
    'light': Icons.light,
    'tungsten': Icons.tungsten,
    'celebration': Icons.celebration,
    'tips_and_updates': Icons.tips_and_updates,
    'blinds': Icons.blinds,
    'blinds_closed': Icons.blinds_closed,
    'curtains': Icons.curtains,
    'curtains_closed': Icons.curtains_closed,
    'cleaning_services': Icons.cleaning_services,
    'print': Icons.print,
    'precision_manufacturing': Icons.precision_manufacturing,
    'settings_suggest': Icons.settings_suggest,
    'build': Icons.build,
    'handyman': Icons.handyman,
    'thermostat_auto': Icons.thermostat_auto,
    'air_outlined': Icons.air_outlined,
    'cloud': Icons.cloud,
    'eco': Icons.eco,
    'filter_drama': Icons.filter_drama,
    'waves': Icons.waves,
    'co2': Icons.co2_outlined,
    'sensor': Icons.sensor_door,
    'occupied': Icons.sensor_occupied_outlined,
  };

  static IconData getDeviceIcon(Device device) {
    if (device.icon != null) {
      return iconMap[device.icon] ?? Icons.device_unknown;
    }

    return Icons.device_unknown;
  }

  static Color? fromRGBA(List<int>? rgbColor) {
    if (rgbColor == null) return null;
    return Color.fromARGB(255, rgbColor![0], rgbColor![1], rgbColor![2]);
  }

  static Color getDeviceColor(Device device) {
    if (!device.isOnline) return Colors.grey;

    final light = fromRGBA(device.findAttribute<LightAttribute>()?.rgbColor);

    if (light != null) return light;

    if (device.color != null) {
      try {
        return Color(int.parse(device.color!.replaceFirst('#', '0xFF')));
      } catch (e) {
        return Colors.teal;
      }
    }
    return Colors.teal;
  }
}
