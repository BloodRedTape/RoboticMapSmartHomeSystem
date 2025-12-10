import asyncio
import json
from aiohttp import web
from typing import Dict, List, Optional
from datetime import datetime

class MatterMicroservice:
    def __init__(self):
        self.devices: Dict[str, dict] = {}
        self.app = web.Application()
        self.commissioning = False
        self.setup_routes()

    def setup_routes(self):
        # Device management
        self.app.router.add_get('/devices', self.get_devices)
        self.app.router.add_post('/devices/discover', self.discover_devices)
        self.app.router.add_get('/devices/{device_id}', self.get_device)
        self.app.router.add_post('/devices/commission', self.commission_device)
        self.app.router.add_post('/devices/{device_id}/decommission', self.decommission_device)
        self.app.router.add_delete('/devices/{device_id}', self.remove_device)

        # Cluster and attributes
        self.app.router.add_get('/devices/{device_id}/clusters', self.get_clusters)
        self.app.router.add_get('/devices/{device_id}/attributes', self.get_attributes)
        self.app.router.add_get('/devices/{device_id}/attributes/{attribute_id}', self.read_attribute)
        self.app.router.add_put('/devices/{device_id}/attributes/{attribute_id}', self.write_attribute)

        # Commands
        self.app.router.add_post('/devices/{device_id}/command', self.send_command)
        self.app.router.add_post('/devices/{device_id}/cluster/{cluster_id}/command/{command_id}', self.send_cluster_command)

        # Device info and state
        self.app.router.add_get('/devices/{device_id}/info', self.get_device_info)
        self.app.router.add_get('/devices/{device_id}/endpoints', self.get_endpoints)
        self.app.router.add_post('/devices/{device_id}/subscribe', self.subscribe_attributes)

    async def get_devices(self, request):
        return web.json_response(list(self.devices.values()))

    async def discover_devices(self, request):
        discovered = [
            {
                'device_id': 'matter_light_001',
                'vendor_id': 4874,
                'product_id': 1234,
                'device_type': 256,
                'device_name': 'Matter Light Bulb',
                'commissioned': False
            },
            {
                'device_id': 'matter_sensor_001',
                'vendor_id': 4874,
                'product_id': 5678,
                'device_type': 770,
                'device_name': 'Matter Temperature Sensor',
                'commissioned': False
            }
        ]

        return web.json_response({
            'status': 'success',
            'discovered': discovered
        })

    async def get_device(self, request):
        device_id = request.match_info['device_id']
        if device_id in self.devices:
            return web.json_response(self.devices[device_id])
        return web.json_response({'error': 'Device not found'}, status=404)

    async def commission_device(self, request):
        if self.commissioning:
            return web.json_response({'error': 'Commission already in progress'}, status=409)

        data = await request.json()
        setup_code = data.get('setup_code')
        device_id = data.get('device_id', 'matter_device_new')

        self.commissioning = True

        self.devices[device_id] = {
            'device_id': device_id,
            'setup_code': setup_code,
            'commissioned': True,
            'vendor_id': 4874,
            'product_id': 1234,
            'device_type': 256,
            'device_name': 'Matter Device',
            'commissioned_at': datetime.now().isoformat(),
            'reachable': True
        }

        self.commissioning = False

        return web.json_response({
            'status': 'commissioned',
            'device': self.devices[device_id]
        })

    async def decommission_device(self, request):
        device_id = request.match_info['device_id']
        if device_id in self.devices:
            self.devices[device_id]['commissioned'] = False
            return web.json_response({'status': 'success', 'message': 'Device decommissioned'})
        return web.json_response({'error': 'Device not found'}, status=404)

    async def remove_device(self, request):
        device_id = request.match_info['device_id']
        if device_id in self.devices:
            del self.devices[device_id]
            return web.json_response({'status': 'success', 'message': 'Device removed'})
        return web.json_response({'error': 'Device not found'}, status=404)

    async def get_clusters(self, request):
        device_id = request.match_info['device_id']
        if device_id not in self.devices:
            return web.json_response({'error': 'Device not found'}, status=404)

        clusters = [
            {'cluster_id': 6, 'name': 'OnOff', 'server': True},
            {'cluster_id': 8, 'name': 'LevelControl', 'server': True},
            {'cluster_id': 768, 'name': 'ColorControl', 'server': True},
            {'cluster_id': 29, 'name': 'BasicInformation', 'server': True}
        ]

        return web.json_response({
            'device_id': device_id,
            'clusters': clusters
        })

    async def get_attributes(self, request):
        device_id = request.match_info['device_id']
        if device_id not in self.devices:
            return web.json_response({'error': 'Device not found'}, status=404)

        attributes = {
            'on_off': {'cluster': 6, 'attribute': 0, 'value': False},
            'current_level': {'cluster': 8, 'attribute': 0, 'value': 128},
            'current_hue': {'cluster': 768, 'attribute': 0, 'value': 0},
            'current_saturation': {'cluster': 768, 'attribute': 1, 'value': 0}
        }

        return web.json_response({
            'device_id': device_id,
            'attributes': attributes
        })

    async def read_attribute(self, request):
        device_id = request.match_info['device_id']
        attribute_id = request.match_info['attribute_id']

        if device_id not in self.devices:
            return web.json_response({'error': 'Device not found'}, status=404)

        return web.json_response({
            'device_id': device_id,
            'attribute_id': attribute_id,
            'value': 0,
            'timestamp': datetime.now().isoformat()
        })

    async def write_attribute(self, request):
        device_id = request.match_info['device_id']
        attribute_id = request.match_info['attribute_id']
        data = await request.json()
        value = data.get('value')

        if device_id not in self.devices:
            return web.json_response({'error': 'Device not found'}, status=404)

        return web.json_response({
            'status': 'success',
            'device_id': device_id,
            'attribute_id': attribute_id,
            'value': value
        })

    async def send_command(self, request):
        device_id = request.match_info['device_id']
        data = await request.json()
        cluster_id = data.get('cluster_id')
        command_id = data.get('command_id')
        args = data.get('args', [])

        if device_id not in self.devices:
            return web.json_response({'error': 'Device not found'}, status=404)

        return web.json_response({
            'status': 'success',
            'device_id': device_id,
            'cluster_id': cluster_id,
            'command_id': command_id,
            'args': args
        })

    async def send_cluster_command(self, request):
        device_id = request.match_info['device_id']
        cluster_id = int(request.match_info['cluster_id'])
        command_id = int(request.match_info['command_id'])
        data = await request.json()
        args = data.get('args', [])

        if device_id not in self.devices:
            return web.json_response({'error': 'Device not found'}, status=404)

        return web.json_response({
            'status': 'success',
            'device_id': device_id,
            'cluster_id': cluster_id,
            'command_id': command_id,
            'args': args,
            'response': {}
        })

    async def get_device_info(self, request):
        device_id = request.match_info['device_id']
        if device_id not in self.devices:
            return web.json_response({'error': 'Device not found'}, status=404)

        return web.json_response({
            'device_id': device_id,
            'vendor_name': 'Matter Device Manufacturer',
            'product_name': 'Matter Light',
            'hardware_version': 1,
            'software_version': '1.0.0',
            'serial_number': 'MTR123456789',
            'unique_id': device_id
        })

    async def get_endpoints(self, request):
        device_id = request.match_info['device_id']
        if device_id not in self.devices:
            return web.json_response({'error': 'Device not found'}, status=404)

        endpoints = [
            {
                'endpoint_id': 0,
                'device_type': 22,
                'clusters': [29, 31, 40, 48, 49, 50, 51]
            },
            {
                'endpoint_id': 1,
                'device_type': 256,
                'clusters': [3, 4, 5, 6, 8, 768]
            }
        ]

        return web.json_response({
            'device_id': device_id,
            'endpoints': endpoints
        })

    async def subscribe_attributes(self, request):
        device_id = request.match_info['device_id']
        data = await request.json()
        attributes = data.get('attributes', [])

        if device_id not in self.devices:
            return web.json_response({'error': 'Device not found'}, status=404)

        return web.json_response({
            'status': 'success',
            'device_id': device_id,
            'subscribed_attributes': attributes,
            'subscription_id': 'sub_12345'
        })

    def run(self, host='0.0.0.0', port=8083):
        web.run_app(self.app, host=host, port=port)

if __name__ == '__main__':
    service = MatterMicroservice()
    service.run()
