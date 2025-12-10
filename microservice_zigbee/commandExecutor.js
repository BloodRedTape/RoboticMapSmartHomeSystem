const DeviceMapper = require('./deviceMapper');

class CommandExecutor {
  constructor(mqttClient, baseTopic) {
    this.mqttClient = mqttClient;
    this.baseTopic = baseTopic;
  }

  async executeCommand(friendlyName, command, params) {
    try {
      const zigbeePayload = DeviceMapper.mapCommandToZigbee(command, params);

      if (!zigbeePayload) {
        console.error(`Unknown command: ${command}`);
        return false;
      }

      const topic = `${this.baseTopic}/${friendlyName}/set`;
      const payload = JSON.stringify(zigbeePayload);

      return new Promise((resolve, reject) => {
        this.mqttClient.publish(topic, payload, (err) => {
          if (err) {
            console.error(`Error publishing command to ${topic}:`, err);
            reject(err);
          } else {
            console.log(`Command sent to ${friendlyName}: ${payload}`);
            resolve(true);
          }
        });
      });
    } catch (error) {
      console.error(`Error executing command ${command}:`, error);
      return false;
    }
  }

  async enablePairing(duration = 120) {
    const topic = `${this.baseTopic}/bridge/request/permit_join`;
    const payload = JSON.stringify({ value: true, time: duration });

    return new Promise((resolve, reject) => {
      this.mqttClient.publish(topic, payload, (err) => {
        if (err) {
          console.error('Error enabling pairing:', err);
          reject(err);
        } else {
          console.log(`Pairing enabled for ${duration} seconds`);
          resolve(true);
        }
      });
    });
  }

  async disablePairing() {
    const topic = `${this.baseTopic}/bridge/request/permit_join`;
    const payload = JSON.stringify({ value: false });

    return new Promise((resolve, reject) => {
      this.mqttClient.publish(topic, payload, (err) => {
        if (err) {
          console.error('Error disabling pairing:', err);
          reject(err);
        } else {
          console.log('Pairing disabled');
          resolve(true);
        }
      });
    });
  }

  async removeDevice(friendlyName) {
    const topic = `${this.baseTopic}/bridge/request/device/remove`;
    const payload = JSON.stringify({ id: friendlyName });

    return new Promise((resolve, reject) => {
      this.mqttClient.publish(topic, payload, (err) => {
        if (err) {
          console.error(`Error removing device ${friendlyName}:`, err);
          reject(err);
        } else {
          console.log(`Device ${friendlyName} removed`);
          resolve(true);
        }
      });
    });
  }
}

module.exports = CommandExecutor;
