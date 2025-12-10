import 'dart:async';
import 'package:dart_common/dart_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend_flutter/cubits/devices_cubit.dart';

class MatterCommissionFakeScreen extends StatefulWidget {
  const MatterCommissionFakeScreen({super.key});
  @override
  State<MatterCommissionFakeScreen> createState() => _MatterCommissionFakeScreenState();
}

class _MatterCommissionFakeScreenState extends State<MatterCommissionFakeScreen> {
  final List<Device> _discoveredDevices = [];
  Device? _selectedDevice;
  Timer? _discoveryTimer;
  int _deviceCounter = 0;
  List<Device> _availableDevices = [];
  @override
  void initState() {
    super.initState();
    final devices = context.read<DevicesCubit>().state;
    _availableDevices = devices.where((d) => d.integration == IntegrationType.matter).toList();
    _startDiscovery();
  }
  @override
  void dispose() {
    _discoveryTimer?.cancel();
    super.dispose();
  }
  String _getGenericName(int index) {
    final types = ['Smart Light', 'Smart Outlet', 'Light Strip', 'Dimmer Switch', 'Color Bulb'];
    return types[index % types.length];
  }
  void _startDiscovery() {
    _discoveryTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
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
        title: const Text('Комісування Matter-пристрою'),
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
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Пошук Matter-пристроїв', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Виявлення пристроїв через механізм комісування', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _discoveredDevices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
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
                          decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.lightbulb_outline, color: Colors.purple, size: 28),
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
          Center(child: Icon(Icons.lightbulb_outline, size: 120, color: colorScheme.primary.withValues(alpha: 0.7))),
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
                _buildInfoRow('Назва', _getGenericName(_discoveredDevices.indexOf(_selectedDevice!))),
                const SizedBox(height: 8),
                _buildInfoRow('ID пристрою', _selectedDevice!.id),
                const SizedBox(height: 8),
                _buildInfoRow('Протокол', _selectedDevice!.integration.value),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Код комісування', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.vpn_key, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(_selectedDevice!.id.replaceAll('-', '').substring(0, 11), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    ],
                  ),
                ),
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
