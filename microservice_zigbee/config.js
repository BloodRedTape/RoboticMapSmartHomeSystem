module.exports = {
  mqtt: {
    broker: process.env.MQTT_BROKER || 'mqtt://localhost:1883',
    baseTopic: process.env.MQTT_BASE_TOPIC || 'zigbee2mqtt',
    clientId: process.env.MQTT_CLIENT_ID || 'smarthome_zigbee_service',
    username: process.env.MQTT_USERNAME || '',
    password: process.env.MQTT_PASSWORD || '',
  },
  backend: {
    url: process.env.BACKEND_URL || 'http://localhost:8080',
  },
  server: {
    host: process.env.LISTEN_HOST || '0.0.0.0',
    port: parseInt(process.env.LISTEN_PORT) || 5582,
  },
  logging: {
    level: process.env.LOG_LEVEL || 'info',
  },
  pairing: {
    timeout: parseInt(process.env.PAIRING_TIMEOUT) || 120,
  },
  reconnect: {
    interval: parseInt(process.env.RECONNECT_INTERVAL) || 5000,
  },
};
