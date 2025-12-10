import 'dart:async';
import 'package:dart_common/dart_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend_flutter/cubits/devices_cubit.dart';

class ZigbeePairingFakeScreen extends StatefulWidget {
  const ZigbeePairingFakeScreen({super.key});
  @override
  State<ZigbeePairingFakeScreen> createState() => _ZigbeePairingFakeScreenState();
}

class _ZigbeePairingFakeScreenState extends State<ZigbeePairingFakeScreen> {
  final List<Device> _discoveredDevices = [];
  Device? _selectedDevice;
  Timer? _discoveryTimer;
  int _deviceCounter = 0;
  List<Device> _availableDevices = [];
  @override
  void initState() {
    super.initState();
    final devices = context.read<DevicesCubit>().state;
    _availableDevices = devices.where((d) => d.integration == IntegrationType.zigbee).toList();
    _startDiscovery();
  }
  @override
  void dispose() {
    _discoveryTimer?.cancel();
    super.dispose();
  }
  String _getGenericName(int index) {
    final types = ['Temperature Sensor', 'Motion Sensor', 'Door Sensor', 'Light Switch', 'Smart Plug'];
    return types[index % types.length];
  }
  String _getDeviceType(int index) {
    final types = ['EndDevice', 'Router', 'EndDevice', 'Router', 'EndDevice'];
    return types[index % types.length];
  }
  String _generateIeeeAddress(String deviceId) {
    final hex = deviceId.replaceAll('-', '');
    return '${hex.substring(0, 2)}:${hex.substring(2, 4)}:${hex.substring(4, 6)}:${hex.substring(6, 8)}:${hex.substring(8, 10)}:${hex.substring(10, 12)}:${hex.substring(12, 14)}:${hex.substring(14, 16)}';
  }
  String _generateNwk(int index) {
    final values = ['0x626a', '0x1a3f', '0x8c2d', '0x4b91', '0xf7e5'];
    return values[index % values.length];
  }
  void _startDiscovery() {
    _discoveryTimer = Timer.periodic(const Duration(seconds: 3, milliseconds: 500), (timer) {
      if (_deviceCounter < _availableDevices.length) {
        setState(() {
          _discoveredDevices.add(_availableDevices[_deviceCounter]);
          _deviceCounter++;
        });
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Додавання Zigbee-пристрою'),
      ),
      body: _selectedDevice == null ? _buildDiscoveryView(colorScheme) : _buildDeviceDetailsView(colorScheme),
    );
  }
  Widget _buildDiscoveryView(ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200, width: 2),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
                    child: Icon(Icons.check, color: Colors.green.shade700, size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(child: Text('Режим спарювання активовано', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                ],
              ),
              const SizedBox(height: 16),
              Text('Координатор ConBee III шукає нові пристрої в мережі', style: TextStyle(fontSize: 14, color: Colors.grey.shade600), textAlign: TextAlign.center),
            ],
          ),
        ),
        Expanded(
          child: _discoveredDevices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 64, height: 64, child: CircularProgressIndicator(strokeWidth: 6, valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600))),
                      const SizedBox(height: 24),
                      Text('Очікування виявлення пристроїв', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _discoveredDevices.length,
                  itemBuilder: (context, index) {
                    final device = _discoveredDevices[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.thermostat, color: Colors.green, size: 28),
                        ),
                        title: Text(_getGenericName(index), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${device.integration.value} - ${device.id.substring(0, 8)}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => setState(() => _selectedDevice = device),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
  Widget _buildDeviceDetailsView(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Center(child: Icon(Icons.thermostat, size: 120, color: colorScheme.primary.withValues(alpha: 0.7))),
          const SizedBox(height: 32),
          Text(_getGenericName(_discoveredDevices.indexOf(_selectedDevice!)), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('Інформація про пристрій', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow('IEEE', _generateIeeeAddress(_selectedDevice!.id)),
                const SizedBox(height: 8),
                _buildInfoRow('Device Type', _getDeviceType(_discoveredDevices.indexOf(_selectedDevice!))),
                const SizedBox(height: 8),
                _buildInfoRow('NWK', _generateNwk(_discoveredDevices.indexOf(_selectedDevice!))),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Підключити', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => setState(() => _selectedDevice = null),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Назад', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
