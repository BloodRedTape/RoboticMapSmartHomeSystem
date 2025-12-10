# HomeKit Microservice

Microservice for integrating HomeKit devices using extended hap library.

## Features

- Device discovery via mDNS/Bonjour
- Device pairing and unpairing
- Characteristic reading and writing
- Service enumeration
- Real-time state synchronization
- Thread-safe concurrent access

## API Endpoints

### Device Management
- GET /devices - List all HomeKit devices
- POST /devices/discover - Discover devices in local network
- GET /devices/{id} - Get device details
- POST /devices/{id}/pair - Pair device with setup code
- POST /devices/{id}/unpair - Unpair device
- DELETE /devices/{id} - Remove device from system

### Characteristics Management
- GET /devices/{id}/characteristics - Get all device characteristics
- GET /devices/{id}/characteristics/{characteristic} - Get specific characteristic value
- PUT /devices/{id}/characteristics/{characteristic} - Set characteristic value

### Device Control
- POST /devices/{id}/command - Send command to device
- GET /devices/{id}/services - Get device services

## Installation

go mod download

## Running

go run main.go

## Integration with Core System

This microservice communicates with the core system through HTTP API. The core system polls device characteristics and sends commands through this service. Device state updates are pushed to core via polling mechanism.
