const express = require('express');
const mqtt = require('mqtt');

class ZigbeeMicroservice {
    constructor() {
        this.app = express();
        this.devices = new Map();
        this.groups = new Map();
        this.mqttClient = null;
        this.bridgeInfo = null;
        this.permitJoinEnabled = false;

        this.app.use(express.json());
        this.setupRoutes();
        this.connectMQTT();
    }

    setupRoutes() {
        // Device management
        this.app.get('/devices', (req, res) => {
            res.json(Array.from(this.devices.values()));
        });

        this.app.get('/devices/:id', (req, res) => {
            const device = this.devices.get(req.params.id);
            if (device) {
                res.json(device);
            } else {
                res.status(404).json({ error: 'Device not found' });
            }
        });

        this.app.delete('/devices/:id', (req, res) => {
            const { id } = req.params;
            const topic = 'zigbee2mqtt/bridge/request/device/remove';
            this.mqttClient.publish(topic, JSON.stringify({ id: id }));

            this.devices.delete(id);
            res.json({ status: 'success', message: 'Device removed' });
        });

        this.app.post('/devices/:id/rename', (req, res) => {
            const { id } = req.params;
            const { name } = req.body;

            const topic = 'zigbee2mqtt/bridge/request/device/rename';
            this.mqttClient.publish(topic, JSON.stringify({ from: id, to: name }));

            res.json({ status: 'success', old_name: id, new_name: name });
        });

        // Device control
        this.app.post('/devices/:id/command', (req, res) => {
            const { id } = req.params;
            const { command, params } = req.body;

            const topic = `zigbee2mqtt/${id}/set`;
            this.mqttClient.publish(topic, JSON.stringify(params));

            res.json({
                status: 'success',
                device_id: id,
                command: command,
                params: params
            });
        });

        this.app.get('/devices/:id/state', (req, res) => {
            const device = this.devices.get(req.params.id);
            if (device) {
                res.json({ device_id: req.params.id, state: device.state });
            } else {
                res.status(404).json({ error: 'Device not found' });
            }
        });

        // Pairing and binding
        this.app.post('/permit-join', (req, res) => {
            const { duration } = req.body;
            this.mqttClient.publish('zigbee2mqtt/bridge/request/permit_join', JSON.stringify({
                value: true,
                time: duration || 60
            }));

            this.permitJoinEnabled = true;
            setTimeout(() => {
                this.permitJoinEnabled = false;
            }, (duration || 60) * 1000);

            res.json({
                status: 'permit_join_enabled',
                duration: duration || 60
            });
        });

        this.app.post('/permit-join/stop', (req, res) => {
            this.mqttClient.publish('zigbee2mqtt/bridge/request/permit_join', JSON.stringify({ value: false }));
            this.permitJoinEnabled = false;
            res.json({ status: 'permit_join_disabled' });
        });

        this.app.get('/permit-join/status', (req, res) => {
            res.json({ permit_join: this.permitJoinEnabled });
        });

        this.app.post('/devices/:id/bind', (req, res) => {
            const { id } = req.params;
            const { target, cluster } = req.body;

            const topic = 'zigbee2mqtt/bridge/request/device/bind';
            this.mqttClient.publish(topic, JSON.stringify({
                from: id,
                to: target,
                clusters: [cluster]
            }));

            res.json({ status: 'success', device: id, target: target, cluster: cluster });
        });

        this.app.post('/devices/:id/unbind', (req, res) => {
            const { id } = req.params;
            const { target, cluster } = req.body;

            const topic = 'zigbee2mqtt/bridge/request/device/unbind';
            this.mqttClient.publish(topic, JSON.stringify({
                from: id,
                to: target,
                clusters: [cluster]
            }));

            res.json({ status: 'success', device: id, target: target, cluster: cluster });
        });

        // Groups management
        this.app.get('/groups', (req, res) => {
            res.json(Array.from(this.groups.values()));
        });

        this.app.post('/groups', (req, res) => {
            const { id, friendly_name } = req.body;
            const topic = 'zigbee2mqtt/bridge/request/group/add';
            this.mqttClient.publish(topic, JSON.stringify({ id: id, friendly_name: friendly_name }));

            res.json({ status: 'success', group_id: id, name: friendly_name });
        });

        this.app.delete('/groups/:id', (req, res) => {
            const { id } = req.params;
            const topic = 'zigbee2mqtt/bridge/request/group/remove';
            this.mqttClient.publish(topic, JSON.stringify({ id: id }));

            this.groups.delete(id);
            res.json({ status: 'success', message: 'Group removed' });
        });

        this.app.post('/groups/:id/members/add', (req, res) => {
            const { id } = req.params;
            const { device_id } = req.body;

            const topic = 'zigbee2mqtt/bridge/request/group/members/add';
            this.mqttClient.publish(topic, JSON.stringify({ group: id, device: device_id }));

            res.json({ status: 'success', group: id, device: device_id });
        });

        this.app.post('/groups/:id/members/remove', (req, res) => {
            const { id } = req.params;
            const { device_id } = req.body;

            const topic = 'zigbee2mqtt/bridge/request/group/members/remove';
            this.mqttClient.publish(topic, JSON.stringify({ group: id, device: device_id }));

            res.json({ status: 'success', group: id, device: device_id });
        });

        // Bridge info
        this.app.get('/bridge/info', (req, res) => {
            res.json(this.bridgeInfo || { status: 'unknown' });
        });

        this.app.get('/bridge/config', (req, res) => {
            this.mqttClient.publish('zigbee2mqtt/bridge/request/config', '');
            res.json({ status: 'requested' });
        });

        // OTA updates
        this.app.post('/devices/:id/ota/check', (req, res) => {
            const { id } = req.params;
            const topic = 'zigbee2mqtt/bridge/request/device/ota_update/check';
            this.mqttClient.publish(topic, JSON.stringify({ id: id }));

            res.json({ status: 'checking', device: id });
        });

        this.app.post('/devices/:id/ota/update', (req, res) => {
            const { id } = req.params;
            const topic = 'zigbee2mqtt/bridge/request/device/ota_update/update';
            this.mqttClient.publish(topic, JSON.stringify({ id: id }));

            res.json({ status: 'updating', device: id });
        });

        // Network map
        this.app.get('/network/map', (req, res) => {
            res.json({
                status: 'success',
                map: {
                    nodes: Array.from(this.devices.values()).map(d => ({
                        id: d.id,
                        type: d.type || 'unknown',
                        lqi: d.linkquality || 0
                    }))
                }
            });
        });
    }

    connectMQTT() {
        this.mqttClient = mqtt.connect('mqtt://localhost:1883');

        this.mqttClient.on('connect', () => {
            console.log('Connected to MQTT broker');
            this.mqttClient.subscribe('zigbee2mqtt/#');
            this.mqttClient.publish('zigbee2mqtt/bridge/request/health_check', '');
        });

        this.mqttClient.on('message', (topic, message) => {
            try {
                const data = JSON.parse(message.toString());

                if (topic === 'zigbee2mqtt/bridge/info') {
                    this.bridgeInfo = data;
                } else if (topic === 'zigbee2mqtt/bridge/devices') {
                    data.forEach(device => {
                        this.devices.set(device.friendly_name, {
                            id: device.friendly_name,
                            ieee_address: device.ieee_address,
                            type: device.type,
                            model: device.model_id,
                            vendor: device.manufacturer,
                            supported: device.supported,
                            state: {}
                        });
                    });
                } else if (topic === 'zigbee2mqtt/bridge/groups') {
                    data.forEach(group => {
                        this.groups.set(group.friendly_name, {
                            id: group.id,
                            friendly_name: group.friendly_name,
                            members: group.members
                        });
                    });
                } else if (topic.startsWith('zigbee2mqtt/') && !topic.includes('bridge')) {
                    const deviceId = topic.split('/')[1];
                    if (topic.endsWith('/availability')) {
                        const device = this.devices.get(deviceId);
                        if (device) {
                            device.available = data.state === 'online';
                        }
                    } else {
                        const device = this.devices.get(deviceId);
                        if (device) {
                            device.state = { ...device.state, ...data };
                            device.last_seen = new Date().toISOString();
                        }
                    }
                }
            } catch (e) {
                console.error('Failed to parse MQTT message:', e);
            }
        });
    }

    run(port = 8084) {
        this.app.listen(port, () => {
            console.log(`Zigbee microservice listening on port ${port}`);
        });
    }
}

const service = new ZigbeeMicroservice();
service.run();
