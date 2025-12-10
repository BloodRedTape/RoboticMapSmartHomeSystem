# Matter Microservice

Microservice for integrating Matter protocol devices using python-matter-server.

## Features

- Device discovery and commissioning
- Device decommissioning and removal
- Cluster enumeration and interaction
- Attribute reading and writing
- Command execution
- Endpoint management
- Attribute subscription support

## API Endpoints

### Device Management
- GET /devices - List all Matter devices
- POST /devices/discover - Discover uncommissioned devices
- GET /devices/{device_id} - Get device details
- POST /devices/commission - Commission new Matter device with setup code
- POST /devices/{device_id}/decommission - Decommission device
- DELETE /devices/{device_id} - Remove device from system

### Cluster and Attributes
- GET /devices/{device_id}/clusters - Get all device clusters
- GET /devices/{device_id}/attributes - Get all device attributes
- GET /devices/{device_id}/attributes/{attribute_id} - Read specific attribute
- PUT /devices/{device_id}/attributes/{attribute_id} - Write specific attribute

### Commands
- POST /devices/{device_id}/command - Send cluster command to device
- POST /devices/{device_id}/cluster/{cluster_id}/command/{command_id} - Send specific cluster command

### Device Info
- GET /devices/{device_id}/info - Get device information
- GET /devices/{device_id}/endpoints - Get device endpoints
- POST /devices/{device_id}/subscribe - Subscribe to attribute updates

## Installation

pip install -r requirements.txt

## Running

python main.py

## Integration with Core System

This microservice communicates with the core system through HTTP API. The core system polls device attributes and sends commands through this service. Matter protocol specifics like clusters and attributes are abstracted into a unified interface.
