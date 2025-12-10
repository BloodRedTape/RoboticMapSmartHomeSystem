# Zigbee Microservice

Microservice for integrating Zigbee devices using Zigbee2MQTT.

## Features

- Device discovery and management via MQTT
- Device removal and renaming
- Real-time state updates via MQTT subscriptions
- Device pairing and binding
- Group management
- OTA firmware updates
- Bridge configuration and monitoring
- Network topology mapping

## API Endpoints

### Device Management
- GET /devices - List all Zigbee devices
- GET /devices/{id} - Get device details
- DELETE /devices/{id} - Remove device from network
- POST /devices/{id}/rename - Rename device

### Device Control
- POST /devices/{id}/command - Send command to device
- GET /devices/{id}/state - Get current device state

### Pairing and Binding
- POST /permit-join - Enable device pairing mode
- POST /permit-join/stop - Disable pairing mode
- GET /permit-join/status - Get pairing mode status
- POST /devices/{id}/bind - Bind device to target
- POST /devices/{id}/unbind - Unbind device from target

### Groups Management
- GET /groups - List all groups
- POST /groups - Create new group
- DELETE /groups/{id} - Delete group
- POST /groups/{id}/members/add - Add device to group
- POST /groups/{id}/members/remove - Remove device from group

### Bridge Operations
- GET /bridge/info - Get Zigbee2MQTT bridge information
- GET /bridge/config - Request bridge configuration

### OTA Updates
- POST /devices/{id}/ota/check - Check for firmware updates
- POST /devices/{id}/ota/update - Start firmware update

### Network
- GET /network/map - Get Zigbee network topology

## Installation

npm install

## Running

npm start

## Requirements

- MQTT broker running on localhost:1883
- Zigbee2MQTT instance connected to the same MQTT broker

## Integration with Core System

This microservice communicates with the core system through HTTP API for commands and exposes device states that are updated via MQTT. The core system subscribes to this service for device state changes and sends control commands via HTTP endpoints.
