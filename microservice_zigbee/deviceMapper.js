const ZIGBEE_TO_COMMON_TYPES = {
  'light': 'light',
  'switch': 'switch',
  'dimmer': 'dimmer_light',
  'color_light': 'color_light',
  'temperature': 'temperature_sensor',
  'humidity': 'humidity_sensor',
  'contact': 'contact_sensor',
  'motion': 'motion_sensor',
  'occupancy': 'occupancy_sensor',
  'door_lock': 'door_lock',
  'plug': 'plug',
  'thermostat': 'thermostat',
  'cover': 'window_covering',
  'button': 'button',
  'vibration': 'vibration_sensor',
  'leak': 'leak_sensor',
  'smoke': 'smoke_sensor',
};

class DeviceMapper {
  static mapZigbeeDevice(zigbeeDevice) {
    const ieee = zigbeeDevice.ieee_address;
    const type = zigbeeDevice.definition?.type || 'unknown';

    if (!ZIGBEE_TO_COMMON_TYPES[type]) {
      return null;
    }

    const commonType = ZIGBEE_TO_COMMON_TYPES[type];
    const attributes = this._extractAttributes(zigbeeDevice);
    const commands = this._getAvailableCommands(type);

    return {
      id: `zigbee_${ieee}`,
      type: commonType,
      name: zigbeeDevice.friendly_name || `Zigbee Device ${ieee}`,
      protocol: 'zigbee',
      attributes,
      commands,
      metadata: {
        ieee_address: ieee,
        network_address: zigbeeDevice.network_address,
        model: zigbeeDevice.definition?.model,
        vendor: zigbeeDevice.definition?.vendor,
        power_source: zigbeeDevice.power_source,
        link_quality: zigbeeDevice.link_quality,
      }
    };
  }

  static _extractAttributes(zigbeeDevice) {
    const attributes = [];
    const state = zigbeeDevice.state || {};

    const attrMapping = {
      'state': { name: 'state', type: 'boolean', transform: (v) => v === 'ON' },
      'brightness': { name: 'brightness', type: 'percentage', transform: (v) => Math.round((v / 255) * 100) },
      'color_temp': { name: 'color_temp', type: 'color_temperature' },
      'color': { name: 'color', type: 'color' },
      'temperature': { name: 'temperature', type: 'temperature' },
      'humidity': { name: 'humidity', type: 'percentage' },
      'contact': { name: 'contact', type: 'boolean' },
      'occupancy': { name: 'occupancy', type: 'boolean' },
      'motion': { name: 'motion', type: 'boolean' },
      'lock_state': { name: 'lock_state', type: 'boolean' },
      'position': { name: 'position', type: 'percentage' },
      'voltage': { name: 'voltage', type: 'number' },
      'battery': { name: 'battery', type: 'percentage' },
      'power': { name: 'power', type: 'number' },
      'energy': { name: 'energy', type: 'number' },
      'current': { name: 'current', type: 'number' },
    };

    for (const [key, config] of Object.entries(attrMapping)) {
      if (state[key] !== undefined) {
        const value = config.transform ? config.transform(state[key]) : state[key];
        attributes.push({
          name: config.name,
          value,
          type: config.type
        });
      }
    }

    return attributes;
  }

  static _getAvailableCommands(type) {
    const commandMapping = {
      'light': ['turn_on', 'turn_off', 'toggle'],
      'switch': ['turn_on', 'turn_off', 'toggle'],
      'dimmer': ['turn_on', 'turn_off', 'set_brightness'],
      'color_light': ['turn_on', 'turn_off', 'set_brightness', 'set_color', 'set_color_temp'],
      'plug': ['turn_on', 'turn_off', 'toggle'],
      'door_lock': ['lock', 'unlock'],
      'thermostat': ['set_temperature', 'set_mode'],
      'cover': ['open', 'close', 'set_position'],
    };
    return commandMapping[type] || [];
  }

  static mapCommandToZigbee(command, params) {
    const commandMapping = {
      'turn_on': { state: 'ON' },
      'turn_off': { state: 'OFF' },
      'toggle': { state: 'TOGGLE' },
      'set_brightness': { brightness: Math.round((params.brightness / 100) * 255) },
      'set_color_temp': { color_temp: params.color_temp },
      'set_color': { color: params.color },
      'lock': { state: 'LOCK' },
      'unlock': { state: 'UNLOCK' },
      'set_temperature': { occupied_heating_setpoint: params.temperature },
      'set_mode': { system_mode: params.mode },
      'open': { state: 'OPEN' },
      'close': { state: 'CLOSE' },
      'set_position': { position: params.position },
    };

    return commandMapping[command] || null;
  }
}

module.exports = DeviceMapper;
