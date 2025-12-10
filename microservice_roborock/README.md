# Roborock Microservice

Microservice for integrating Roborock vacuum robots into the smart home system.

## Features

- Device discovery and binding
- Complete device lifecycle management
- Map import and room segmentation
- Real-time position tracking
- Cleaning commands and scheduling
- Consumables monitoring
- Status reporting

## API Endpoints

### Device Management
- GET /devices - List all connected Roborock devices
- POST /devices/discover - Discover devices in local network
- GET /devices/{device_id} - Get device details
- POST /devices/{device_id}/bind - Bind device with IP and token
- DELETE /devices/{device_id} - Remove device from system

### Device Control
- POST /devices/{device_id}/command - Send raw command to device
- GET /devices/{device_id}/status - Get current device status
- GET /devices/{device_id}/consumables - Get consumables status
- GET /devices/{device_id}/clean-summary - Get cleaning history summary

### Map Operations
- GET /devices/{device_id}/map - Get current map data
- POST /devices/{device_id}/map/import - Import map from device to core system
- GET /devices/{device_id}/map/rooms - Get list of rooms from device map

### Position Tracking
- GET /devices/{device_id}/position - Get current robot position

### Cleaning Commands
- POST /devices/{device_id}/clean - Start full cleaning
- POST /devices/{device_id}/clean-room - Clean specific rooms
- POST /devices/{device_id}/pause - Pause cleaning
- POST /devices/{device_id}/stop - Stop cleaning
- POST /devices/{device_id}/dock - Return to dock

## Installation

pip install -r requirements.txt

## Running

python main.py

## Integration with Core System

This microservice is designed to communicate with the core system microservice through HTTP API. The core system polls device states and sends commands through this service.
